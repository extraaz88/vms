import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/visit_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/visit_model.dart';
import '../../widgets/visit_management_card.dart';
import '../../widgets/checkin_checkout_slider.dart';
import '../../widgets/custom_bottom_navigation.dart';

class VisitManagementScreen extends StatefulWidget {
  const VisitManagementScreen({super.key});

  @override
  State<VisitManagementScreen> createState() => _VisitManagementScreenState();
}

class _VisitManagementScreenState extends State<VisitManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitProvider>().loadVisits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Visit Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<VisitProvider>().loadVisits();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/visit/history'),
          ),
        ],
      ),
      body: Consumer<VisitProvider>(
        builder: (context, visitProvider, child) {
          final activeVisit = visitProvider.activeVisit;
          
          return RefreshIndicator(
            onRefresh: () => visitProvider.loadVisits(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeaderSection()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideX(begin: -0.2, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Current Visit Status Card
                  if (activeVisit != null)
                    _buildActiveVisitCard(activeVisit)
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Check-in/Check-out Slider
                  _buildCheckinCheckoutSection(activeVisit)
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  _buildQuickActions()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 600.ms)
                      .slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Visits Preview
                  _buildRecentVisitsPreview(visitProvider)
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 800.ms)
                      .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visit Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your field visits efficiently',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveVisitCard(Visit activeVisit) {
    return VisitManagementCard(
      visit: activeVisit,
      onTap: () => context.push('/visit/details/${activeVisit.id}'),
    );
  }

  Widget _buildCheckinCheckoutSection(Visit? activeVisit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                activeVisit != null ? Icons.location_on : Icons.add_location,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                activeVisit != null ? 'Active Visit' : 'Start New Visit',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CheckinCheckoutSlider(
            activeVisit: activeVisit,
            onCheckIn: () => context.push('/visit/checkin'),
            onCheckOut: activeVisit != null 
                ? () => context.push('/visit/checkout/${activeVisit.id}')
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.history,
                title: 'Visit History',
                subtitle: 'View past visits',
                color: AppTheme.secondaryColor,
                onTap: () => context.push('/visit/history'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.analytics,
                title: 'Analytics',
                subtitle: 'Visit insights',
                color: AppTheme.successColor,
                onTap: () => context.push('/visit/analytics'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'Visit preferences',
                color: AppTheme.warningColor,
                onTap: () => context.push('/visit/settings'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.help,
                title: 'Help',
                subtitle: 'Get support',
                color: AppTheme.errorColor,
                onTap: () => context.push('/help'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentVisitsPreview(VisitProvider visitProvider) {
    final recentVisits = visitProvider.visits.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Visits',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/visit/history'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentVisits.isEmpty)
          _buildEmptyState()
        else
          ...recentVisits.map((visit) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildVisitPreviewCard(visit),
          )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off,
            size: 48,
            color: Colors.grey.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'No visits yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start your first visit to see it here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitPreviewCard(Visit visit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: visit.isActive 
              ? AppTheme.successColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: visit.isActive 
                  ? AppTheme.successColor.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              visit.isActive ? Icons.location_on : Icons.location_off,
              color: visit.isActive ? AppTheme.successColor : AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.clientName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  visit.status.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: visit.isActive ? AppTheme.successColor : AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.withOpacity(0.6),
          ),
        ],
      ),
    );
  }

}
