import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: authState.isLoggedIn
                ? _buildLoggedInProfile(context, ref, authState)
                : _buildLoggedOutPrompt(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      automaticallyImplyLeading: false,
      title: const Text('প্রোফাইল', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
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
            'আপনার প্রোফাইল',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: AppTheme.space12),
          Text(
            'বাসের তথ্য ও সঠিক শিডিউল ট্র্যাক করতে আপনার অ্যাকাউন্টে লগইন করুন',
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
                  color: AppTheme.primaryBlue.withOpacity(0.3),
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
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text('লগইন / নিবন্ধন করুন',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),
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
            color: AppTheme.primaryBlue.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
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
                color: AppTheme.primaryBlue.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 72),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildLoggedInProfile(
      BuildContext context, WidgetRef ref, AuthState authState) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.space12),
          _buildProfileHeader(context, authState),
          const SizedBox(height: AppTheme.space32),
          _buildInfoCard(context, authState),
          const SizedBox(height: AppTheme.space32),
          _buildLogoutButton(context, ref),
          const SizedBox(height: AppTheme.space48),
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
                color: AppTheme.primaryBlue.withOpacity(0.2),
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
          authState.displayName ?? 'ব্যবহারকারী',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          authState.email ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
          ),
          child: Text(
            authState.role == 'student' ? 'শিক্ষার্থী' : 'শিক্ষক',
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

  Widget _buildInfoCard(BuildContext context, AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          _buildInfoRow(context, 'নাম', authState.displayName ?? '—', Icons.person_outline_rounded),
          const Divider(indent: 48, height: 1),
          _buildInfoRow(context, 'ইমেইল', authState.email ?? '—', Icons.email_outlined),
          const Divider(indent: 48, height: 1),
          _buildInfoRow(
              context,
              'ভূমিকা',
              authState.role == 'student' ? 'শিক্ষার্থী' : 'শিক্ষক',
              Icons.badge_outlined),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go('/home');
        },
        icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
        label: const Text(
          'লগ আউট',
          style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
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

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
