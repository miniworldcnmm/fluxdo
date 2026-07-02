import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 在 [CacheObjectProvider]（sqlite 后端）之上做三个针对性优化。
///
/// 背景：CacheStore 每个 key 的会话首访会 `get(key)` 后立即回写一次 touched
/// 时间戳（`_getCacheDataFromDatabase` → `_updateCacheDataInDatabase`）。
/// sqflite 每条 UPDATE 是独立事务 = 一次 fsync；首次打开表情面板几百张图
/// 就是几百个 fsync 串行排队，把后续 SELECT 全部堵住 → 初次加载明显变慢。
///
/// 1. **touch 节流**（对齐已删除的 HiveCacheInfoRepository 同名优化）：
///    「除 touched 外字段与上次落盘一致」的纯 touch 更新，1 小时内跳过落盘。
///    LRU 淘汰精度损失可忽略（stalePeriod 是 7~90 天），写入量降约两个数量级。
/// 2. **WAL + synchronous=NORMAL**：写不再阻塞读，fsync 从每事务一次降为
///    checkpoint 批量。WAL 下 NORMAL 掉电最多丢最近几次 touched 更新，
///    索引本身不会损坏。
/// 3. **补 key 索引**：上游 onCreate 把建表与建索引写在同一条 `execute` 里，
///    而 sqflite 单次只执行第一条语句 → 全新建库时 key 索引实际从未创建，
///    `get(key)` 在上万行表上是全表扫描。这里用幂等 DDL 补上（索引名与
///    上游 onUpgrade 路径创建的一致，已存在则跳过）。
class ThrottledCacheObjectProvider extends CacheObjectProvider {
  ThrottledCacheObjectProvider({required String databaseName})
      : super(databaseName: databaseName);

  /// 纯 touch 更新的最小落盘间隔。
  static const Duration _touchPersistInterval = Duration(hours: 1);

  /// key -> 上次落盘状态（非 touched 字段指纹 + touched 毫秒）。
  /// 仅会话内有效；条目数最多为本会话访问过的 key 数，单条几十字节。
  final Map<String, ({String fp, int touchedMs})> _persisted = {};

  bool _tuned = false;

  @override
  Future<bool> open() async {
    final result = await super.open();
    final database = db;
    if (database != null && !_tuned) {
      _tuned = true;
      try {
        // journal_mode pragma 会返回结果行，用 rawQuery 而非 execute，
        // 避免 Android 底层把「有返回值的 execute」当错误。
        await database.rawQuery('PRAGMA journal_mode=WAL');
        await database.execute('PRAGMA synchronous=NORMAL');
        await database.execute(
          'CREATE INDEX IF NOT EXISTS cacheObjectkey ON cacheObject (key)',
        );
      } catch (e) {
        // 调优失败不影响功能，退化为上游默认行为。
        debugPrint('[ThrottledCacheObjectProvider] $databaseName 调优失败: $e');
      }
    }
    return result;
  }

  @override
  Future<CacheObject?> get(String key) async {
    final result = await super.get(key);
    if (result != null) _record(result);
    return result;
  }

  @override
  Future<List<CacheObject>> getAllObjects() async {
    final result = await super.getAllObjects();
    for (final obj in result) {
      _record(obj);
    }
    return result;
  }

  @override
  Future<CacheObject> insert(
    CacheObject cacheObject, {
    bool setTouchedToNow = true,
  }) async {
    final result = await super.insert(
      cacheObject,
      setTouchedToNow: setTouchedToNow,
    );
    // insert 的 toMap 已把 touched 写成 now，但返回对象不携带；按 now 记录。
    _persisted[result.key] = (
      fp: _fingerprint(result),
      touchedMs: DateTime.now().millisecondsSinceEpoch,
    );
    return result;
  }

  @override
  Future<int> update(
    CacheObject cacheObject, {
    bool setTouchedToNow = true,
  }) async {
    final newTouchedMs = setTouchedToNow
        ? DateTime.now().millisecondsSinceEpoch
        : cacheObject.touched?.millisecondsSinceEpoch ?? 0;
    final prev = _persisted[cacheObject.key];
    if (prev != null &&
        prev.fp == _fingerprint(cacheObject) &&
        newTouchedMs - prev.touchedMs <
            _touchPersistInterval.inMilliseconds) {
      return 1; // 纯 touch 更新且间隔不足，跳过落盘
    }
    final result = await super.update(
      cacheObject,
      setTouchedToNow: setTouchedToNow,
    );
    _persisted[cacheObject.key] = (
      fp: _fingerprint(cacheObject),
      touchedMs: newTouchedMs,
    );
    return result;
  }

  void _record(CacheObject obj) {
    _persisted[obj.key] = (
      fp: _fingerprint(obj),
      touchedMs: obj.touched?.millisecondsSinceEpoch ?? 0,
    );
  }

  /// 除 touched 外全部字段的指纹，用于识别「纯 touch 更新」。
  String _fingerprint(CacheObject o) =>
      '${o.id}|${o.url}|${o.relativePath}|${o.eTag}|'
      '${o.validTill.millisecondsSinceEpoch}|${o.length}';
}
