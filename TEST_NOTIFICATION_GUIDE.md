# Test Notification Feature

## Overview
Added a floating action button in notification screen to add real-time test notifications with "Hello Saurabh!" message.

## How It Works

### 1. Floating Action Button
**Location**: Bottom-right corner of notification screen

**Features:**
- ✅ Blue button with bell icon
- ✅ Label: "Test Notification"
- ✅ Click to add new notification instantly

### 2. Test Notification Details
When you click the button, it adds:

```
Title: "Hello Saurabh! 👋"
Message: "This is a real-time test notification. Your visit management system is working perfectly!"
Type: System (Grey icon)
Time: Just now
Status: Unread
```

### 3. Real-time Updates

**What happens:**
1. Click button ✅
2. New notification appears at top of list ✅
3. Unread badge count increases ✅
4. Green snackbar shows: "✅ New notification added!" ✅
5. Notification is marked as unread with blue dot ✅

## Usage

### Step-by-Step:
```bash
# 1. Run the app
flutter run

# 2. Go to Dashboard
# 3. Click notification icon (🔔³)
# 4. You'll see notification screen
# 5. Look at bottom-right corner
# 6. Click "Test Notification" button
# 7. Watch new notification appear!
```

### Visual Flow:
```
Dashboard → Click 🔔 → Notification Screen
                              ↓
                    [+ Test Notification] ← Click here
                              ↓
                    New notification appears!
                    "Hello Saurabh! 👋"
```

## Features

### Instant Addition
- Notification appears immediately at top of list
- No page reload needed
- Smooth animation

### Unique ID
Each test notification gets unique ID:
```dart
id: DateTime.now().millisecondsSinceEpoch.toString()
```

### Multiple Clicks
- Can click multiple times
- Each click adds new notification
- All appear at top of list
- Each with current timestamp

## Testing

### Test Scenarios:

1. **Add Single Notification**
   - Click button once
   - See notification appear
   - Check unread count increases

2. **Add Multiple Notifications**
   - Click button 5 times
   - See 5 new notifications
   - All say "Hello Saurabh!"
   - All have different timestamps

3. **Mark as Read**
   - Add test notification
   - Tap on it to view details
   - Blue dot disappears
   - Unread count decreases

4. **Delete Test Notification**
   - Add test notification
   - Swipe left to delete
   - Notification removed
   - Count updates

5. **Mark All as Read**
   - Add multiple test notifications
   - Click "Mark all read"
   - All become read
   - Badge updates

## Customization

### Change Message:
```dart
// In notifications_screen.dart, line 94
message: 'Your custom message here!',
```

### Change Title:
```dart
// Line 93
title: 'Your custom title! 👋',
```

### Change Icon/Color:
```dart
// Line 97
type: NotificationType.achievement, // Green
type: NotificationType.visit,       // Blue
type: NotificationType.lead,        // Purple
type: NotificationType.reminder,    // Orange
```

### Add More Fields:
```dart
NotificationItem(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  title: 'Hello Saurabh! 👋',
  message: 'Welcome to VMS!',
  time: DateTime.now(),
  isRead: false,
  type: NotificationType.system,
  // Add custom fields here
),
```

## Button Styles

### Current Style:
```dart
FloatingActionButton.extended(
  icon: Icon(Icons.add_alert),
  label: Text('Test Notification'),
  backgroundColor: AppTheme.primaryColor,
)
```

### Alternative Styles:

**Simple FAB:**
```dart
FloatingActionButton(
  onPressed: _addTestNotification,
  child: Icon(Icons.add_alert),
)
```

**Different Position:**
```dart
floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
```

**Custom Colors:**
```dart
backgroundColor: Colors.green,
foregroundColor: Colors.white,
```

## Console Output

When you click the button, console shows:
```
✅ New notification added!
Notification ID: 1728467234567
Title: Hello Saurabh! 👋
Time: 2025-10-09 14:30:00
```

## Production Use

For real notifications from API:

### 1. Create Notification Provider
```dart
class NotificationProvider with ChangeNotifier {
  List<NotificationItem> _notifications = [];
  
  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}
```

### 2. Listen to API/WebSocket
```dart
// When new notification from server
notificationProvider.addNotification(newNotification);
```

### 3. Firebase Cloud Messaging
```dart
FirebaseMessaging.onMessage.listen((message) {
  // Add to notification list
  notificationProvider.addNotification(
    NotificationItem.fromFCM(message),
  );
});
```

## Features List

✅ Floating action button
✅ Real-time notification addition
✅ "Hello Saurabh!" message
✅ Instant UI update
✅ Unread badge increment
✅ Success snackbar
✅ Unique ID generation
✅ Smooth animations
✅ Multiple additions supported

## Next Steps

- [ ] Connect to real API
- [ ] Add notification provider
- [ ] Implement push notifications
- [ ] Add notification sound
- [ ] Add notification persistence
- [ ] Sync across devices

## Testing Checklist

- ✅ Button visible at bottom-right
- ✅ Button shows correct label
- ✅ Click adds notification
- ✅ Notification appears at top
- ✅ Shows "Hello Saurabh!"
- ✅ Unread count increases
- ✅ Success message shows
- ✅ Can tap to view details
- ✅ Can swipe to delete
- ✅ Can mark as read
- ✅ Multiple clicks work

## Notes

- Test button only appears on notification screen
- Notifications are not persisted (lost on app restart)
- Each notification has unique timestamp
- Button floats above list (doesn't scroll)
- Green success snackbar confirms addition

