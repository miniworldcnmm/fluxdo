import 'package:flutter/material.dart';

/// 把 PromptPreset.iconRaw 渲染成一个 Widget
///
/// iconRaw 可以是：
/// - emoji 字符（首 rune > 0xFF）：直接用 Text 渲染
/// - Material icon name（小写下划线）：查表
/// - 未知：fallback 到 Icons.auto_awesome_outlined
class PresetIcon extends StatelessWidget {
  const PresetIcon({
    super.key,
    required this.iconRaw,
    this.size = 18,
    this.color,
  });

  final String iconRaw;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (_looksLikeEmoji(iconRaw)) {
      // emoji 用 Text，字号略小一点保证视觉等高
      return Text(
        iconRaw,
        style: TextStyle(fontSize: size * 0.95, height: 1),
      );
    }
    final icon = _materialIconMap[iconRaw] ?? Icons.auto_awesome_outlined;
    return Icon(icon, size: size, color: color);
  }

  static bool _looksLikeEmoji(String s) {
    if (s.isEmpty) return false;
    final first = s.runes.first;
    // 排除 ASCII 字母、数字、下划线、冒号等
    if (first < 0x80) return false;
    return true;
  }
}

/// 暴露给 IconEmojiPicker 使用的 outlined icon 候选集
const List<String> kBuiltInIconNames = [
  'image_outlined',
  'brush_outlined',
  'draw_outlined',
  'palette_outlined',
  'auto_awesome_outlined',
  'lightbulb_outlined',
  'summarize_outlined',
  'translate_outlined',
  'question_answer_outlined',
  'smart_toy_outlined',
  'emoji_emotions_outlined',
  'camera_alt_outlined',
  'movie_outlined',
  'map_outlined',
  'favorite_outline',
  'star_outline',
  'share_outlined',
  'crop_din_outlined',
  'view_in_ar_outlined',
  'sticky_note_2_outlined',
  'grid_4x4',
];

/// Material icon name → IconData 映射
const Map<String, IconData> _materialIconMap = {
  'image_outlined': Icons.image_outlined,
  'brush_outlined': Icons.brush_outlined,
  'draw_outlined': Icons.draw_outlined,
  'palette_outlined': Icons.palette_outlined,
  'auto_awesome_outlined': Icons.auto_awesome_outlined,
  'lightbulb_outlined': Icons.lightbulb_outlined,
  'summarize_outlined': Icons.summarize_outlined,
  'translate_outlined': Icons.translate_outlined,
  'question_answer_outlined': Icons.question_answer_outlined,
  'smart_toy_outlined': Icons.smart_toy_outlined,
  'emoji_emotions_outlined': Icons.emoji_emotions_outlined,
  'camera_alt_outlined': Icons.camera_alt_outlined,
  'movie_outlined': Icons.movie_outlined,
  'map_outlined': Icons.map_outlined,
  'favorite_outline': Icons.favorite_outline,
  'star_outline': Icons.star_outline,
  'share_outlined': Icons.share_outlined,
  'crop_din_outlined': Icons.crop_din_outlined,
  'view_in_ar_outlined': Icons.view_in_ar_outlined,
  'sticky_note_2_outlined': Icons.sticky_note_2_outlined,
  'grid_4x4': Icons.grid_4x4,
  // 兼容历史 chip 用的图标（防止预设 iconRaw 找不到时降级）
  'image': Icons.image_outlined,
  'brush': Icons.brush_outlined,
  'draw': Icons.draw_outlined,
};
