import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/providers/lead_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lead_model.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/auth_helper.dart';
import '../../services/lead_dropdown_service.dart';

class LeadListScreen extends StatefulWidget {
  const LeadListScreen({super.key});

  @override
  State<LeadListScreen> createState() => _LeadListScreenState();
}

class _LeadListScreenState extends State<LeadListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus; // Changed from LeadStatus? to String?
  String? _selectedSource; // Changed from LeadSource? to String?
  String _selectedTimeRange = 'Custom Date'; // Default to custom date

  // Custom date range
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // API dropdown values
  List<String> _statusList = [];
  Map<String, String> _sourceMap = {};
  bool _isLoadingDropdowns = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadProvider>().initialize();
      _loadDropdownData();
    });
  }

  // Load dropdown data from API
  Future<void> _loadDropdownData() async {
    try {
      print('\n📋 LEAD LIST SCREEN: Loading filter dropdown data...');

      // Clear cache to get fresh data
      LeadDropdownService.clearCache();

      // Get authenticated user ID (created_by)
      final createdBy = await AuthHelper.getAuthenticatedUserId();
      print('🔑 Lead List - Authenticated User ID (created_by): $createdBy');

      // Load status and source data in parallel
      final results = await Future.wait([
        LeadDropdownService.getLeadStatusList(),
        LeadDropdownService.getLeadSourceMap(createdBy),
      ]);

      setState(() {
        _statusList = results[0] as List<String>;
        _sourceMap = results[1] as Map<String, String>;
        _isLoadingDropdowns = false;
      });

      print('✅ Filter dropdowns loaded:');
      print('Status List: $_statusList');
      print('Source Map: $_sourceMap');
      print('Source Map Values: ${_sourceMap.values.toList()}\n');
    } catch (e) {
      print('❌ Error loading filter dropdowns: $e');
      setState(() {
        // Use fallback data on error
        _statusList = [
          'New',
          'Assigned',
          'In Process',
          'Converted',
          'Recycled',
          'Dead',
        ];
        _sourceMap = {
          "1": "Website",
          "2": "Social media",
          "3": "Google",
          "4": "Refferal",
          "5": "partner",
          "8": "Other",
        };
        _isLoadingDropdowns = false;
      });
    }
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by Time',
            onSelected: (value) {
              if (value == 'Custom Date') {
                _showCustomDatePicker();
              } else {
                setState(() {
                  _selectedTimeRange = value;
                  _customStartDate = null;
                  _customEndDate = null;
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'Today',
                child: Row(
                  children: [
                    Icon(
                      Icons.today,
                      color: _selectedTimeRange == 'Today'
                          ? AppTheme.primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Today',
                      style: TextStyle(
                        fontWeight: _selectedTimeRange == 'Today'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedTimeRange == 'Today'
                            ? AppTheme.primaryColor
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Week',
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      color: _selectedTimeRange == 'Week'
                          ? AppTheme.primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'This Week',
                      style: TextStyle(
                        fontWeight: _selectedTimeRange == 'Week'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedTimeRange == 'Week'
                            ? AppTheme.primaryColor
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Month',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: _selectedTimeRange == 'Month'
                          ? AppTheme.primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'This Month',
                      style: TextStyle(
                        fontWeight: _selectedTimeRange == 'Month'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedTimeRange == 'Month'
                            ? AppTheme.primaryColor
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Custom Date',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _selectedTimeRange == 'Custom Date'
                          ? AppTheme.primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _customStartDate != null && _customEndDate != null
                            ? 'Custom: ${DateFormat('MMM dd').format(_customStartDate!)} - ${DateFormat('MMM dd').format(_customEndDate!)}'
                            : 'Custom Date Range',
                        style: TextStyle(
                          fontWeight: _selectedTimeRange == 'Custom Date'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedTimeRange == 'Custom Date'
                              ? AppTheme.primaryColor
                              : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [_buildHeader(), _buildFilters(), _buildLeadsList()],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        children: [
          _buildSearchBar(),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
          _buildStatsCards(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: ResponsiveUtils.getResponsiveElevation(context, 10),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search leads...',
          hintStyle: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: ResponsiveUtils.getResponsiveIconSize(context, 20),
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
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
                    stats.values
                        .fold(0, (sum, count) => sum + count)
                        .toString(),
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context),
        vertical: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
      ),
      child: ResponsiveUtils.isMobile(context)
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterChip(
                        'Status',
                        _selectedStatus ?? 'All Status',
                        () => _showStatusFilter(),
                      ),
                    ),
                    SizedBox(
                      width:
                          ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
                    ),
                    Expanded(
                      child: _buildFilterChip(
                        'Source',
                        _selectedSource ?? 'All Sources',
                        () => _showSourceFilter(),
                      ),
                    ),
                  ],
                ),
                // SizedBox(
                //   height: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
                // ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     IconButton(
                //       onPressed: _clearFilters,
                //       icon: Icon(
                //         Icons.clear_all,
                //         size: ResponsiveUtils.getResponsiveIconSize(
                //           context,
                //           20,
                //         ),
                //       ),
                //       tooltip: 'Clear Filters',
                //     ),
                //   ],
                // ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildFilterChip(
                    'Status',
                    _selectedStatus ?? 'All Status',
                    () => _showStatusFilter(),
                  ),
                ),
                SizedBox(
                  width: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
                ),
                Expanded(
                  child: _buildFilterChip(
                    'Source',
                    _selectedSource ?? 'All Sources',
                    () => _showSourceFilter(),
                  ),
                ),
                SizedBox(
                  width: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
                ),
                IconButton(
                  onPressed: _clearFilters,
                  icon: Icon(
                    Icons.clear_all,
                    size: ResponsiveUtils.getResponsiveIconSize(context, 20),
                  ),
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
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
          vertical: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 20),
          ),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '$label: $value',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
            ),
            Icon(
              Icons.arrow_drop_down,
              size: ResponsiveUtils.getResponsiveIconSize(context, 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadsList() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getResponsiveSpacing(context),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, 20),
            ),
            topRight: Radius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, 20),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: ResponsiveUtils.getResponsiveElevation(context, 10),
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Consumer<LeadProvider>(
          builder: (context, leadProvider, child) {
            if (leadProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
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
                          backgroundColor: AppTheme.primaryColor.withOpacity(
                            0.1,
                          ),
                          child: Text(
                            lead.name.isNotEmpty
                                ? lead.name[0].toUpperCase()
                                : 'L',
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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (lead.company != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  lead.company!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
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
                          child: _buildInfoItem(Icons.email, lead.email),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoItem(Icons.phone, lead.phone),
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
                          child: _buildInfoItem(Icons.business, lead.industry),
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
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
        Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor),
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

    // Time range filter
    if (_selectedTimeRange == 'Custom Date' &&
        _customStartDate != null &&
        _customEndDate != null) {
      // Custom date range filtering
      final startDate = DateTime(
        _customStartDate!.year,
        _customStartDate!.month,
        _customStartDate!.day,
      );
      final endDate = DateTime(
        _customEndDate!.year,
        _customEndDate!.month,
        _customEndDate!.day,
        23,
        59,
        59,
      );

      filteredLeads = filteredLeads.where((lead) {
        return (lead.createdAt.isAfter(startDate) ||
                lead.createdAt.isAtSameMomentAs(startDate)) &&
            (lead.createdAt.isBefore(endDate) ||
                lead.createdAt.isAtSameMomentAs(endDate));
      }).toList();

      print(
        '🔍 Filtering by custom date: ${DateFormat('MMM dd').format(_customStartDate!)} - ${DateFormat('MMM dd').format(_customEndDate!)} (${filteredLeads.length} results)',
      );
    } else if (_selectedTimeRange != 'Custom Date') {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedTimeRange) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'Week':
          // Start of current week (Monday)
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case 'Month':
          // Start of current month
          startDate = DateTime(now.year, now.month, 1);
          break;
        default:
          startDate = DateTime(2000); // Fallback
      }

      filteredLeads = filteredLeads.where((lead) {
        return lead.createdAt.isAfter(startDate) ||
            lead.createdAt.isAtSameMomentAs(startDate);
      }).toList();

      print(
        '🔍 Filtering by time: $_selectedTimeRange (${filteredLeads.length} results)',
      );
    }

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

    // Status filter - Compare display names
    if (_selectedStatus != null) {
      filteredLeads = filteredLeads
          .where((lead) => lead.status.displayName == _selectedStatus)
          .toList();
      print(
        '🔍 Filtering by status: $_selectedStatus (${filteredLeads.length} results)',
      );
    }

    // Source filter - Compare display names
    if (_selectedSource != null) {
      filteredLeads = filteredLeads
          .where((lead) => lead.source.displayName == _selectedSource)
          .toList();
      print(
        '🔍 Filtering by source: $_selectedSource (${filteredLeads.length} results)',
      );
    }

    return filteredLeads;
  }

  void _showStatusFilter() {
    print('\n🔍 STATUS FILTER CLICKED');
    print('Available Status List: $_statusList');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: ResponsiveUtils.getResponsivePadding(context),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter by Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'All Status',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            16,
                          ),
                        ),
                      ),
                      selected: _selectedStatus == null,
                      onTap: () {
                        setState(() {
                          _selectedStatus = null;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    // Use API values instead of enum
                    ..._statusList.map(
                      (status) => ListTile(
                        title: Text(
                          status,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              16,
                            ),
                          ),
                        ),
                        selected: status == _selectedStatus,
                        onTap: () {
                          setState(() {
                            _selectedStatus = status;
                          });
                          print('✅ Status filter selected: $status');
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSourceFilter() {
    print('\n🔍 SOURCE FILTER CLICKED');
    print('Available Source Map: $_sourceMap');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: ResponsiveUtils.getResponsivePadding(context),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter by Source',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'All Sources',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            16,
                          ),
                        ),
                      ),
                      selected: _selectedSource == null,
                      onTap: () {
                        setState(() {
                          _selectedSource = null;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    // Use API values instead of enum
                    ..._sourceMap.values.map(
                      (source) => ListTile(
                        title: Text(
                          source,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              16,
                            ),
                          ),
                        ),
                        selected: source == _selectedSource,
                        onTap: () {
                          setState(() {
                            _selectedSource = source;
                          });
                          print('✅ Source filter selected: $source');
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedSource = null;
      _selectedTimeRange = 'Custom Date';
      _customStartDate = null;
      _customEndDate = null;
      _searchController.clear();
    });
  }

  // Show custom date range picker
  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedTimeRange = 'Custom Date';
      });

      print('\n📅 Custom date range selected:');
      print('Start: ${DateFormat('MMM dd, yyyy').format(_customStartDate!)}');
      print('End: ${DateFormat('MMM dd, yyyy').format(_customEndDate!)}');
    }
  }
}
