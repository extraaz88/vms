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
import '../../core/theme/app_theme.dart';
import '../../widgets/visit_details_form.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../widgets/app_logo.dart';

class VisitManagementScreen extends StatefulWidget {
  const VisitManagementScreen({super.key});

  @override
  State<VisitManagementScreen> createState() => _VisitManagementScreenState();
}

class _VisitManagementScreenState extends State<VisitManagementScreen> {
  String? _visitPlace;
  String? _visitPerson;
  String? _visitReason;
  String? _visitArea;
  File? _visitPhoto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitProvider>().initializeVisits();
      _loadFormDataFromPrefs(); // Load saved form data
    });
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
          if (formData['photoPath'] != null && formData['photoPath'].isNotEmpty) {
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
            const AppLogo(
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text('Visit Management'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<VisitProvider>().initializeVisits();
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
          return RefreshIndicator(
            onRefresh: () => visitProvider.initializeVisits(),
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
                  
                  // Visit Details Form
                  _buildVisitDetailsForm()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 24),
                  
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
            currentIndex: 1,
            isCheckedIn: visitProvider.hasActiveVisit,
          );
        },
      ),
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

  Widget _buildVisitDetailsForm() {
    return VisitDetailsForm(
      initialPlace: _visitPlace,
      initialPerson: _visitPerson,
      initialReason: _visitReason,
      initialArea: _visitArea,
      initialPhoto: _visitPhoto,
      onSubmit: (place, person, reason, area, photo) async {
        setState(() {
          _visitPlace = place;
          _visitPerson = person;
          _visitReason = reason;
          _visitArea = area;
          _visitPhoto = photo;
        });
        
        // Create visit directly using the new createVisit method
        await _createVisitDirectly(place, person, reason, area, photo);
      },
      onCancel: () {
        setState(() {
          _visitPlace = null;
          _visitPerson = null;
          _visitReason = null;
          _visitArea = null;
          _visitPhoto = null;
        });
      },
    );
  }

  Future<void> _createVisitDirectly(String place, String person, String reason, String? area, File? photo) async {
    try {
      final visitProvider = context.read<VisitProvider>();
      final locationProvider = context.read<LocationProvider>();
      
      if (locationProvider.currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location not available. Please enable location services.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
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
        
        // Increment target counter
        context.read<TargetProvider>().incrementSubmission();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Visit created successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
              borderRadius: BorderRadius.circular(8),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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

}
