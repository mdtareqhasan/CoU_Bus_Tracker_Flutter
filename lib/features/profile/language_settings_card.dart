import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/locale_provider.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/app_pill.dart';

/// Language selection card shown on the Profile screen (both logged-in and
/// logged-out).
///
/// Switching re-renders the whole app immediately through [localeProvider] —
/// no restart — and persists via `StorageService.language_code`.
class LanguageSettingsCard extends ConsumerWidget {
  const LanguageSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCode = ref.watch(localeProvider).languageCode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space12,
        AppTheme.space24,
        AppTheme.space32,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.space16),
        elevation: GlassCardElevation.soft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.bluePrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    size: 18,
                    color: AppTheme.bluePrimary,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  context.l10n.profileLanguage,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space8,
              children: [
                AppPill(
                  label: context.l10n.languageBengali,
                  icon: Icons.translate_rounded,
                  color: AppTheme.bluePrimary,
                  selected: currentCode == 'bn',
                  dense: false,
                  onTap: () => ref
                      .read(localeProvider.notifier)
                      .setLanguageCode('bn'),
                ),
                AppPill(
                  label: context.l10n.languageEnglish,
                  icon: Icons.language_rounded,
                  color: AppTheme.cyanBright,
                  selected: currentCode == 'en',
                  dense: false,
                  onTap: () => ref
                      .read(localeProvider.notifier)
                      .setLanguageCode('en'),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }
}
