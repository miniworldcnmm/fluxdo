import 'package:ai_model_manager/ai_model_manager.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../l10n/s.dart';
import '../../utils/dialog_utils.dart';

/// 弹出模型选择 sheet
///
/// 设计参考 Kelivo `model_select_sheet.dart`：搜索框 + 按 provider 分组 +
/// 当前/默认模型高亮 + brand logo + 能力标签。
///
/// 选中时返回选中的 model；用户取消时返回 null。
Future<({AiProvider provider, AiModel model})?> showAiModelSelectSheet({
  required BuildContext context,
  required List<({AiProvider provider, AiModel model})> allModels,
  required ({AiProvider provider, AiModel model}) current,
}) {
  return showAppBottomSheet<({AiProvider provider, AiModel model})>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AiModelSelectSheet(
      allModels: allModels,
      current: current,
    ),
  );
}

class _AiModelSelectSheet extends StatefulWidget {
  const _AiModelSelectSheet({
    required this.allModels,
    required this.current,
  });

  final List<({AiProvider provider, AiModel model})> allModels;
  final ({AiProvider provider, AiModel model}) current;

  @override
  State<_AiModelSelectSheet> createState() => _AiModelSelectSheetState();
}

class _AiModelSelectSheetState extends State<_AiModelSelectSheet> {
  final _searchController = TextEditingController();
  final _scrollController = AutoScrollController(axis: Axis.vertical);
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;

    final filtered = _filterModels();
    final groups = _groupByProvider(filtered);

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            // 搜索框（去掉冗余标题栏，drag handle 已经表明这是 sheet）
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: S.current.ai_modelSearchHint,
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHigh,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // 列表 / 空状态
            Flexible(
              child: filtered.isEmpty
                  ? _buildEmpty(theme)
                  : _buildList(groups, theme),
            ),
            // 底部 provider 快速跳转 dock（仅当 ≥2 个 provider 且非搜索空态）
            if (filtered.isNotEmpty) _buildProviderDock(groups, theme),
          ],
        ),
      ),
    );
  }

  List<({AiProvider provider, AiModel model})> _filterModels() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.allModels;
    return widget.allModels.where((m) {
      final name = (m.model.name ?? m.model.id).toLowerCase();
      final id = m.model.id.toLowerCase();
      final provider = m.provider.name.toLowerCase();
      return name.contains(q) || id.contains(q) || provider.contains(q);
    }).toList(growable: false);
  }

  /// 按 provider 分组并保持原 order
  Map<String, List<({AiProvider provider, AiModel model})>> _groupByProvider(
    List<({AiProvider provider, AiModel model})> models,
  ) {
    final result = <String, List<({AiProvider provider, AiModel model})>>{};
    for (final m in models) {
      result.putIfAbsent(m.provider.id, () => []).add(m);
    }
    return result;
  }

  Widget _buildEmpty(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            S.current.ai_modelSearchNoMatch,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    Map<String, List<({AiProvider provider, AiModel model})>> groups,
    ThemeData theme,
  ) {
    final entries = groups.entries.toList(growable: false);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      itemCount: entries.length,
      itemBuilder: (context, idx) {
        final entry = entries[idx];
        final providerName = entry.value.first.provider.name;
        return AutoScrollTag(
          key: ValueKey('section_${entry.key}'),
          controller: _scrollController,
          index: idx,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Text(
                  providerName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              for (final m in entry.value)
                _ModelRow(item: m, current: widget.current),
            ],
          ),
        );
      },
    );
  }

  /// 底部 provider 快速跳转 dock
  ///
  /// 横向 logo 列表，点击 → 滚动到对应 provider section
  Widget _buildProviderDock(
    Map<String, List<({AiProvider provider, AiModel model})>> groups,
    ThemeData theme,
  ) {
    final entries = groups.entries.toList(growable: false);
    if (entries.length <= 1) return const SizedBox.shrink();
    final currentProviderId = widget.current.provider.id;
    // 单行胶囊（参考 Kelivo `_ProviderChip` 设计）：
    // - 边框轮廓样式，不用填充背景（更轻、不抢主列表）
    // - logo 18px + 名字横排
    // - 选中态用极浅 primary tint 背景（alpha 0.05-0.08，比 primaryContainer 克制）
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.25);
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, idx) {
            final entry = entries[idx];
            final provider = entry.value.first.provider;
            final isCurrent = provider.id == currentProviderId;
            final bg = isCurrent
                ? theme.colorScheme.primary
                    .withValues(alpha: isDark ? 0.08 : 0.05)
                : Colors.transparent;
            return Material(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => _scrollController.scrollToIndex(
                  idx,
                  preferPosition: AutoScrollPosition.begin,
                  duration: const Duration(milliseconds: 280),
                ),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ModelIcon(
                        providerName: provider.name,
                        modelName: provider.name,
                        size: 18,
                        withBackground: false,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        provider.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 这条 row 是否需要展示能力 badge 行
bool _hasAnyBadge(AiModel model, bool isImageOut) {
  return isImageOut ||
      model.input.contains(Modality.image) ||
      model.abilities.contains(ModelAbility.reasoning) ||
      model.abilities.contains(ModelAbility.tool);
}

class _ModelRow extends StatelessWidget {
  const _ModelRow({required this.item, required this.current});

  final ({AiProvider provider, AiModel model}) item;
  final ({AiProvider provider, AiModel model}) current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrent = item.provider.id == current.provider.id &&
        item.model.id == current.model.id;
    final modelName = item.model.name ?? item.model.id;
    final isImageOut = item.model.output.contains(Modality.image);

    return Material(
      color: isCurrent
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ModelIcon(
                providerName: item.provider.name,
                modelName: modelName,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      modelName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.model.id != modelName)
                      Text(
                        item.model.id,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (_hasAnyBadge(item.model, isImageOut)) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          if (isImageOut)
                            _CapabilityBadge(
                              icon: Icons.image_outlined,
                              label: 'image',
                              color: const Color(0xFFEA580C),
                            ),
                          // vision = 模型 input 含 image（多模态识图能力）
                          if (item.model.input.contains(Modality.image))
                            _CapabilityBadge(
                              icon: Icons.visibility_outlined,
                              label: 'vision',
                              color: theme.colorScheme.tertiary,
                            ),
                          if (item.model.abilities
                              .contains(ModelAbility.reasoning))
                            _CapabilityBadge(
                              icon: Icons.psychology_alt_outlined,
                              label: 'reasoning',
                              color: theme.colorScheme.secondary,
                            ),
                          if (item.model.abilities.contains(ModelAbility.tool))
                            _CapabilityBadge(
                              icon: Icons.build_outlined,
                              label: 'tool',
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isCurrent)
                Icon(Icons.check_circle,
                    size: 20, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapabilityBadge extends StatelessWidget {
  const _CapabilityBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
