import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/providers/lead_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lead_model.dart';

class LeadListScreen extends StatefulWidget {
  const LeadListScreen({super.key});

  @override
  State<LeadListScreen> createState() => _LeadListScreenState();
}

class _LeadListScreenState extends State<LeadListScreen> {
  final TextEditingController _searchController = TextEditingController();
  LeadStatus? _selectedStatus;
  LeadSource? _selectedSource;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/leads/create'),
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
          child: Column(
            children: [
              _buildHeader(),
              _buildFilters(),
              _buildLeadsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildStatsCards(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search leads...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatsCards() {
    return Consumer<LeadProvider>(
      builder: (context, leadProvider, child) {
        final stats = leadProvider.getLeadsStatistics();
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Leads',
                stats.values.fold(0, (sum, count) => sum + count).toString(),
                Icons.people,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'New',
                stats['New']?.toString() ?? '0',
                Icons.new_releases,
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Qualified',
                stats['Qualified']?.toString() ?? '0',
                Icons.check_circle,
                AppTheme.warningColor,
              ),
            ),
          ],
        );
      },
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              'Status',
              _selectedStatus?.displayName ?? 'All Status',
              () => _showStatusFilter(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterChip(
              'Source',
              _selectedSource?.displayName ?? 'All Sources',
              () => _showSourceFilter(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Filters',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $value',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadsList() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Consumer<LeadProvider>(
          builder: (context, leadProvider, child) {
            if (leadProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              );
            }

            if (leadProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${leadProvider.error}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => leadProvider.refreshLeads(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final filteredLeads = _getFilteredLeads(leadProvider.leads);

            if (filteredLeads.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 64,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No leads found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first lead to get started',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/leads/create'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Lead'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredLeads.length,
              itemBuilder: (context, index) {
                final lead = filteredLeads[index];
                return _buildLeadCard(lead, index);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeadCard(Lead lead, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/leads/${lead.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        lead.name.isNotEmpty ? lead.name[0].toUpperCase() : 'L',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (lead.company != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              lead.company!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildStatusChip(lead.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.email,
                        lead.email,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.phone,
                        lead.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.trending_up,
                        lead.source.displayName,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.business,
                        lead.industry,
                      ),
                    ),
                  ],
                ),
                if (lead.opportunityAmount != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 16,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${NumberFormat('#,##0.00').format(lead.opportunityAmount)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Created ${DateFormat('MMM dd, yyyy').format(lead.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: (index * 50).ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<Lead> _getFilteredLeads(List<Lead> leads) {
    var filteredLeads = leads;

    // Search filter
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filteredLeads = filteredLeads.where((lead) {
        return lead.name.toLowerCase().contains(searchQuery) ||
               lead.email.toLowerCase().contains(searchQuery) ||
               lead.phone.toLowerCase().contains(searchQuery) ||
               (lead.company?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    }

    // Status filter
    if (_selectedStatus != null) {
      filteredLeads = filteredLeads.where((lead) => lead.status == _selectedStatus).toList();
    }

    // Source filter
    if (_selectedSource != null) {
      filteredLeads = filteredLeads.where((lead) => lead.source == _selectedSource).toList();
    }

    return filteredLeads;
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter by Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All Status'),
              selected: _selectedStatus == null,
              onTap: () {
                setState(() {
                  _selectedStatus = null;
                });
                Navigator.pop(context);
              },
            ),
            ...LeadStatus.values.map((status) => ListTile(
              title: Text(status.displayName),
              selected: status == _selectedStatus,
              onTap: () {
                setState(() {
                  _selectedStatus = status;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showSourceFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter by Source',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All Sources'),
              selected: _selectedSource == null,
              onTap: () {
                setState(() {
                  _selectedSource = null;
                });
                Navigator.pop(context);
              },
            ),
            ...LeadSource.values.map((source) => ListTile(
              title: Text(source.displayName),
              selected: source == _selectedSource,
              onTap: () {
                setState(() {
                  _selectedSource = source;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedSource = null;
      _searchController.clear();
    });
  }
}
