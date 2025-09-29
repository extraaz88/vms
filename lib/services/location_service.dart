import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/location_model.dart';

class LocationService {
  StreamSubscription<Position>? _positionStream;
  
  // Get current position
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }
  
  // Start location stream
  void startLocationStream({
    required Function(Position) onLocationUpdate,
    required Function(String) onError,
  }) {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(
      (Position position) {
        onLocationUpdate(position);
      },
      onError: (error) {
        onError('Location stream error: ${error.toString()}');
      },
    );
  }
  
  // Stop location stream
  Future<void> stopLocationStream() async {
    await _positionStream?.cancel();
    _positionStream = null;
  }
  
  // Store location locally
  Future<void> storeLocationLocally(LocationLog locationLog) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'location_logs';
      
      // Get existing logs
      List<String> existingLogs = prefs.getStringList(key) ?? [];
      
      // Add new log
      existingLogs.add(json.encode(locationLog.toJson()));
      
      // Store back
      await prefs.setStringList(key, existingLogs);
    } catch (e) {
      print('Error storing location locally: $e');
    }
  }
  
  // Get stored locations
  Future<List<LocationLog>> getStoredLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'location_logs';
      
      List<String> storedLogs = prefs.getStringList(key) ?? [];
      
      return storedLogs.map((logString) {
        final logJson = json.decode(logString);
        return LocationLog.fromJson(logJson);
      }).toList();
    } catch (e) {
      print('Error getting stored locations: $e');
      return [];
    }
  }
  
  // Clear stored locations
  Future<void> clearStoredLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('location_logs');
    } catch (e) {
      print('Error clearing stored locations: $e');
    }
  }
  
  // Calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
  
  // Check if location is valid (not duplicate within time/distance threshold)
  bool isValidLocation(LocationLog newLog, LocationLog? lastLog, {
    int timeThresholdMinutes = 1,
    double distanceThresholdMeters = 10,
  }) {
    if (lastLog == null) return true;
    
    // Check time threshold
    final timeDifference = newLog.timestamp.difference(lastLog.timestamp);
    if (timeDifference.inMinutes < timeThresholdMinutes) {
      return false;
    }
    
    // Check distance threshold
    final distance = calculateDistance(
      newLog.latitude,
      newLog.longitude,
      lastLog.latitude,
      lastLog.longitude,
    );
    
    return distance >= distanceThresholdMeters;
  }
}
