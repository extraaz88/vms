import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/visit_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/target_provider.dart';
import '../../core/providers/checkin_checkout_history_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../services/sales/assigned_leads_service.dart';
import '../../utils/responsive_utils.dart';

/// Sales Dashboard Screen - For sales personnel
class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  // Assigned leads data
  int _assignedLeadsCount = 0;
  int _completedLeadsCount = 0;

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
    final targetProvider = context.read<TargetProvider>();
    final historyProvider = context.read<CheckInCheckOutHistoryProvider>();
    final authProvider = context.read<AuthProvider>();

    // Get current user ID for attendance history
    final userId = authProvider.user?.id;
    final userIdInt = int.tryParse(userId ?? '') ?? 0;

    // Initialize basic data first
    await Future.wait([
      visitProvider.initializeVisits(),
      locationProvider.initializeLocation(),
      targetProvider.initializeTargets(),
      if (userIdInt > 0) historyProvider.loadCheckInCheckOutHistory(userIdInt),
    ]);

    // Fetch lead count from API if user ID is available
    if (userId != null && userId.isNotEmpty) {
      await targetProvider.fetchLeadCountFromAPI(userId);
      // Load assigned leads for progress calculation
      await _loadAssignedLeads(userId);
    }

    // Start location tracking for auto checkout
    if (!locationProvider.isTracking && locationProvider.hasPermission) {
      await locationProvider.startTracking();
    }

    // Sync target provider with actual visit count
    _syncTargetWithVisits(visitProvider, targetProvider);

    // Set up callback to automatically update target when visits are completed
    visitProvider.onVisitCompleted = (int completedCount) {
      targetProvider.updateCompletedVisits(completedCount);
      // Update completed leads count
      if (mounted) {
        setState(() {
          _completedLeadsCount = completedCount.clamp(0, _assignedLeadsCount);
        });
      }
    };
  }

  void _syncTargetWithVisits(
    VisitProvider visitProvider,
    TargetProvider targetProvider,
  ) {
    final todayVisitsCount = _getTodayVisitsCount(visitProvider.visits);
    targetProvider.updateCompletedVisits(todayVisitsCount);

    // Update completed leads count
    if (mounted) {
      setState(() {
        _completedLeadsCount = todayVisitsCount.clamp(0, _assignedLeadsCount);
      });
    }
  }

  int _getTodayVisitsCount(List visits) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return visits.where((visit) {
      final visitDate = DateTime(
        visit.visitTime.year,
        visit.visitTime.month,
        visit.visitTime.day,
      );
      return visitDate.isAtSameMomentAs(today);
    }).length;
  }

  Future<void> _loadAssignedLeads(String userId) async {
    try {
      final assignedLeads = await AssignedLeadsService.getAssignedLeads(userId);
      final visitProvider = context.read<VisitProvider>();
      final todayVisits = _getTodayVisitsCount(visitProvider.visits);

      setState(() {
        _assignedLeadsCount = assignedLeads.length;
        _completedLeadsCount = todayVisits.clamp(0, assignedLeads.length);
      });
    } catch (e) {
      debugPrint('❌ Error loading assigned leads: $e');
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      final lakhs = amount / 100000;
      if (lakhs >= 100) {
        final crores = lakhs / 100;
        return '${crores.toStringAsFixed(2)}Cr';
      }
      return '${lakhs.toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _showExitDialog(context) ?? false;
      },
      child: Scaffold(
        drawer: const CustomDrawer(),
        backgroundColor: AppTheme.backgroundColor,
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                final unreadCount = notificationProvider.unreadCount;
                return IconButton(
                  icon: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => context.push('/notifications'),
                  tooltip: 'Notifications',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () => context.push('/profile'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _initializeData,
          backgroundColor: Colors.white.withOpacity(0.2),
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Green gradient background section
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryDarkColor,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: ResponsiveUtils.getResponsivePadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Rest of the content with normal background
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding: ResponsiveUtils.getResponsivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: ResponsiveUtils.getResponsiveSpacing(context) * 1,
                      ),
                      // Current Status (Today's Status)
                      _buildCurrentStatus(),
                      SizedBox(
                        height: ResponsiveUtils.getResponsiveSpacing(context) * 1,
                      ),
                      // Statistics Cards (Today's Progress)
                      _buildStatisticsCards(),
                      SizedBox(
                        height: ResponsiveUtils.getResponsiveSpacing(context) * 2,
                      ),
                      // Lead Management Section
                      _buildLeadManagementSection(),
                      // Bottom padding for better scrolling
                      SizedBox(
                        height: ResponsiveUtils.getResponsiveSpacing(context) * 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Consumer<VisitProvider>(
          builder: (context, visitProvider, child) {
            return CustomBottomNavigation(
              currentIndex: 0,
              isCheckedIn: visitProvider.hasActiveVisit,
            );
          },
        ),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Exit App'),
          ],
        ),
        content: const Text('Do you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  // Import the build methods from the original dashboard
  // For now, we'll create simplified versions
  Widget _buildWelcomeSection() {
    return Consumer3<AuthProvider, LocationProvider, TargetProvider>(
      builder: (context, authProvider, locationProvider, targetProvider, child) {
        final user = authProvider.user;
        final isSalesPerson = user?.isSalesPerson ?? false;
        final monthlyTargetAmount = targetProvider.monthlyTargetAmount;

        if (isSalesPerson) {
          final completedAmount =
              (monthlyTargetAmount * targetProvider.progressPercentage).clamp(
            0.0,
            monthlyTargetAmount,
          );
          final remainingAmount = (monthlyTargetAmount - completedAmount).clamp(
            0.0,
            monthlyTargetAmount,
          );
          final progressValue = monthlyTargetAmount > 0
              ? (completedAmount / monthlyTargetAmount)
              : 0.0;

          return Container(
            margin: EdgeInsets.only(
              top: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
            ),
            padding: EdgeInsets.all(
              ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your target amount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                ),
                Text(
                  '₹ ${_formatAmount(monthlyTargetAmount)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 40),
                  ),
                ),
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                ),
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progressValue,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${_formatAmount(completedAmount)} Completed',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 17),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      '₹${_formatAmount(remainingAmount)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 17),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0);
        }

        return Container(
          padding: ResponsiveUtils.getResponsivePadding(context),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDarkColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, 16),
            ),
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
                      user?.name ?? 'User',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
                          ),
                    ),
                    SizedBox(
                      height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                    ),
                    Text(
                      'Ready for your field visits?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildCurrentStatus() {
    // This is a simplified version - you can copy the full implementation from original dashboard
    return Consumer2<VisitProvider, LocationProvider>(
      builder: (context, visitProvider, locationProvider, child) {
        final hasActiveVisit = visitProvider.hasActiveVisit;
        return Container(
          margin: EdgeInsets.only(
            bottom: ResponsiveUtils.getResponsiveSpacing(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
                ),
                child: Text(
                  'Today\'s Status',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                      ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              Container(
                padding: ResponsiveUtils.getResponsivePadding(context),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getResponsiveBorderRadius(context, 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      hasActiveVisit ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: hasActiveVisit ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      hasActiveVisit ? 'Visit Active' : 'No Active Visit',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCards() {
    return Consumer2<TargetProvider, VisitProvider>(
      builder: (context, targetProvider, visitProvider, child) {
        final totalAssigned = _assignedLeadsCount > 0
            ? _assignedLeadsCount
            : targetProvider.dailyTargets;
        final completed = _completedLeadsCount > 0
            ? _completedLeadsCount
            : targetProvider.currentSubmissions;
        final remaining = totalAssigned - completed;
        final progressPercentage = totalAssigned > 0
            ? (completed / totalAssigned)
            : 0.0;

        return Container(
          margin: EdgeInsets.only(
            bottom: ResponsiveUtils.getResponsiveSpacing(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
                ),
                child: Text(
                  'Today\'s Progress',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                      ),
                ),
              ),
              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context) * 0.9,
              ),
              Container(
                padding: EdgeInsets.all(
                  ResponsiveUtils.getResponsiveSpacing(context) * 1.25,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Completed', completed.toString(), Colors.green),
                        _buildStatItem('Remaining', remaining.toString(), Colors.orange),
                        _buildStatItem('Total', totalAssigned.toString(), AppTheme.primaryColor),
                      ],
                    ),
                    SizedBox(
                      height: ResponsiveUtils.getResponsiveSpacing(context),
                    ),
                    LinearProgressIndicator(
                      value: progressPercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
            color: Colors.grey[600],
          ),
        ),
      ],
    );
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
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                  ),
            ),
            TextButton(
              onPressed: () => context.push('/leads'),
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
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
            SizedBox(
              width: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
            ),
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
}

