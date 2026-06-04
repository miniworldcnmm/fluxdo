import 'package:flutter/material.dart';

import '../../../services/eruda_settings_service.dart';

/// Eruda 设备内 DevTools 开关卡片（调试用）。
///
/// 开启后, 主站 WebView 页面右下角出现 ⚙ 悬浮按钮, 可打开
/// Console / Network / Elements / Sources 面板。默认关闭。
/// 见 [ErudaSettingsService]。
class ErudaCard extends StatelessWidget {
  const ErudaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ErudaSettingsService.instance;

    return ValueListenableBuilder<bool>(
      valueListenable: service.notifier,
      builder: (context, enabled, _) {
        return Card(
          clipBehavior: Clip.antiAlias,
          color: enabled
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: enabled
                ? BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  )
                : BorderSide.none,
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Eruda 调试控制台'),
                subtitle: Text(
                  enabled
                      ? '已开启：页面右下角 ⚙ 可看 Console / Network / Elements'
                      : '关闭（默认）。开启后可在页面内查看网络 / 控制台 / 元素',
                ),
                secondary: Icon(
                  enabled ? Icons.terminal : Icons.terminal_outlined,
                  color: enabled ? theme.colorScheme.primary : null,
                ),
                value: enabled,
                onChanged: (value) => service.setEnabled(value),
              ),
              if (enabled) ...[
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '切换后需重新打开相关页面 / 重启应用才生效',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
