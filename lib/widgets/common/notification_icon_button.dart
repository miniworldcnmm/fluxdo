import 'package:flutter/material.dart';
import 'package:app_icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/s.dart';
import '../../providers/message_bus/notification_providers.dart';
import '../notification/notification_quick_panel.dart';

class NotificationIconButton extends ConsumerWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(
      notificationCountStateProvider.select((s) => s.allUnread),
    );
    return IconButton(
      onPressed: () {
        NotificationQuickPanel.show(context);
      },
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
        child: const Icon(Symbols.notifications_rounded),
      ),
      tooltip: context.l10n.common_notification,
    );
  }
}
