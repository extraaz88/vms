# Location Logging Implementation

This document describes the implementation of automatic location logging that hits the API every 2 seconds when the app opens.

## Overview

The app now automatically logs the user's location to `https://live.extraaaz.com/api/location/log` every 2 seconds when the app is running. This includes:

- User ID (default: 3, can be updated)
- Current latitude and longitude
- Location accuracy
- Battery percentage (simplified implementation)
- Timestamp in the format "YYYY-MM-DD HH:mm"

## Implementation Details

### Files Created/Modified

1. **`lib/services/location_logging_service.dart`**
   - Core service that handles the periodic API calls
   - Manages location permissions and battery monitoring
   - Sends data in the required JSON format

2. **`lib/core/providers/location_logging_provider.dart`**
   - Provider for state management
   - Tracks logging status, request counts, and statistics
   - Handles start/stop functionality

3. **`lib/screens/test/location_logging_test_screen.dart`**
   - Test screen to monitor and control location logging
   - Shows real-time statistics and responses
   - Allows manual start/stop of logging

4. **`lib/main.dart`**
   - Integrated the location logging provider
   - Starts location logging automatically when app opens

5. **`lib/screens/home/dashboard_screen.dart`**
   - Added location logging status widget
   - Shows current logging status and statistics

### API Request Format

The service sends the following JSON data every 2 seconds:

```json
{
  "user_id": 3,
  "latitude": 18.5204,
  "longitude": 73.8567,
  "accuracy": 2,
  "battery_percent": 85,
  "logged_at": "2025-01-03 09:30"
}
```

### Features

- **Automatic Start**: Location logging starts automatically when the app opens
- **Real-time Monitoring**: Dashboard shows current status and statistics
- **Manual Control**: Users can start/stop logging manually
- **Error Handling**: Comprehensive error handling and logging
- **Statistics Tracking**: Tracks request count, success rate, and errors
- **Response Logging**: All API responses are logged to console

### Permissions

The following permissions are required in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### Testing

1. **Test Screen**: Navigate to `/test/location-logging` to access the test interface
2. **Dashboard Widget**: The main dashboard shows a status widget with logging information
3. **Console Logs**: All API requests and responses are logged to the console

### Usage

1. **Automatic**: Location logging starts automatically when the app opens
2. **Manual Control**: Use the dashboard widget or test screen to start/stop logging
3. **Monitoring**: Check the dashboard for real-time statistics and status

### Configuration

- **API URL**: `https://live.extraaaz.com/api/location/log`
- **Interval**: 2 seconds
- **User ID**: Default 3, can be updated via `updateUserId()` method
- **Battery Level**: Currently uses a default value (85%), can be enhanced with platform channels

### Future Enhancements

1. **Real Battery Monitoring**: Implement platform channels to get actual battery level
2. **Background Service**: Run location logging in background even when app is minimized
3. **Data Persistence**: Store failed requests and retry when network is available
4. **User Preferences**: Allow users to configure logging interval and enable/disable

## Console Output

When running, you'll see detailed logs in the console:

```
📤 LOCATION LOG REQUEST
═══════════════════════════════════════
API URL: https://live.extraaaz.com/api/location/log
Request Data:
{
  "user_id": 3,
  "latitude": 18.5204,
  "longitude": 73.8567,
  "accuracy": 2.0,
  "battery_percent": 85,
  "logged_at": "2025-01-03 09:30"
}
═══════════════════════════════════════

📥 LOCATION LOG RESPONSE
═══════════════════════════════════════
Status Code: 200
Response:
{
  "status": "success",
  "message": "Location logged successfully"
}
═══════════════════════════════════════
```

This implementation provides a robust location logging system that meets the requirements specified in the user query.
