import 'dart:convert';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxdo/services/hive_cache_info_repository.dart';
import 'package:fluxdo/storage/app_database.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  var seq = 0;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_cache_repo_test_');
    Hive.init(tempDir.path);
    AppDatabase.debugMarkInitialized();
  });

  tearDownAll(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // 临时目录清理失败不影响断言
    }
  });

  CacheObject newObject(String key, {String? eTag}) => CacheObject(
        'https://example.com/$key.png',
        key: key,
        relativePath: '$key.png',
        validTill: DateTime.now().add(const Duration(days: 7)),
        eTag: eTag,
      );

  test('insert / get 往返,close 后重开数据与 id 序列保持', () async {
    final name = 'repo_${seq++}';
    final repo = HiveCacheInfoRepository(databaseName: name);
    await repo.open();

    final inserted = await repo.insert(newObject('a'));
    expect(inserted.id, isNotNull);
    expect((await repo.get('a'))!.url, inserted.url);
    expect(await repo.get('missing'), isNull);

    await repo.close();

    final reopened = HiveCacheInfoRepository(databaseName: name);
    await reopened.open();
    expect((await reopened.get('a'))!.id, inserted.id);
    // id 序列从已有最大值继续,不与旧条目冲突
    final b = await reopened.insert(newObject('b'));
    expect(b.id, isNot(inserted.id));
    await reopened.close();
  });

  test('纯 touch 更新在节流窗口内跳过落盘,字段变化立即落盘', () async {
    final name = 'repo_${seq++}';
    final repo = HiveCacheInfoRepository(databaseName: name);
    await repo.open();
    final inserted = await repo.insert(newObject('a'));
    final box = await Hive.openBox<Map>('image_cache_meta_$name');

    Future<void> setStoredTouched(int millis) async {
      final raw = Map<String, dynamic>.from(box.get('a')!);
      raw[CacheObject.columnTouched] = millis;
      await box.put('a', raw);
    }

    // 磁盘 touched = 10 分钟前(< 1h 窗口)→ 纯 touch 更新被跳过
    final tenMinAgo = DateTime.now()
        .subtract(const Duration(minutes: 10))
        .millisecondsSinceEpoch;
    await setStoredTouched(tenMinAgo);
    await repo.update(inserted);
    expect(box.get('a')![CacheObject.columnTouched], tenMinAgo);

    // 磁盘 touched = 2 小时前(> 窗口)→ 落盘刷新
    final twoHoursAgo = DateTime.now()
        .subtract(const Duration(hours: 2))
        .millisecondsSinceEpoch;
    await setStoredTouched(twoHoursAgo);
    await repo.update(inserted);
    expect(
      box.get('a')![CacheObject.columnTouched] as int,
      greaterThan(twoHoursAgo),
    );

    // 窗口内但 eTag 变化 → 必须落盘
    await setStoredTouched(tenMinAgo);
    await repo.update(
      CacheObject(
        inserted.url,
        key: inserted.key,
        id: inserted.id,
        relativePath: inserted.relativePath,
        validTill: inserted.validTill,
        eTag: 'changed',
      ),
    );
    expect(box.get('a')![CacheObject.columnETag], 'changed');

    await repo.close();
  });

  test('getObjectsOverCapacity / getOldObjects / deleteAll', () async {
    final name = 'repo_${seq++}';
    final repo = HiveCacheInfoRepository(databaseName: name);
    await repo.open();
    final box = await Hive.openBox<Map>('image_cache_meta_$name');

    final ids = <int>[];
    for (var i = 0; i < 5; i++) {
      final obj = await repo.insert(newObject('k$i'));
      ids.add(obj.id!);
      // 错开 touched:k0 最旧(5 天前),k4 最新(1 天前)
      final raw = Map<String, dynamic>.from(box.get('k$i')!);
      raw[CacheObject.columnTouched] = DateTime.now()
          .subtract(Duration(days: 5 - i))
          .millisecondsSinceEpoch;
      await box.put('k$i', raw);
    }

    final over = await repo.getObjectsOverCapacity(3);
    expect(over.map((o) => o.key).toList(), ['k0', 'k1']);

    // 2.5 天的阈值落在 k2(3 天前)与 k3(2 天前)之间,避免边界歧义
    final old = await repo.getOldObjects(const Duration(days: 2, hours: 12));
    expect(old.map((o) => o.key).toSet(), {'k0', 'k1', 'k2'});

    expect(await repo.deleteAll(ids.take(2)), 2);
    expect(await repo.get('k0'), isNull);
    expect(await repo.get('k1'), isNull);
    expect(await repo.get('k2'), isNotNull);
    // 重复删除返回 0
    expect(await repo.delete(ids.first), 0);

    await repo.close();
  });

  test('首次 open 自动迁移旧 JSON 索引并删除源文件', () async {
    final name = 'repo_${seq++}';
    final jsonFile = File(p.join(tempDir.path, '$name.json'));
    final now = DateTime.now().millisecondsSinceEpoch;
    await jsonFile.writeAsString(jsonEncode([
      {
        CacheObject.columnId: 7,
        CacheObject.columnUrl: 'https://example.com/m1.png',
        CacheObject.columnKey: 'm1',
        CacheObject.columnPath: 'm1.png',
        CacheObject.columnValidTill: now + 1000000,
        CacheObject.columnTouched: now,
      },
      {
        CacheObject.columnId: 9,
        CacheObject.columnUrl: 'https://example.com/m2.png',
        CacheObject.columnKey: 'm2',
        CacheObject.columnPath: 'm2.png',
        CacheObject.columnValidTill: now + 1000000,
        CacheObject.columnTouched: now,
      },
    ]));

    final repo = HiveCacheInfoRepository(
      databaseName: name,
      legacyRepository: JsonCacheInfoRepository.withFile(jsonFile),
    );
    await repo.open();

    expect((await repo.get('m1'))!.id, 7);
    expect((await repo.get('m2'))!.id, 9);
    expect(jsonFile.existsSync(), isFalse, reason: '迁移完成后应删除 JSON 源文件');

    // 迁移后的 id 序列避开已有 id
    final fresh = await repo.insert(newObject('m3'));
    expect(fresh.id, greaterThan(9));

    await repo.close();
  });
}
