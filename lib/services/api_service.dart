import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/visit_model.dart';
import '../models/location_model.dart';
import '../models/checkin_checkout_history_model.dart';
import '../utils/auth_helper.dart';
import 'mock_data_service.dart';

class ApiService {
  static const String baseUrl = 'https://crm.bharatbill.live/api';
  String? _authToken = '26d9vCKPrU8725q0Iuf3Z9BaWWR6sYM1n1QehMpwf5107d83';
  static bool _useMockData = false; // Set to false to use real API
  bool _isDeveloper = false; // Track if current user is a developer

  // Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Clear authentication token
  void clearAuthToken() {
    _authToken = null;
    _isDeveloper = false; // Reset developer status
  }

  // Set developer status
  void setDeveloperStatus(bool isDeveloper) {
    _isDeveloper = isDeveloper;
  }

  // Get headers with authentication
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // Log API request details
  void _logRequest(
    String method,
    String url,
    Map<String, String> headers,
    String body,
  ) {
    // Skip logging if user is a developer
    if (_isDeveloper) return;
    
    developer.log('\n📤 API REQUEST', name: 'ApiService.Request', level: 700);
    developer.log(
      '═══════════════════════════════════════',
      name: 'ApiService.Request',
      level: 700,
    );
    developer.log('Method: $method', name: 'ApiService.Request', level: 700);
    developer.log('URL: $url', name: 'ApiService.Request', level: 700);
    developer.log('Headers:', name: 'ApiService.Request', level: 700);
    headers.forEach((key, value) {
      if (key.toLowerCase() == 'authorization') {
        developer.log(
          '  $key: Bearer ${value.substring(7, 17)}...',
          name: 'ApiService.Request',
          level: 700,
        );
      } else {
        developer.log('  $key: $value', name: 'ApiService.Request', level: 700);
      }
    });
    developer.log('Body:', name: 'ApiService.Request', level: 700);
    try {
      final formattedBody = JsonEncoder.withIndent(
        '  ',
      ).convert(json.decode(body));
      developer.log(formattedBody, name: 'ApiService.Request', level: 700);
    } catch (e) {
      developer.log('  $body', name: 'ApiService.Request', level: 700);
    }
    developer.log(
      '═══════════════════════════════════════',
      name: 'ApiService.Request',
      level: 700,
    );
  }

  // Log multipart request details
  void _logMultipartRequest(http.MultipartRequest request) {
    // Skip logging if user is a developer
    if (_isDeveloper) return;
    
    developer.log(
      '\n📤 API REQUEST (MULTIPART)',
      name: 'ApiService.Request',
      level: 700,
    );
    developer.log(
      '═══════════════════════════════════════',
      name: 'ApiService.Request',
      level: 700,
    );
    developer.log(
      'Method: ${request.method}',
      name: 'ApiService.Request',
      level: 700,
    );
    developer.log(
      'URL: ${request.url}',
      name: 'ApiService.Request',
      level: 700,
    );
    developer.log('Headers:', name: 'ApiService.Request', level: 700);
    request.headers.forEach((key, value) {
      if (key.toLowerCase() == 'authorization') {
        developer.log(
          '  $key: Bearer ${value.substring(7, 17)}...',
          name: 'ApiService.Request',
          level: 700,
        );
      } else {
        developer.log('  $key: $value', name: 'ApiService.Request', level: 700);
      }
    });
    developer.log('Fields:', name: 'ApiService.Request', level: 700);
    request.fields.forEach((key, value) {
      developer.log('  $key: $value', name: 'ApiService.Request', level: 700);
    });
    developer.log('Files:', name: 'ApiService.Request', level: 700);
    for (var file in request.files) {
      developer.log(
        '  ${file.field}: ${file.filename} (${file.length} bytes)',
        name: 'ApiService.Request',
        level: 700,
      );
    }
    developer.log(
      '═══════════════════════════════════════',
      name: 'ApiService.Request',
      level: 700,
    );
  }

  // Log API response details
  void _logResponse(http.Response response) {
    // Skip logging if user is a developer
    if (_isDeveloper) return;
    
    developer.log('\n📥 API RESPONSE', name: 'ApiService.Response', level: 700);
    developer.log(
      '═══════════════════════════════════════',
      name: 'ApiService.Response',
      level: 700,
    );
    developer.log(
      'Status Code: ${response.statusCode}',
      name: 'ApiService.Response',
      level: 700,
    );
    developer.log('Headers:', name: 'ApiService.Response', level: 700);
    response.headers.forEach((key, value) {
      developer.log('  $key: $value', name: 'ApiService.Response', level: 700);
    });
    developer.log('Body:', name: 'ApiService.Response', level: 700);
    try {
      final formattedBody = JsonEncoder.withIndent(
        '  ',
      ).convert(json.decode(response.body));
      developer.log(formattedBody, name: 'ApiService.Response', level: 700);
    } catch (e) {
      developer.log(
        '  ${response.body}',
        name: 'ApiService.Response',
        level: 700,
      );
    }
    developer.log(
      '═══════════════════════════════════════',
      name: 'ApiService.Response',
      level: 700,
    );
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    _logResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  // Handle API response that can be either Map or List
  dynamic _handleResponseFlexible(http.Response response) {
    _logResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  // Authentication APIs

  // Login - Real API implementation
  Future<Map<String, dynamic>> login(String email, String password) async {
    final requestBody = {'email': email, 'password': password};

    final headers = _getHeaders();
    final body = json.encode(requestBody);

    _logRequest('POST', '$baseUrl/sign-in', headers, body);

    final response = await http.post(
      Uri.parse('$baseUrl/sign-in'),
      headers: headers,
      body: body,
    );

    final responseData = _handleResponse(response);

    // Extract and store token if available
    if (responseData['token'] != null) {
      _authToken = responseData['token'];
      if (kDebugMode) {
        developer.log(
          '\n🔑 TOKEN RECEIVED:',
          name: 'ApiService.Auth',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.Auth',
          level: 800,
        );
        developer.log(
          'Token: ${responseData['token']}',
          name: 'ApiService.Auth',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.Auth',
          level: 800,
        );
      }
    }

    return responseData;
  }

  // Update Profile - Always use mock data
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> userData,
  ) async {
    return {
      'status': 'success',
      'message': 'Profile updated successfully',
      'user': userData,
    };
  }

  // Lead APIs

  // Get Lead Status List - Real API implementation
  Future<List<String>> getLeadStatusList() async {
    final headers = _getHeaders();
    final url = '$baseUrl/lead/status';

    developer.log(
      '\n🔍 FETCHING LEAD STATUS LIST:',
      name: 'ApiService.LeadStatus',
      level: 800,
    );
    developer.log('URL: $url', name: 'ApiService.LeadStatus', level: 800);
    developer.log(
      'Bearer Token: ${_authToken?.substring(0, 20)}...',
      name: 'ApiService.LeadStatus',
      level: 800,
    );

    _logRequest('GET', url, headers, '');

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      developer.log(
        '\n📥 LEAD STATUS API RESPONSE:',
        name: 'ApiService.LeadStatus',
        level: 800,
      );
      developer.log(
        'Status Code: ${response.statusCode}',
        name: 'ApiService.LeadStatus',
        level: 800,
      );
      developer.log(
        'Response Body: ${response.body}',
        name: 'ApiService.LeadStatus',
        level: 800,
      );

      // Log the response for debugging
      _logResponse(response);

      // Check if request was successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Decode JSON directly - expecting a List, not a Map
        final responseData = json.decode(response.body);

        developer.log(
          'Response Data Type: ${responseData.runtimeType}',
          name: 'ApiService.LeadStatus',
          level: 800,
        );

        if (responseData is List) {
          final statusList = List<String>.from(responseData);
          developer.log(
            '\n✅ LEAD STATUS API SUCCESS:',
            name: 'ApiService.LeadStatus',
            level: 800,
          );
          developer.log(
            '═══════════════════════════════════════',
            name: 'ApiService.LeadStatus',
            level: 800,
          );
          developer.log(
            'Status Count: ${statusList.length}',
            name: 'ApiService.LeadStatus',
            level: 800,
          );
          developer.log(
            'Status List: $statusList',
            name: 'ApiService.LeadStatus',
            level: 800,
          );
          developer.log(
            '═══════════════════════════════════════',
            name: 'ApiService.LeadStatus',
            level: 800,
          );
          return statusList;
        } else {
          developer.log(
            '❌ Invalid response format: ${responseData.runtimeType}',
            name: 'ApiService.LeadStatus',
            level: 1000,
          );
          throw Exception(
            'Invalid response format for lead status. Expected List but got ${responseData.runtimeType}',
          );
        }
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      developer.log(
        '\n❌ LEAD STATUS API ERROR:',
        name: 'ApiService.LeadStatus',
        level: 1000,
      );
      developer.log('Error: $e', name: 'ApiService.LeadStatus', level: 1000);
      developer.log(
        'Stack Trace: $stackTrace',
        name: 'ApiService.LeadStatus',
        level: 1000,
      );
      rethrow;
    }
  }

