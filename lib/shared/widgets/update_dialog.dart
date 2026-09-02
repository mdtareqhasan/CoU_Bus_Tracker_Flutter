import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../core/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onSkip;
  final VoidCallback? onUpdate;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    this.onSkip,
    this.onUpdate,
  });

  static Future<void> show(
    BuildContext context, {
    required UpdateInfo updateInfo,
    VoidCallback? onSkip,
    VoidCallback? onUpdate,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (_) => UpdateDialog(
        updateInfo: updateInfo,
        onSkip: onSkip,
        onUpdate: onUpdate,
      ),
    );
  }

  Future<void> _launchUpdate() async {
    final url = updateInfo.downloadUrl ?? '';
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    onUpdate?.call();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !updateInfo.forceUpdate,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ).animate().scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
              ),
              const SizedBox(height: AppTheme.space16),
              const Text(
                'নতুন আপডেট পাওয়া গেছে',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1F2E),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: AppTheme.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ভার্সন ${updateInfo.latestVersion}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              if (updateInfo.message != null &&
                  updateInfo.message!.isNotEmpty) ...[
                const SizedBox(height: AppTheme.space12),
                Text(
                  updateInfo.message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ],
              const SizedBox(height: AppTheme.space24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _launchUpdate,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'আপডেট করুন',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
              if (!updateInfo.forceUpdate) ...[
                const SizedBox(height: AppTheme.space12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () {
                      onSkip?.call();
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'পরে আপডেট করব',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
