import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/l10n.dart';

/// Placeholder for the Route tab.
///
/// Intentionally empty for now — the header only identifies the tab. Content
/// will be added once the route feature is specified.
class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppTheme.space24,
              left: AppTheme.space24,
              right: AppTheme.space24,
              bottom: AppTheme.space24,
            ),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradientFor(context),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(AppTheme.radiusExtraLarge),
              ),
            ),
            child: Text(
              context.l10n.navRoute,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }
}
