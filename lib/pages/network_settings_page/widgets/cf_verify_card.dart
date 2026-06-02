import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/s.dart';
import '../../../providers/preferences_provider.dart';
import '../../../services/cf_challenge_service.dart';
import '../../../services/toast_service.dart';

/// Cloudflare 验证独立卡片：自动验证开关 + 立即验证入口
class CfVerifyCard extends ConsumerWidget {
  const CfVerifyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final autoEnabled = ref.watch(
      preferencesProvider.select((p) => p.autoCfChallenge),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.shield_outlined),
            title: Text(context.l10n.cfVerify_autoTitle),
            subtitle: Text(context.l10n.cfVerify_autoDesc),
            value: autoEnabled,
            onChanged: (value) => ref
                .read(preferencesProvider.notifier)
                .setAutoCfChallenge(value),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: Text(context.l10n.cf_securityVerifyTitle),
            subtitle: Text(context.l10n.error_securityChallenge),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _showManualVerify(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showManualVerify(BuildContext context) async {
    final result = await CfChallengeService().showManualVerifyNow(
      context,
      true,
    );

    if (!context.mounted) return;

    if (result == true) {
      ToastService.showSuccess(S.current.common_success);
    } else if (result == false) {
      ToastService.showError(S.current.cf_failedRetry);
    } else {
      ToastService.showError(S.current.cf_cannotOpenVerifyPage);
    }
  }
}
