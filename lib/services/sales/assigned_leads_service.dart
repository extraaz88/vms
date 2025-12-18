import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:vms/models/lead_model.dart';
import 'package:vms/services/api_service.dart';


class AssignedLeadsService {
  static final ApiService _apiService = ApiService();

  // Cache for assigned leads
  static List<Lead>? _cachedAssignedLeads;
  static String? _cachedUserId;

  // Get Assigned Leads from API
  static Future<List<Lead>> getAssignedLeads(String userId) async {
    try {
      if (kDebugMode) {
        developer.log(
          '\n🔄 ASSIGNED LEADS SERVICE: Fetching assigned leads for user: $userId...',
          name: 'AssignedLeadsService',
          level: 800,
        );
      }

      // Use cached data if available and for the same user
      if (_cachedAssignedLeads != null && _cachedUserId == userId) {
        if (kDebugMode) {
          developer.log(
            '📋 Using cached assigned leads (${_cachedAssignedLeads!.length} leads)',
            name: 'AssignedLeadsService',
            level: 800,
          );
        }
        return _cachedAssignedLeads!;
      }

      // Fetch from API
      final assignedLeadsData = await _apiService.getAssignedLeads(userId);

      if (kDebugMode) {
        developer.log(
          'Raw API response: ${assignedLeadsData.length} items',
          name: 'AssignedLeadsService',
          level: 800,
        );
      }

      // Convert API data to Lead objects
      final assignedLeads = <Lead>[];
      for (int i = 0; i < assignedLeadsData.length; i++) {
        try {
          final leadData = assignedLeadsData[i];
          final lead = _convertApiDataToLead(leadData);
          assignedLeads.add(lead);

          if (kDebugMode && i == 0) {
            developer.log(
              'First lead converted: ${lead.name} - ${lead.email}',
              name: 'AssignedLeadsService',
              level: 800,
            );
          }
        } catch (e) {
          if (kDebugMode) {
            developer.log(
              'Failed to convert lead at index $i: $e',
              name: 'AssignedLeadsService',
              level: 1000,
            );
          }
        }
      }

      // Cache the result
      _cachedAssignedLeads = assignedLeads;
      _cachedUserId = userId;

      if (kDebugMode) {
        developer.log(
          '\n✅ ASSIGNED LEADS SERVICE: Fetched successfully',
          name: 'AssignedLeadsService',
          level: 800,
        );
        developer.log(
          'Assigned Leads Count: ${assignedLeads.length}',
          name: 'AssignedLeadsService',
          level: 800,
        );
        if (assignedLeads.isNotEmpty) {
          developer.log(
            'Sample Lead: ${assignedLeads.first.name} (${assignedLeads.first.email})',
            name: 'AssignedLeadsService',
            level: 800,
          );
          developer.log(
            'All Leads: ${assignedLeads.map((l) => '${l.name} (${l.id})').join(', ')}',
            name: 'AssignedLeadsService',
            level: 800,
          );
        }
      }

      return assignedLeads;
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          '\n❌ ASSIGNED LEADS SERVICE: Failed to fetch assigned leads',
          name: 'AssignedLeadsService',
          level: 800,
        );
        developer.log('Error: $e', name: 'AssignedLeadsService', level: 800);
      }

      // Return empty list if API fails
      return [];
    }
  }

  // Convert API data to Lead model
  static Lead _convertApiDataToLead(Map<String, dynamic> data) {
    return Lead(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      company: data['company']?.toString() ?? data['account']?.toString(),
      industry: data['industry']?.toString() ?? '',
      status: _parseLeadStatus(data['status']),
      source: _parseLeadSource(data['source']),
      opportunityAmount: _parseDouble(data['opportunity_amount']),
      assignedUser:
          data['assigned_to']?.toString() ?? data['assigned_user']?.toString(),
      createdAt: _parseDateTime(data['created_at']),
      updatedAt: _parseDateTime(data['updated_at']),
      description: data['notes']?.toString() ?? data['description']?.toString(),
      address: data['lead_address']?.toString() ?? data['address']?.toString(),
      city: data['lead_city']?.toString() ?? data['city']?.toString(),
      state: data['lead_state']?.toString() ?? data['state']?.toString(),
      country: data['lead_country']?.toString() ?? data['country']?.toString(),
      postalCode:
          data['lead_postalcode']?.toString() ??
          data['postal_code']?.toString(),
    );
  }

  // Parse LeadStatus from API data
  static LeadStatus _parseLeadStatus(dynamic status) {
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
  static LeadSource _parseLeadSource(dynamic source) {
    if (source == null) return LeadSource.other;

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

    return LeadSource.other;
  }

  // Parse double from dynamic value
  static double? _parseDouble(dynamic value) {
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
  static DateTime _parseDateTime(dynamic value) {
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

  // Clear cache
  static void clearCache() {
    _cachedAssignedLeads = null;
    _cachedUserId = null;

    if (kDebugMode) {
      developer.log(
        '🗑️ ASSIGNED LEADS SERVICE: Cache cleared',
        name: 'AssignedLeadsService.Cache',
        level: 800,
      );
    }
  }

  // Refresh assigned leads (clear cache and fetch new data)
  static Future<List<Lead>> refreshAssignedLeads(String userId) async {
    clearCache();
    return getAssignedLeads(userId);
  }
}
