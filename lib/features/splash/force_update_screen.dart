import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';

class ForceUpdateScreen extends StatelessWidget {
  /// Legacy single-language message (old backends / old cache).
  final String message;
  final String messageBn;
  final String messageEn;
  final String playStoreUrl;
  final bool forceUpdate;
  final VoidCallback? onSkip;

  const ForceUpdateScreen({
    super.key,
    required this.message,
    this.messageBn = '',
    this.messageEn = '',
    required this.playStoreUrl,
    required this.forceUpdate,
    this.onSkip,
  });

  /// Body copy for the active locale.
  ///
  /// Order: the admin's copy for this language → the other language → the
  /// legacy single-language value → the app's own translated default. That way
  /// an English rider never sees Bangla text merely because the panel's Bangla
  /// box was the only one filled in.
  String _messageFor(BuildContext context) {
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final preferred = (isBangla ? messageBn : messageEn).trim();
    final other = (isBangla ? messageEn : messageBn).trim();

    if (preferred.isNotEmpty) return preferred;
    if (other.isNotEmpty) return other;
    if (message.trim().isNotEmpty) return message.trim();
    return context.l10n.newVersionBody;
  }

  Future<void> _launchStore() async {
    final uri = Uri.parse(playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !forceUpdate) {
          onSkip?.call();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppTheme.primaryBlue,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    forceUpdate
                        ? context.l10n.forceUpdateTitle
                        : context.l10n.newVersionTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _messageFor(context),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _launchStore,
                      icon: const Icon(Icons.download_rounded),
                      label: Text(
                        context.l10n.updateNow,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  if (!forceUpdate) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: onSkip,
                      child: Text(
                        context.l10n.updateLater,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
