# Local Notification Implementation Guide

## Overview
Implemented **flutter_local_notifications** package to send system notifications to phone's notification bar with app logo, sound, and vibration - even when app is closed/minimized.

## Features Implemented ✅

### 1. Phone System Notifications
- ✅ Shows in phone's notification bar
- ✅ Works when app is closed/minimized
- ✅ App logo displayed
- ✅ Notification sound plays
- ✅ Phone vibrates
- ✅ Tap notification to open app

### 2. Notification Buttons
Two buttons added to notification screen:

#### Green Button: "Phone Notification" 📱
- Sends notification to phone system
- Shows in notification bar
- With sound + vibration
- App logo visible
- Works even when app closed

#### Blue Button: "In-App Only" 📲
- Only adds to in-app notification list
- No system notification
- No sound/vibration
- For testing UI only

## Setup Steps Done

### 1. Package Added ✅
```yaml
# pubspec.yaml
flutter_local_notifications: ^17.2.3
```

### 2. Android Permissions ✅
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### 3. Notification Service Created ✅
**File**: `lib/services/local_notification_service.dart`

Features:
- Initialize notifications
- Request permissions (Android 13+)
- Show notifications with app logo
- Handle notification taps
- Multiple notification types

### 4. Initialized in Main ✅
```dart
// main.dart
await LocalNotificationService().initialize();
```

### 5. Buttons Added ✅
Two floating action buttons in notification screen.

## How to Use

### Step-by-Step Testing:

```bash
# 1. Install package
flutter pub get

# 2. Run app (fresh build recommended)
flutter run

# 3. Navigate to notifications
Dashboard → Click 🔔 icon

# 4. Click GREEN button "Phone Notification"
Bottom-right corner

# 5. Check phone notification bar ⬇️
Swipe down from top of phone

# 6. You'll see:
📱 "Hello Saurabh! 👋"
   "Your VMS app is working perfectly!..."
   [VMS App Logo]
```

### What You'll See:

**In Phone Notification Bar:**
```
┌────────────────────────────────┐
│ 🖼️ [VMS Logo]                  │
│                                │
│ Hello Saurabh! 👋             │
│ Your VMS app is working        │
│ perfectly! Notification        │
│ system is active.              │
│                                │
│ Just now                       │
└────────────────────────────────┘
```

**Features:**
- 🔔 Notification sound plays
- 📳 Phone vibrates
- 🖼️ App logo shows
- ⏰ Timestamp displayed
- 👆 Tap to open app

## Notification Types

Service supports multiple types:

### 1. Saurabh Greeting (Current)
```dart
LocalNotificationService().showSaurabhNotification();
```

### 2. Visit Notification
```dart
LocalNotificationService().showVisitNotification(
  title: 'New Visit Assigned',
  message: 'You have a visit to ABC Company',
);
```

### 3. Lead Notification
```dart
LocalNotificationService().showLeadNotification(
  title: 'Lead Updated',
  message: 'Lead "John" has been updated',
);
```

### 4. Reminder Notification
```dart
LocalNotificationService().showReminderNotification(
  title: 'Check-in Reminder',
  message: 'Don\'t forget to check-in',
);
```

### 5. Custom Notification
```dart
LocalNotificationService().showNotification(
  id: 123,
  title: 'Your Title',
  body: 'Your Message',
  payload: 'custom_data',
);
```

## Testing Scenarios

### 1. App Open
- Click green button
- Notification appears in bar
- Sound plays
- Vibration
- In-app list updates

### 2. App Minimized
- Minimize app (Home button)
- Click green button before minimizing
- Or schedule notification
- Notification shows even when minimized
- Tap notification to open app

### 3. App Closed
- Close app completely
- Notification persists in bar
- Can tap to reopen app

### 4. Multiple Notifications
- Click button multiple times
- Each creates new notification
- All visible in notification bar
- Each has unique ID

## Configuration

### Change App Icon
Update `@mipmap/launcher_icon` in:
```dart
// local_notification_service.dart
icon: '@mipmap/launcher_icon',
```

### Change Sound/Vibration
```dart
const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
  'vms_channel',
  'VMS Notifications',
  importance: Importance.high,     // Change priority
  priority: Priority.high,
  enableVibration: true,           // Enable/disable vibration
  playSound: true,                 // Enable/disable sound
  // Add custom sound:
  // sound: RawResourceAndroidNotificationSound('notification'),
);
```

