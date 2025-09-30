import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';

class VisitDetailsScreen extends StatelessWidget {
  final String place;
  final String person;
  final String reason;
  final String area;
  final File? photo;
  final double? latitude;
  final double? longitude;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final VoidCallback? onEdit;
  final VoidCallback? onCheckOut;

  const VisitDetailsScreen({
    super.key,
    required this.place,
    required this.person,
    required this.reason,
    required this.area,
    this.photo,
    this.latitude,
    this.longitude,
    this.checkInTime,
    this.checkOutTime,
    this.onEdit,
    this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = checkOutTime == null;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Visit Details'),
        actions: [
          if (isActive) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: onCheckOut,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(context, isActive)
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.2, end: 0),
            
            const SizedBox(height: 24),
            
            // Visit Information Card
            _buildVisitInfoCard(context)
                .animate()
                .fadeIn(duration: 600.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 24),
            
            // Photo Card
            if (photo != null)
              _buildPhotoCard(context)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 300.ms)
                  .slideY(begin: 0.2, end: 0),
            
            if (photo != null) const SizedBox(height: 24),
            
            // Timing Information Card
            _buildTimingCard(context)
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms)
                .slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 24),
            
            // Location Coordinates Card
            if (latitude != null && longitude != null)
              _buildCoordinatesCard(context)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 500.ms)
                  .slideY(begin: 0.2, end: 0),
            
            if (latitude != null && longitude != null) const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive 
              ? [AppTheme.successColor, AppTheme.successColor.withOpacity(0.8)]
              : [AppTheme.textSecondaryColor, AppTheme.textSecondaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isActive ? AppTheme.successColor : AppTheme.textSecondaryColor).withOpacity(0.3),
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
            child: Icon(
              isActive ? Icons.location_on : Icons.check_circle,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Visit Active' : 'Visit Completed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive ? 'Currently at location' : 'Visit has been completed',
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

  Widget _buildVisitInfoCard(BuildContext context) {
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
          Text(
            'Visit Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildInfoRow(
            context,
            icon: Icons.location_city,
            label: 'Visiting Area',
            value: area,
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            context,
            icon: Icons.place,
            label: 'Visiting Place',
            value: place,
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            context,
            icon: Icons.person,
            label: 'Visiting Person',
            value: person,
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            context,
            icon: Icons.description,
            label: 'Visiting Reason',
            value: reason,
            isMultiline: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context) {
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
          Text(
            'Visit Place Photo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              photo!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatesCard(BuildContext context) {
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
          Text(
            'Location Coordinates',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildInfoRow(
            context,
            icon: Icons.my_location,
            label: 'Latitude',
            value: latitude!.toStringAsFixed(6),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            context,
            icon: Icons.my_location,
            label: 'Longitude',
            value: longitude!.toStringAsFixed(6),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            context,
            icon: Icons.location_searching,
            label: 'Coordinates',
            value: '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
          ),
        ],
      ),
    );
  }

  Widget _buildTimingCard(BuildContext context) {
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
          Text(
            'Timing Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          if (checkInTime != null)
            _buildInfoRow(
              context,
              icon: Icons.login,
              label: 'Check-in Time',
              value: _formatDateTime(checkInTime!),
            ),
          
          if (checkInTime != null && checkOutTime != null)
            const SizedBox(height: 16),
          
          if (checkOutTime != null)
            _buildInfoRow(
              context,
              icon: Icons.logout,
              label: 'Check-out Time',
              value: _formatDateTime(checkOutTime!),
            ),
          
          if (checkInTime != null && checkOutTime != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              icon: Icons.access_time,
              label: 'Duration',
              value: _calculateDuration(checkInTime!, checkOutTime!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
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
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _calculateDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
