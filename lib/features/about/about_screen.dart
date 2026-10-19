import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/app_pill.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space24,
                AppTheme.space24,
                AppTheme.space24,
                AppTheme.space48,
              ),
              child: Column(
                children: [
                  _buildAppSection(context),
                  const SizedBox(height: AppTheme.space24),
                  _buildDeptSection(),
                  const SizedBox(height: AppTheme.space24),
                  _buildDeveloperCard(
                    context,
                    name: 'Md. Tareq Hasan',
                    role: 'Lead Developer',
                    info: 'Dept. of CSE, Batch: 16, Comilla University',
                    imagePath: 'assets/images/tareq.jpeg',
                    isLead: true,
                  ),
                  const SizedBox(height: AppTheme.space16),
                  _buildDeveloperCard(
                    context,
                    name: 'Raihan Khan',
                    role: 'Project Consultant',
                    info:
                        'Senior Platform Engineer at Makro Pro, Thailand\nCSE 10 Batch, Comilla University',
                    imagePath: 'assets/images/raihan.jpeg',
                  ),
                  const SizedBox(height: AppTheme.space16),
                  _buildDeveloperCard(
                    context,
                    name: 'Md. Atikur Rahman',
                    role: 'Advisor',
                    info: 'Lecturer, Dept. of CSE, Comilla University',
                    imagePath: 'assets/images/atik_sir.jpg',
                  ),
                  const SizedBox(height: AppTheme.space16),
                  _buildDeveloperCard(
                    context,
                    name: 'MD. Kawsar Amin',
                    role: 'Current Maintainer & Core Contributor',
                    info: 'Dept. of CSE, Batch: 17, Comilla University',
                    imagePath: '',
                    isLead: true,
                  ),
                ],
              ),
            ),
          ),
        ],
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
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'About Us',
        style: TextStyle(
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

  Widget _buildAppSection(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
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
              )
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(duration: 12000.ms, curve: Curves.linear),
              Container(
                width: 130,
                height: 130,
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/buslogo.jpeg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space20),
        Text(
          context.l10n.appName,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
        const SizedBox(height: AppTheme.space8),
        Text(
          'An Android app to track Comilla University buses in real-time with bus schedules',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildDeptSection() {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.space16),
      elevation: GlassCardElevation.soft,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            child: Image.asset(
              'assets/images/deptlogo.jpg',
              width: 200,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          const Text(
            'Computer Science and Engineering',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          const Text(
            'The initiative to make this app has been taken from the CSE dept.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDeveloperCard(
    BuildContext context, {
    required String name,
    required String role,
    required String info,
    required String imagePath,
    bool isLead = false,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.space24),
      elevation: isLead ? GlassCardElevation.glow : GlassCardElevation.soft,
      glowColor: isLead ? AppTheme.cyanBright : null,
      child: Column(
        children: [
          // Avatar with rotating aurora ring for leads
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isLead)
                  Container(
                    width: 130,
                    height: 130,
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
                  ).animate(onPlay: (c) => c.repeat()).rotate(
                        duration: 14000.ms,
                        curve: Curves.linear,
                      ),
                Container(
                  width: isLead ? 118 : 130,
                  height: isLead ? 118 : 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.cyanBright.withValues(alpha: 0.10),
                  ),
                  child: ClipOval(
                    child: imagePath.isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: AppTheme.bluePrimary,
                            ),
                          )
                        : Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: AppTheme.bluePrimary,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          AppPill(
            label: role,
            icon: isLead ? Icons.star_rounded : Icons.person_outline_rounded,
            color: isLead ? AppTheme.cyanBright : AppTheme.bluePrimary,
            dense: true,
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            info,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
