import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/providers/location_provider.dart';
import '../models/visit_model.dart';
import '../services/geocoding_service.dart';

class CheckinCheckoutSlider extends StatefulWidget {
  final Visit? activeVisit;
  final VoidCallback onCheckIn;
  final VoidCallback? onCheckOut;

  const CheckinCheckoutSlider({
    super.key,
    this.activeVisit,
    required this.onCheckIn,
    this.onCheckOut,
  });

  @override
  State<CheckinCheckoutSlider> createState() => _CheckinCheckoutSliderState();
}

class _CheckinCheckoutSliderState extends State<CheckinCheckoutSlider>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isSliderVisible = false;
  String _areaName = 'Loading...';
  bool _isLoadingArea = true;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _loadAreaName();
    
    // Start pulse animation for check-in button
    if (widget.activeVisit == null) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
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

  void _toggleSlider() {
    setState(() {
      _isSliderVisible = !_isSliderVisible;
    });
    
    if (_isSliderVisible) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }
  }

  void _handleCheckIn() {
    // Show slide animation before navigation
    _slideController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          widget.onCheckIn();
        }
      });
    });
  }

  void _handleCheckOut() {
    if (widget.onCheckOut != null) {
      // Show slide animation before navigation
      _slideController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            widget.onCheckOut!();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final hasLocation = locationProvider.currentPosition != null;
    
    return Column(
      children: [
        // Main Action Button
        _buildMainActionButton(hasLocation),
        
        const SizedBox(height: 16),
        
        // Location Info
        _buildLocationInfo(locationProvider, hasLocation),
        
        const SizedBox(height: 16),
        
        // Slider Toggle
        _buildSliderToggle(),
        
        // Slider Content
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _slideAnimation.value,
                child: child,
              ),
            );
          },
          child: _buildSliderContent(),
        ),
      ],
    );
  }

  Widget _buildMainActionButton(bool hasLocation) {
    final isActive = widget.activeVisit != null;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? 1.0 : _pulseAnimation.value,
          child: GestureDetector(
            onTap: hasLocation 
                ? (isActive ? _handleCheckOut : _handleCheckIn)
                : null,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasLocation
                      ? (isActive 
                          ? [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.8)]
                          : [AppTheme.successColor, AppTheme.successColor.withOpacity(0.8)])
                      : [Colors.grey, Colors.grey.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (hasLocation
                        ? (isActive ? AppTheme.errorColor : AppTheme.successColor)
                        : Colors.grey).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasLocation
                        ? (isActive ? Icons.logout : Icons.login)
                        : Icons.location_off,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    hasLocation
                        ? (isActive ? 'CHECK-OUT' : 'CHECK-IN')
                        : 'LOCATION UNAVAILABLE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationInfo(LocationProvider locationProvider, bool hasLocation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasLocation ? Icons.gps_fixed : Icons.gps_off,
                color: hasLocation ? AppTheme.successColor : AppTheme.errorColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                hasLocation ? 'Current Location' : 'Location Not Available',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: hasLocation ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingArea)
            Row(
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
                  'Loading area information...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          else
            Text(
              _areaName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          if (hasLocation && locationProvider.currentPosition != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.my_location,
                  color: AppTheme.textSecondaryColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${locationProvider.currentPosition!.latitude.toStringAsFixed(6)}, ${locationProvider.currentPosition!.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSliderToggle() {
    return GestureDetector(
      onTap: _toggleSlider,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isSliderVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              _isSliderVisible ? 'Hide Details' : 'Show Details',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderContent() {
    if (!_isSliderVisible) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visit Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (widget.activeVisit != null) ...[
            _buildActiveVisitInfo(),
          ] else ...[
            _buildCheckInInfo(),
          ],
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.info_outline,
                  label: 'More Info',
                  color: AppTheme.secondaryColor,
                  onTap: () => context.push('/visit/details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.map,
                  label: 'View Map',
                  color: AppTheme.primaryColor,
                  onTap: () => _openInMaps(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveVisitInfo() {
    final visit = widget.activeVisit!;
    final duration = visit.checkInTime != null 
        ? DateTime.now().difference(visit.checkInTime!)
        : Duration.zero;
    
    return Column(
      children: [
        _buildInfoRow('Client', visit.clientName, Icons.person),
        _buildInfoRow('Status', 'Active Visit', Icons.location_on, AppTheme.successColor),
        _buildInfoRow('Duration', _formatDuration(duration), Icons.timer),
        if (visit.notes?.isNotEmpty == true)
          _buildInfoRow('Notes', visit.notes!, Icons.note),
      ],
    );
  }

  Widget _buildCheckInInfo() {
    return Column(
      children: [
        _buildInfoRow('Action', 'Ready to Check-in', Icons.login, AppTheme.primaryColor),
        _buildInfoRow('Location', _areaName, Icons.location_on),
        _buildInfoRow('Status', 'Waiting for check-in', Icons.pending),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color ?? AppTheme.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimaryColor,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _openInMaps() {
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.currentPosition != null) {
      // This would open the current location in maps
      // Implementation depends on your MapsService
      ScaffoldMessenger.of(context).showSnackBar(
        
        const SnackBar(
          content: Text('Opening in maps...'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}
