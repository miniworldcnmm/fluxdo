import 'package:flutter/material.dart';

import '../../l10n/s.dart';
import '../../utils/dialog_utils.dart';

/// 弹出 AI 输入区的"+"号工具菜单
///
/// 视觉参考 Kelivo BottomToolsSheet：drag handle + 横排圆角卡片。
/// 三张卡片：拍照 / 相册 / 切生图（图像模式下变"退出生图"）
Future<void> showAiBottomToolsSheet({
  required BuildContext context,
  VoidCallback? onCamera,
  VoidCallback? onPhotos,
  VoidCallback? onToggleImageMode,
  bool imageMode = false,
  bool imageModeAvailable = false,
}) {
  return showAppBottomSheet<void>(
    context: context,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AiBottomToolsSheet(
      onCamera: onCamera,
      onPhotos: onPhotos,
      onToggleImageMode: onToggleImageMode,
      imageMode: imageMode,
      imageModeAvailable: imageModeAvailable,
    ),
  );
}

class _AiBottomToolsSheet extends StatelessWidget {
  const _AiBottomToolsSheet({
    this.onCamera,
    this.onPhotos,
    this.onToggleImageMode,
    this.imageMode = false,
    this.imageModeAvailable = false,
  });

  final VoidCallback? onCamera;
  final VoidCallback? onPhotos;
  final VoidCallback? onToggleImageMode;
  final bool imageMode;
  final bool imageModeAvailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _ToolCard(
                  icon: Icons.camera_alt_outlined,
                  label: S.current.ai_toolsCamera,
                  onTap: onCamera == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          onCamera!();
                        },
                ),
                const SizedBox(width: 12),
                _ToolCard(
                  icon: Icons.photo_library_outlined,
                  label: S.current.ai_toolsPhotos,
                  onTap: onPhotos == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          onPhotos!();
                        },
                ),
                const SizedBox(width: 12),
                _ToolCard(
                  icon: imageMode ? Icons.brush : Icons.brush_outlined,
                  label: imageMode
                      ? S.current.ai_modeBackToChat
                      : S.current.ai_modeSwitchToImage,
                  active: imageMode,
                  // disabled 视觉但仍可点 → 父级会弹引导 dialog
                  dimmed: !imageModeAvailable && !imageMode,
                  onTap: onToggleImageMode == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          onToggleImageMode!();
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Kelivo 风格的圆角动作卡片（72 高，icon 在上 label 在下）
class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.dimmed = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// active 用 primaryContainer 背景 + primary 前景，区分"已激活"状态
  final bool active;

  /// dimmed 用 onSurface 40% alpha，表示功能不可用（但仍可点弹引导）
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = active
        ? theme.colorScheme.primaryContainer
        : (isDark ? Colors.white10 : const Color(0xFFF2F3F5));
    final fg = active
        ? theme.colorScheme.onPrimaryContainer
        : (dimmed
            ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
            : theme.colorScheme.onSurface);

    return Expanded(
      child: SizedBox(
        height: 80,
        child: Material(
          color: baseColor,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 26, color: fg),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: fg,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
