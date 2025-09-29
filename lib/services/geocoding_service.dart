import 'package:geocoding/geocoding.dart';

class GeocodingService {
  // Get area name from latitude and longitude
  static Future<String> getAreaName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        
        // Build address from available components
        final components = <String>[];
        
        if (placemark.name != null && placemark.name!.isNotEmpty) {
          components.add(placemark.name!);
        }
        if (placemark.street != null && placemark.street!.isNotEmpty) {
          components.add(placemark.street!);
        }
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          components.add(placemark.locality!);
        }
        if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
          components.add(placemark.subLocality!);
        }
        if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
          components.add(placemark.administrativeArea!);
        }
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          components.add(placemark.country!);
        }
        
        if (components.isNotEmpty) {
          return components.join(', ');
        }
      }
      
      // Fallback to coordinates if no placemark found
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      
    } catch (e) {
      print('Error getting area name: $e');
      // Fallback to coordinates
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    }
  }
  
  // Get detailed address from coordinates
  static Future<Map<String, String>> getDetailedAddress(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        
        return {
          'name': placemark.name ?? '',
          'street': placemark.street ?? '',
          'locality': placemark.locality ?? '',
          'subLocality': placemark.subLocality ?? '',
          'administrativeArea': placemark.administrativeArea ?? '',
          'postalCode': placemark.postalCode ?? '',
          'country': placemark.country ?? '',
          'isoCountryCode': placemark.isoCountryCode ?? '',
          'fullAddress': _buildFullAddress(placemark),
        };
      }
      
      return {
        'fullAddress': '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
      };
      
    } catch (e) {
      print('Error getting detailed address: $e');
      return {
        'fullAddress': '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
      };
    }
  }
  
  // Build full address from placemark
  static String _buildFullAddress(Placemark placemark) {
    final components = <String>[];
    
    if (placemark.name != null && placemark.name!.isNotEmpty) {
      components.add(placemark.name!);
    }
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      components.add(placemark.street!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      components.add(placemark.locality!);
    }
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      components.add(placemark.subLocality!);
    }
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      components.add(placemark.administrativeArea!);
    }
    if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
      components.add(placemark.postalCode!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      components.add(placemark.country!);
    }
    
    return components.join(', ');
  }
  
  // Get coordinates from address (reverse geocoding)
  static Future<List<Location>> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      return locations;
    } catch (e) {
      print('Error getting coordinates from address: $e');
      return [];
    }
  }
}
