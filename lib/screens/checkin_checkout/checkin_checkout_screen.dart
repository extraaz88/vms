import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/providers/visit_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../services/geocoding_service.dart';
import '../attendance/attendance_screen.dart';

class CheckinCheckoutScreen extends StatefulWidget {
  const CheckinCheckoutScreen({super.key});

  @override
  State<CheckinCheckoutScreen> createState() => _CheckinCheckoutScreenState();
}

class _CheckinCheckoutScreenState extends State<CheckinCheckoutScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  String _areaName = 'Loading...';
  bool _isLoadingArea = true;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final visitProvider = context.read<VisitProvider>();
    final locationProvider = context.read<LocationProvider>();
    
    await Future.wait([
      visitProvider.initializeVisits(),
      locationProvider.initializeLocation(),
    ]);
    
    await _loadAreaName();
  }

  Future<void> _loadAreaName() async {
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.currentPosition != null) {
      try {
        final areaName = await GeocodingService.getAreaName(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        );
        if (mounted) {
          setState(() {
            _areaName = areaName;
            _isLoadingArea = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _areaName = 'Location not available';
            _isLoadingArea = false;
          });
        }
      }
    } else {
      setState(() {
        _areaName = 'Location not available';
        _isLoadingArea = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Check-In & Out'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: () => _showAttendanceDrawer(),
            tooltip: 'View Attendance',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _initializeData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<VisitProvider>(
        builder: (context, visitProvider, child) {
          final activeVisit = visitProvider.activeVisit;
          final hasLocation = context.watch<LocationProvider>().currentPosition != null;
          
          return RefreshIndicator(
            onRefresh: _initializeData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Status Section
                  _buildTodaysStatus(activeVisit)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  // Date and Time
                  _buildDateTime()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 40),
                  
                  // Slide to Check-In/Out Button
                  _buildSlideButton(activeVisit, hasLocation)
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 40),
                  
                  // Current Location
                  _buildCurrentLocation()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 600.ms)
                      .slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  // Attendance Details (if there's an active visit)
                  if (activeVisit != null)
                    _buildAttendanceDetails(activeVisit)
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 800.ms)
                        .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildTodaysStatus(activeVisit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Status',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check In',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.5),
                            style: BorderStyle.solid,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeVisit?.checkInTime != null
                          ? DateFormat('HH:mm').format(activeVisit!.checkInTime)
                          : '--:--',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check Out',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.5),
                            style: BorderStyle.solid,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeVisit?.checkOutTime != null
                          ? DateFormat('HH:mm').format(activeVisit!.checkOutTime)
                          : '--:--',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTime() {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('d MMMM yyyy').format(now),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<DateTime>(
          stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
          builder: (context, snapshot) {
            final currentTime = snapshot.data ?? now;
            return Text(
              DateFormat('h:mm:ss a').format(currentTime),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSlideButton(activeVisit, hasLocation) {
    final isActive = activeVisit != null;
    final buttonText = isActive ? 'Slide to Check Out' : 'Slide to Check In';
    final buttonColor = isActive ? AppTheme.errorColor : AppTheme.successColor;
    
    return GestureDetector(
      onPanUpdate: (details) {
        if (!hasLocation) return;
        
        // Calculate slide progress based on horizontal movement
        final screenWidth = MediaQuery.of(context).size.width;
        final slideWidth = screenWidth - 80; // Account for padding
        final progress = (details.localPosition.dx / slideWidth).clamp(0.0, 1.0);
        
        _slideController.value = progress;
      },
      onPanEnd: (details) {
        if (!hasLocation) return;
        
        if (_slideAnimation.value > 0.7) {
          // Complete the action
          _handleSlideComplete(isActive, activeVisit);
        } else {
          // Reset the slide
          _slideController.reverse();
        }
      },
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: buttonColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: buttonColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                color: buttonColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(35),
              ),
            ),
            
            // Slide indicator
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                final containerWidth = MediaQuery.of(context).size.width - 40; // Account for padding
                final maxSlideDistance = containerWidth - 70; // Account for button width
                
                return Positioned(
                  left: 4 + (_slideAnimation.value * maxSlideDistance),
                  top: 4,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(31),
                      boxShadow: [
                        BoxShadow(
                          color: buttonColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isActive ? Icons.logout_rounded : Icons.login_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                );
              },
            ),
            
            // Text
            Center(
              child: Text(
                hasLocation ? buttonText : 'Location Unavailable',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: hasLocation ? buttonColor : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSlideComplete(bool isActive, activeVisit) async {
    if (isActive && activeVisit != null) {
      // Handle check-out
      await _performCheckOut(activeVisit);
    } else {
      // Handle check-in
      await _performCheckIn();
    }
  }

  Future<void> _performCheckIn() async {
    try {
      final visitProvider = context.read<VisitProvider>();
      final locationProvider = context.read<LocationProvider>();
      
      if (locationProvider.currentPosition == null) {
        _showErrorSnackBar('Location not available. Please enable location services.');
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

      // Create new visit
      final success = await visitProvider.checkIn(
        clientName: 'Field Visit', // You can customize this
        latitude: locationProvider.currentPosition!.latitude,
        longitude: locationProvider.currentPosition!.longitude,
        notes: 'Check-in from mobile app',
      );
      
      if (!success) {
        throw Exception(visitProvider.error ?? 'Check-in failed');
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      _showSuccessSnackBar('Check-in successful!');
      
      // Reset slider
      _slideController.reset();
      
      // Refresh the screen
      _initializeData();
      
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      _showErrorSnackBar('Check-in failed: ${e.toString()}');
    }
  }

  Future<void> _performCheckOut(activeVisit) async {
    try {
      final visitProvider = context.read<VisitProvider>();
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Complete the visit
      final success = await visitProvider.checkOut(
        visitId: activeVisit.id,
        notes: 'Check-out from mobile app',
      );
      
      if (!success) {
        throw Exception(visitProvider.error ?? 'Check-out failed');
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      _showSuccessSnackBar('Attendance Done! Check-out successful.');
      
      // Reset slider
      _slideController.reset();
      
      // Refresh the screen
      _initializeData();
      
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      _showErrorSnackBar('Check-out failed: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAttendanceDrawer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AttendanceScreen(),
      ),
    );
  }


  Widget _buildCurrentLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Location:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
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
              Icon(
                Icons.location_on_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isLoadingArea
                    ? Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Loading location...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _areaName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceDetails(activeVisit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
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
              // Check-in Details
              _buildAttendanceRow(
                icon: Icons.login_rounded,
                title: 'Check-in Time',
                value: DateFormat('dd MMM yyyy, h:mm a').format(activeVisit.checkInTime),
                color: AppTheme.successColor,
              ),
              const SizedBox(height: 16),
              _buildAttendanceRow(
                icon: Icons.location_on_rounded,
                title: 'Check-in Location',
                value: '${activeVisit.latitude.toStringAsFixed(6)}, ${activeVisit.longitude.toStringAsFixed(6)}',
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              _buildAttendanceRow(
                icon: Icons.person_rounded,
                title: 'Client',
                value: activeVisit.clientName,
                color: AppTheme.secondaryColor,
              ),
              if (activeVisit.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _buildAttendanceRow(
                  icon: Icons.note_rounded,
                  title: 'Notes',
                  value: activeVisit.notes!,
                  color: AppTheme.warningColor,
                ),
              ],
              const SizedBox(height: 16),
              // Working Duration
              _buildWorkingDuration(activeVisit),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingDuration(activeVisit) {
    return StreamBuilder<Duration>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) {
        return DateTime.now().difference(activeVisit.checkInTime);
      }),
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final seconds = duration.inSeconds.remainder(60);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.successColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer_rounded,
                color: AppTheme.successColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Working Duration',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
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

}
