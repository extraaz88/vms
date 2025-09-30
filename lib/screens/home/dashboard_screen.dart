import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/visit_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/target_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../widgets/app_logo.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _blinkingController;

  @override
  void initState() {
    super.initState();
    _blinkingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _blinkingController.repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _blinkingController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final visitProvider = context.read<VisitProvider>();
    final locationProvider = context.read<LocationProvider>();
    final targetProvider = context.read<TargetProvider>();
    
    await Future.wait([
      visitProvider.initializeVisits(),
      locationProvider.initializeLocation(),
      targetProvider.initializeTargets(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text('VMS'),
          ],
        ),
        actions: [
          
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
              
              //const SizedBox(height: 24),
              
              // Quick Actions
              //_buildQuickActions(),
              
              //const SizedBox(height: 24),
              
              // Current Status
              //_buildCurrentStatus(),
              
              const SizedBox(height: 24),
              
              // Statistics Cards
              _buildStatisticsCards(),
              
              const SizedBox(height: 24),
              
              // Lead Management Section
              _buildLeadManagementSection(),
              const SizedBox(height: 24),
              
              // Visiting History Section
              _buildVisitingHistorySection(),
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
      bottomNavigationBar: Consumer<VisitProvider>(
        builder: (context, visitProvider, child) {
          return CustomBottomNavigation(
            currentIndex: 0,
            isCheckedIn: visitProvider.hasActiveVisit,
          );
        },
      ),
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
                child: const AppLogo(
                  width: 32,
                  height: 32,
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



  Widget _buildStatisticsCards() {
    return Consumer2<TargetProvider, VisitProvider>(
      builder: (context, targetProvider, visitProvider, child) {
        final todayVisitsCount = _getTodayVisitsCount(visitProvider.visits);
        final isTargetCompleted = targetProvider.isTargetCompleted;
        final remainingTargets = targetProvider.remainingTargets;
        final progressPercentage = targetProvider.progressPercentage;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Today\'s Progress',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Main Progress Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Circular Progress Indicator
                    _buildCircularProgress(
                      progress: progressPercentage,
                      completed: todayVisitsCount,
                      total: targetProvider.dailyTargets,
                      isCompleted: isTargetCompleted,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            value: todayVisitsCount.toString(),
                            label: 'Completed',
                            color: AppTheme.successColor,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[200],
                        ),
                        Expanded(
                          child: _buildBlinkingStatItem(
                            value: remainingTargets.toString(),
                            label: 'Remaining',
                            color: remainingTargets > 0 ? AppTheme.warningColor : AppTheme.successColor,
                            icon: remainingTargets > 0 ? Icons.pending_outlined : Icons.celebration_outlined,
                            shouldBlink: !isTargetCompleted && remainingTargets > 0,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/visit/management'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTargetCompleted 
                              ? Colors.red 
                              : AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isTargetCompleted 
                              ? 'Continue Excellence'
                              : remainingTargets > 0 
                                  ? 'Complete ${remainingTargets} More Visit${remainingTargets > 1 ? 's' : ''}'
                                  : 'Add Visit',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: 600.ms)
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildCircularProgress({
    required double progress,
    required int completed,
    required int total,
    required bool isCompleted,
  }) {
    return Container(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          // Background circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
            ),
          ),
          // Completed portion (static/dark)
          Container(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted 
                    ? Colors.red  // Red when completed
                    : AppTheme.primaryColor, // Dark blue when in progress
              ),
            ),
          ),
          // Blinking remaining portion (only when not completed)
          if (!isCompleted && progress < 1.0)
            AnimatedBuilder(
              animation: _createBlinkingAnimation(),
              builder: (context, child) {
                return Container(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: 1.0, // Full circle for remaining portion
                    strokeWidth: 8,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor.withOpacity(0.4 + (0.4 * _blinkingController.value)), // Darker color with blinking opacity
                    ),
                  ),
                );
              },
            ),
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.red : AppTheme.primaryColor,
                  ),
                ),
                Text(
                  '$completed/$total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBlinkingStatItem({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
    required bool shouldBlink,
  }) {
    return AnimatedBuilder(
      animation: _createBlinkingAnimation(),
      builder: (context, child) {
        // Zoom effect: scale from 1.0 to 1.3 and back
        final scaleValue = shouldBlink ? 1.0 + (0.3 * _blinkingController.value) : 1.0;
        
        return Column(
          children: [
            Transform.scale(
              scale: scaleValue,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Transform.scale(
              scale: scaleValue,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Animation<double> _createBlinkingAnimation() {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _blinkingController,
      curve: Curves.easeInOut,
    ));
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

  Widget _buildVisitingHistorySection() {
    return Consumer<VisitProvider>(
      builder: (context, visitProvider, child) {
        final totalVisitsCount = visitProvider.visits.length;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Visiting History ($totalVisitsCount)',
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
            if (visitProvider.isLoading)
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
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (visitProvider.visits.isEmpty)
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
                      'No visits yet',
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
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/visit/management'),
                      icon: const Icon(Icons.add),
                      label: const Text('Start First Visit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: visitProvider.visits.take(3).map((visit) => _buildVisitHistoryCard(visit)).toList(),
              ),
          ],
        );
      },
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: 700.ms)
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildVisitHistoryCard(visit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  ? AppTheme.warningColor.withOpacity(0.1)
                  : AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              visit.isActive ? Icons.location_on : Icons.check_circle,
              color: visit.isActive 
                  ? AppTheme.warningColor
                  : AppTheme.successColor,
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatVisitDate(visit.visitTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                if (visit.visitingReason != null && visit.visitingReason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    visit.visitingReason!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: visit.isActive 
                  ? AppTheme.warningColor.withOpacity(0.1)
                  : AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              visit.isActive ? 'Active' : 'Completed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: visit.isActive 
                    ? AppTheme.warningColor
                    : AppTheme.successColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatVisitDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visitDate = DateTime(date.year, date.month, date.day);
    
    if (visitDate == today) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (visitDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
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

  int _getTodayVisitsCount(List visits) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return visits.where((visit) {
      final visitDate = DateTime(visit.visitTime.year, visit.visitTime.month, visit.visitTime.day);
      return visitDate.isAtSameMomentAs(today);
    }).length;
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (mounted) {
      context.go('/login');
    }
  }
}
