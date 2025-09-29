import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vms/models/visit_model.dart';

import '../../core/providers/visit_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/visiting_card.dart';
import '../../services/maps_service.dart';

class VisitCheckinScreen extends StatefulWidget {
  const VisitCheckinScreen({super.key});

  @override
  State<VisitCheckinScreen> createState() => _VisitCheckinScreenState();
}

class _VisitCheckinScreenState extends State<VisitCheckinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showCheckOutDialog(BuildContext context, Visit visit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCheckOutBottomSheet(visit),
    );
  }

  Widget _buildCheckOutBottomSheet(Visit visit) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_off,
                    color: AppTheme.warningColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check Out',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        visit.clientName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Location Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check-out Location',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLocationInfo(
                          'Latitude',
                          visit.latitude.toStringAsFixed(6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLocationInfo(
                          'Longitude',
                          visit.longitude.toStringAsFixed(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Check-out Notes
            Text(
              'Check-out Notes (Optional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any notes about your visit...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleCheckOut(visit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Check Out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckOut(Visit visit) async {
    final visitProvider = context.read<VisitProvider>();
    
    try {
      await visitProvider.checkOut(
        visitId: visit.id,
        notes: _notesController.text.trim(),
      );
      
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        Navigator.pop(context); // Close visit screen
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Check-out successful! Visit completed.'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-out failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    final locationProvider = context.read<LocationProvider>();
    await locationProvider.initializeLocation();

    setState(() {
      _isGettingLocation = false;
    });
  }

  Future<void> _handleCheckIn() async {
    if (!_formKey.currentState!.validate()) return;

    final visitProvider = context.read<VisitProvider>();
    final locationProvider = context.read<LocationProvider>();

    if (locationProvider.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get current location. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final success = await visitProvider.checkIn(
      clientName: _clientNameController.text.trim(),
      latitude: locationProvider.currentPosition!.latitude,
      longitude: locationProvider.currentPosition!.longitude,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Check-in successful! Visit started.'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      
      // Show success animation before closing
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.go('/dashboard');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text(visitProvider.error ?? 'Check-in failed'),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Visit Management'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<VisitProvider>(
        builder: (context, visitProvider, child) {
          // Check if there's an active visit
          final activeVisit = visitProvider.activeVisit;
          
          if (activeVisit != null) {
            // Show visiting card with check-out functionality
            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  VisitingCard(
                    visit: activeVisit,
                    onCheckOut: () => _showCheckOutDialog(context, activeVisit),
                  ),
                ],
              ),
            );
          } else {
            // Show check-in form
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeaderSection()
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: -0.2, end: 0),
                    
                    const SizedBox(height: 32),
                    
                    // Location Status
                    _buildLocationStatus()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .slideX(begin: -0.2, end: 0),
                    
                    const SizedBox(height: 32),
                    
                    // Form Fields
                    _buildFormFields()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 400.ms)
                        .slideX(begin: -0.2, end: 0),
                    
                    const SizedBox(height: 32),
                    
                    // Check In Button
                    _buildCheckInButton()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.successColor, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
              Icons.login,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Check In',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start tracking your visit',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms)
    .slideX(begin: -0.2, end: 0);
  }

  Widget _buildLocationStatus() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
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
                      color: (_isGettingLocation || locationProvider.currentPosition == null)
                          ? AppTheme.warningColor.withOpacity(0.1)
                          : AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isGettingLocation
                          ? Icons.my_location
                          : locationProvider.currentPosition != null
                              ? Icons.location_on
                              : Icons.location_off,
                      color: (_isGettingLocation || locationProvider.currentPosition == null)
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
                          'Location Status',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _isGettingLocation
                              ? 'Getting your location...'
                              : locationProvider.currentPosition != null
                                  ? 'Location acquired'
                                  : 'Location not available',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isGettingLocation)
                    TextButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                    ),
                ],
              ),
              
              if (locationProvider.currentPosition != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.successColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.gps_fixed,
                            size: 16,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Latitude: ${locationProvider.currentPosition!.latitude.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.gps_fixed,
                            size: 16,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Longitude: ${locationProvider.currentPosition!.longitude.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.gps_fixed,
                            size: 16,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Accuracy: ${locationProvider.currentPosition!.accuracy.toStringAsFixed(1)}m',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                if (locationProvider.currentPosition != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await MapsService.openInGoogleMaps(
                        locationProvider.currentPosition!.latitude,
                        locationProvider.currentPosition!.longitude,
                        label: 'Check-in Location'
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('View in Google Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visit Details',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _clientNameController,
          label: 'Client Name',
          hint: 'Enter client/company name',
          prefixIcon: const Icon(Icons.business),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter client name';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _notesController,
          label: 'Notes (Optional)',
          hint: 'Enter any additional notes',
          prefixIcon: const Icon(Icons.note_outlined),
          maxLines: 3,
        ),
      ],
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: 400.ms)
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildCheckInButton() {
    return Consumer<VisitProvider>(
      builder: (context, visitProvider, child) {
        return Column(
          children: [
            CustomButton(
              text: 'Check In',
              onPressed: _isGettingLocation || visitProvider.isLoading
                  ? null
                  : _handleCheckIn,
              isLoading: visitProvider.isLoading,
              width: double.infinity,
              height: 56,
            ),
            
            if (_isGettingLocation) ...[
              const SizedBox(height: 16),
              Text(
                'Please wait while we get your location...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 600.ms)
        .slideY(begin: 0.2, end: 0);
      },
    );
  }
}
