import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../core/providers/visit_provider.dart';
import '../../core/providers/target_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../models/lead_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/visit_details_form.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../widgets/app_logo.dart';
import '../../services/assigned_leads_service.dart';
import '../../utils/auth_helper.dart';
import '../../utils/responsive_utils.dart';

class VisitManagementScreen extends StatefulWidget {
  final String? preselectedLeadId;

  const VisitManagementScreen({super.key, this.preselectedLeadId});

  @override
  State<VisitManagementScreen> createState() => _VisitManagementScreenState();
}

class _VisitManagementScreenState extends State<VisitManagementScreen> {
  String? _visitPlace;
  String? _visitPerson;
  String? _visitReason;
  String? _visitArea;
  File? _visitPhoto;
  Lead? _selectedLead;

  // Assigned leads from API
  List<Lead> _assignedLeads = [];
  bool _isLoadingAssignedLeads = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitProvider>().initializeVisits();
      _loadAssignedLeads(); // Load assigned leads from API
      _loadFormDataFromPrefs(); // Load saved form data
    });
  }

  // Load assigned leads from API
  Future<void> _loadAssignedLeads() async {
    try {
      setState(() {
        _isLoadingAssignedLeads = true;
      });

      debugPrint('\n📋 VISIT MANAGEMENT: Loading assigned leads...');

      // Get authenticated user ID
      final userId = await AuthHelper.getAuthenticatedUserId();

      debugPrint('🔑 Authenticated User ID: $userId');

      // Fetch assigned leads from API
      final assignedLeads = await AssignedLeadsService.getAssignedLeads(userId);

      // If a lead ID was preselected, find and select it
      Lead? preselectedLead;
      if (widget.preselectedLeadId != null && assignedLeads.isNotEmpty) {
        try {
          preselectedLead = assignedLeads.firstWhere(
            (lead) => lead.id == widget.preselectedLeadId,
          );
          debugPrint('✅ Found preselected lead: ${preselectedLead.name}');
        } catch (e) {
          debugPrint(
            '⚠️ Preselected lead not found: ${widget.preselectedLeadId}',
          );
        }
      }

      // Set both leads and selected lead in the same setState
      setState(() {
        _assignedLeads = assignedLeads;
        _isLoadingAssignedLeads = false;
        if (preselectedLead != null) {
          _selectedLead = preselectedLead;
        }
      });

      debugPrint('✅ Assigned leads loaded: ${assignedLeads.length} leads');
      if (assignedLeads.isNotEmpty) {
        debugPrint(
          '📋 First lead: ${assignedLeads.first.name} (${assignedLeads.first.email})',
        );
      }
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Error loading assigned leads: $e');
      setState(() {
        _assignedLeads = [];
        _isLoadingAssignedLeads = false;
      });
    }
  }

  // Load form data from SharedPreferences
  Future<void> _loadFormDataFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final formDataJson = prefs.getString('visit_form_data');
      if (formDataJson != null) {
        final formData = json.decode(formDataJson);
        setState(() {
          _visitPlace = formData['visitingPlace'] ?? '';
          _visitPerson = formData['visitingPerson'] ?? '';
          _visitReason = formData['visitingReason'] ?? '';
          _visitArea = formData['visitingArea'] ?? '';
          if (formData['photoPath'] != null &&
              formData['photoPath'].isNotEmpty) {
            _visitPhoto = File(formData['photoPath']);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading form data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            AppLogo(
              width: ResponsiveUtils.getResponsiveIconSize(context, 24),
              height: ResponsiveUtils.getResponsiveIconSize(context, 24),
            ),
            SizedBox(
              width: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
            ),
            Text(
              'Visit Management',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: ResponsiveUtils.getResponsiveIconSize(context, 24),
            ),
            onPressed: () {
              context.read<VisitProvider>().initializeVisits();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.history,
              size: ResponsiveUtils.getResponsiveIconSize(context, 24),
            ),
            onPressed: () => context.push('/visit/history'),
          ),
        ],
      ),
      body: Consumer<VisitProvider>(
        builder: (context, visitProvider, child) {
          return RefreshIndicator(
            onRefresh: () => visitProvider.initializeVisits(),
            child: SingleChildScrollView(
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeaderSection()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideX(begin: -0.2, end: 0),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
                  ),

                  // Visit Details Form
                  _buildVisitDetailsForm()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
                  ),

                  // Quick Actions
                  _buildQuickActions()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<VisitProvider>(
        builder: (context, visitProvider, child) {
          return CustomBottomNavigation(
            currentIndex: 1, // VMS is at index 1 for non-Flutter Developer
            isCheckedIn: visitProvider.hasActiveVisit,
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, 16),
        ),
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
            padding: EdgeInsets.all(
              ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 12),
              ),
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.white,
              size: ResponsiveUtils.getResponsiveIconSize(context, 28),
            ),
          ),
          SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visit Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      20,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
                ),
                Text(
                  'Manage your field visits efficiently',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitDetailsForm() {
    return VisitDetailsForm(
      initialPlace: _visitPlace,
      initialPerson: _visitPerson,
      initialReason: _visitReason,
      initialArea: _visitArea,
      initialPhoto: _visitPhoto,
      selectedLead: _selectedLead,
      leads: _assignedLeads, // Use assigned leads from API instead of all leads
      isLoadingLeads: _isLoadingAssignedLeads,
      onSubmit: (place, person, reason, area, photo, selectedLead) async {
        setState(() {
          _visitPlace = place;
          _visitPerson = person;
          _visitReason = reason;
          _visitArea = area;
          _visitPhoto = photo;
          _selectedLead = selectedLead;
        });

        // Create visit directly using the new createVisit method
        await _createVisitDirectly(
          place,
          person,
          reason,
          area,
          photo,
          selectedLead,
        );
      },
      onCancel: () {
        setState(() {
          _visitPlace = null;
          _visitPerson = null;
          _visitReason = null;
          _visitArea = null;
          _visitPhoto = null;
          _selectedLead = null;
        });
      },
      onRefreshLeads: _loadAssignedLeads, // Refresh assigned leads on demand
    );
  }

  Future<void> _createVisitDirectly(
    String place,
    String person,
    String reason,
    String? area,
    File? photo,
    Lead? selectedLead,
  ) async {
    try {
      final visitProvider = context.read<VisitProvider>();
      final locationProvider = context.read<LocationProvider>();

      if (locationProvider.currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Location not available. Please enable location services.',
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 8),
              ),
            ),
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create visit directly
      final success = await visitProvider.createVisit(
        latitude: locationProvider.currentPosition!.latitude,
        longitude: locationProvider.currentPosition!.longitude,
        clientName: place,
        notes: person,
        visitingReason: reason,
        visitingArea: area,
        photoPath: photo?.path,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (success) {
        // Clear form data after successful creation
        setState(() {
          _visitPlace = null;
          _visitPerson = null;
          _visitReason = null;
          _visitArea = null;
          _visitPhoto = null;
        });

        // Clear saved form data
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('visit_form_data');

        // Update target counter with actual visit count
        final visitProvider = context.read<VisitProvider>();
        final targetProvider = context.read<TargetProvider>();
        final todayVisitsCount = _getTodayVisitsCount(visitProvider.visits);
        targetProvider.updateCompletedVisits(todayVisitsCount);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Visit created successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 8),
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(visitProvider.error ?? 'Visit creation failed'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 8),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating visit: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 22),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
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
            SizedBox(
              width: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
            ),
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
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.75),
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
            SizedBox(
              width: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
            ),
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
        padding: ResponsiveUtils.getResponsivePadding(context),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 12),
          ),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: ResponsiveUtils.getResponsiveElevation(context, 8),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(
                ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getResponsiveBorderRadius(context, 8),
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: ResponsiveUtils.getResponsiveIconSize(context, 20),
              ),
            ),
            SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              ),
            ),
            SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to count today's visits
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
}
