import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/providers/visit_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/visit_model.dart';

class VisitHistoryScreen extends StatefulWidget {
  const VisitHistoryScreen({super.key});

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitProvider>().loadVisits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Visit History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<VisitProvider>().loadVisits();
            },
          ),
        ],
      ),
      body: Consumer<VisitProvider>(
        builder: (context, visitProvider, child) {
          if (visitProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (visitProvider.visits.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => visitProvider.loadVisits(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visitProvider.visits.length,
              itemBuilder: (context, index) {
                final visit = visitProvider.visits[index];
                return _buildVisitCard(visit, index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Visits Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your visit history will appear here',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/visit/checkin');
            },
            icon: const Icon(Icons.add),
            label: const Text('Start First Visit'),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(Visit visit, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showVisitDetails(visit),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: visit.isActive 
                            ? AppTheme.warningColor.withOpacity(0.1)
                            : AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        visit.isActive ? Icons.location_on : Icons.check_circle,
                        color: visit.isActive 
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
                            visit.clientName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(visit.checkInTime),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: visit.isActive 
                            ? AppTheme.warningColor.withOpacity(0.1)
                            : AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        visit.isActive ? 'Active' : 'Completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: visit.isActive 
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Visit Details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Check In',
                        _formatTime(visit.checkInTime),
                        Icons.login,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailItem(
                        'Check Out',
                        visit.checkOutTime != null 
                            ? _formatTime(visit.checkOutTime!)
                            : 'N/A',
                        Icons.logout,
                        AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailItem(
                        'Duration',
                        visit.durationString,
                        Icons.access_time,
                        AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
                
                if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            visit.notes!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Location Info
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${visit.latitude.toStringAsFixed(4)}, ${visit.longitude.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: (index * 100).ms)
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showVisitDetails(Visit visit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVisitDetailsSheet(visit),
    );
  }

  Widget _buildVisitDetailsSheet(Visit visit) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Visit Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection('Client Information', [
                    _buildDetailRow('Client Name', visit.clientName),
                    _buildDetailRow('Status', visit.isActive ? 'Active' : 'Completed'),
                  ]),
                  
                  _buildDetailSection('Timing Information', [
                    _buildDetailRow('Check In', _formatDateTime(visit.checkInTime)),
                    _buildDetailRow('Check Out', visit.checkOutTime != null 
                        ? _formatDateTime(visit.checkOutTime!)
                        : 'Not completed'),
                    _buildDetailRow('Duration', visit.durationString),
                  ]),
                  
                  _buildDetailSection('Location Information', [
                    _buildDetailRow('Latitude', visit.latitude.toStringAsFixed(6)),
                    _buildDetailRow('Longitude', visit.longitude.toStringAsFixed(6)),
                  ]),
                  
                  if (visit.notes != null && visit.notes!.isNotEmpty)
                    _buildDetailSection('Notes', [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          visit.notes!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ]),
                  
                  if (visit.checkOutNotes != null && visit.checkOutNotes!.isNotEmpty)
                    _buildDetailSection('Check-out Notes', [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          visit.checkOutNotes!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ]),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${_formatTime(date)}';
  }
}
