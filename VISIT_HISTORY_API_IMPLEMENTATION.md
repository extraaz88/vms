# Visit History API Implementation

## Overview
This implementation fetches visit details history from the live API and displays it in the Visit History screen with detailed console logging.

## API Endpoint
```
GET https://live.extraaaz.com/api/visits/details/history/{userid}
```

## Implementation Details

### 1. API Service
**File**: `lib/services/api_service.dart`

Added `getVisitDetailsHistory()` method that:
- Fetches visit history for a specific user ID
- Handles multiple response formats (List, Map with data/visits/visit_details keys)
- Provides detailed console logging
- Converts raw data to `Visit` objects

### 2. Visit Provider
**File**: `lib/core/providers/visit_provider.dart`

Updated `loadVisits()` method to:
- Get authenticated user ID automatically
- Call the new API endpoint
- Display detailed console logs of all visits
- Update the UI with fetched data

### 3. Visit History Screen
**File**: `lib/screens/visits/visit_history_screen.dart`

Already configured to:
- Display visit history data
- Show visit details (place, person, area)
- Display photos if available
- Show location information
- Refresh data on pull-to-refresh

## Console Output

### When Loading Visit History:
```
📋 Loading visit history for user ID: 3

🔍 FETCHING VISIT DETAILS HISTORY:
[ApiService.VisitHistory] URL: https://live.extraaaz.com/api/visits/details/history/3
[ApiService.VisitHistory] User ID: 3
[ApiService.VisitHistory] Bearer Token: 26d9vCKPrU8725q0Iuf3...

📥 VISIT DETAILS HISTORY API RESPONSE:
[ApiService.VisitHistory] Status Code: 200
[ApiService.VisitHistory] Response Body: [{"id":1,"client_name":"...",...}]

✅ VISIT DETAILS HISTORY API SUCCESS:
═══════════════════════════════════════
[ApiService.VisitHistory] Visit History Count: 5
[ApiService.VisitHistory] Visit History Data: [...]
═══════════════════════════════════════

✅ Loaded 5 visits from history
═══════════════════════════════════════
VISIT HISTORY DATA:
Visit 1:
  - ID: 1
  - Client: ABC Company
  - Date: 2025-01-15 10:30:00.000
  - Status: Completed
  - Location: 18.5204, 73.8567
  - Visiting Place: Office Building
  - Visiting Person: John Doe
  - Visiting Area: Pune
---
Visit 2:
  - ID: 2
  - Client: XYZ Ltd
  - Date: 2025-01-14 14:15:00.000
  - Status: Active
  - Location: 19.0282, 73.0574
  ...
═══════════════════════════════════════
```

### Error Handling:
```
❌ VISIT DETAILS HISTORY API ERROR:
[ApiService.VisitHistory] Error: Connection failed
[ApiService.VisitHistory] Stack Trace: ...

❌ Failed to load visits: Connection failed
```

## Features

✅ **Real API Integration**: Connects to live API endpoint  
✅ **Auto User ID**: Automatically uses authenticated user ID  
✅ **Detailed Logging**: Console logs show all API requests and responses  
✅ **Data Display**: Shows all visit details on screen  
✅ **Error Handling**: Proper error messages for failures  
✅ **Pull to Refresh**: Swipe down to reload data  
✅ **Visit Details**: Shows place, person, area, photo, location  

## Data Fields Displayed

### On Screen:
- Client Name
- Visit Date & Time
- Visit Status (Active/Completed)
- Visiting Place
- Visiting Person  
- Visiting Area
- Photo (if available)
- Location (with geocoding)
- Notes

### In Console:
- Visit ID
- All above fields
- Latitude & Longitude
- Plus detailed API request/response logs

## How It Works

1. **App Opens**: Visit history screen loads
2. **Get User ID**: Retrieves authenticated user ID (defaults to 3)
3. **API Call**: Hits `https://live.extraaaz.com/api/visits/details/history/{userid}`
4. **Parse Response**: Handles different response formats
5. **Console Logs**: Prints detailed logs to console
6. **Display Data**: Shows visits in beautiful card layout
7. **Refresh**: Pull down to reload latest data

## Usage

### View Visit History:
1. Navigate to Visit History screen from menu
2. Data loads automatically
3. Pull down to refresh
4. Tap any visit card for detailed view

### Check Console Logs:
When running in debug mode:
```bash
flutter run
```

Look for these log markers:
- 📋 Loading visit history
- 🔍 API Request
- 📥 API Response
- ✅ Success messages
- ❌ Error messages

## API Response Formats Supported

### Format 1: Direct List
```json
[
  {
    "id": 1,
    "client_name": "ABC Company",
    "check_in_time": "2025-01-15T10:30:00",
    ...
  }
]
```

### Format 2: Wrapped in 'data'
```json
{
  "data": [
    {
      "id": 1,
      ...
    }
  ]
}
```

### Format 3: Wrapped in 'visits'
```json
{
  "visits": [
    {
      "id": 1,
      ...
    }
  ]
}
```

### Format 4: Wrapped in 'visit_details'
```json
{
  "visit_details": [
    {
      "id": 1,
      ...
    }
  ]
}
```

All formats are automatically handled!

## Testing

### Test the Implementation:
1. Run the app: `flutter run`
2. Login with valid credentials
3. Navigate to Visit History
4. Check console for detailed logs
5. Verify data displays on screen
6. Test pull-to-refresh

### Expected Console Output:
- API endpoint URL
- User ID being used
- Bearer token (first 20 chars)
- HTTP status code
- Full response body
- Parsed visit count
- All visit details
- Success/error status

## Troubleshooting

### No Data Showing:
- Check console logs for API response
- Verify user ID is correct
- Ensure API is returning data for that user
- Check bearer token is valid

### API Error:
- Check internet connection
- Verify API endpoint is accessible
- Check bearer token hasn't expired
- Look at error details in console

### Console Logs Not Showing:
- Run in debug mode: `flutter run`
- Enable verbose logging
- Check you're looking at the right terminal window

## Files Modified

1. **lib/services/api_service.dart**
   - Added `getVisitDetailsHistory()` method
   - Added comprehensive logging
   - Handles multiple response formats

2. **lib/core/providers/visit_provider.dart**
   - Updated `loadVisits()` to use new API
   - Added detailed console logging
   - Auto-fetch user ID from auth

3. **lib/screens/visits/visit_history_screen.dart**
   - Already properly configured
   - Displays all visit data
   - Shows visit details form info

## Notes

- User ID is automatically retrieved from authenticated session
- Default user ID is 3 if not found
- All logs are only shown in debug mode
- Data refreshes on screen navigation
- Pull-to-refresh available
- Detailed error messages for debugging

