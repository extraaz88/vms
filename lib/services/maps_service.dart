import 'package:url_launcher/url_launcher.dart';

class MapsService {
  // Open location in Google Maps
  static Future<void> openInGoogleMaps(double latitude, double longitude, {String? label}) async {
    try {
      // Google Maps URL
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      
      // Try to open in Google Maps app first
      final googleMapsAppUrl = 'https://maps.google.com/?q=$latitude,$longitude';
      
      // Try to launch Google Maps app
      if (await canLaunchUrl(Uri.parse(googleMapsAppUrl))) {
        await launchUrl(Uri.parse(googleMapsAppUrl), mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        // Fallback to web version
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      } else {
        // Final fallback - open in browser
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      print('Error opening Google Maps: $e');
      // Try alternative method
      await _openInAlternativeMaps(latitude, longitude, label);
    }
  }
  
  // Alternative method to open maps
  static Future<void> _openInAlternativeMaps(double latitude, double longitude, String? label) async {
    try {
      // Try different map URLs
      final urls = [
        'https://maps.google.com/maps?q=$latitude,$longitude',
        'https://www.google.com/maps/@$latitude,$longitude,15z',
        'geo:$latitude,$longitude?q=$latitude,$longitude${label != null ? '($label)' : ''}',
      ];
      
      for (String url in urls) {
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            return;
          }
        } catch (e) {
          continue;
        }
      }
      
      print('Could not open any maps application');
    } catch (e) {
      print('Error opening alternative maps: $e');
    }
  }
  
  // Open location with label in Google Maps
  static Future<void> openLocationWithLabel(double latitude, double longitude, String label) async {
    try {
      final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$label';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        await openInGoogleMaps(latitude, longitude, label: label);
      }
    } catch (e) {
      print('Error opening location with label: $e');
      await openInGoogleMaps(latitude, longitude);
    }
  }
  
  // Get directions to location
  static Future<void> getDirections(double latitude, double longitude, {double? fromLat, double? fromLng}) async {
    try {
      String url;
      
      if (fromLat != null && fromLng != null) {
        // Directions from specific location
        url = 'https://www.google.com/maps/dir/$fromLat,$fromLng/$latitude,$longitude';
      } else {
        // Directions from current location
        url = 'https://www.google.com/maps/dir//$latitude,$longitude';
      }
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        await openInGoogleMaps(latitude, longitude);
      }
    } catch (e) {
      print('Error getting directions: $e');
      await openInGoogleMaps(latitude, longitude);
    }
  }
  
  // Open current location in Google Maps
  static Future<void> openCurrentLocation(double latitude, double longitude) async {
    await openInGoogleMaps(latitude, longitude, label: 'Current Location');
  }
  
  // Check if maps app is available
  static Future<bool> isMapsAvailable() async {
    try {
      final url = 'https://maps.google.com/';
      return await canLaunchUrl(Uri.parse(url));
    } catch (e) {
      return false;
    }
  }
}
