import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../l10n/l10n.dart';
import 'theme.dart';
import '../shared/widgets/animated_bottom_nav.dart';
import '../shared/widgets/app_pill.dart';

class ShellScreen extends StatefulWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    const tabs = ['/home', '/buses', '/schedules', '/notices', '/profile'];
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i])) return i;
    }
    return 0;
  }

  void _onTap(int index, BuildContext context) {
    const tabs = ['/home', '/buses', '/schedules', '/notices', '/profile'];
    context.go(tabs[index]);
  }

  bool _isHomeTab(BuildContext context) {
    return GoRouterState.of(context).uri.path == '/home';
  }

  Future<bool> _onWillPop() async {
    if (_isHomeTab(context)) {
      final shouldExit = await _showExitDialog();
      if (shouldExit == true) {
        SystemNavigator.pop();
      }
      return false;
    } else {
      context.go('/home');
      return false;
    }
  }

  Future<bool?> _showExitDialog() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space24,
                  AppTheme.space20,
                  AppTheme.space24,
                  AppTheme.space24,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(
                    color: isDark
                        ? Colors.white12
                        : AppTheme.textHint.withValues(alpha: 0.18),
                  ),
                  boxShadow: AppTheme.shadowLG,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppTheme.space20),
                      decoration: BoxDecoration(
                        color: AppTheme.textHint.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.power_settings_new_rounded,
                        color: AppTheme.error,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      ctx.l10n.exitAppTitle,
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      ctx.l10n.exitAppMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? Colors.white60
                                : AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppTheme.space24),
                    Row(
                      children: [
                        Expanded(
                          child: _SheetButton(
                            label: ctx.l10n.commonNo,
                            onTap: () => Navigator.of(ctx).pop(false),
                            tonal: true,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: _SheetButton(
                            label: ctx.l10n.commonYes,
                            onTap: () => Navigator.of(ctx).pop(true),
                            tonal: false,
                            danger: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = _calculateSelectedIndex(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: AppBottomNav(
          currentIndex: index,
          onTap: (i) => _onTap(i, context),
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onTap,
    required this.tonal,
    this.danger = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool tonal;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = danger ? AppTheme.error : AppTheme.bluePrimary;
    final bg = tonal
        ? color.withValues(alpha: 0.10)
        : (danger ? AppTheme.error : AppTheme.bluePrimary);
    final fg = tonal ? color : Colors.white;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: tonal
                ? Border.all(color: color.withValues(alpha: 0.30))
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// Re-export AppPill so screens that import this file still get a clean API.
export '../shared/widgets/app_pill.dart' show AppPill;