### Channel Settings
```dart
channelId: 'vms_channel',          // Unique channel ID
channelName: 'VMS Notifications',  // Name shown in settings
channelDescription: 'Notifications for Visit Management System',
```

## Permissions

### Android 13+ (API 33+)
Auto-requests permission on first notification.

User will see:
```
Allow VMS to send notifications?
[Allow] [Don't Allow]
```

### Manual Permission Request
```dart
await LocalNotificationService()._requestPermissions();
```

## Files Created/Modified

### Created:
1. ✅ `lib/services/local_notification_service.dart` - Service class

### Modified:
1. ✅ `pubspec.yaml` - Added package
2. ✅ `android/app/src/main/AndroidManifest.xml` - Added permissions
3. ✅ `lib/main.dart` - Initialize service
4. ✅ `lib/screens/notifications/notifications_screen.dart` - Added buttons

## Console Output

When notification sent:
```
✅ Local Notifications initialized successfully

📬 Notification sent:
   ID: 1728467890
   Title: Hello Saurabh! 👋
   Body: Your VMS app is working perfectly! Notification system is active.
```

## Troubleshooting

### Notification Not Showing?

1. **Check Permissions**
   - Go to: Settings → Apps → VMS → Notifications
   - Ensure "All VMS notifications" is ON

2. **Check Do Not Disturb**
   - Disable DND mode temporarily
   - Or allow VMS to override DND

3. **Rebuild App**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **Check Android Version**
   - Android 13+ requires explicit permission
   - App will auto-request on first notification

5. **Check Console Logs**
   - Look for initialization message
   - Check for errors

### Sound Not Playing?

1. Check phone volume
2. Check notification channel settings
3. Verify DND mode is off
4. Check app notification settings

### App Logo Not Showing?

1. Ensure `launcher_icon` exists in `android/app/src/main/res/mipmap-*/`
2. Rebuild app after icon changes
3. Clear app data and reinstall

## Production Usage

### Background Notifications
For receiving from server:
```dart
// When API sends notification
final notificationData = apiResponse['notification'];
LocalNotificationService().showNotification(
  id: notificationData['id'],
  title: notificationData['title'],
  body: notificationData['message'],
);
```

### Scheduled Notifications
```dart
// Coming soon - requires timezone package
LocalNotificationService().scheduleNotification(
  id: 1,
  title: 'Daily Reminder',
  body: 'Check your visits',
  scheduledTime: DateTime(2025, 10, 10, 9, 0),
);
```

### With Firebase Cloud Messaging
```dart
// lib/services/fcm_service.dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Show local notification when FCM received
  LocalNotificationService().showNotification(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: message.notification?.title ?? 'New Message',
    body: message.notification?.body ?? '',
  );
});
```

## Advanced Features

### Notification Actions
Add action buttons to notifications:
```dart
actions: <AndroidNotificationAction>[
  AndroidNotificationAction(
    'view',
    'View',
    showsUserInterface: true,
  ),
  AndroidNotificationAction(
    'dismiss',
    'Dismiss',
  ),
],
```

### Big Picture
Show image in notification:
```dart
styleInformation: BigPictureStyleInformation(
  FilePathAndroidBitmap('path/to/image.jpg'),
),
```

### Progress Bar
Show download/upload progress:
```dart
showProgress: true,
maxProgress: 100,
progress: 45,
```

## Testing Checklist

- ✅ Green button visible
- ✅ Click sends notification
- ✅ Notification appears in phone bar
- ✅ Sound plays
- ✅ Phone vibrates
- ✅ App logo visible
- ✅ Title: "Hello Saurabh! 👋"
- ✅ Message shows correctly
- ✅ Tap opens app
- ✅ Works when app minimized
- ✅ Works when app closed
- ✅ Multiple notifications work
- ✅ In-app list also updates

## Next Steps

- [ ] Integrate with real API
- [ ] Add notification categories
- [ ] Scheduled notifications
- [ ] Firebase Cloud Messaging
- [ ] Custom notification sounds
- [ ] Notification grouping
- [ ] Inbox style notifications
- [ ] Notification analytics

## Notes

- Notifications persist even after app closes
- Each notification has unique ID
- Tap notification to open app
- Swipe to dismiss from notification bar
- Settings accessible from phone Settings app
- Channel name shows in notification settings

## Support

Package: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
Version: 17.2.3

