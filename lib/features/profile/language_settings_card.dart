import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/locale_provider.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';

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
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    size: 20,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  context.l10n.profileLanguage,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(indent: 48, height: 1),
            _LanguageOption(
              icon: Icons.translate_rounded,
              title: context.l10n.languageBengali,
              selected: currentCode == 'bn',
              onTap: () =>
                  ref.read(localeProvider.notifier).setLanguageCode('bn'),
            ),
            const Divider(indent: 48, height: 1),
            _LanguageOption(
              icon: Icons.language_rounded,
              title: context.l10n.languageEnglish,
              selected: currentCode == 'en',
              onTap: () =>
                  ref.read(localeProvider.notifier).setLanguageCode('en'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontSize: 14),
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppTheme.primaryBlue : AppTheme.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
