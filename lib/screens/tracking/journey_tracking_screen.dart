import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/providers/location_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/location_model.dart';
import '../../services/maps_service.dart';

class JourneyTrackingScreen extends StatefulWidget {
  const JourneyTrackingScreen({super.key});

  @override
  State<JourneyTrackingScreen> createState() => _JourneyTrackingScreenState();
}

class _JourneyTrackingScreenState extends State<JourneyTrackingScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadJourneyData();
  }

  Future<void> _loadJourneyData() async {
    setState(() {
      _isLoading = true;
    });

    final locationProvider = context.read<LocationProvider>();
    await locationProvider.getJourneyData(_selectedDate);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadJourneyData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Journey Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadJourneyData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector
          _buildDateSelector(),
          
          // Journey Summary
          _buildJourneySummary(),
          
          // Journey Map/List
          Expanded(
            child: _buildJourneyContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today,
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
                  'Selected Date',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Change'),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms)
    .slideY(begin: -0.2, end: 0);
  }

  Widget _buildJourneySummary() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final logs = locationProvider.locationLogs;
        final totalDistance = _calculateTotalDistance(logs);
        final totalTime = _calculateTotalTime(logs);
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Points',
                  '${logs.length}',
                  Icons.location_on,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Distance',
                  '${totalDistance.toStringAsFixed(1)} km',
                  Icons.straighten,
                  AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Duration',
                  _formatDuration(totalTime),
                  Icons.access_time,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyContent() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        if (_isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (locationProvider.locationLogs.isEmpty) {
          return _buildEmptyState();
        }

        return _buildJourneyList(locationProvider.locationLogs);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Journey Data',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No location data found for the selected date.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to live tracking to start tracking
              Navigator.of(context).pushNamed('/tracking/live');
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Start Tracking'),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyList(List<LocationLog> logs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final isFirst = index == 0;
        final isLast = index == logs.length - 1;
        final previousLog = index > 0 ? logs[index - 1] : null;
        
        return _buildLocationLogCard(log, isFirst, isLast, previousLog, index);
      },
    );
  }

  Widget _buildLocationLogCard(LocationLog log, bool isFirst, bool isLast, LocationLog? previousLog, int index) {
    final distance = previousLog != null 
        ? _calculateDistance(previousLog, log)
        : 0.0;
    
    return GestureDetector(
      onTap: () => _showLocationOptions(log, index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
        children: [
          // Timeline indicator
          Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 20,
                  color: AppTheme.textSecondaryColor.withOpacity(0.3),
                ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isFirst 
                      ? AppTheme.successColor
                      : isLast
                          ? AppTheme.primaryColor
                          : AppTheme.secondaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 20,
                  color: AppTheme.textSecondaryColor.withOpacity(0.3),
                ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Location details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Point ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFirst 
                            ? AppTheme.successColor.withOpacity(0.1)
                            : isLast
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isFirst 
                            ? 'Start'
                            : isLast
                                ? 'End'
                                : 'Waypoint',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isFirst 
                              ? AppTheme.successColor
                              : isLast
                                  ? AppTheme.primaryColor
                                  : AppTheme.secondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm:ss').format(log.timestamp),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.gps_fixed,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${log.accuracy.toStringAsFixed(1)}m',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${log.latitude.toStringAsFixed(6)}, ${log.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                
                if (distance > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.straighten,
                        size: 16,
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(2)} km from previous',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: (index * 50).ms)
    .slideX(begin: 0.2, end: 0),
    );
  }

  double _calculateTotalDistance(List<LocationLog> logs) {
    double total = 0.0;
    for (int i = 1; i < logs.length; i++) {
      total += _calculateDistance(logs[i - 1], logs[i]);
    }
    return total;
  }

  double _calculateDistance(LocationLog log1, LocationLog log2) {
    // Haversine formula implementation
    const double earthRadius = 6371; // km
    
    final double lat1Rad = log1.latitude * (3.14159265359 / 180);
    final double lat2Rad = log2.latitude * (3.14159265359 / 180);
    final double deltaLatRad = (log2.latitude - log1.latitude) * (3.14159265359 / 180);
    final double deltaLonRad = (log2.longitude - log1.longitude) * (3.14159265359 / 180);
    
    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  Duration _calculateTotalTime(List<LocationLog> logs) {
    if (logs.length < 2) return const Duration();
    return logs.last.timestamp.difference(logs.first.timestamp);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Show location options when tapping on a location card
  void _showLocationOptions(LocationLog log, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Location ${index + 1}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${log.latitude.toStringAsFixed(6)}, ${log.longitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('HH:mm:ss').format(log.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await MapsService.openInGoogleMaps(
                        log.latitude, 
                        log.longitude, 
                        label: 'Journey Point ${index + 1}'
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Open in Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await MapsService.getDirections(log.latitude, log.longitude);
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
