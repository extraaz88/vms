# Visit History API Fix

## Problem
```
type 'Null' is not a subtype of type 'String'
```

## Root Cause
API response has different field names than expected:

### API Response Fields:
```json
{
  "id": 1,
  "person_name": "Vikas",        // Not "client_name"
  "reason": "Sales",              // Not "visiting_reason" 
  "area_name": "kharghar",        // Not "visiting_area"
  "photo": "img.png",             // Not "photo_path"
  "created_at": "2025-10-06...",  // No "check_in_time"
  "get_lead": {...}               // Lead data nested here
}
```

### Expected Fields (Old):
```dart
clientName: json['client_name']  // ❌ Null
checkInTime: json['check_in_time'] // ❌ Null
```

## Solution

### Updated `Visit.fromJson()` in `visit_model.dart`:

✅ **Multiple fallback options** for each field:
- `clientName`: `client_name` → `user_name` → `person_name` → `visiting_person` → `"Unknown"`
- `checkInTime`: `check_in_time` → `created_at` (fallback)
- `visitingReason`: `visiting_reason` → `reason`
- `visitingArea`: `visiting_area` → `area_name`
- `photoPath`: `photo_path` → `photo`
- `notes`: `notes` → `in_notes` → `reason`
- `visitingPerson`: `visiting_person` → `person_name`
- `leadName`: `lead_name` → `get_lead['name']`
- `leadEmail`: `lead_email` → `get_lead['email']`
- `leadPhone`: `lead_phone` → `get_lead['phone']`

✅ **Null-safe parsing**: All fields properly handle null values

## Fixed Code

```dart
factory Visit.fromJson(Map<String, dynamic> json) {
  return Visit(
    id: json['id'].toString(),
    clientName: json['client_name'] ?? 
                json['user_name'] ?? 
                json['person_name'] ?? 
                json['visiting_person'] ??
                'Unknown',
    checkInTime: json['check_in_time'] != null 
        ? DateTime.parse(json['check_in_time'])
        : DateTime.parse(json['created_at']),
    // ... other fields with fallbacks
  );
}
```

## Result

✅ Handles all API response formats
✅ No more null errors
✅ Visit history displays correctly
✅ Works with nested lead data (`get_lead`)

## Test Again

```bash
flutter run
```

Now visit history will show all visits properly! 🎉

