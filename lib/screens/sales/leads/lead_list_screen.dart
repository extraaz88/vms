import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vms/core/providers/lead_provider.dart';
import 'package:vms/core/providers/visit_provider.dart';
import 'package:vms/core/theme/app_theme.dart';
import 'package:vms/models/lead_model.dart';
import 'package:vms/utils/auth_helper.dart' show AuthHelper;
import 'package:vms/utils/responsive_utils.dart';
import 'package:vms/widgets/custom_bottom_navigation.dart';

import '../../../services/sales/assigned_leads_service.dart';
import '../../../services/sales/lead_dropdown_service.dart';

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
  String _selectedFilterTab =
      'All'; // Filter tab: All, Assigned, In Process, Demo Pending

  // Custom date range
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // API dropdown values
  List<String> _statusList = [];
  Map<String, String> _sourceMap = {};
  List<Lead> _assignedLeads = [];
  Set<String> _assignedLeadIds = {};
  bool _isLoadingAssignedLeads = true;
  String? _assignedLeadsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadProvider>().initialize();
      _loadDropdownData();
      _loadAssignedLeads();
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
      });
    }
  }

  Future<void> _loadAssignedLeads({bool forceRefresh = false}) async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingAssignedLeads = true;
          if (forceRefresh) {
            _assignedLeadsError = null;
          }
        });
      }

      final userId = await AuthHelper.getAuthenticatedUserId();
      final leads = forceRefresh
          ? await AssignedLeadsService.refreshAssignedLeads(userId)
          : await AssignedLeadsService.getAssignedLeads(userId);

      if (mounted) {
        setState(() {
          _assignedLeads = leads;
          _assignedLeadIds = leads.whereType<Lead>().map((lead) => lead.id).toSet();
          _isLoadingAssignedLeads = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _assignedLeadsError = 'Failed to load assigned leads';
          _isLoadingAssignedLeads = false;
        });
      }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Text(
              'All Leads',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<LeadProvider>().refreshLeads();
              _loadAssignedLeads(forceRefresh: true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => context.push('/leads/create'),
          ),
        ],
      ),
      body: Container(
        color: AppTheme.primaryColor,
        child: SafeArea(
          child: Column(children: [_buildHeader(), _buildLeadsList()]),
        ),
      ),
      bottomNavigationBar: Consumer<VisitProvider>(
        builder: (context, visitProvider, child) {
          return CustomBottomNavigation(
            currentIndex: 2,
            isCheckedIn: visitProvider.hasActiveVisit,
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context)),
      child: Column(
        children: [
          _buildSearchBar(),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
          _buildStatsCards(),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
          _buildFilterTabs(),
          if (_isLoadingAssignedLeads) ...[
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            const LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              backgroundColor: Colors.white24,
            ),
          ] else if (_assignedLeadsError != null) ...[
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _assignedLeadsError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search leads...',
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      style: const TextStyle(fontSize: 14),
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildStatsCards() {
    return Consumer<LeadProvider>(
      builder: (context, leadProvider, child) {
        final stats = leadProvider.getLeadsStatistics();
        final regularLeadsCount = stats.values.fold(
          0,
          (sum, count) => sum + count,
        );
        final assignedLeadsCount = _assignedLeads.length;

        // Calculate total without double-counting (leads that exist in both)
        final mergedLeads = _combineLeads(leadProvider.leads);
        final totalLeadsCount = mergedLeads.length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Leads',
                totalLeadsCount.toString(),
                Icons.people,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Assigned',
                assignedLeadsCount.toString(),
                Icons.people,
                AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Regular',
                regularLeadsCount.toString(),
                Icons.person_outline,
                AppTheme.secondaryColor,
              ),
            ),
          ],
        );
      },
    );
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsList() {
    return Expanded(
      child: Container(
        color: Colors.white,
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

            // Debug: Check what we have before combining
            print('\n📋 BEFORE COMBINING:');
            print('Regular leads from provider: ${leadProvider.leads.length}');
            print('Assigned leads: ${_assignedLeads.length}');

            final mergedLeads = _combineLeads(leadProvider.leads);
            print('Merged leads total: ${mergedLeads.length}');

            final filteredLeads = _getFilteredLeads(mergedLeads);
            print('Filtered leads: ${filteredLeads.length}\n');

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

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<LeadProvider>().refreshLeads();
                await _loadAssignedLeads(forceRefresh: true);
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: filteredLeads.length,
                itemBuilder: (context, index) {
                  final lead = filteredLeads[index];
                  final isAssigned = _assignedLeadIds.contains(lead.id);
                  return _buildLeadCard(lead, index, isAssigned: isAssigned);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeadCard(Lead lead, int index, {bool isAssigned = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          onTap: isAssigned
              ? () {
                  // Only assigned leads can navigate to visit management
                  final uri = Uri(
                    path: '/visit/management',
                    queryParameters: {'leadId': lead.id},
                  );
                  context.push(uri.toString());
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      radius: 24,
                      child: Text(
                        lead.name.isNotEmpty ? lead.name[0].toUpperCase() : 'L',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatusBadge(lead.status),
                        if (isAssigned) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Assigned',
                              style: TextStyle(
                                color: AppTheme.warningColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Created ${DateFormat('MMM dd, yyyy').format(lead.createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.email, lead.email),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.phone, lead.phone),
                    if (lead.address != null &&
                        lead.address!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.location_on, lead.address!),
                    ],
                  ],
                ),
                if (isAssigned) ...[
                  const SizedBox(height: 16),
                  _buildAssignedActions(lead),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? textColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor ?? Colors.grey[600],
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(LeadStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case LeadStatus.newLead:
        backgroundColor = AppTheme.primaryColor.withOpacity(0.15);
        textColor = AppTheme.primaryColor;
        break;
      case LeadStatus.contacted:
        backgroundColor = AppTheme.warningColor.withOpacity(0.15);
        textColor = AppTheme.warningColor;
        break;
      case LeadStatus.qualified:
        backgroundColor = AppTheme.successColor.withOpacity(0.15);
        textColor = AppTheme.successColor;
        break;
      case LeadStatus.closedWon:
        backgroundColor = AppTheme.successColor.withOpacity(0.15);
        textColor = AppTheme.successColor;
        break;
      case LeadStatus.closedLost:
        backgroundColor = AppTheme.errorColor.withOpacity(0.15);
        textColor = AppTheme.errorColor;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.15);
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAssignedActions(Lead lead) {
    final phone = lead.phone.trim();
    final email = lead.email.trim();
    final address = lead.address?.trim() ?? '';
    final hasPhone = phone.isNotEmpty;
    final hasEmail = email.isNotEmpty;
    final hasAddress = address.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.call,
            color: AppTheme.primaryColor.withOpacity(0.15),
            iconColor: AppTheme.primaryColor,
            onTap: hasPhone ? () => _launchCall(phone) : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.chat_bubble_outline,
            color: AppTheme.primaryColor.withOpacity(0.15),
            iconColor: AppTheme.primaryColor,
            onTap: hasPhone ? () => _launchWhatsApp(phone) : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.email_outlined,
            color: AppTheme.secondaryColor.withOpacity(0.15),
            iconColor: AppTheme.secondaryColor,
            onTap: hasEmail ? () => _launchEmail(email) : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.location_on_outlined,
            color: AppTheme.warningColor.withOpacity(0.15),
            iconColor: AppTheme.warningColor,
            onTap: hasAddress ? () => _launchMap(address) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey.withOpacity(0.1) : color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDisabled ? Colors.grey : iconColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  Future<void> _launchCall(String phone) async {
    await _launchExternal(
      Uri(scheme: 'tel', path: phone),
      errorMessage: 'Unable to place the call',
    );
  }

  Future<void> _launchWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      _showLaunchError('Phone number is invalid');
      return;
    }
    await _launchExternal(
      Uri.parse('https://wa.me/$digits'),
      errorMessage: 'Unable to open WhatsApp',
    );
  }

  Future<void> _launchEmail(String email) async {
    await _launchExternal(
      Uri(scheme: 'mailto', path: email),
      errorMessage: 'Unable to open email client',
    );
  }

  Future<void> _launchMap(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    await _launchExternal(
      Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
      ),
      errorMessage: 'Unable to open Maps',
    );
  }

  Future<void> _launchExternal(Uri uri, {String? errorMessage}) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showLaunchError(errorMessage ?? 'Unable to open link');
      }
    } catch (e) {
      _showLaunchError(errorMessage ?? 'Unable to open link');
    }
  }

  void _showLaunchError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  List<Lead> _combineLeads(List<Lead> leads) {
    // Debug output
    print('\n🔄 COMBINING LEADS:');
    print('═══════════════════════════════════════');
    print('📊 Regular leads count: ${leads.length}');
    print('📋 Assigned leads count: ${_assignedLeads.length}');

    // Create a map to store all leads (no duplicates by ID)
    final Map<String, Lead> merged = {};

    // First, add ALL regular leads (created leads)
    for (final lead in leads) {
      merged[lead.id] = lead;
    }
    print('✅ After adding regular leads: ${merged.length}');

    // Then, add assigned leads (these will override regular leads if same ID exists)
    // This prioritizes assigned leads when there's a duplicate
    for (final assignedLead in _assignedLeads) {
      merged[assignedLead.id] = assignedLead;
    }

    print('✅ After adding assigned leads: ${merged.length}');
    print('📝 Final combined leads: ${merged.length}');
    print('═══════════════════════════════════════\n');

    return merged.values.toList();
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', _selectedFilterTab == 'All'),
          _buildFilterChip('Assigned', _selectedFilterTab == 'Assigned'),
          _buildFilterChip('In Process', _selectedFilterTab == 'In Process'),
          _buildFilterChip('Converted', _selectedFilterTab == 'Converted'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilterTab = label;
          });
        },
        selectedColor: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  List<Lead> _getFilteredLeads(List<Lead> leads) {
    var filteredLeads = leads;

    // Filter by selected tab
    if (_selectedFilterTab == 'Assigned') {
      // Show only assigned leads from backend
      filteredLeads = filteredLeads.where((lead) {
        return _assignedLeadIds.contains(lead.id);
      }).toList();
    } else if (_selectedFilterTab == 'In Process') {
      // Show leads with "In Process" status
      filteredLeads = filteredLeads.where((lead) {
        return lead.status.displayName == 'In Process';
      }).toList();
    } else if (_selectedFilterTab == 'Converted') {
      // Show leads with "Demo Pending" or "Converted" status
      filteredLeads = filteredLeads.where((lead) {
        return lead.status.displayName == 'Demo Pending' ||
            lead.status.displayName == 'Converted';
      }).toList();
    }
    // "All" tab shows all leads (no additional filtering)

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
}
