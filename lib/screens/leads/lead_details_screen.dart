import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/providers/lead_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lead_model.dart';

class LeadDetailsScreen extends StatefulWidget {
  final String leadId;
  
  const LeadDetailsScreen({
    super.key,
    required this.leadId,
  });

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LeadProvider>(
      builder: (context, leadProvider, child) {
        final lead = leadProvider.getLeadById(widget.leadId);
        
        if (lead == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Lead Details'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Lead not found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(lead.name),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(context, lead),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteDialog(context, lead),
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.secondaryColor,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildLeadHeader(lead),
                    const SizedBox(height: 20),
                    _buildLeadDetails(lead),
                    const SizedBox(height: 20),
                    _buildActionButtons(lead),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeadHeader(Lead lead) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              lead.name.isNotEmpty ? lead.name[0].toUpperCase() : 'L',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lead.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          if (lead.company != null) ...[
            const SizedBox(height: 8),
            Text(
              lead.company!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildStatusChip(lead.status),
          if (lead.opportunityAmount != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.attach_money,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${NumberFormat('#,##0.00').format(lead.opportunityAmount)}',
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildLeadDetails(Lead lead) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lead Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildInfoSection('Contact Information', [
            _buildInfoRow(Icons.email, 'Email', lead.email),
            _buildInfoRow(Icons.phone, 'Phone', lead.phone),
            if (lead.title != null) _buildInfoRow(Icons.work, 'Title', lead.title!),
            if (lead.website != null) _buildInfoRow(Icons.web, 'Website', lead.website!),
          ]),
          
          const SizedBox(height: 20),
          
          _buildInfoSection('Business Information', [
            _buildInfoRow(Icons.business, 'Industry', lead.industry),
            _buildInfoRow(Icons.trending_up, 'Source', lead.source.displayName),
            if (lead.campaign != null) _buildInfoRow(Icons.campaign, 'Campaign', lead.campaign!),
            if (lead.assignedUser != null) _buildInfoRow(Icons.person_pin, 'Assigned User', lead.assignedUser!),
          ]),
          
          if (lead.address != null || lead.city != null || lead.state != null) ...[
            const SizedBox(height: 20),
            _buildInfoSection('Address Information', [
              if (lead.address != null) _buildInfoRow(Icons.location_on, 'Address', lead.address!),
              if (lead.city != null) _buildInfoRow(Icons.location_city, 'City', lead.city!),
              if (lead.state != null) _buildInfoRow(Icons.map, 'State', lead.state!),
              if (lead.postalCode != null) _buildInfoRow(Icons.local_post_office, 'Postal Code', lead.postalCode!),
              if (lead.country != null) _buildInfoRow(Icons.public, 'Country', lead.country!),
            ]),
          ],
          
          if (lead.description != null) ...[
            const SizedBox(height: 20),
            _buildInfoSection('Description', [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lead.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ]),
          ],
          
          const SizedBox(height: 20),
          
          _buildInfoSection('Timeline', [
            _buildInfoRow(Icons.calendar_today, 'Created', DateFormat('MMM dd, yyyy HH:mm').format(lead.createdAt)),
            _buildInfoRow(Icons.update, 'Last Updated', DateFormat('MMM dd, yyyy HH:mm').format(lead.updatedAt)),
          ]),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppTheme.primaryColor,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(LeadStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case LeadStatus.newLead:
        backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
        textColor = AppTheme.primaryColor;
        break;
      case LeadStatus.contacted:
        backgroundColor = AppTheme.warningColor.withOpacity(0.1);
        textColor = AppTheme.warningColor;
        break;
      case LeadStatus.qualified:
        backgroundColor = AppTheme.successColor.withOpacity(0.1);
        textColor = AppTheme.successColor;
        break;
      case LeadStatus.closedWon:
        backgroundColor = AppTheme.successColor.withOpacity(0.1);
        textColor = AppTheme.successColor;
        break;
      case LeadStatus.closedLost:
        backgroundColor = AppTheme.errorColor.withOpacity(0.1);
        textColor = AppTheme.errorColor;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Lead lead) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showEditDialog(context, lead),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
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
                  onPressed: () => _showDeleteDialog(context, lead),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  void _showEditDialog(BuildContext context, Lead lead) {
    // For now, just show a message
    // In a real app, you would navigate to an edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon!'),
        backgroundColor: AppTheme.warningColor,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Lead lead) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lead'),
        content: Text('Are you sure you want to delete "${lead.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final leadProvider = context.read<LeadProvider>();
              final success = await leadProvider.deleteLead(lead.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lead deleted successfully!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
                context.pop();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete lead: ${leadProvider.error}'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
