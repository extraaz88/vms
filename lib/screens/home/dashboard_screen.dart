import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/visit_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/custom_bottom_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final visitProvider = context.read<VisitProvider>();
    final locationProvider = context.read<LocationProvider>();
    
    await Future.wait([
      visitProvider.initializeVisits(),
      locationProvider.initializeLocation(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('VMS Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => context.push('/test'),
            tooltip: 'Mock Data Test',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initializeData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActions(),
              
              const SizedBox(height: 24),
              
              // Current Status
              _buildCurrentStatus(),
              
              const SizedBox(height: 24),
              
              // Statistics Cards
              _buildStatisticsCards(),
              
              const SizedBox(height: 24),
              
              // Lead Management Section
              _buildLeadManagementSection(),
              const SizedBox(height: 24),
              
              // Recent Activity
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
      floatingActionButton: Consumer<VisitProvider>(
        builder: (context, visitProvider, child) {
          return CustomFloatingActionButton(
            icon: visitProvider.hasActiveVisit ? Icons.check_outlined : Icons.location_on,
            tooltip: visitProvider.hasActiveVisit ? 'Check Out' : 'Check In',
            onPressed: () {
              if (visitProvider.hasActiveVisit) {
                context.push('/visit/checkout/${visitProvider.currentVisit!.id}');
              } else {
                context.push('/visit/checkin');
              }
            },
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDarkColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authProvider.user?.name ?? 'User',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready for your field visits?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DashboardCard(
                title: 'Visit Management',
                subtitle: 'Manage visits',
                icon: Icons.location_on,
                color: AppTheme.successColor,
                onTap: () => context.push('/visit/management'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardCard(
                title: 'Journey',
                subtitle: 'View tracking',
                icon: Icons.route,
                color: AppTheme.secondaryColor,
                onTap: () => context.push('/tracking/journey'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardCard(
                title: 'Live Track',
                subtitle: 'Team locations',
                icon: Icons.my_location,
                color: AppTheme.accentColor,
                onTap: () => context.push('/tracking/live'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardCard(
                title: 'History',
                subtitle: 'Past visits',
                icon: Icons.history,
                color: AppTheme.primaryColor,
                onTap: () => context.push('/visit/history'),
              ),
            ),
          ],
        ),
      ],
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: 200.ms)
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildCurrentStatus() {
    return Consumer<VisitProvider>(
      builder: (context, visitProvider, child) {
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: visitProvider.hasActiveVisit 
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.textSecondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      visitProvider.hasActiveVisit ? Icons.location_on : Icons.location_off,
                      color: visitProvider.hasActiveVisit 
                          ? AppTheme.successColor
                          : AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Status',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          visitProvider.hasActiveVisit 
                              ? 'Active Visit: ${visitProvider.currentVisit?.clientName}'
                              : 'No active visit',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (visitProvider.hasActiveVisit)
                    Text(
                      visitProvider.currentVisit?.durationString ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              if (visitProvider.hasActiveVisit) ...[
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Check Out',
                  onPressed: () => context.push('/visit/checkout/${visitProvider.currentVisit!.id}'),
                  width: double.infinity,
                ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Summary',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DashboardCard(
                title: '0',
                subtitle: 'Visits Today',
                icon: Icons.business,
                color: AppTheme.primaryColor,
                isStatistics: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardCard(
                title: '0',
                subtitle: 'Distance (km)',
                icon: Icons.straighten,
                color: AppTheme.secondaryColor,
                isStatistics: true,
              ),
            ),
          ],
        ),
      ],
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: 600.ms)
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildLeadManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lead Management',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/leads'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DashboardCard(
                title: 'Leads',
                subtitle: 'Manage leads',
                icon: Icons.people,
                color: AppTheme.secondaryColor,
                onTap: () => context.push('/leads'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardCard(
                title: 'New Lead',
                subtitle: 'Add new lead',
                icon: Icons.person_add,
                color: AppTheme.primaryColor,
                onTap: () => context.push('/leads/create'),
              ),
            ),
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
        Container(
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
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: AppTheme.textSecondaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No recent activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your visit history will appear here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: 800.ms)
    .slideY(begin: 0.2, end: 0);
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (mounted) {
      context.go('/login');
    }
  }
}
