# Notification Sound & Vibration Fix

## Problem
Notification aa raha hai but sound aur vibration nahi aa raha.

## Solution Applied ✅

### Changes Made:

1. **Notification Channel Created** with max importance
2. **Sound enabled** in channel
3. **Vibration enabled** in channel
4. **LED lights enabled**
5. **Priority set to MAX**

### Code Updated:
- Created dedicated notification channel
- Importance: `Importance.max` (highest)
- Priority: `Priority.max` (highest)
- Sound: ✅ Enabled
- Vibration: ✅ Enabled

## How to Test

### Step 1: Uninstall & Reinstall App (Important!)
```bash
# Uninstall app from phone first
# This clears old notification channel settings

# Then run fresh:
flutter clean
flutter pub get
flutter run
```

**Why Uninstall?**
- Old notification channel settings are cached
- New settings won't apply to existing channel
- Fresh install creates new channel with correct settings

### Step 2: Check Phone Settings

#### After Fresh Install:
1. Open phone **Settings**
2. Go to **Apps** → **VMS**
3. Tap **Notifications**
4. Find **"VMS Notifications"** channel
5. Ensure these are ON:
   - ✅ Show notifications
   - ✅ Sound
   - ✅ Vibrate
   - ✅ Pop on screen

#### Visual Guide:
```
Settings → Apps → VMS → Notifications
┌────────────────────────────────┐
│ VMS Notifications              │
│ ✅ Show notifications          │
│ ✅ Sound                       │
│ ✅ Vibrate                     │
│ ✅ Pop on screen               │
│ ✅ Show badge                  │
└────────────────────────────────┘
```

### Step 3: Check Phone Volume

1. **Ring Volume** should be up (not silent)
2. **Do Not Disturb** should be OFF
3. **Silent Mode** should be OFF

### Step 4: Test Notification

```bash
# Run app
flutter run

# Go to: Dashboard → Notifications
# Click: Green "Phone Notification" button
# You should hear: Sound + Feel: Vibration
```

## Troubleshooting

### Sound Still Not Playing?

#### 1. Check Ring Volume
```
- Press Volume Up button
- Ensure ring volume (not media volume) is up
- Try maximum volume for testing
```

#### 2. Disable Do Not Disturb
```
Settings → Sound → Do Not Disturb
- Turn OFF
- Or add VMS to exceptions
```

#### 3. Check Sound Settings
```
Settings → Apps → VMS → Notifications → VMS Notifications
- Tap on channel
- Sound: Should be "Default notification sound"
- If "None" - select a sound
```

#### 4. Reset App Notification Settings
```
Settings → Apps → VMS → Notifications
- Tap "⋮" (three dots)
- Reset to default
- Or uninstall/reinstall app
```

### Vibration Not Working?

#### 1. Check Phone Settings
```
Settings → Sound
- Vibrate for calls: ON
- Touch vibration: ON
```

#### 2. Check VMS Notification Channel
```
Settings → Apps → VMS → Notifications → VMS Notifications
- Vibration: ON
```

#### 3. Test Phone Vibration
```
Settings → Sound → Vibration intensity
- Test to ensure vibration motor works
```

### Still No Sound/Vibration?

#### Try This:
```bash
# 1. Completely uninstall app
adb uninstall com.extraaaz.vms

# OR manually uninstall from phone

# 2. Clean everything
flutter clean

# 3. Fresh install
flutter run
```

## Phone-Specific Issues

### Samsung Phones:
```
Settings → Notifications → App settings → VMS
- Set priority to "High"
- Allow to override Do Not Disturb
```

### Xiaomi/MIUI:
```
Settings → Apps → Manage apps → VMS → Notifications
- Enable "Show notifications"
- Set priority to "Urgent"
```

### OnePlus/OxygenOS:
```
Settings → Apps → VMS → Notifications
- Allow notification dot
- Enable vibration
```

### Stock Android:
```
Settings → Apps → VMS → Notifications
- Select channel
- Ensure sound & vibration enabled
```

## Console Verification

After running app, check console for:
```
✅ Local Notifications initialized successfully
📢 Notification channel created with sound & vibration
```

If you see these, service is configured correctly.

## Testing Commands

### Fresh Install Test:
```bash
# 1. Uninstall
flutter clean

# 2. Run
flutter run

# 3. Test
# Go to notification screen
# Click green button
# Should hear sound + feel vibration
```

### Quick Test:
```bash
# If already installed, just run
flutter run

# Test notification
# If no sound/vibration, uninstall and try fresh install
```

## What Changed in Code

### Before:
```dart
importance: Importance.high,
priority: Priority.high,
```

### After:
```dart
importance: Importance.max,  // Maximum priority
priority: Priority.max,      // Maximum priority
enableVibration: true,       // Explicit vibration
playSound: true,             // Explicit sound
enableLights: true,          // LED notification
```

### Plus Added:
```dart
// Dedicated notification channel creation
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'vms_channel',
  'VMS Notifications',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  enableLights: true,
);
```

## Expected Behavior

When clicking "Phone Notification" button:

1. ✅ Notification appears in notification bar
2. ✅ **Sound plays** (default notification sound)
3. ✅ **Phone vibrates** (short vibration)
4. ✅ LED light blinks (if phone has LED)
5. ✅ App logo visible
6. ✅ "Hello Saurabh!" message

## Important Notes

⚠️ **Must uninstall & reinstall** for sound/vibration settings to apply to existing channel

⚠️ **Ring volume** must be up (not media volume)

⚠️ **Do Not Disturb** must be OFF or VMS must be in exceptions

⚠️ **Battery saver** might block sounds - disable for testing

## Files Modified

1. ✅ `lib/services/local_notification_service.dart`
   - Added notification channel creation
   - Set importance to max
   - Enabled sound & vibration explicitly
   - Added LED notification

## Verification Checklist

- ✅ App uninstalled & reinstalled
- ✅ Console shows channel creation message
- ✅ Phone volume is up
- ✅ Do Not Disturb is OFF
- ✅ VMS notification settings show sound ON
- ✅ VMS notification settings show vibrate ON
- ✅ Green button clicked
- ✅ Sound plays
- ✅ Phone vibrates

## Debug Mode

To see detailed logs:
```dart
// In local_notification_service.dart
// Check for these prints:
print('📢 Notification channel created with sound & vibration');
print('📬 Notification sent:');
```

## Success Indicators

When working correctly:
- 🔔 Sound plays immediately
- 📳 Phone vibrates
- 📬 Notification appears
- 💡 LED blinks (if available)

---

**Status**: ✅ Fixed in code
**Action Required**: Uninstall app → Clean → Reinstall → Test
**Expected Result**: Sound + Vibration work

