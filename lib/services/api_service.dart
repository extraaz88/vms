import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/visit_model.dart';
import '../models/location_model.dart';
import 'mock_data_service.dart';

class ApiService {
  static const String baseUrl = '';
  String? _authToken;
  static bool _useMockData = true; // Set to true to use mock data
  
  // Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }
  
  // Clear authentication token
  void clearAuthToken() {
    _authToken = null;
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
  
  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
  
  // Authentication APIs
  
  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (_useMockData) {
      return await MockDataService.mockLogin(email, password);
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _getHeaders(),
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    
    return _handleResponse(response);
  }
  
  // Update Profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: _getHeaders(),
      body: json.encode(userData),
    );
    
    return _handleResponse(response);
  }
  
  // Visit APIs
  
  // Check-in
  Future<Map<String, dynamic>> checkIn({
    required String clientName,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    if (_useMockData) {
      return await MockDataService.mockCheckIn(
        clientName: clientName,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/visits/checkin'),
      headers: _getHeaders(),
      body: json.encode({
        'client_name': clientName,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
      }),
    );
    
    return _handleResponse(response);
  }
  
  // Check-out
  Future<Map<String, dynamic>> checkOut({
    required String visitId,
    String? notes,
  }) async {
    if (_useMockData) {
      return await MockDataService.mockCheckOut(
        visitId: visitId,
        notes: notes,
      );
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/visits/$visitId/checkout'),
      headers: _getHeaders(),
      body: json.encode({
        'notes': notes,
      }),
    );
    
    return _handleResponse(response);
  }
  
  // Get visits
  Future<List<Visit>> getVisits() async {
    if (_useMockData) {
      return await MockDataService.mockGetVisits();
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/visits'),
      headers: _getHeaders(),
    );
    
    final data = _handleResponse(response);
    return (data['visits'] as List)
        .map((visit) => Visit.fromJson(visit))
        .toList();
  }
  
  // Get visits by date range
  Future<List<Visit>> getVisitsByDateRange(DateTime startDate, DateTime endDate) async {
    final response = await http.get(
      Uri.parse('$baseUrl/visits?start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}'),
      headers: _getHeaders(),
    );
    
    final data = _handleResponse(response);
    return (data['visits'] as List)
        .map((visit) => Visit.fromJson(visit))
        .toList();
  }
  
  // Update visit notes
  Future<Map<String, dynamic>> updateVisitNotes(String visitId, String notes) async {
    final response = await http.put(
      Uri.parse('$baseUrl/visits/$visitId'),
      headers: _getHeaders(),
      body: json.encode({
        'notes': notes,
      }),
    );
    
    return _handleResponse(response);
  }
  
  // Get visit statistics
  Future<Map<String, dynamic>> getVisitStatistics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/visits/statistics'),
      headers: _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  // Location APIs
  
  // Log location
  Future<Map<String, dynamic>> logLocation(
    double latitude,
    double longitude,
    double accuracy,
    double battery,
  ) async {
    if (_useMockData) {
      return await MockDataService.mockLogLocation(
        latitude,
        longitude,
        accuracy,
        battery,
      );
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/location/log'),
      headers: _getHeaders(),
      body: json.encode({
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'battery': battery,
      }),
    );
    
    return _handleResponse(response);
  }
  
  // Get journey data
  Future<List<LocationLog>> getJourneyData(DateTime date) async {
    if (_useMockData) {
      return await MockDataService.mockGetJourneyData(date);
    }
    
    final dateString = date.toIso8601String().split('T')[0];
    final response = await http.get(
      Uri.parse('$baseUrl/location/journey?date=$dateString'),
      headers: _getHeaders(),
    );
    
    final data = _handleResponse(response);
    return (data as List<dynamic>)
        .map((log) => LocationLog.fromJson(log as Map<String, dynamic>))
        .toList();
  }
  
  // Get live tracking data
  Future<List<Map<String, dynamic>>> getLiveTrackingData() async {
    if (_useMockData) {
      return await MockDataService.mockGetLiveTrackingData();
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/location/live'),
      headers: _getHeaders(),
    );
    
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data as List<dynamic>);
  }
  
  // Get journey data for specific user and date
  Future<List<LocationLog>> getJourneyDataForUser(DateTime date, String userId) async {
    final dateString = date.toIso8601String().split('T')[0];
    final response = await http.get(
      Uri.parse('$baseUrl/location/journey?date=$dateString&user_id=$userId'),
      headers: _getHeaders(),
    );
    
    final data = _handleResponse(response);
    return (data as List<dynamic>)
        .map((log) => LocationLog.fromJson(log as Map<String, dynamic>))
        .toList();
  }
}
