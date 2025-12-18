import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vms/core/providers/auth_provider.dart';
import 'package:vms/core/providers/visit_provider.dart';
import 'package:vms/core/theme/app_theme.dart';
import 'package:vms/models/visit_model.dart';
import 'package:vms/services/geocoding_service.dart';
import 'package:vms/services/maps_service.dart';


class VisitorManagementDetailScreen extends StatefulWidget {
  final String visitId;

  const VisitorManagementDetailScreen({super.key, required this.visitId});

  @override
  State<VisitorManagementDetailScreen> createState() =>
      _VisitorManagementDetailScreenState();
}

class _VisitorManagementDetailScreenState
    extends State<VisitorManagementDetailScreen> {
  Visit? _visit;
  String _areaName = 'Loading...';
  Map<String, String> _detailedAddress = {};
  bool _isLoadingArea = true;

  @override
  void initState() {
    super.initState();
    _loadVisitDetails();
  }

  Future<void> _loadVisitDetails() async {
    final visitProvider = context.read<VisitProvider>();
    await visitProvider.loadVisits();

    final visit = visitProvider.visits.firstWhere(
      (v) => v.id == widget.visitId,
      orElse: () => throw Exception('Visit not found'),
    );

    setState(() {
      _visit = visit;
    });

    await _loadAreaDetails(visit.latitude, visit.longitude);
  }

  Future<void> _loadAreaDetails(double latitude, double longitude) async {
    try {
      final areaName = await GeocodingService.getAreaName(latitude, longitude);
      final detailedAddress = await GeocodingService.getDetailedAddress(
        latitude,
        longitude,
      );

      if (mounted) {
        setState(() {
          _areaName = areaName;
          _detailedAddress = detailedAddress;
          _isLoadingArea = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _areaName =
              '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
          _isLoadingArea = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_visit == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Visit Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Visit Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => _openInMaps(),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareVisit(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            _buildHeaderCard()
                .animate()
                .fadeIn(duration: 600.ms)
                .slideX(begin: -0.2, end: 0),

            const SizedBox(height: 16),

            // Status Card
            _buildStatusCard()
                .animate()
                .fadeIn(duration: 600.ms, delay: 200.ms)
                .slideX(begin: 0.2, end: 0),

            const SizedBox(height: 16),

            // Location Card
            _buildLocationCard()
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 16),

            // Timing Card
            _buildTimingCard()
                .animate()
                .fadeIn(duration: 600.ms, delay: 600.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 16),

            // Notes Card
            if (_visit?.notes?.isNotEmpty == true)
              _buildNotesCard()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 800.ms)
                  .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 16),

            // Actions Card
            _buildActionsCard()
                .animate()
                .fadeIn(duration: 600.ms, delay: 1000.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _visit!.isActive
                ? AppTheme.successColor.withOpacity(0.1)
                : AppTheme.primaryColor.withOpacity(0.1),
            _visit!.isActive
                ? AppTheme.successColor.withOpacity(0.05)
                : AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _visit!.isActive
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (_visit!.isActive
                        ? AppTheme.successColor
                        : AppTheme.primaryColor)
                    .withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      (_visit!.isActive
                              ? AppTheme.successColor
                              : AppTheme.primaryColor)
                          .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _visit!.isActive ? Icons.location_on : Icons.location_off,
                  color: _visit!.isActive
                      ? AppTheme.successColor
                      : AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.read<AuthProvider>().user?.name ?? 'User',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Visit ID: ${_visit!.id}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              if (_visit!.isActive) _buildActiveTimer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTimer() {
    return StreamBuilder<Duration>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) {
        if (_visit?.checkInTime != null) {
          return DateTime.now().difference(_visit!.checkInTime);
        }
        return Duration.zero;
      }),
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final seconds = duration.inSeconds.remainder(60);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.successColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.successColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Text(
            'Visit Status',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _visit!.isActive
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _visit!.isActive ? Icons.check_circle : Icons.pending,
                  color: _visit!.isActive
                      ? AppTheme.successColor
                      : AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _visit!.status.toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _visit!.isActive
                            ? AppTheme.successColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _visit!.isActive
                          ? 'Visit is currently active'
                          : 'Visit has been completed',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Icon(Icons.location_on, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Location Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingArea)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _buildLocationInfo('Area', _areaName, Icons.place),
            if (_detailedAddress['street']?.isNotEmpty == true)
              _buildLocationInfo(
                'Street',
                _detailedAddress['street'] ?? '',
                Icons.streetview,
              ),
            if (_detailedAddress['locality']?.isNotEmpty == true)
              _buildLocationInfo(
                'Locality',
                _detailedAddress['locality'] ?? '',
                Icons.location_city,
              ),
            if (_detailedAddress['administrativeArea']?.isNotEmpty == true)
              _buildLocationInfo(
                'State',
                _detailedAddress['administrativeArea'] ?? '',
                Icons.public,
              ),
            _buildLocationInfo(
              'Coordinates',
              '${_visit!.latitude.toStringAsFixed(6)}, ${_visit!.longitude.toStringAsFixed(6)}',
              Icons.gps_fixed,
            ),
          ],

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openInMaps(),
                  icon: const Icon(Icons.map),
                  label: const Text('Open in Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _getDirections(),
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 16),
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
                    fontFamily: label == 'Coordinates' ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Icon(Icons.access_time, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Timing Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTimingInfo(
                  'Check-in',
                  _visit?.checkInTime != null
                      ? DateFormat('HH:mm').format(_visit!.checkInTime!)
                      : 'Not started',
                  Icons.login,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimingInfo(
                  'Check-out',
                  _visit?.checkOutTime != null
                      ? DateFormat('HH:mm').format(_visit!.checkOutTime!)
                      : _visit?.isActive == true
                      ? 'Active'
                      : 'Not completed',
                  Icons.logout,
                  _visit?.isActive == true
                      ? AppTheme.warningColor
                      : AppTheme.errorColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_visit!.checkInTime != null)
            _buildTimingInfo(
              'Duration',
              _visit!.durationString,
              Icons.timer,
              AppTheme.primaryColor,
            ),
        ],
      ),
    );
  }

  Widget _buildTimingInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Icon(Icons.note, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
            ),
            child: Text(
              _visit!.notes!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimaryColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Text(
            'Actions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (_visit!.isActive) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/visit/checkout/${_visit!.id}'),
                icon: const Icon(Icons.logout),
                label: const Text('Check-out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareVisit(),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openInMaps(),
                  icon: const Icon(Icons.map),
                  label: const Text('Maps'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openInMaps() {
    MapsService.openInGoogleMaps(
      _visit!.latitude,
      _visit!.longitude,
      label: _visit!.clientName,
    );
  }

  void _getDirections() {
    MapsService.getDirections(_visit!.latitude, _visit!.longitude);
  }

  void _shareVisit() {
    // Implementation for sharing visit details
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visit details shared!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}
