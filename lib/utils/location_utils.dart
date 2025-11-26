import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationUtils {
  // Office coordinates (19.0282137, 73.0575063)
  static const double OFFICE_LATITUDE = 19.0282137;
  static const double OFFICE_LONGITUDE = 73.0575063;
  
  // Office radius in meters
  static const double OFFICE_RADIUS_METERS = 50.0;
  
  /// Calculate distance between two points in meters using Haversine formula
  static double calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
  
  /// Check if user is within office radius
  static bool isWithinOfficeRadius(double userLatitude, double userLongitude) {
    final distance = calculateDistance(
      userLatitude, 
      userLongitude, 
      OFFICE_LATITUDE, 
      OFFICE_LONGITUDE
    );
    
    return distance <= OFFICE_RADIUS_METERS;
  }
  
  /// Get distance from office in meters
  static double getDistanceFromOffice(double userLatitude, double userLongitude) {
    return calculateDistance(
      userLatitude, 
      userLongitude, 
      OFFICE_LATITUDE, 
      OFFICE_LONGITUDE
    );
  }
  
  /// Get formatted distance string
  static String getFormattedDistance(double userLatitude, double userLongitude) {
    final distance = getDistanceFromOffice(userLatitude, userLongitude);
    
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} meters';
    } else {
      final km = distance / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }
  
  /// Get office location info
  static Map<String, double> getOfficeLocation() {
    return {
      'latitude': OFFICE_LATITUDE,
      'longitude': OFFICE_LONGITUDE,
      'radius': OFFICE_RADIUS_METERS,
    };
  }
}



