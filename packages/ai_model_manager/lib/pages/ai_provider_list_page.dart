import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_provider.dart';
import '../providers/ai_provider_providers.dart';
import '../l10n/ai_l10n.dart';
import '../utils/dialog_utils.dart';
import '../widgets/model_icon.dart';
import '../widgets/swipe_action_cell.dart';
import 'ai_provider_edit_page.dart';

class AiProviderListPage extends ConsumerWidget {
  const AiProviderListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(aiProviderListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AiL10n.current.addProvider.replaceAll('添加', '').trim().isEmpty
            ? 'Providers'
            : AiL10n.current.addProvider.replaceAll('添加', '').trim()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: AiL10n.current.addProvider,
            onPressed: () => _navigateToEdit(context),
          ),
        ],
      ),
      body: providers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dns_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(AiL10n.current.noProviderConfigured,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text(AiL10n.current.addProviderHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7))),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _navigateToEdit(context),
                    icon: const Icon(Icons.add),
                    label: Text(AiL10n.current.addProvider),
                  ),
                ],
              ),
            )
          : SwipeActionScope(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: providers.length,
                itemBuilder: (ctx, i) {
                  final p = providers[i];
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: i < providers.length - 1 ? 8 : 0),
                    child: SwipeActionCell(
                      key: ValueKey(p.id),
                      trailingActions: [
                        SwipeAction(
                          icon: Icons.edit_outlined,
                          color: Colors.blue,
                          label: AiL10n.current.edit,
                          onPressed: () => _navigateToEdit(context, p),
                        ),
                        SwipeAction(
                          icon: Icons.delete_outline,
                          color: Colors.red,
                          label: AiL10n.current.delete,
                          onPressed: () =>
                              _confirmDelete(context, ref, p),
                        ),
                      ],
                      child: _ProviderCard(
                        provider: p,
                        onTap: () => _navigateToEdit(context, p),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _navigateToEdit(BuildContext context, [AiProvider? provider]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiProviderEditPage(provider: provider),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, AiProvider provider) {
    showAppDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AiL10n.current.confirmDelete),
        content: Text(AiL10n.current.confirmDeleteProvider(provider.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AiL10n.current.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(aiProviderListProvider.notifier)
                  .removeProvider(provider.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(AiL10n.current.delete),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final AiProvider provider;
  final VoidCallback onTap;

  const _ProviderCard({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCount = provider.models.length;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ModelIcon(
              providerName: provider.name,
              modelName: provider.name,
              size: 44,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          provider.type.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$totalCount',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                size: 20),
          ],
        ),
      ),
    );
  }
}
