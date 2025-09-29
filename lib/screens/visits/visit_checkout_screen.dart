import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/visit_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class VisitCheckoutScreen extends StatefulWidget {
  final String visitId;

  const VisitCheckoutScreen({
    super.key,
    required this.visitId,
  });

  @override
  State<VisitCheckoutScreen> createState() => _VisitCheckoutScreenState();
}

class _VisitCheckoutScreenState extends State<VisitCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVisitDetails();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _loadVisitDetails() {
    // Visit details should already be loaded in the provider
    // This method can be used to refresh if needed
  }

  Future<void> _handleCheckOut() async {
    if (!_formKey.currentState!.validate()) return;

    final visitProvider = context.read<VisitProvider>();

    final success = await visitProvider.checkOut(
      visitId: widget.visitId,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-out successful!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.go('/dashboard');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(visitProvider.error ?? 'Check-out failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Check Out'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(),
              
              const SizedBox(height: 32),
              
              // Visit Details
              _buildVisitDetails(),
              
              const SizedBox(height: 32),
              
              // Check Out Notes
              _buildCheckOutNotes(),
              
              const SizedBox(height: 32),
              
              // Check Out Button
              _buildCheckOutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.errorColor, Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.3),
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
              Icons.logout,
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
                  'Check Out',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete your visit',
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

  Widget _buildVisitDetails() {
    return Consumer<VisitProvider>(
      builder: (context, visitProvider, child) {
        final visit = visitProvider.currentVisit;
        
        if (visit == null) {
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
            child: const Center(
              child: Text('Visit not found'),
            ),
          );
        }

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
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.business,
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
                          'Visit Details',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Client: ${visit.clientName}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Visit Info Cards
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Check In',
                      _formatDateTime(visit.checkInTime),
                      Icons.login,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      'Duration',
                      visit.durationString,
                      Icons.access_time,
                      AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Location',
                      '${visit.latitude.toStringAsFixed(4)}, ${visit.longitude.toStringAsFixed(4)}',
                      Icons.location_on,
                      AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      'Status',
                      visit.isActive ? 'Active' : 'Completed',
                      Icons.info,
                      visit.isActive ? AppTheme.warningColor : AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              
              if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-in Notes:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        visit.notes!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
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

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckOutNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Check-out Notes',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _notesController,
          label: 'Notes (Optional)',
          hint: 'Enter any notes about the visit completion',
          prefixIcon: const Icon(Icons.note_outlined),
          maxLines: 4,
          validator: (value) {
            // Notes are optional, so no validation needed
            return null;
          },
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Adding notes will help you remember important details about this visit.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: 400.ms)
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildCheckOutButton() {
    return Consumer<VisitProvider>(
      builder: (context, visitProvider, child) {
        return CustomButton(
          text: 'Check Out',
          onPressed: visitProvider.isLoading ? null : _handleCheckOut,
          isLoading: visitProvider.isLoading,
          width: double.infinity,
          height: 56,
          backgroundColor: AppTheme.errorColor,
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 600.ms)
        .slideY(begin: 0.2, end: 0);
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
