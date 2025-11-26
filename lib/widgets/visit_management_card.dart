import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/visit_model.dart';
import '../services/geocoding_service.dart';

class VisitManagementCard extends StatefulWidget {
  final Visit visit;
  final VoidCallback onTap;
  final bool showTimer;

  const VisitManagementCard({
    super.key,
    required this.visit,
    required this.onTap,
    this.showTimer = true,
  });

  @override
  State<VisitManagementCard> createState() => _VisitManagementCardState();
}

class _VisitManagementCardState extends State<VisitManagementCard> {
  String _areaName = 'Loading...';
  bool _isLoadingArea = true;

  @override
  void initState() {
    super.initState();
    _loadAreaName();
  }

  Future<void> _loadAreaName() async {
    try {
      final areaName = await GeocodingService.getAreaName(
        widget.visit.latitude,
        widget.visit.longitude,
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
          _areaName =
              '${widget.visit.latitude.toStringAsFixed(6)}, ${widget.visit.longitude.toStringAsFixed(6)}';
          _isLoadingArea = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.visit.isActive
                  ? AppTheme.successColor.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.1),
              widget.visit.isActive
                  ? AppTheme.successColor.withOpacity(0.05)
                  : AppTheme.primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.visit.isActive
                ? AppTheme.successColor.withOpacity(0.3)
                : AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (widget.visit.isActive
                          ? AppTheme.successColor
                          : AppTheme.primaryColor)
                      .withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.visit.isActive
                        ? AppTheme.successColor.withOpacity(0.2)
                        : AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.visit.isActive
                        ? Icons.location_on
                        : Icons.location_off,
                    color: widget.visit.isActive
                        ? AppTheme.successColor
                        : AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.visit.clientName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.visit.status.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.visit.isActive
                              ? AppTheme.successColor
                              : AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.visit.isActive && widget.showTimer) _buildTimer(),
              ],
            ),

            const SizedBox(height: 16),

            // Location details
            _buildLocationDetails(),

            const SizedBox(height: 16),

            // Visit details
            _buildVisitDetails(),

            if (widget.visit.isActive) ...[
              const SizedBox(height: 16),
              _buildActiveVisitActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return StreamBuilder<Duration>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) {
        if (widget.visit.checkInTime != null) {
          return DateTime.now().difference(widget.visit.checkInTime);
        }
        return Duration.zero;
      }),
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final seconds = duration.inSeconds.remainder(60);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.successColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Location',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingArea)
            Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading area...',
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
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.gps_fixed,
                color: AppTheme.textSecondaryColor,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.visit.latitude.toStringAsFixed(6)}, ${widget.visit.longitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitDetails() {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            icon: Icons.access_time,
            label: 'Check-in',
            value: widget.visit.checkInTime != null
                ? DateFormat('HH:mm').format(widget.visit.checkInTime)
                : 'Not started',
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDetailItem(
            icon: Icons.access_time_filled,
            label: 'Check-out',
            value: widget.visit.checkOutTime != null
                ? DateFormat('HH:mm').format(widget.visit.checkOutTime!)
                : widget.visit.isActive
                ? 'Active'
                : 'Not completed',
            color: widget.visit.isActive
                ? AppTheme.successColor
                : AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveVisitActions() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.successColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Visit Active',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your visit is currently active. Tap to view details or check-out.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}
