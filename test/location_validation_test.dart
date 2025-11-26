import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_validation_service.dart';

void main() {
  group('LocationValidationService Tests', () {
    test('should return true when user is within office radius', () {
      // Create a position very close to office (within 50m)
      final position = Position(
        latitude: 19.0282137, // Same as office latitude
        longitude: 73.0575063, // Same as office longitude
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      final result = LocationValidationService.isUserInOffice(position);
      expect(result, true);
    });

    test('should return false when user is far from office', () {
      // Create a position far from office (more than 50m)
      final position = Position(
        latitude: 19.0300000, // Far from office
        longitude: 73.0600000, // Far from office
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      final result = LocationValidationService.isUserInOffice(position);
      expect(result, false);
    });

    test('should calculate correct distance', () {
      // Test distance calculation
      final distance = LocationValidationService.calculateDistance(
        19.0282137, // Office latitude
        73.0575063, // Office longitude
        19.0282137, // Same latitude
        73.0575063, // Same longitude
      );

      expect(distance, closeTo(0.0, 1.0)); // Should be very close to 0
    });

    test('should format distance correctly', () {
      expect(LocationValidationService.formatDistance(50.0), '50m');
      expect(LocationValidationService.formatDistance(1500.0), '1.5km');
      expect(LocationValidationService.formatDistance(500.0), '500m');
    });

    test('should get office coordinates', () {
      final coords = LocationValidationService.getOfficeCoordinates();
      expect(coords['latitude'], 19.0282137);
      expect(coords['longitude'], 73.0575063);
    });

    test('should get allowed radius', () {
      final radius = LocationValidationService.getAllowedRadius();
      expect(radius, 50.0);
    });
  });
}
