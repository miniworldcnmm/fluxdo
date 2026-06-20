import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/s.dart';
import '../../models/read_later_item.dart';
import '../../providers/read_later_provider.dart';
import '../../pages/topic_detail_page/topic_detail_page.dart';
import '../../services/local_notification_service.dart'; // navigatorKey
import '../../utils/dialog_utils.dart';
import '../../utils/time_utils.dart';
import '../common/app_bottom_sheet.dart';

/// 稍后阅读列表 BottomSheet
class ReadLaterSheet extends ConsumerWidget {
  const ReadLaterSheet({super.key});

  /// 显示稍后阅读列表
  static Future<void> show() {
    final context = navigatorKey.currentContext;
    if (context == null) return Future.value();
    return showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReadLaterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(readLaterProvider);
    final theme = Theme.of(context);

    // 删除最后一个后自动关闭
    ref.listen<List<ReadLaterItem>>(readLaterProvider, (prev, next) {
      if (next.isEmpty && (prev?.isNotEmpty ?? false)) {
        Navigator.of(context).pop();
      }
    });

    return AppSheetScaffold(
      showCloseButton: false,
      contentPadding: EdgeInsets.zero,
      maxHeightFactor: 0.6,
      titleWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.readLater_title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${items.length}/$maxReadLaterItems',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            _buildItem(context, ref, items[index], theme),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    WidgetRef ref,
    ReadLaterItem item,
    ThemeData theme,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        item.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        TimeUtils.formatRelativeTime(item.addedAt),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.delete_outline,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onPressed: () {
          ref.read(readLaterProvider.notifier).remove(item.topicId);
        },
      ),
      onTap: () {
        // 关闭 Sheet
        Navigator.pop(context);
        // 跳转到话题详情
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => TopicDetailPage(
              topicId: item.topicId,
              initialTitle: item.title,
              scrollToPostNumber: item.scrollToPostNumber,
            ),
          ),
        );
      },
    );
  }
}
