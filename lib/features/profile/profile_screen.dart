import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../auth/auth_provider.dart';
import '../auth/department_options.dart';
import '../auth/session_options.dart';
import 'language_settings_card.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/app_pill.dart';
import '../../shared/widgets/info_row.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/danger_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: authState.isLoggedIn
                  ? _buildLoggedInProfile(context, authState)
                  : _buildLoggedOutPrompt(context),
            ),
            const SliverToBoxAdapter(child: LanguageSettingsCard()),
            if (authState.isLoggedIn)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space24,
                    AppTheme.space32,
                    AppTheme.space24,
                    AppTheme.space48,
                  ),
                  child: _buildLogoutButton(context, ref),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.blueVivid,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => context.go('/home'),
      ),
      title: Text(
        context.l10n.profileTitle,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.2,
        ),
      ),
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.auroraHeaderGradient),
          ),
          Positioned(
            top: -40,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.cyanBright.withValues(alpha: 0.30),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.indigoDeep.withValues(alpha: 0.50),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.glassOverlay),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedOutPrompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space32,
        AppTheme.space24,
        AppTheme.space24,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.space24),
          _buildPromptIllustration(),
          const SizedBox(height: AppTheme.space32),
          Text(
            context.l10n.profileYourProfile,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: AppTheme.space12),
          Text(
            context.l10n.profileLoginPrompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: AppTheme.space32),
          PrimaryButton(
            label: context.l10n.profileLoginRegister,
            icon: Icons.login_rounded,
            onPressed: () => context.go('/auth/role'),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildPromptIllustration() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.blueVivid.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.10, 1.10),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  AppTheme.indigoDeep,
                  AppTheme.blueVivid,
                  AppTheme.cyanBright,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: AppTheme.auroraGlow,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }

  Widget _buildLoggedInProfile(BuildContext context, AuthState authState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space24,
        AppTheme.space24,
        0,
      ),
      child: Column(
        children: [
          _buildProfileHeader(context, authState),
          const SizedBox(height: AppTheme.space24),
          if (authState.idCardImageUrl != null &&
              authState.idCardImageUrl!.isNotEmpty)
            _buildIdCardSection(context, authState),
          const SizedBox(height: AppTheme.space24),
          _buildInfoCard(context, authState),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AuthState authState) {
    return Column(
      children: [
        // Avatar with aurora glow ring
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.indigoDeep,
                AppTheme.blueVivid,
                AppTheme.cyanBright,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.blueVivid, AppTheme.cyanBright],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  (authState.displayName ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
        const SizedBox(height: AppTheme.space16),
        Text(
          authState.displayName ?? context.l10n.commonUserName,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.15, end: 0),
        const SizedBox(height: 4),
        Text(
          authState.email != null && authState.email!.isNotEmpty
              ? authState.email!
              : '—',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: AppTheme.space12),
        AppPill(
          label: authState.role == 'student'
              ? context.l10n.roleStudent
              : context.l10n.roleTeacher,
          icon: Icons.badge_rounded,
          color: AppTheme.bluePrimary,
          outline: true,
          dense: true,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0),
      ],
    );
  }

  Widget _buildIdCardSection(BuildContext context, AuthState authState) {
    return GlassCard(
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
                  Icons.badge_outlined,
                  size: 18,
                  color: AppTheme.bluePrimary,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Text(
                context.l10n.profileIdCard,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            child: GestureDetector(
              onTap: () => _showFullIdCard(context, authState.idCardImageUrl!),
              child: CachedNetworkImage(
                imageUrl: authState.idCardImageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: AppTheme.bluePrimary.withValues(alpha: 0.06),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.bluePrimary,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: AppTheme.bluePrimary.withValues(alpha: 0.06),
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: AppTheme.error,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            context.l10n.profileTapToViewPhoto,
            style: const TextStyle(
              color: AppTheme.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0);
  }

  void _showFullIdCard(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, AuthState authState) {
    final isStudent = authState.role == 'student';

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space4,
      ),
      elevation: GlassCardElevation.soft,
      child: Column(
        children: [
          InfoRow(
            icon: Icons.person_outline_rounded,
            label: context.l10n.profileName,
            value: authState.displayName ?? '—',
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            color: AppTheme.bluePrimary.withValues(alpha: 0.06),
          ),
          InfoRow(
            icon: Icons.email_outlined,
            label: context.l10n.profileEmail,
            value: authState.email != null && authState.email!.isNotEmpty
                ? authState.email!
                : '—',
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            color: AppTheme.bluePrimary.withValues(alpha: 0.06),
          ),
          InfoRow(
            icon: Icons.badge_outlined,
            label: context.l10n.profileRole,
            value: isStudent
                ? context.l10n.roleStudent
                : context.l10n.roleTeacher,
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            color: AppTheme.bluePrimary.withValues(alpha: 0.06),
          ),
          InfoRow(
            icon: Icons.business_outlined,
            label: isStudent
                ? context.l10n.fieldDepartment
                : context.l10n.fieldDepartmentOffice,
            value: _localizedOrDash(
              authState.department,
              (value) => departmentLabelFor(value, context.l10n),
            ),
            maxLines: 2,
          ),
          if (isStudent) ...[
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              color: AppTheme.bluePrimary.withValues(alpha: 0.06),
            ),
            InfoRow(
              icon: Icons.pin_outlined,
              label: context.l10n.fieldRollNumber,
              value: _localizedOrDash(authState.rollNumber, (value) => value),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              color: AppTheme.bluePrimary.withValues(alpha: 0.06),
            ),
            InfoRow(
              icon: Icons.class_outlined,
              label: context.l10n.fieldSession,
              value: _localizedOrDash(
                authState.session,
                (value) => sessionLabelFor(value, context.l10n),
              ),
            ),
          ] else ...[
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              color: AppTheme.bluePrimary.withValues(alpha: 0.06),
            ),
            InfoRow(
              icon: Icons.work_outline_rounded,
              label: context.l10n.fieldDesignation,
              value: _localizedOrDash(authState.designation, (value) => value),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              color: AppTheme.bluePrimary.withValues(alpha: 0.06),
            ),
            InfoRow(
              icon: Icons.badge_outlined,
              label: context.l10n.fieldEmployeeId,
              value: _localizedOrDash(authState.employeeId, (value) => value),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  String _localizedOrDash(String? stored, String Function(String) localize) {
    if (stored == null || stored.trim().isEmpty) return '—';
    return localize(stored.trim());
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return DangerButton(
      label: context.l10n.profileLogout,
      icon: Icons.logout_rounded,
      onPressed: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go('/auth/role');
      },
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15, end: 0);
  }
}
