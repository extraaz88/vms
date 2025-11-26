import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/lead_model.dart';

class LeadDropdownService {
  static final ApiService _apiService = ApiService();

  // Cache for lead status list
  static List<String>? _cachedStatusList;

  // Cache for lead source map
  static Map<String, String>? _cachedSourceMap;

  // Get Lead Status List from API
  static Future<List<String>> getLeadStatusList() async {
    try {
      if (kDebugMode) {
        developer.log(
          '\n🔄 LEAD DROPDOWN SERVICE: Fetching lead status list...',
          name: 'LeadDropdownService.Status',
          level: 800,
        );
      }

      // Use cached data if available
      if (_cachedStatusList != null) {
        if (kDebugMode) {
          developer.log(
            '📋 Using cached status list: $_cachedStatusList',
            name: 'LeadDropdownService.Status',
            level: 800,
          );
        }
        return _cachedStatusList!;
      }

      // Fetch from API
      final statusList = await _apiService.getLeadStatusList();

      // Cache the result
      _cachedStatusList = statusList;

      if (kDebugMode) {
        developer.log(
          '\n✅ LEAD DROPDOWN SERVICE: Status list fetched successfully',
          name: 'LeadDropdownService.Status',
          level: 800,
        );
        developer.log(
          'Status List: $statusList',
          name: 'LeadDropdownService.Status',
          level: 800,
        );
      }

      return statusList;
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          '\n❌ LEAD DROPDOWN SERVICE: Failed to fetch status list',
          name: 'LeadDropdownService.Status',
          level: 800,
        );
        developer.log(
          'Error: $e',
          name: 'LeadDropdownService.Status',
          level: 800,
        );
      }

      // Return fallback data if API fails
      return ['New', 'Assigned', 'In Process', 'Converted', 'Recycled', 'Dead'];
    }
  }

  // Get Lead Source Map from API
  // Endpoint: /lead/source/{created_by}
  static Future<Map<String, String>> getLeadSourceMap(String createdBy) async {
    try {
      if (kDebugMode) {
        developer.log(
          '\n🔄 LEAD DROPDOWN SERVICE: Fetching lead source map for created_by: $createdBy...',
          name: 'LeadDropdownService.Source',
          level: 800,
        );
      }

      // Always fetch fresh data from API (don't use cache)
      // This ensures we get the latest source values from the API
      final sourceMap = await _apiService.getLeadSourceList(createdBy);

      // Update cache with fresh data
      _cachedSourceMap = sourceMap;

      if (kDebugMode) {
        developer.log(
          '\n✅ LEAD DROPDOWN SERVICE: Source map fetched successfully',
          name: 'LeadDropdownService.Source',
          level: 800,
        );
        developer.log(
          'Source Map: $sourceMap',
          name: 'LeadDropdownService.Source',
          level: 800,
        );
        developer.log(
          'Source Values: ${sourceMap.values.toList()}',
          name: 'LeadDropdownService.Source',
          level: 800,
        );
      }

      return sourceMap;
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          '\n❌ LEAD DROPDOWN SERVICE: Failed to fetch source map',
          name: 'LeadDropdownService.Source',
          level: 800,
        );
        developer.log(
          'Error: $e',
          name: 'LeadDropdownService.Source',
          level: 800,
        );
      }

      // Return fallback data if API fails
      return {
        "1": "Website",
        "2": "Social media",
        "3": "Google",
        "4": "Refferal",
        "5": "partner",
        "8": "Other",
      };
    }
  }

  // Clear cache
  static void clearCache() {
    _cachedStatusList = null;
    _cachedSourceMap = null;

    if (kDebugMode) {
      developer.log(
        '🗑️ LEAD DROPDOWN SERVICE: Cache cleared',
        name: 'LeadDropdownService.Cache',
        level: 800,
      );
    }
  }

  // Convert API status string to LeadStatus enum
  static LeadStatus getStatusFromApiString(String apiValue) {
    return LeadStatus.fromApiString(apiValue);
  }

  // Convert API source string to LeadSource enum
  static LeadSource getSourceFromApiString(String apiValue) {
    return LeadSource.fromApiString(apiValue);
  }
}
