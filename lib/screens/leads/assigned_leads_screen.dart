import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/lead_model.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/auth_helper.dart';
import '../../services/assigned_leads_service.dart';

class AssignedLeadsScreen extends StatefulWidget {
  const AssignedLeadsScreen({super.key});

  @override
  State<AssignedLeadsScreen> createState() => _AssignedLeadsScreenState();
}

class _AssignedLeadsScreenState extends State<AssignedLeadsScreen> {
  List<Lead> _assignedLeads = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAssignedLeads();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignedLeads() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = await AuthHelper.getAuthenticatedUserId();
      final leads = await AssignedLeadsService.getAssignedLeads(userId);

      setState(() {
        _assignedLeads = leads;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load assigned leads: $e';
        _isLoading = false;
      });
    }
  }

  List<Lead> _getFilteredLeads() {
    if (_searchController.text.isEmpty) {
      return _assignedLeads;
    }

    final query = _searchController.text.toLowerCase();
    return _assignedLeads.where((lead) {
      return lead.name.toLowerCase().contains(query) ||
          lead.email.toLowerCase().contains(query) ||
          lead.phone.toLowerCase().contains(query) ||
          (lead.company?.toLowerCase().contains(query) ?? false) ||
          (lead.industry.toLowerCase().contains(query)) ||
          (lead.address?.toLowerCase().contains(query) ?? false) ||
          (lead.city?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Leads'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              AssignedLeadsService.clearCache();
              _loadAssignedLeads();
            },
            tooltip: 'Refresh',
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
          child: Column(children: [_buildHeader(), _buildLeadsList()]),
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
          _buildStatsCard(),
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
          hintText: 'Search assigned leads...',
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

  Widget _buildStatsCard() {
    final filteredLeads = _getFilteredLeads();
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
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Assigned',
                  _assignedLeads.length.toString(),
                  Icons.people,
                  AppTheme.primaryColor,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              Expanded(
                child: _buildStatItem(
                  'Showing',
                  filteredLeads.length.toString(),
                  Icons.filter_list,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
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
    );
  }

  Widget _buildLeadsList() {
    if (_isLoading) {
      return Expanded(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    if (_error != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: ResponsiveUtils.getResponsiveIconSize(context, 64),
                color: AppTheme.errorColor,
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              Text(
                'Error',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppTheme.errorColor),
              ),
              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
              ),
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.errorColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              ElevatedButton(
                onPressed: _loadAssignedLeads,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredLeads = _getFilteredLeads();

    if (filteredLeads.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: ResponsiveUtils.getResponsiveIconSize(context, 64),
                color: AppTheme.textSecondaryColor,
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              Text(
                _assignedLeads.isEmpty
                    ? 'No assigned leads found'
                    : 'No leads match your search',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
              ),
              Text(
                _assignedLeads.isEmpty
                    ? 'You don\'t have any assigned leads yet'
                    : 'Try adjusting your search criteria',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
        child: RefreshIndicator(
          onRefresh: () async {
            AssignedLeadsService.clearCache();
            await _loadAssignedLeads();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredLeads.length,
            itemBuilder: (context, index) {
              final lead = filteredLeads[index];
              return _buildLeadCard(lead, index);
            },
          ),
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
              onTap: () {
                // Navigate to visit management with preselected lead
                final uri = Uri(
                  path: '/visit/management',
                  queryParameters: {'leadId': lead.id},
                );
                context.push(uri.toString());
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with avatar, name, and status
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(
                            0.1,
                          ),
                          radius: 20,
                          child: Text(
                            lead.name.isNotEmpty
                                ? lead.name[0].toUpperCase()
                                : 'L',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                18,
                              ),
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

                    // Contact Information - Compact layout
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactInfoItem(Icons.email, lead.email),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactPhoneItem(lead.phone)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactInfoItem(
                            Icons.business,
                            lead.industry,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactInfoItem(
                            Icons.trending_up,
                            lead.source.displayName,
                          ),
                        ),
                      ],
                    ),
                    if (lead.opportunityAmount != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: 4),
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

                    // Full Address Information - Clickable to open Google Maps
                    if (lead.address != null && lead.address!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openAddressInMaps(lead.address!),
                              child: Text(
                                lead.address!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontSize:
                                          ResponsiveUtils.getResponsiveFontSize(
                                            context,
                                            12,
                                          ),
                                      decoration: TextDecoration.underline,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (lead.city != null || lead.state != null) ...[
                      // Fallback to city/state if address is not available
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                final location = [
                                  if (lead.city != null) lead.city!,
                                  if (lead.state != null) lead.state!,
                                ].join(', ');
                                if (location.isNotEmpty) {
                                  _openAddressInMaps(location);
                                }
                              },
                              child: Text(
                                [
                                  if (lead.city != null) lead.city!,
                                  if (lead.state != null) lead.state!,
                                ].join(', '),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontSize:
                                          ResponsiveUtils.getResponsiveFontSize(
                                            context,
                                            12,
                                          ),
                                      decoration: TextDecoration.underline,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Created Date
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Created: ${DateFormat('MMM dd, yyyy').format(lead.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textSecondaryColor,
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  12,
                                ),
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
        .fadeIn(duration: 600.ms, delay: (index * 50).ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildCompactInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onTap: () => _openMail(text),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimaryColor,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactPhoneItem(String phoneNumber) {
    return Row(
      children: [
        Icon(Icons.phone, size: 14, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onTap: () => _openDialer(phoneNumber),
            child: Text(
              phoneNumber,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: () => _openWhatsApp(phoneNumber),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.message, size: 12, color: Colors.white),
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
      case LeadStatus.assigned:
        backgroundColor = AppTheme.warningColor.withOpacity(0.1);
        textColor = AppTheme.warningColor;
        break;
      case LeadStatus.inProcess:
        backgroundColor = AppTheme.secondaryColor.withOpacity(0.1);
        textColor = AppTheme.secondaryColor;
        break;
      case LeadStatus.converted:
        backgroundColor = AppTheme.successColor.withOpacity(0.1);
        textColor = AppTheme.successColor;
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

  Future<void> _openMail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open mail'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _openAddressInMaps(String address) async {
    try {
      // Encode the address for URL
      final encodedAddress = Uri.encodeComponent(address);

      // Try to open in Google Maps app first
      final googleMapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
      );

      if (await canLaunchUrl(googleMapsUri)) {
        final launched = await launchUrl(
          googleMapsUri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          // Fallback to web browser
          await launchUrl(
            googleMapsUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        }
      } else {
        throw Exception('Could not launch Google Maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Google Maps: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _openDialer(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open dialer',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              ),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    try {
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      if (cleanPhone.startsWith('+')) {
        cleanPhone = cleanPhone.substring(1);
      }

      cleanPhone = cleanPhone.replaceAll(RegExp(r'[^\d]'), '');

      if (cleanPhone.length == 10) {
        cleanPhone = '91$cleanPhone';
      } else if (cleanPhone.length < 10) {
        cleanPhone = '91$cleanPhone';
      }

      bool launched = false;

      try {
        final whatsappUri = Uri.parse('whatsapp://send?phone=$cleanPhone');
        launched = await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (e) {
        // Continue to next method if this fails
      }

      try {
        final webUri = Uri.parse('https://wa.me/$cleanPhone');
        launched = await launchUrl(webUri, mode: LaunchMode.platformDefault);
        if (launched) return;

        if (!launched) {
          launched = await launchUrl(
            webUri,
            mode: LaunchMode.externalApplication,
          );
        }

        if (!launched) {
          launched = await launchUrl(
            webUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        }
      } catch (e) {
        // Will show error message below
      }

      if (!launched) {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open WhatsApp. Please make sure WhatsApp is installed.',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              ),
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
