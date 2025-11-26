import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/lead_model.dart';
import '../../services/api_service.dart';
import '../../utils/auth_helper.dart';
import 'notification_provider.dart';

class LeadProvider extends ChangeNotifier {
  List<Lead> _leads = [];
  bool _isLoading = false;
  String? _error;
  final ApiService _apiService = ApiService();
  NotificationProvider? _notificationProvider;

  // Set notification provider (called from main or screens)
  void setNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

  // Getters
  List<Lead> get leads => _leads;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize provider
  Future<void> initialize() async {
    await fetchLeadsFromAPI();
  }

  // Fetch leads from API
  Future<void> fetchLeadsFromAPI() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('\n📋 LEAD PROVIDER: Fetching leads from API...');

      // Get authenticated user ID (dynamic)
      final userId = await AuthHelper.getAuthenticatedUserId();
      print('🔑 Lead Provider - Authenticated User ID: $userId');

      // Fetch leads from API
      final leadsData = await _apiService.getUserLeads(userId);
      print('✅ Fetched ${leadsData.length} leads from API');

      // Convert API data to Lead objects
      _leads = leadsData
          .map((leadData) {
            try {
              return _convertApiDataToLead(leadData);
            } catch (e) {
              print('⚠️ Failed to convert lead: $e');
              return null;
            }
          })
          .whereType<Lead>()
          .toList();

      // Save to local storage
      await _saveLeads();

