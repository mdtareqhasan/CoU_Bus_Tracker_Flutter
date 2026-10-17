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
            // Shown logged-in and logged-out alike: language is an app
            // setting, not an account one.
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
      backgroundColor: AppTheme.primaryBlue,
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
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      ),
    );
  }

  Widget _buildLoggedOutPrompt(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          _buildPromptIllustration(),
          const SizedBox(height: AppTheme.space48),
          Text(
            context.l10n.profileYourProfile,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: AppTheme.space12),
          Text(
            context.l10n.profileLoginPrompt,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: AppTheme.space48),
          Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => context.go('/auth/role'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        context.l10n.profileLoginRegister,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 400.ms)
              .scale(begin: const Offset(0.9, 0.9)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPromptIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 2000.ms,
              curve: Curves.easeInOut,
            ),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(45),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 72,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildLoggedInProfile(BuildContext context, AuthState authState) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.space12),
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
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              (authState.displayName ?? 'U').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          authState.displayName ?? context.l10n.commonUserName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          authState.email != null && authState.email!.isNotEmpty
              ? authState.email!
              : '—',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
          ),
          child: Text(
            authState.role == 'student'
                ? context.l10n.roleStudent
                : context.l10n.roleTeacher,
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdCardSection(BuildContext context, AuthState authState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  Icons.badge_outlined,
                  size: 20,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.l10n.profileIdCard,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: GestureDetector(
              onTap: () => _showFullIdCard(context, authState.idCardImageUrl!),
              child: CachedNetworkImage(
                imageUrl: authState.idCardImageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: AppTheme.primaryBlue.withValues(alpha: 0.05),
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
          const SizedBox(height: 8),
          Text(
            context.l10n.profileTapToViewPhoto,
            style: const TextStyle(
              color: AppTheme.textHint,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
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

    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            context.l10n.profileName,
            authState.displayName ?? '—',
            Icons.person_outline_rounded,
          ),
          const Divider(indent: 48, height: 1),
          _buildInfoRow(
            context,
            context.l10n.profileEmail,
            authState.email != null && authState.email!.isNotEmpty
                ? authState.email!
                : '—',
            Icons.email_outlined,
          ),
          const Divider(indent: 48, height: 1),
          _buildInfoRow(
            context,
            context.l10n.profileRole,
            isStudent ? context.l10n.roleStudent : context.l10n.roleTeacher,
            Icons.badge_outlined,
          ),

          // Academic details — write-once fields filled in at registration /
          // profile completion. Department and session are stored canonically
          // (Bengali department name, English session value), so show them in
          // the app's language like the registration pickers do.
          const Divider(indent: 48, height: 1),
          _buildInfoRow(
            context,
            isStudent
                ? context.l10n.fieldDepartment
                : context.l10n.fieldDepartmentOffice,
            _localizedOrDash(
              authState.department,
              (value) => departmentLabelFor(value, context.l10n),
            ),
            Icons.business_outlined,
            // Department/office names can be long ("Office of the Director of
            // Planning & Development") — give them a second line.
            maxLines: 2,
          ),
          if (isStudent) ...[
            const Divider(indent: 48, height: 1),
            _buildInfoRow(
              context,
              context.l10n.fieldRollNumber,
              _localizedOrDash(authState.rollNumber, (value) => value),
              Icons.pin_outlined,
            ),
            const Divider(indent: 48, height: 1),
            _buildInfoRow(
              context,
              context.l10n.fieldSession,
              _localizedOrDash(
                authState.session,
                (value) => sessionLabelFor(value, context.l10n),
              ),
              Icons.class_outlined,
            ),
          ] else ...[
            const Divider(indent: 48, height: 1),
            _buildInfoRow(
              context,
              context.l10n.fieldDesignation,
              _localizedOrDash(authState.designation, (value) => value),
              Icons.work_outline_rounded,
            ),
            const Divider(indent: 48, height: 1),
            _buildInfoRow(
              context,
              context.l10n.fieldEmployeeId,
              _localizedOrDash(authState.employeeId, (value) => value),
              Icons.badge_outlined,
            ),
          ],
        ],
      ),
    );
  }

  /// The display form of a stored academic value: blank → '—', otherwise
  /// [localize] (e.g. the localized department/session name).
  String _localizedOrDash(String? stored, String Function(String) localize) {
    if (stored == null || stored.trim().isEmpty) return '—';
    return localize(stored.trim());
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go('/auth/role');
        },
        icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
        label: Text(
          context.l10n.profileLogout,
          style: const TextStyle(
            color: AppTheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppTheme.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