  // Get Lead Source List - Real API implementation
  // Endpoint: /lead/source/{created_by}
  // created_by is the logged-in user's ID
  Future<Map<String, String>> getLeadSourceList(String createdBy) async {
    final headers = _getHeaders();
    final url = '$baseUrl/lead/source/$createdBy';

    developer.log(
      '\n🔍 FETCHING LEAD SOURCE LIST:',
      name: 'ApiService.LeadSource',
      level: 800,
    );
    developer.log('URL: $url', name: 'ApiService.LeadSource', level: 800);
    developer.log(
      'Created By (User ID): $createdBy',
      name: 'ApiService.LeadSource',
      level: 800,
    );
    developer.log(
      'Bearer Token: ${_authToken?.substring(0, 20)}...',
      name: 'ApiService.LeadSource',
      level: 800,
    );

    _logRequest('GET', url, headers, '');

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      developer.log(
        '\n📥 LEAD SOURCE API RESPONSE:',
        name: 'ApiService.LeadSource',
        level: 800,
      );
      developer.log(
        'Status Code: ${response.statusCode}',
        name: 'ApiService.LeadSource',
        level: 800,
      );
      developer.log(
        'Response Body: ${response.body}',
        name: 'ApiService.LeadSource',
        level: 800,
      );

      // Log the response for debugging
      _logResponse(response);

      // Check if request was successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Decode JSON directly - expecting a Map
        final responseData = json.decode(response.body);

        developer.log(
          'Response Data Type: ${responseData.runtimeType}',
          name: 'ApiService.LeadSource',
          level: 800,
        );

        if (responseData is Map) {
          final sourceMap = Map<String, String>.from(responseData);

          developer.log(
            '\n✅ LEAD SOURCE API SUCCESS:',
            name: 'ApiService.LeadSource',
            level: 800,
          );
          developer.log(
            '═══════════════════════════════════════',
            name: 'ApiService.LeadSource',
            level: 800,
          );
          developer.log(
            'Source Count: ${sourceMap.length}',
            name: 'ApiService.LeadSource',
            level: 800,
          );
          developer.log(
            'Source Map: $sourceMap',
            name: 'ApiService.LeadSource',
            level: 800,
          );
          developer.log(
            '═══════════════════════════════════════',
            name: 'ApiService.LeadSource',
            level: 800,
          );
          return sourceMap;
        } else {
          developer.log(
            '❌ Invalid response format: ${responseData.runtimeType}',
            name: 'ApiService.LeadSource',
            level: 1000,
          );
          throw Exception(
            'Invalid response format for lead source. Expected Map but got ${responseData.runtimeType}',
          );
        }
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      developer.log(
        '\n❌ LEAD SOURCE API ERROR:',
        name: 'ApiService.LeadSource',
        level: 1000,
      );
      developer.log('Error: $e', name: 'ApiService.LeadSource', level: 1000);
      developer.log(
        'Stack Trace: $stackTrace',
        name: 'ApiService.LeadSource',
        level: 1000,
      );
      rethrow;
    }
  }

  // Get Assigned Leads for User - Real API implementation
  Future<List<Map<String, dynamic>>> getAssignedLeads(String userId) async {
    final headers = _getHeaders();
    final url = '$baseUrl/assignlead/$userId';

    developer.log(
      '\n🔍 FETCHING ASSIGNED LEADS:',
      name: 'ApiService.AssignedLeads',
      level: 800,
    );
    developer.log('URL: $url', name: 'ApiService.AssignedLeads', level: 800);
    developer.log(
      'User ID: $userId',
      name: 'ApiService.AssignedLeads',
      level: 800,
    );
    developer.log(
      'Bearer Token: ${_authToken?.substring(0, 20)}...',
      name: 'ApiService.AssignedLeads',
      level: 800,
    );

    _logRequest('GET', url, headers, '');

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      developer.log(
        '\n📥 ASSIGNED LEADS API RESPONSE:',
        name: 'ApiService.AssignedLeads',
        level: 800,
      );
      developer.log(
        'Status Code: ${response.statusCode}',
        name: 'ApiService.AssignedLeads',
        level: 800,
      );
      developer.log(
        'Response Body: ${response.body}',
        name: 'ApiService.AssignedLeads',
        level: 800,
      );

      // Log the response for debugging
      _logResponse(response);

      // Check if request was successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Decode JSON
        final responseData = json.decode(response.body);

        developer.log(
          'Response Data Type: ${responseData.runtimeType}',
          name: 'ApiService.AssignedLeads',
          level: 800,
        );

        // Handle both List and Map responses
        List<Map<String, dynamic>> assignedLeads = [];

        if (responseData is List) {
          // Direct list of leads
          assignedLeads = List<Map<String, dynamic>>.from(responseData);
        } else if (responseData is Map) {
          // Check if response has 'data' field
          if (responseData['data'] != null && responseData['data'] is List) {
            assignedLeads = List<Map<String, dynamic>>.from(
              responseData['data'],
            );
          } else if (responseData['leads'] != null &&
              responseData['leads'] is List) {
            assignedLeads = List<Map<String, dynamic>>.from(
              responseData['leads'],
            );
          } else {
            // Handle Map format where key=id, value=name
            // Example: {"29": "ok", "33": "kok", "34": "Raj"}
            developer.log(
              'Detected Map format (key=id, value=name)',
              name: 'ApiService.AssignedLeads',
              level: 800,
            );

            final mapData = Map<String, dynamic>.from(responseData);
            assignedLeads = mapData.entries.map((entry) {
              return {
                'id': entry.key,
                'name': entry.value.toString(),
                // Add minimal required fields with defaults
                'email':
                    '${entry.value.toString().toLowerCase().replaceAll(' ', '')}@example.com',
                'phone': '0000000000',
                'industry': 'Sales',
              };
            }).toList();

            developer.log(
              'Converted ${assignedLeads.length} leads from Map format',
              name: 'ApiService.AssignedLeads',
              level: 800,
            );
          }
        }

        developer.log(
          '\n✅ ASSIGNED LEADS API SUCCESS:',
          name: 'ApiService.AssignedLeads',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.AssignedLeads',
          level: 800,
        );
        developer.log(
          'Assigned Leads Count: ${assignedLeads.length}',
          name: 'ApiService.AssignedLeads',
          level: 800,
        );
        developer.log(
          'Assigned Leads: $assignedLeads',
          name: 'ApiService.AssignedLeads',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.AssignedLeads',
          level: 800,
        );
        return assignedLeads;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      developer.log(
        '\n❌ ASSIGNED LEADS API ERROR:',
        name: 'ApiService.AssignedLeads',
        level: 1000,
      );
      developer.log('Error: $e', name: 'ApiService.AssignedLeads', level: 1000);
      developer.log(
        'Stack Trace: $stackTrace',
        name: 'ApiService.AssignedLeads',
        level: 1000,
      );
      rethrow;
    }
  }

  // Get All Leads for User - Real API implementation
  // Endpoint: /lead/{created_by}
  Future<List<Map<String, dynamic>>> getUserLeads(String userId) async {
    final headers = _getHeaders();
    // Using created_by as the path parameter (same as userId)
    final url = '$baseUrl/lead/$userId';

    developer.log(
      '\n🔍 FETCHING USER LEADS:',
      name: 'ApiService.UserLeads',
      level: 800,
    );
    developer.log('URL: $url', name: 'ApiService.UserLeads', level: 800);
    developer.log('Created By (User ID): $userId', name: 'ApiService.UserLeads', level: 800);
    developer.log(
      'Bearer Token: ${_authToken?.substring(0, 20)}...',
      name: 'ApiService.UserLeads',
      level: 800,
    );

    _logRequest('GET', url, headers, '');

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      developer.log(
        '\n📥 USER LEADS API RESPONSE:',
        name: 'ApiService.UserLeads',
        level: 800,
      );
      developer.log(
        'Status Code: ${response.statusCode}',
        name: 'ApiService.UserLeads',
        level: 800,
      );
      developer.log(
        'Response Body: ${response.body}',
        name: 'ApiService.UserLeads',
        level: 800,
      );

      // Log the response for debugging
      _logResponse(response);

      // Check if request was successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Decode JSON
        final responseData = json.decode(response.body);

        developer.log(
          'Response Data Type: ${responseData.runtimeType}',
          name: 'ApiService.UserLeads',
          level: 800,
        );

        // Handle both List and Map responses
        List<Map<String, dynamic>> userLeads = [];

        if (responseData is List) {
          // Direct list of leads
          userLeads = List<Map<String, dynamic>>.from(responseData);
        } else if (responseData is Map) {
          // Check if response has 'data' field
          if (responseData['data'] != null && responseData['data'] is List) {
            userLeads = List<Map<String, dynamic>>.from(responseData['data']);
          } else if (responseData['leads'] != null &&
              responseData['leads'] is List) {
            userLeads = List<Map<String, dynamic>>.from(responseData['leads']);
          } else {
            // If it's a single lead, wrap it in a list
            userLeads = [Map<String, dynamic>.from(responseData)];
          }
        }

        developer.log(
          '\n✅ USER LEADS API SUCCESS:',
          name: 'ApiService.UserLeads',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.UserLeads',
          level: 800,
        );
        developer.log(
          'User Leads Count: ${userLeads.length}',
          name: 'ApiService.UserLeads',
          level: 800,
        );
        developer.log(
          'User Leads: $userLeads',
          name: 'ApiService.UserLeads',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.UserLeads',
          level: 800,
        );
        return userLeads;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      developer.log(
        '\n❌ USER LEADS API ERROR:',
        name: 'ApiService.UserLeads',
        level: 1000,
      );
      developer.log('Error: $e', name: 'ApiService.UserLeads', level: 1000);
      developer.log(
        'Stack Trace: $stackTrace',
        name: 'ApiService.UserLeads',
        level: 1000,
      );
      rethrow;
    }
  }

  // Create New Lead - Real API implementation
  Future<Map<String, dynamic>> createLead({
    required int userId,
    required String title,
    required int account,
    required String name,
    required String email,
    required int leadPostalcode,
    required double opportunityAmount,
    required int status,
    required int source,
    required String phone,
    required String website,
    required String leadCountry,
    required String leadState,
    required String leadCity,
    required String leadAddress,
    required String campaign,
    required String industry,
    required String description,
  }) async {
    final requestBody = {
      'user_id': userId,
      'title': title,
      'account': account,
      'name': name,
      'email': email,
      'lead_postalcode': leadPostalcode,
      'opportunity_amount': opportunityAmount,
      'status': status,
      'source': source,
      'phone': phone,
      'website': website,
      'lead_country': leadCountry,
      'lead_state': leadState,
      'lead_city': leadCity,
      'lead_address': leadAddress,
      'campaign': campaign,
      'industry': industry,
      'description': description,
    };

    final headers = _getHeaders();
    final body = json.encode(requestBody);

    developer.log(
      '\n🔑 CREATE LEAD BEARER TOKEN:',
      name: 'ApiService.CreateLead',
      level: 800,
    );
    developer.log(
      '═══════════════════════════════════════',
      name: 'ApiService.CreateLead',
      level: 800,
    );
    developer.log(
      'Bearer Token: $_authToken',
      name: 'ApiService.CreateLead',
      level: 800,
    );
    developer.log(
      '═══════════════════════════════════════',
      name: 'ApiService.CreateLead',
      level: 800,
    );

    _logRequest('POST', '$baseUrl/lead', headers, body);

    final response = await http.post(
      Uri.parse('$baseUrl/lead'),
      headers: headers,
      body: body,
    );

    final responseData = _handleResponse(response);

    developer.log(
      '\n✅ LEAD CREATED SUCCESSFULLY:',
      name: 'ApiService.CreateLead',
      level: 800,
    );
    developer.log(
      '═══════════════════════════════════════',
      name: 'ApiService.CreateLead',
      level: 800,
    );
    developer.log(
      'Status: ${responseData['status']}',
      name: 'ApiService.CreateLead',
      level: 800,
    );
    developer.log(
      'Message: ${responseData['message']}',
      name: 'ApiService.CreateLead',
      level: 800,
    );
    developer.log(
      'Lead ID: ${responseData['lead']?['id']}',
      name: 'ApiService.CreateLead',
      level: 800,
    );
    developer.log(
      'Lead Name: ${responseData['lead']?['name']}',
      name: 'ApiService.CreateLead',
      level: 800,
    );
    developer.log(
      'Lead Email: ${responseData['lead']?['email']}',
      name: 'ApiService.CreateLead',
      level: 800,
    );
    developer.log(
      '═══════════════════════════════════════',
      name: 'ApiService.CreateLead',
      level: 800,
    );

    return responseData;
  }

  // Visit APIs

  // Create visit directly (without check-in/check-out) - Always use mock data
  Future<Map<String, dynamic>> createVisit({
    required double latitude,
    required double longitude,
    String? clientName,
    String? notes,
    String? visitingReason,
    String? visitingArea,
    String? photoPath,
  }) async {
    return await MockDataService.mockCreateVisit(
      latitude: latitude,
      longitude: longitude,
      clientName: clientName,
      notes: notes,
      visitingReason: visitingReason,
      visitingArea: visitingArea,
      photoPath: photoPath,
    );
  }

  // Create visit details with lead information
  Future<Map<String, dynamic>> createVisitDetails({
    required String visitingPlace,
    required String visitingPerson,
    required String visitingReason,
    String? visitingArea,
    String? photoPath,
    String? leadId,
    String? leadName,
    String? leadEmail,
    String? leadPhone,
    required double latitude,
    required double longitude,
    String? connectingTime,
    String? status,
  }) async {
    if (_useMockData) {
      return await MockDataService.mockCreateVisitDetails(
        visitingPlace: visitingPlace,
        visitingPerson: visitingPerson,
        visitingReason: visitingReason,
        visitingArea: visitingArea,
        photoPath: photoPath,
        leadId: leadId,
        leadName: leadName,
        leadEmail: leadEmail,
        leadPhone: leadPhone,
        latitude: latitude,
        longitude: longitude,
        connectingTime: connectingTime,
        status: status,
      );
    }

    // Get authenticated user ID
    final userId = await AuthHelper.getAuthenticatedUserId();

    if (kDebugMode) {
      developer.log(
        '🔑 Visit Details - Authenticated User ID: $userId',
        name: 'ApiService.VisitDetails',
        level: 800,
      );
    }

    // Create multipart request for form data
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/visits/details'),
    );

    // Add headers (excluding Content-Type as it will be set automatically for multipart)
    final headers = _getHeaders();
    headers.remove('Content-Type'); // Remove Content-Type for multipart
    request.headers.addAll(headers);

    // Add form fields
    request.fields['user_id'] = userId;
    request.fields['area_name'] = visitingArea ?? visitingPlace;
    request.fields['person_name'] = visitingPerson;
    request.fields['reason'] = visitingReason;
    request.fields['place_name'] = visitingPlace;
    request.fields['visiting_place'] = visitingPlace;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();

    // Add lead information if available
    if (leadId != null) request.fields['lead_id'] = leadId;
    if (leadName != null) request.fields['lead_name'] = leadName;
    if (leadEmail != null) request.fields['lead_email'] = leadEmail;
    if (leadPhone != null) request.fields['lead_phone'] = leadPhone;
    if (status != null && status.isNotEmpty) {
      request.fields['status'] = status;
    }
    if (connectingTime != null && connectingTime.isNotEmpty) {
      request.fields['connecting_time'] = connectingTime;
    }

    // Add photo file if available
    if (photoPath != null && photoPath.isNotEmpty) {
      final photoFile = File(photoPath);
      if (await photoFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', photoPath),
        );
      }
    }

    // Log the request
    _logMultipartRequest(request);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _logResponse(response);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          developer.log(
            '✅ Visit details created successfully',
            name: 'ApiService.CheckIn',
            level: 800,
          );
          developer.log(
            'Visit ID: ${responseData['visit_details']['id']}',
            name: 'ApiService.CheckIn',
            level: 800,
          );
        }
        return responseData;
      } else {
        throw Exception(
          'Failed to create visit details: ${responseData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          '❌ Error creating visit details: $e',
          name: 'ApiService.Error',
          level: 1000,
        );
      }
      rethrow;
    }
  }

  // Check-in
  Future<Map<String, dynamic>> checkIn({
    required int userId,
    required String userName,
    required double inLatitude,
    required double inLongitude,
    required String checkInTime,
    required double inAccuracy,
    required double inBatteryPercent,
    String? inNotes,
  }) async {
    if (_useMockData) {
      return await MockDataService.mockCheckIn(
        latitude: inLatitude,
        longitude: inLongitude,
        clientName: userName,
        notes: inNotes,
      );
    }

    final requestBody = {
      'user_id': userId,
      'user_name': userName,
      'in_latitude': inLatitude,
      'in_longitude': inLongitude,
      'check_in_time': checkInTime,
      'in_accuracy': inAccuracy,
      'in_battery_percent': inBatteryPercent,
      if (inNotes != null) 'in_notes': inNotes,
    };

    final headers = _getHeaders();
    final body = json.encode(requestBody);

    // Log bearer token for check-in
    if (kDebugMode) {
      developer.log(
        '\n🔑 CHECK-IN BEARER TOKEN:',
        name: 'ApiService.CheckIn',
        level: 800,
      );
      developer.log(
        '═══════════════════════════════════════',
        name: 'ApiService.CheckIn',
        level: 800,
      );
      developer.log(
        'Bearer Token: $_authToken',
        name: 'ApiService.CheckIn',
        level: 800,
      );
      developer.log(
        '═══════════════════════════════════════',
        name: 'ApiService.CheckIn',
        level: 800,
      );
    }

    _logRequest('POST', '$baseUrl/visits/checkin', headers, body);

    final response = await http.post(
      Uri.parse('$baseUrl/visits/checkin'),
      headers: headers,
      body: body,
    );

    final responseData = _handleResponse(response);

    // Extract and store token if available (check-in response also has token)
    if (responseData['token'] != null) {
      _authToken = responseData['token'];
      if (kDebugMode) {
        developer.log(
          '\n🔑 CHECK-IN TOKEN RECEIVED:',
          name: 'ApiService.CheckIn',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.CheckIn',
          level: 800,
        );
        developer.log(
          'Token: ${responseData['token']}',
          name: 'ApiService.CheckIn',
          level: 800,
        );
        developer.log(
          'Visit ID: ${responseData['visit']['id']}',
          name: 'ApiService.CheckIn',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.CheckIn',
          level: 800,
        );
      }
    }

    return responseData;
  }

  // Check-out - Real API implementation with working hours validation
  Future<Map<String, dynamic>> checkOut({
    required String visitId,
    required int userId,
    required double outLatitude,
    required double outLongitude,
    required String checkOutTime,
    required double outAccuracy,
    required double outBatteryPercent,
    String? outNotes,
    DateTime? checkInTime, // Add check-in time for working hours calculation
  }) async {
    // Calculate working hours if check-in time is provided
    Map<String, dynamic> workingHoursData = {};
    if (checkInTime != null) {
      final checkInDateTime = checkInTime;
      final checkOutDateTime = DateTime.parse(checkOutTime);
      final workingDuration = checkOutDateTime.difference(checkInDateTime);
      final workingHours = workingDuration.inMinutes / 60.0;
      
      // Determine if it's full day (>= 7 hours 48 minutes) or half day (< 7 hours 48 minutes)
      // 7 hours 48 minutes = 7.8 hours
      const double thresholdHours = 7.8; // 7 hours 48 minutes
      final isFullDay = workingHours >= thresholdHours;
      final isHalfDay = workingHours < thresholdHours;
      
      workingHoursData = {
        'working_hours': workingHours,
        'working_minutes': workingDuration.inMinutes,
        'is_full_day': isFullDay,
        'is_half_day': isHalfDay,
        'attendance_status': isFullDay ? 'full_day' : 'half_day',
      };

      if (kDebugMode) {
        developer.log(
          '\n⏰ WORKING HOURS CALCULATION:',
          name: 'ApiService.CheckOut',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.CheckOut',
          level: 800,
        );
        developer.log(
          'Check-in Time: ${checkInDateTime.toString()}',
          name: 'ApiService.CheckOut',
          level: 800,
        );
        developer.log(
          'Check-out Time: ${checkOutDateTime.toString()}',
          name: 'ApiService.CheckOut',
          level: 800,
        );
        developer.log(
          'Working Duration: ${workingDuration.inHours}h ${workingDuration.inMinutes % 60}m',
          name: 'ApiService.CheckOut',
          level: 800,
        );
        developer.log(
          'Working Hours: ${workingHours.toStringAsFixed(2)} hours',
          name: 'ApiService.CheckOut',
          level: 800,
        );
        developer.log(
          'Is Full Day: $isFullDay',
          name: 'ApiService.CheckOut',
          level: 800,
        );
        developer.log(
          'Is Half Day: $isHalfDay',
          name: 'ApiService.CheckOut',
          level: 800,
        );
        developer.log(
          'Attendance Status: ${workingHoursData['attendance_status']}',
          name: 'ApiService.CheckOut',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.CheckOut',
          level: 800,
        );
      }
    }

    final requestBody = {
      'user_id': userId,
      'out_latitude': outLatitude,
      'out_longitude': outLongitude,
      'check_out_time': checkOutTime,
      'out_accuracy': outAccuracy,
      'out_battery_percent': outBatteryPercent,
      if (outNotes != null) 'out_notes': outNotes,
      ...workingHoursData, // Include working hours data
    };

    final headers = _getHeaders();
    final body = json.encode(requestBody);

    // Log bearer token for check-out
    if (kDebugMode) {
      developer.log(
        '\n🔑 CHECK-OUT BEARER TOKEN:',
        name: 'ApiService.CheckOut',
        level: 800,
      );
      developer.log(
        '═══════════════════════════════════════',
        name: 'ApiService.CheckOut',
        level: 800,
      );
      developer.log(
        'Bearer Token: $_authToken',
        name: 'ApiService.CheckOut',
        level: 800,
      );
      developer.log(
        'Visit ID: $visitId',
        name: 'ApiService.CheckOut',
        level: 800,
      );
      developer.log(
        '═══════════════════════════════════════',
        name: 'ApiService.CheckOut',
        level: 800,
      );
    }

    _logRequest('POST', '$baseUrl/visits/checkout/$visitId', headers, body);

    final response = await http.post(
      Uri.parse('$baseUrl/visits/checkout/$visitId'),
      headers: headers,
      body: body,
    );

    final responseData = _handleResponse(response);

    // Add working hours data to response
    responseData['working_hours_data'] = workingHoursData;

    // Extract and store token if available (check-out response also has token)
    if (responseData['token'] != null) {
      _authToken = responseData['token'];
      if (kDebugMode) {
        developer.log(
          '\n🔑 CHECK-OUT TOKEN RECEIVED:',
          name: 'ApiService.CheckOut',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.CheckOut',
          level: 800,
        );
        developer.log(
          'Token: ${responseData['token']}',
          name: 'ApiService.CheckOut',
          level: 800,
        );
        developer.log(
          'Visit ID: ${responseData['visit']['id']}',
          name: 'ApiService.CheckOut',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.CheckOut',
          level: 800,
        );
      }
    }

    return responseData;
  }

  // Check-out - Old API format (mock data for backward compatibility)
  Future<Map<String, dynamic>> checkOutOld({
    required String visitId,
    String? notes,
  }) async {
    return await MockDataService.mockCheckOut(visitId: visitId, notes: notes);
  }

  // Get visits - Always use mock data
  Future<List<Visit>> getVisits() async {
    return await MockDataService.mockGetVisits();
  }

  // Get current active visit - Always use mock data
  Future<Visit?> getCurrentActiveVisit() async {
    return await MockDataService.mockGetCurrentActiveVisit();
  }

  // Get visits by date range - Always use mock data
  Future<List<Visit>> getVisitsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await MockDataService.mockGetVisits();
  }

  // Update visit notes - Always use mock data
  Future<Map<String, dynamic>> updateVisitNotes(
    String visitId,
    String notes,
  ) async {
    return {
      'status': 'success',
      'message': 'Notes updated successfully',
      'visit': {'id': visitId, 'notes': notes},
    };
  }

  // Get visit statistics - Always use mock data
  Future<Map<String, dynamic>> getVisitStatistics() async {
    return {
      'total_visits': 10,
      'completed_visits': 8,
      'active_visits': 2,
      'success_rate': 80.0,
    };
  }

  // Check if user has already checked in today (to prevent multiple checkins per day)
  Future<Map<String, dynamic>> getTodayCheckInStatus(int userId) async {
    final headers = _getHeaders();
    final url = '$baseUrl/visits/checkinout/today/$userId';

    developer.log(
      '\n🔍 CHECKING TODAY\'S CHECK-IN STATUS:',
      name: 'ApiService.TodayCheckInStatus',
      level: 800,
    );
    developer.log('URL: $url', name: 'ApiService.TodayCheckInStatus', level: 800);
    developer.log('User ID: $userId', name: 'ApiService.TodayCheckInStatus', level: 800);

    _logRequest('GET', url, headers, '');

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      developer.log(
        '\n📥 TODAY\'S CHECK-IN STATUS API RESPONSE:',
        name: 'ApiService.TodayCheckInStatus',
        level: 800,
      );
      developer.log(
        'Status Code: ${response.statusCode}',
        name: 'ApiService.TodayCheckInStatus',
        level: 800,
      );
      developer.log(
        'Response Body: ${response.body}',
        name: 'ApiService.TodayCheckInStatus',
        level: 800,
      );

      _logResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);

        developer.log(
          '\n✅ TODAY\'S CHECK-IN STATUS API SUCCESS:',
          name: 'ApiService.TodayCheckInStatus',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.TodayCheckInStatus',
          level: 800,
        );
        developer.log(
          'Response Data: $responseData',
          name: 'ApiService.TodayCheckInStatus',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.TodayCheckInStatus',
          level: 800,
        );

        return {
          'status': 'success',
          'data': responseData,
          'hasCheckedInToday': responseData['has_checked_in_today'] ?? false,
          'hasCheckedOutToday': responseData['has_checked_out_today'] ?? false,
          'todayCheckInId': responseData['today_checkin_id'],
          'todayCheckInTime': responseData['today_checkin_time'],
          'todayCheckOutTime': responseData['today_checkout_time'],
          'canCheckIn': !(responseData['has_checked_in_today'] ?? false),
          'canCheckOut': (responseData['has_checked_in_today'] ?? false) && 
                        !(responseData['has_checked_out_today'] ?? false),
        };
      } else {
        // No check-in found for today
        return {
          'status': 'no_checkin_today',
          'data': null,
          'hasCheckedInToday': false,
          'hasCheckedOutToday': false,
          'canCheckIn': true,
          'canCheckOut': false,
        };
      }
    } catch (e, stackTrace) {
      developer.log(
        '\n❌ TODAY\'S CHECK-IN STATUS API ERROR:',
        name: 'ApiService.TodayCheckInStatus',
        level: 1000,
      );
      developer.log('Error: $e', name: 'ApiService.TodayCheckInStatus', level: 1000);
      developer.log(
        'Stack Trace: $stackTrace',
        name: 'ApiService.TodayCheckInStatus',
        level: 1000,
      );
      
      return {
        'status': 'error',
        'data': null,
        'hasCheckedInToday': false,
        'hasCheckedOutToday': false,
        'canCheckIn': true,
        'canCheckOut': false,
        'error': e.toString(),
      };
    }
  }

  // Check if user is already checked in - Real API implementation
  // Returns check-in ID if user is checked in, null otherwise
  Future<Map<String, dynamic>> getCheckInStatus(int userId) async {
    final headers = _getHeaders();
    final url = '$baseUrl/visits/checkinId/$userId';

    developer.log(
      '\n🔍 CHECKING CHECK-IN STATUS:',
      name: 'ApiService.CheckInStatus',
      level: 800,
    );
    developer.log('URL: $url', name: 'ApiService.CheckInStatus', level: 800);
    developer.log(
      'User ID: $userId',
      name: 'ApiService.CheckInStatus',
      level: 800,
    );

    _logRequest('GET', url, headers, '');

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      developer.log(
        '\n📥 CHECK-IN STATUS API RESPONSE:',
        name: 'ApiService.CheckInStatus',
        level: 800,
      );
      developer.log(
        'Status Code: ${response.statusCode}',
        name: 'ApiService.CheckInStatus',
        level: 800,
      );
      developer.log(
        'Response Body: ${response.body}',
        name: 'ApiService.CheckInStatus',
        level: 800,
      );

      _logResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // API returns just a number (ID) like "16" or null
        final responseBody = response.body.trim();
        
        // Check if response is empty or null
        if (responseBody.isEmpty || responseBody == 'null' || responseBody == '""') {
          developer.log(
            '\n✅ CHECK-IN STATUS API SUCCESS: No active check-in',
            name: 'ApiService.CheckInStatus',
            level: 800,
          );
          return {
            'status': 'success',
            'checkInId': null,
            'isCheckedIn': false,
          };
        }
        
        // Try to parse as JSON first (in case it's a JSON object)
        dynamic responseData;
        try {
          responseData = json.decode(responseBody);
        } catch (e) {
          // If not JSON, try parsing as number directly
          responseData = responseBody;
        }
        
        // Extract check-in ID
        String? checkInId;
        if (responseData is int) {
          checkInId = responseData.toString();
        } else if (responseData is String && responseData.isNotEmpty && responseData != 'null') {
          // Try to parse string as number
          final parsed = int.tryParse(responseData);
          if (parsed != null) {
            checkInId = parsed.toString();
          } else {
            checkInId = responseData;
          }
        } else if (responseData is Map) {
          // If it's a Map, try to extract ID from common fields
          checkInId = responseData['id']?.toString() ?? 
                     responseData['checkInId']?.toString() ?? 
                     responseData['checkin_id']?.toString();
        }

        developer.log(
          '\n✅ CHECK-IN STATUS API SUCCESS:',
          name: 'ApiService.CheckInStatus',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.CheckInStatus',
          level: 800,
        );
        developer.log(
          'Response Data: $responseData',
          name: 'ApiService.CheckInStatus',
          level: 800,
        );
        developer.log(
          'Check-In ID: $checkInId',
          name: 'ApiService.CheckInStatus',
          level: 800,
        );
        developer.log(
          'Is Checked In: ${checkInId != null && checkInId.isNotEmpty}',
          name: 'ApiService.CheckInStatus',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.CheckInStatus',
          level: 800,
        );

        return {
          'status': 'success',
          'checkInId': checkInId,
          'isCheckedIn': checkInId != null && checkInId.isNotEmpty,
          'data': responseData,
        };
      } else {
        // No active check-in found
        developer.log(
          '\n✅ CHECK-IN STATUS: No active check-in (Status ${response.statusCode})',
          name: 'ApiService.CheckInStatus',
          level: 800,
        );
        return {
          'status': 'no_checkin',
          'checkInId': null,
          'isCheckedIn': false,
        };
      }
    } catch (e, stackTrace) {
      developer.log(
        '\n❌ CHECK-IN STATUS API ERROR:',
        name: 'ApiService.CheckInStatus',
        level: 1000,
      );
      developer.log('Error: $e', name: 'ApiService.CheckInStatus', level: 1000);
      developer.log(
        'Stack Trace: $stackTrace',
        name: 'ApiService.CheckInStatus',
        level: 1000,
      );
      
      return {
        'status': 'error',
        'checkInId': null,
        'isCheckedIn': false,
        'error': e.toString(),
      };
    }
  }

  // Get visit details history for a user - Real API implementation
  Future<List<Visit>> getVisitDetailsHistory(int userId) async {
    final headers = _getHeaders();
    final url = '$baseUrl/visits/details/history/$userId';

    developer.log(
      '\n🔍 FETCHING VISIT DETAILS HISTORY:',
      name: 'ApiService.VisitHistory',
      level: 800,
    );
    developer.log('URL: $url', name: 'ApiService.VisitHistory', level: 800);
    developer.log(
      'User ID: $userId',
      name: 'ApiService.VisitHistory',
      level: 800,
    );
    developer.log(
      'Bearer Token: ${_authToken?.substring(0, 20)}...',
      name: 'ApiService.VisitHistory',
      level: 800,
    );

    _logRequest('GET', url, headers, '');

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      developer.log(
        '\n📥 VISIT DETAILS HISTORY API RESPONSE:',
        name: 'ApiService.VisitHistory',
        level: 800,
      );
      developer.log(
        'Status Code: ${response.statusCode}',
        name: 'ApiService.VisitHistory',
        level: 800,
      );
      developer.log(
        'Response Body: ${response.body}',
        name: 'ApiService.VisitHistory',
        level: 800,
      );

      // Log the response for debugging
      _logResponse(response);

      // Check if request was successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Decode JSON
        final responseData = json.decode(response.body);

        developer.log(
          'Response Data Type: ${responseData.runtimeType}',
          name: 'ApiService.VisitHistory',
          level: 800,
        );

        // Handle different response formats
        List<Map<String, dynamic>> visitsList = [];

        if (responseData is List) {
          // Direct list of visits
          visitsList = List<Map<String, dynamic>>.from(responseData);
        } else if (responseData is Map) {
          // Check if response has 'data' field
          if (responseData['data'] != null && responseData['data'] is List) {
            visitsList = List<Map<String, dynamic>>.from(responseData['data']);
          } else if (responseData['visits'] != null &&
              responseData['visits'] is List) {
            visitsList = List<Map<String, dynamic>>.from(
              responseData['visits'],
            );
          } else if (responseData['visit_details'] != null &&
              responseData['visit_details'] is List) {
            visitsList = List<Map<String, dynamic>>.from(
              responseData['visit_details'],
            );
          } else {
            // If it's a single visit, wrap it in a list
            visitsList = [Map<String, dynamic>.from(responseData)];
          }
        }

        developer.log(
          '\n✅ VISIT DETAILS HISTORY API SUCCESS:',
          name: 'ApiService.VisitHistory',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.VisitHistory',
          level: 800,
        );
        developer.log(
          'Visit History Count: ${visitsList.length}',
          name: 'ApiService.VisitHistory',
          level: 800,
        );
        developer.log(
          'Visit History Data: $visitsList',
          name: 'ApiService.VisitHistory',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.VisitHistory',
          level: 800,
        );

        // Convert to Visit objects
        final visits = visitsList.map((visitData) {
          try {
            return Visit.fromJson(visitData);
          } catch (e) {
            developer.log(
              '⚠️ Error parsing visit: $e',
              name: 'ApiService.VisitHistory',
              level: 900,
            );
            developer.log(
              'Problematic data: $visitData',
              name: 'ApiService.VisitHistory',
              level: 900,
            );
            rethrow;
          }
        }).toList();

        return visits;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      developer.log(
        '\n❌ VISIT DETAILS HISTORY API ERROR:',
        name: 'ApiService.VisitHistory',
        level: 1000,
      );
      developer.log('Error: $e', name: 'ApiService.VisitHistory', level: 1000);
      developer.log(
        'Stack Trace: $stackTrace',
        name: 'ApiService.VisitHistory',
        level: 1000,
      );
      rethrow;
    }
  }

  // Location APIs

  // Log location to live API - Real API implementation
  Future<Map<String, dynamic>> logLocationToLiveApi({
    required int userId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required int batteryPercent,
    required String loggedAt,
  }) async {
    final requestBody = {
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'battery_percent': batteryPercent,
      'logged_at': loggedAt,
    };

    final headers = _getHeaders();
    final body = json.encode(requestBody);

    if (kDebugMode) {
      developer.log(
        '\n📍 LOGGING LOCATION TO LIVE API:',
        name: 'ApiService.LocationLog',
        level: 800,
      );
      developer.log(
        'User ID: $userId',
        name: 'ApiService.LocationLog',
        level: 800,
      );
      developer.log(
        'Location: ($latitude, $longitude)',
        name: 'ApiService.LocationLog',
        level: 800,
      );
      developer.log(
        'Battery: $batteryPercent%',
        name: 'ApiService.LocationLog',
        level: 800,
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/location/log'),
        headers: headers,
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);
        if (kDebugMode) {
          developer.log(
            '✅ Location logged successfully',
            name: 'ApiService.LocationLog',
            level: 800,
          );
        }
        return responseData;
      } else {
        if (kDebugMode) {
          developer.log(
            '❌ Location log failed: ${response.statusCode}',
            name: 'ApiService.LocationLog',
            level: 1000,
          );
        }
        throw Exception('Failed to log location: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          '❌ Error logging location: $e',
          name: 'ApiService.LocationLog',
          level: 1000,
        );
      }
      rethrow;
    }
  }

  // Log location - Always use mock data
  Future<Map<String, dynamic>> logLocation(
    double latitude,
    double longitude,
    double accuracy,
    double battery,
  ) async {
    return await MockDataService.mockLogLocation(
      latitude,
      longitude,
      accuracy,
      battery,
    );
  }

  // Get journey data - Always use mock data
  Future<List<LocationLog>> getJourneyData(DateTime date) async {
    return await MockDataService.mockGetJourneyData(date);
  }

  // Get live tracking data - Always use mock data
  Future<List<Map<String, dynamic>>> getLiveTrackingData() async {
    return await MockDataService.mockGetLiveTrackingData();
  }

  // Get journey data for specific user and date - Always use mock data
  Future<List<LocationLog>> getJourneyDataForUser(
    DateTime date,
    String userId,
  ) async {
    return await MockDataService.mockGetJourneyData(date);
  }

  // Check-in/Check-out History APIs

  // Get check-in/check-out count for a user - Real API implementation
  Future<Map<String, dynamic>> getCheckInCheckOutCount(int userId) async {
    final headers = _getHeaders();
    final url = '$baseUrl/visits/checkinout/count/$userId';

    developer.log(
      '\n🔍 FETCHING CHECK-IN/CHECK-OUT COUNT:',
      name: 'ApiService.CheckInOutCount',
      level: 800,
    );
    developer.log('URL: $url', name: 'ApiService.CheckInOutCount', level: 800);
    developer.log('User ID: $userId', name: 'ApiService.CheckInOutCount', level: 800);
    developer.log(
      'Bearer Token: ${_authToken?.substring(0, 20)}...',
      name: 'ApiService.CheckInOutCount',
      level: 800,
    );

    _logRequest('GET', url, headers, '');

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      developer.log(
        '\n📥 CHECK-IN/CHECK-OUT COUNT API RESPONSE:',
        name: 'ApiService.CheckInOutCount',
        level: 800,
      );
      developer.log(
        'Status Code: ${response.statusCode}',
        name: 'ApiService.CheckInOutCount',
        level: 800,
      );
      developer.log(
        'Response Body: ${response.body}',
        name: 'ApiService.CheckInOutCount',
        level: 800,
      );

      _logResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);

        developer.log(
          '\n✅ CHECK-IN/CHECK-OUT COUNT API SUCCESS:',
          name: 'ApiService.CheckInOutCount',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.CheckInOutCount',
          level: 800,
        );
        developer.log(
          'Count Data: $responseData',
          name: 'ApiService.CheckInOutCount',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.CheckInOutCount',
          level: 800,
        );

        return {
          'status': 'success',
          'data': responseData,
          'totalCheckIns': responseData['total_checkins'] ?? 0,
          'totalCheckOuts': responseData['total_checkouts'] ?? 0,
          'totalSessions': responseData['total_sessions'] ?? 0,
          'completedSessions': responseData['completed_sessions'] ?? 0,
          'activeSessions': responseData['active_sessions'] ?? 0,
        };
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      developer.log(
        '\n❌ CHECK-IN/CHECK-OUT COUNT API ERROR:',
        name: 'ApiService.CheckInOutCount',
        level: 1000,
      );
      developer.log('Error: $e', name: 'ApiService.CheckInOutCount', level: 1000);
      developer.log(
        'Stack Trace: $stackTrace',
        name: 'ApiService.CheckInOutCount',
        level: 1000,
      );
      
      return {
        'status': 'error',
        'data': null,
        'totalCheckIns': 0,
        'totalCheckOuts': 0,
        'totalSessions': 0,
        'completedSessions': 0,
        'activeSessions': 0,
        'error': e.toString(),
      };
    }
  }

  // Get lead count for user - Real API implementation
  Future<Map<String, dynamic>> getLeadCount(String userId) async {
    final headers = _getHeaders();
    final url = '$baseUrl/lead/total/$userId';

    developer.log(
      '\n🔍 FETCHING LEAD COUNT:',
      name: 'ApiService.LeadCount',
      level: 800,
    );
    developer.log('URL: $url', name: 'ApiService.LeadCount', level: 800);
    developer.log('User ID: $userId', name: 'ApiService.LeadCount', level: 800);
    developer.log(
      'Bearer Token: ${_authToken != null ? (_authToken!.length > 20 ? _authToken!.substring(0, 20) : _authToken!) : 'null'}...',
      name: 'ApiService.LeadCount',
      level: 800,
    );

    _logRequest('GET', url, headers, '');

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      developer.log(
        '\n📥 LEAD COUNT API RESPONSE:',
        name: 'ApiService.LeadCount',
        level: 800,
      );
      developer.log(
        'Status Code: ${response.statusCode}',
        name: 'ApiService.LeadCount',
        level: 800,
      );
      developer.log(
        'Response Body: ${response.body}',
        name: 'ApiService.LeadCount',
        level: 800,
      );

      _logResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);

        // Print detailed response to console
        debugPrint('\n🎯 LEAD COUNT API RESPONSE DETAILS:');
        debugPrint('═══════════════════════════════════════');
        debugPrint('📊 Raw Response Body: ${response.body}');
        debugPrint('📊 Parsed Response Data: $responseData');
        debugPrint('📊 Response Type: ${responseData.runtimeType}');
        debugPrint('═══════════════════════════════════════');
        
        // Print individual fields with better formatting
        debugPrint('📈 API Response Fields:');
        debugPrint('  - today_total_lead: ${responseData['today_total_lead']}');
        debugPrint('  - today_visit_lead: ${responseData['today_visit_lead']}');
        debugPrint('  - total_lead: ${responseData['total_lead']}');
        debugPrint('  - visit_lead: ${responseData['visit_lead']}');
        debugPrint('═══════════════════════════════════════');
        
        // Print what will be used as target
        final totalLead = responseData['total_lead'] ?? 0;
        debugPrint('🎯 TARGET CALCULATION:');
        debugPrint('  - Using total_lead as daily target: $totalLead');
        debugPrint('  - This will be displayed on dashboard');
        debugPrint('  - Remaining targets will decrease as visits complete');
        debugPrint('═══════════════════════════════════════');

        developer.log(
          '\n✅ LEAD COUNT API SUCCESS:',
          name: 'ApiService.LeadCount',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.LeadCount',
          level: 800,
        );
        developer.log(
          'Lead Count Data: $responseData',
          name: 'ApiService.LeadCount',
          level: 800,
        );
        developer.log(
          '═══════════════════════════════════════',
          name: 'ApiService.LeadCount',
          level: 800,
        );

        return {
          'status': 'success',
          'data': responseData,
          'todayTotalLead': responseData['today_total_lead'] ?? 0,
          'todayVisitLead': responseData['today_visit_lead'] ?? 0,
          'totalLead': responseData['total_lead'] ?? 0,
          'visitLead': responseData['visit_lead'] ?? 0,
        };
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      // Print error details to console
      debugPrint('\n❌ LEAD COUNT API ERROR:');
      debugPrint('═══════════════════════════════════════');
      debugPrint('🚨 Error: $e');
      debugPrint('🚨 Stack Trace: $stackTrace');
      debugPrint('═══════════════════════════════════════');

      developer.log(
        '\n❌ LEAD COUNT API ERROR:',
        name: 'ApiService.LeadCount',
        level: 1000,
      );
      developer.log('Error: $e', name: 'ApiService.LeadCount', level: 1000);
      developer.log(
        'Stack Trace: $stackTrace',
        name: 'ApiService.LeadCount',
        level: 1000,
      );
      
      return {
        'status': 'error',
        'data': null,
        'todayTotalLead': 0,
        'todayVisitLead': 0,
        'totalLead': 0,
        'visitLead': 0,
        'error': e.toString(),
      };
    }
  }

  // Get check-in/check-out history for a user - Real API implementation
  Future<List<UserCheckInCheckOutHistory>> getCheckInCheckOutHistory(
    int userId,
  ) async {
    final headers = _getHeaders();

    _logRequest(
      'GET',
      '$baseUrl/visits/checkinout/history/$userId',
      headers,
      '',
    );

    final response = await http.get(
      Uri.parse('$baseUrl/visits/checkinout/history/$userId'),
      headers: headers,
    );

    final responseData = _handleResponseFlexible(response);

    if (kDebugMode) {
      developer.log(
        '🔍 Check-in/Check-out History API Response Debug:',
        name: 'ApiService.Debug',
        level: 500,
      );
      developer.log(
        'Response type: ${responseData.runtimeType}',
        name: 'ApiService.Debug',
        level: 500,
      );
      developer.log(
        'Response status: ${response.statusCode}',
        name: 'ApiService.Debug',
        level: 500,
      );
      developer.log(
        'Response headers: ${response.headers}',
        name: 'ApiService.Debug',
        level: 500,
      );
      developer.log(
        'Full response: $responseData',
        name: 'ApiService.Debug',
        level: 500,
      );

      // Additional debugging for the specific error
      if (responseData is List) {
        final listData = responseData;
        developer.log(
          '✅ Response is a List with ${listData.length} items',
          name: 'ApiService.Debug',
          level: 500,
        );
        if (listData.isNotEmpty) {
          developer.log(
            'First item type: ${listData.first.runtimeType}',
            name: 'ApiService.Debug',
            level: 500,
          );
          developer.log(
            'First item content: ${listData.first}',
            name: 'ApiService.Debug',
            level: 500,
          );
        }
      } else {
        developer.log(
          '❌ Response is not a List, it is: ${responseData.runtimeType}',
          name: 'ApiService.Debug',
          level: 500,
        );
      }
    }

    // Handle different response formats
    List<dynamic> dataList;

    if (responseData is List) {
      dataList = responseData;
    } else {
      // Assume it's a Map and try to find the data array
      final responseMap = responseData;
      if (responseMap.containsKey('data') && responseMap['data'] is List) {
        dataList = responseMap['data'];
      } else if (responseMap.containsKey('users') &&
          responseMap['users'] is List) {
        dataList = responseMap['users'];
      } else {
        // If it's a single user object, wrap it in a list
        dataList = [responseData];
      }
    }

    if (kDebugMode) {
      developer.log(
        'Processed data list length: ${dataList.length}',
        name: 'ApiService.Debug',
        level: 500,
      );
      if (dataList.isNotEmpty) {
        developer.log(
          'First item type: ${dataList.first.runtimeType}',
          name: 'ApiService.Debug',
          level: 500,
        );
        developer.log(
          'First item: ${dataList.first}',
          name: 'ApiService.Debug',
          level: 500,
        );
      }
    }

    // Parse the data list
    try {
      return dataList.map((item) {
        if (item is Map<String, dynamic>) {
          try {
            return UserCheckInCheckOutHistory.fromJson(item);
          } catch (e) {
            if (kDebugMode) {
              developer.log(
                '❌ Error parsing individual item: $e',
                name: 'ApiService.Error',
                level: 1000,
              );
              developer.log(
                'Problematic item: $item',
                name: 'ApiService.Error',
                level: 1000,
              );
            }
            rethrow;
          }
        } else {
          throw Exception(
            'Invalid item format in response: ${item.runtimeType}. Item: $item',
          );
        }
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          '❌ Error parsing check-in/check-out history: $e',
          name: 'ApiService.Error',
          level: 1000,
        );
        developer.log(
          'Problematic data: $dataList',
          name: 'ApiService.Error',
          level: 1000,
        );
      }
      // Convert the error to a more user-friendly string
      throw Exception('API Error: ${e.toString()}');
    }
  }
}