      print('✅ ${_leads.length} leads loaded and saved to local storage');
    } catch (e) {
      print('❌ Error fetching leads from API: $e');
      _error = 'Failed to load leads: $e';

      // Fallback to local storage if API fails
      await _loadLeads();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convert API data to Lead model
  Lead _convertApiDataToLead(Map<String, dynamic> data) {
    return Lead(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      title: data['title']?.toString(),
      account: data['account']?.toString(),
      company: data['company']?.toString() ?? data['account']?.toString(),
      website: data['website']?.toString(),
      address: data['lead_address']?.toString() ?? data['address']?.toString(),
      city: data['lead_city']?.toString() ?? data['city']?.toString(),
      state: data['lead_state']?.toString() ?? data['state']?.toString(),
      postalCode:
          data['lead_postalcode']?.toString() ??
          data['postal_code']?.toString(),
      country: data['lead_country']?.toString() ?? data['country']?.toString(),
      status: _parseLeadStatus(data['status']),
      source: _parseLeadSource(data['source']),
      opportunityAmount: _parseDouble(data['opportunity_amount']),
      campaign: data['campaign']?.toString(),
      industry: data['industry']?.toString() ?? 'Sales',
      assignedUser:
          data['created_by']?.toString() ?? data['user_id']?.toString(),
      description: data['description']?.toString(),
      createdAt: _parseDateTime(data['created_at']),
      updatedAt: _parseDateTime(data['updated_at']),
    );
  }

  // Parse LeadStatus from API data
  LeadStatus _parseLeadStatus(dynamic status) {
    if (status == null) return LeadStatus.newLead;

    if (status is int) {
      // Handle numeric status
      switch (status) {
        case 1:
          return LeadStatus.newLead;
        case 2:
          return LeadStatus.contacted;
        case 3:
          return LeadStatus.qualified;
        case 4:
          return LeadStatus.closedWon;
        case 5:
          return LeadStatus.closedLost;
        default:
          return LeadStatus.newLead;
      }
    } else if (status is String) {
      // Handle string status
      try {
        return LeadStatus.fromApiString(status);
      } catch (e) {
        return LeadStatus.newLead;
      }
    }

    return LeadStatus.newLead;
  }

  // Parse LeadSource from API data
  LeadSource _parseLeadSource(dynamic source) {
    if (source == null) return LeadSource.coldCalling;

    if (source is int) {
      // Handle numeric source
      switch (source) {
        case 1:
          return LeadSource.coldCalling;
        case 2:
          return LeadSource.referral;
        case 3:
          return LeadSource.contact;
        case 4:
          return LeadSource.blueprint;
        case 5:
          return LeadSource.partner;
        default:
          return LeadSource.other;
      }
    } else if (source is String) {
      // Handle string source
      try {
        return LeadSource.fromApiString(source);
      } catch (e) {
        return LeadSource.other;
      }
    }

    return LeadSource.coldCalling;
  }

  // Parse double from dynamic value
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  // Parse DateTime from dynamic value
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Load leads from local storage
  Future<void> _loadLeads() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final leadsJson = prefs.getString('leads_data');

      if (leadsJson != null) {
        final List<dynamic> leadsList = json.decode(leadsJson);
        _leads = leadsList.map((json) => Lead.fromJson(json)).toList();
      } else {
        // Start with empty list - no dummy data
        _leads = [];
      }
    } catch (e) {
      _error = 'Failed to load leads: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save leads to local storage
  Future<void> _saveLeads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final leadsJson = json.encode(
        _leads.map((lead) => lead.toJson()).toList(),
      );
      await prefs.setString('leads_data', leadsJson);
    } catch (e) {
      _error = 'Failed to save leads: $e';
      notifyListeners();
    }
  }

  // Create new lead using API
  Future<bool> createLead(Lead lead) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('\n🔵 CREATE LEAD - Starting API call...');
      print('Lead Name: ${lead.name}');
      print('Lead Email: ${lead.email}');
      print('Lead Phone: ${lead.phone}');
      print('Assigned User: ${lead.assignedUser ?? "Not Set"}');
      print('Account: ${lead.account ?? "Not Set"}');
      print('Status: ${lead.status.displayName}');
      print('Source: ${lead.source.displayName}');

      // Get authenticated user ID (creator of the lead)
      final authenticatedUserId = await AuthHelper.getAuthenticatedUserId();
      print('🔑 Lead Provider - Authenticated User ID: $authenticatedUserId');

      // Parse values safely with tryParse
      final userId = int.tryParse(authenticatedUserId) ?? 1;
      final account = int.tryParse(lead.account ?? '') ?? 5;
      final postalCode = int.tryParse(lead.postalCode ?? '') ?? 0;

      print('🔄 Parsed Values:');
      print('  User ID (Creator): $userId');
      print('  Account: $account');
      print('  Postal Code: $postalCode');

      // Call API to create lead
      final response = await _apiService.createLead(
        userId: userId,
        title: lead.title ?? 'No Title',
        account: account,
        name: lead.name,
        email: lead.email,
        leadPostalcode: postalCode,
        opportunityAmount: lead.opportunityAmount ?? 0.0,
        status: _getStatusValue(lead.status),
        source: _getSourceValue(lead.source),
        phone: lead.phone,
        website: lead.website ?? '',
        leadCountry: lead.country ?? 'India',
        leadState: lead.state ?? '',
        leadCity: lead.city ?? '',
        leadAddress: lead.address ?? '',
        campaign: lead.campaign?.trim().isNotEmpty == true
            ? lead.campaign!.trim()
            : 'Not Specified',
        industry: lead.industry,
        description: lead.description?.trim().isNotEmpty == true
            ? lead.description!.trim()
            : 'No description provided',
      );

      print('\n✅ CREATE LEAD - API Response received');
      print('Response Status: ${response['status']}');
      print('Response Message: ${response['message']}');
      print('Response contains lead data: ${response['lead'] != null}');

      // If API call is successful, create lead object from response
      if (response['status'] == 'success' && response['lead'] != null) {
        final leadData = response['lead'];
        print('\n✅ CREATE LEAD - Parsing lead data...');
        print('Lead ID from API: ${leadData['id']}');

        // Parse dates safely
        DateTime? createdAt;
        DateTime? updatedAt;
        try {
          if (leadData['created_at'] != null) {
            createdAt = DateTime.parse(leadData['created_at'].toString());
          }
        } catch (e) {
          print('⚠️ Error parsing created_at: $e');
          createdAt = DateTime.now();
        }
        try {
          if (leadData['updated_at'] != null) {
            updatedAt = DateTime.parse(leadData['updated_at'].toString());
          }
        } catch (e) {
          print('⚠️ Error parsing updated_at: $e');
          updatedAt = DateTime.now();
        }

        final newLead = Lead(
          id: leadData['id']?.toString() ?? '',
          name: leadData['name']?.toString() ?? '',
          email: leadData['email']?.toString() ?? '',
          phone: leadData['phone']?.toString() ?? '',
          title: leadData['title']?.toString(),
          account: leadData['account']?.toString(),
          website: leadData['website']?.toString(),
          address: leadData['lead_address']?.toString(),
          city: leadData['lead_city']?.toString(),
          state: leadData['lead_state']?.toString(),
          postalCode: leadData['lead_postalcode']?.toString(),
          country: leadData['lead_country']?.toString(),
          status: LeadStatus.fromApiString(
            leadData['status_name']?.toString() ?? 'New',
          ),
          source: LeadSource.fromApiString(
            leadData['source_name']?.toString() ?? 'Cold Calling',
          ),
          opportunityAmount: leadData['opportunity_amount']?.toDouble(),
          campaign: leadData['campaign']?.toString(),
          industry: leadData['industry']?.toString() ?? 'Sales',
          assignedUser: leadData['created_by']?.toString(),
          description: leadData['description']?.toString(),
          createdAt: createdAt ?? DateTime.now(),
          updatedAt: updatedAt ?? DateTime.now(),
        );

        _leads.add(newLead);
        await _saveLeads();

        print('✅ CREATE LEAD - Success! Lead added to local storage');
        _error = null; // Clear any previous errors
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('\n❌ CREATE LEAD - API response not successful');
        throw Exception(response['message'] ?? 'Failed to create lead');
      }
    } catch (e, stackTrace) {
      print('\n❌ CREATE LEAD - ERROR OCCURRED:');
      print('Error: $e');
      print('Stack Trace: $stackTrace');
      _error = 'Failed to create lead: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Helper method to convert LeadStatus to API value
  int _getStatusValue(LeadStatus status) {
    // Map status to API values (0-5)
    switch (status) {
      case LeadStatus.newLead:
        return 0;
      case LeadStatus.assigned:
        return 1;
      case LeadStatus.inProcess:
        return 2;
      case LeadStatus.converted:
        return 3;
      case LeadStatus.recycled:
        return 4;
      case LeadStatus.dead:
        return 5;
      default:
        return 0;
    }
  }

  // Helper method to convert LeadSource to API value
  int _getSourceValue(LeadSource source) {
    // Map source to API values (assuming 1-5 or similar)
    // You may need to adjust these values based on your API
    switch (source) {
      case LeadSource.coldCalling:
        return 1;
      case LeadSource.referral:
        return 2;
      case LeadSource.contact:
        return 3;
      case LeadSource.blueprint:
        return 4;
      case LeadSource.partner:
        return 5;
      default:
        return 1;
    }
  }

  // Update lead
  Future<bool> updateLead(
    Lead updatedLead, {
    NotificationProvider? notificationProvider,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final index = _leads.indexWhere((lead) => lead.id == updatedLead.id);
      if (index != -1) {
        final oldLead = _leads[index];
        final oldStatus = oldLead.status;
        final newStatus = updatedLead.status;

        _leads[index] = updatedLead;
        await _saveLeads();

        // Check if lead was completed (converted or closedWon)
        final isCompleted =
            (newStatus == LeadStatus.converted ||
            newStatus == LeadStatus.closedWon);
        final wasNotCompleted =
            (oldStatus != LeadStatus.converted &&
            oldStatus != LeadStatus.closedWon);

        if (isCompleted && wasNotCompleted) {
          // Trigger notification for lead completion
          final provider = notificationProvider ?? _notificationProvider;
          if (provider != null) {
            await provider.addNotification(
              title: 'Lead Completed',
              message:
                  'Lead "${updatedLead.name}" has been marked as ${newStatus.displayName}',
              type: NotificationType.lead,
            );
          }
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update lead: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete lead
  Future<bool> deleteLead(String leadId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _leads.removeWhere((lead) => lead.id == leadId);
      await _saveLeads();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete lead: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get lead by ID
  Lead? getLeadById(String leadId) {
    try {
      return _leads.firstWhere((lead) => lead.id == leadId);
    } catch (e) {
      return null;
    }
  }

  // Filter leads by status
  List<Lead> getLeadsByStatus(LeadStatus status) {
    return _leads.where((lead) => lead.status == status).toList();
  }

  // Filter leads by source
  List<Lead> getLeadsBySource(LeadSource source) {
    return _leads.where((lead) => lead.source == source).toList();
  }

  // Search leads
  List<Lead> searchLeads(String query) {
    if (query.isEmpty) return _leads;

    final lowercaseQuery = query.toLowerCase();
    return _leads.where((lead) {
      return lead.name.toLowerCase().contains(lowercaseQuery) ||
          lead.email.toLowerCase().contains(lowercaseQuery) ||
          lead.phone.toLowerCase().contains(lowercaseQuery) ||
          (lead.title?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (lead.company?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Get leads statistics
  Map<String, int> getLeadsStatistics() {
    final stats = <String, int>{};

    for (final status in LeadStatus.values) {
      stats[status.displayName] = getLeadsByStatus(status).length;
    }

    return stats;
  }

  // Clear all leads
  Future<void> clearAllLeads() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _leads.clear();
      await _saveLeads();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear leads: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh leads
  Future<void> refreshLeads() async {
    await fetchLeadsFromAPI();
  }
}
