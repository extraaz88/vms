# Location Logging API Implementation

## Overview
This implementation adds automatic location logging to the live API endpoint every 2 seconds when the app is open.

## API Endpoint
```
POST https://live.extraaaz.com/api/location/log
```

## Request Payload
```json
{
  "user_id": 3,
  "latitude": 18.5204,
  "longitude": 73.8567,
  "accuracy": 2,
  "battery_percent": 15,
  "logged_at": "2025-10-03 09:30"
}
```

## Implementation Details

### 1. Battery Monitoring
- **Package**: `battery_plus: ^6.0.2` added to `pubspec.yaml`
- **Real Battery**: Gets actual battery percentage from the device
- **Updates**: Battery level is updated before each API call

### 2. Location Logging Service
- **Interval**: Every 2 seconds using `Timer.periodic`
- **Auto-start**: Starts automatically when app opens
- **Location**: Uses current GPS location with accuracy
- **Timestamp Format**: `yyyy-MM-dd HH:mm` (e.g., "2025-10-03 09:30")

### 3. Files Modified

#### `pubspec.yaml`
- Added `battery_plus: ^6.0.2` package for real battery monitoring

#### `lib/services/api_service.dart`
- Added `logLocationToLiveApi()` method
- Sends data to `https://live.extraaaz.com/api/location/log`
- Includes proper error handling and logging

#### `lib/core/providers/location_provider.dart`
- Added `Battery` instance for battery monitoring
- Added `Timer` for periodic logging (2 seconds)
- Added `startPeriodicLocationLogging()` method
- Added `stopPeriodicLocationLogging()` method
- Added `_updateBatteryLevel()` method
- Added `_logLocationToApi()` method
- Battery level type changed from `double` to `int`

#### `lib/main.dart`
- Initialize location provider on app start
- Automatically start periodic location logging
- Logging starts immediately when app opens

## Usage

### Automatic Start
The location logging starts automatically when the app opens. No manual intervention needed.

### Manual Control (if needed)
```dart
// Get location provider
final locationProvider = context.read<LocationProvider>();

// Start logging
locationProvider.startPeriodicLocationLogging();

// Stop logging
locationProvider.stopPeriodicLocationLogging();

// Check if logging is active
bool isLogging = locationProvider.isLoggingLocation;

// Get current battery level
int battery = locationProvider.batteryLevel;
```

## Setup Instructions

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the App**:
   ```bash
   flutter run
   ```

3. **Location Logging**:
   - App will automatically request location permissions
   - Once granted, location logging starts every 2 seconds
   - Battery level is updated from device before each API call
   - User ID is automatically retrieved from authenticated user (defaults to 3 if not found)

## Features

✅ **Automatic Start**: Logging begins when app opens  
✅ **Real Battery**: Uses actual device battery percentage  
✅ **Accurate Location**: GPS location with accuracy measurement  
✅ **Proper Timestamp**: Formatted as "yyyy-MM-dd HH:mm"  
✅ **Error Handling**: Continues logging even if individual API calls fail  
✅ **Debug Logging**: Detailed console logs for debugging  
✅ **User ID**: Automatically uses authenticated user ID  

## Debug Output

When running in debug mode, you'll see:
```
📍 Starting periodic location logging (every 2 seconds)...
📍 Location logged: (18.5204, 73.8567), Battery: 85%
📍 Location logged: (18.5205, 73.8568), Battery: 85%
...
```

## API Response Handling

- **Success (200-299)**: Location logged successfully
- **Error (400+)**: Error logged to console, continues logging
- **Network Error**: Caught and logged, continues logging

## Performance Considerations

- Timer runs every 2 seconds as requested
- Location updates use cached position when available
- Battery level updated before each API call
- No blocking operations - logging happens asynchronously
- Timer is properly disposed when provider is destroyed

## Testing

To test the implementation:

1. **Check Logs**: Look for "📍" emoji in console
2. **Battery**: Ensure battery percentage matches device
3. **Location**: Verify coordinates are accurate
4. **Timing**: Confirm logs appear every 2 seconds
5. **API**: Check API receives correct data format

## Notes

- Location permission must be granted for logging to work
- Battery permission is automatic on most devices
- Logging stops when app is closed
- Timer is automatically disposed when provider is destroyed
- Fallback user_id is 3 if no authenticated user found

