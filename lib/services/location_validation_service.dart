import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationValidationService {
  // static const double _officeLatitude = 28.6139; // Delhi - TEST LOCATION
  // static const double _officeLongitude = 77.2090; // Delhi - TEST LOCATION

  static const double _officeLatitude = 19.0282137; // Original office location
  static const double _officeLongitude = 73.0575063; // Original office location

  // Alternative office location (commented):
  // static const double _officeLatitude = 19.186354;
  // static const double _officeLongitude = 73.191948;

  static const double _allowedRadiusMeters = 200.0; // 150 meters radius

  /// Check if user is within 150 meters of the office
  /// Returns true if user is within office radius, false otherwise
  static bool isUserInOffice(Position userPosition) {
    final distance = calculateDistance(
      _officeLatitude,
      _officeLongitude,
      userPosition.latitude,
      userPosition.longitude,
    );

    return distance <= _allowedRadiusMeters;
  }

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters

    // Convert degrees to radians
    final double lat1Rad = lat1 * pi / 180;
    final double lon1Rad = lon1 * pi / 180;
    final double lat2Rad = lat2 * pi / 180;
    final double lon2Rad = lon2 * pi / 180;

    // Calculate differences
    final double deltaLat = lat2Rad - lat1Rad;
    final double deltaLon = lon2Rad - lon1Rad;

    // Haversine formula
    final double a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Get office coordinates
  static Map<String, double> getOfficeCoordinates() {
    return {'latitude': _officeLatitude, 'longitude': _officeLongitude};
  }

  /// Get allowed radius in meters
  static double getAllowedRadius() {
    return _allowedRadiusMeters;
  }

  /// Get distance from office
  /// Returns distance in meters, or null if position is null
  static double? getDistanceFromOffice(Position? position) {
    if (position == null) return null;

    return calculateDistance(
      _officeLatitude,
      _officeLongitude,
      position.latitude,
      position.longitude,
    );
  }

  /// Format distance for display
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)}m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }
}
