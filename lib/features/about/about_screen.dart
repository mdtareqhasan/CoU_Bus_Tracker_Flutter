import 'package:flutter/material.dart';
import '../../app/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                children: [
                  _buildAppSection(context),
                  const SizedBox(height: AppTheme.space32),
                  _buildDeptSection(context),
                  const SizedBox(height: AppTheme.space32),
                  _buildDeveloperCard(
                    context,
                    name: 'Md. Tareq Hasan',
                    role: 'Lead Developer',
                    info: 'Dept. of CSE, Batch: 16, Comilla University',
                    imagePath: 'assets/images/tareq.jpeg',
                  ),
                  const SizedBox(height: AppTheme.space24),
                  _buildDeveloperCard(
                    context,
                    name: 'Raihan Khan',
                    role: 'Project Consultant',
                    info: 'Platform Engineer at Marko Pro\nCSE 10 Batch, Comilla University',
                    imagePath: 'assets/images/raihan.jpeg',
                  ),
                  const SizedBox(height: AppTheme.space24),
                  _buildDeveloperCard(
                    context,
                    name: 'Md. Atikur Rahman',
                    role: 'Advisor',
                    info: 'Lecturer, Dept. of CSE, Comilla University',
                    imagePath: 'assets/images/atik_sir.jpg',
                  ),
                  const SizedBox(height: AppTheme.space48),
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
      backgroundColor: AppTheme.primaryBlue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('About Us', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
    );
  }

  Widget _buildAppSection(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: AppTheme.softShadow,
            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1), width: 4),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/buslogo.jpeg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'CoU Bus Tracker',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          'An Android app to track Comilla University buses in real-time with bus schedules',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildDeptSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Image.asset(
              'assets/images/deptlogo.jpg',
              width: 200,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            'Computer Science and Engineering',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'The initiative to make this app has been taken from the CSE dept.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(
    BuildContext context, {
    required String name,
    required String role,
    required String info,
    required String imagePath,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusExtraLarge),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1), width: 4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusExtraLarge - 4),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppTheme.accentBlue,
                  child: const Icon(Icons.person_rounded, size: 50, color: AppTheme.primaryBlue),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            role,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            info,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
