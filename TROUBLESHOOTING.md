# Troubleshooting Guide

## Build Issues

### 1. Kotlin Compilation Error (workmanager)
**Error**: `Execution failed for task ':workmanager:compileDebugKotlin'`

**Solution**: 
- The `workmanager` package has been removed from `pubspec.yaml` due to compatibility issues
- Background location tracking is now handled by the app's location provider
- Run `flutter clean` and `flutter pub get` to refresh dependencies

### 2. Gradle Build Failed
**Error**: `BUILD FAILED in Xm Xs`

**Solutions**:
```bash
# Clean the project
flutter clean

# Get fresh dependencies
flutter pub get

# Clean Gradle cache
cd android
./gradlew clean
cd ..

# Try building again
flutter build apk --debug
```

### 3. Location Permission Issues
**Error**: Location services not working

**Solutions**:
- Ensure permissions are added to `android/app/src/main/AndroidManifest.xml`
- Check that location permissions are granted on the device
- Test on a physical device (emulator may have location issues)

### 4. API Connection Issues
**Error**: Network requests failing

**Solutions**:
- Update the API base URL in `lib/services/api_service.dart`
- Check internet connection
- Ensure Laravel backend is running
- Verify API endpoints match the expected format

## Common Solutions

### Clean Build Process
```bash
# 1. Clean Flutter
flutter clean

# 2. Clean Android
cd android && ./gradlew clean && cd ..

# 3. Get dependencies
flutter pub get

# 4. Build
flutter build apk --debug
```

### Dependency Issues
If you encounter dependency conflicts:

1. **Remove problematic packages** from `pubspec.yaml`
2. **Use compatible versions** (check pub.dev for version compatibility)
3. **Run `flutter pub deps`** to check dependency tree
4. **Use `flutter pub upgrade`** to update packages

### Android-Specific Issues

#### Gradle Version
Ensure your `android/gradle/wrapper/gradle-wrapper.properties` has:
```
distributionUrl=https\://services.gradle.org/distributions/gradle-7.5-all.zip
```

#### SDK Versions
In `android/app/build.gradle.kts`:
```kotlin
minSdk = 21
targetSdk = 34
compileSdk = 34
```

### iOS-Specific Issues

#### Podfile
If building for iOS, ensure `ios/Podfile` has:
```ruby
platform :ios, '12.0'
```

#### Permissions
Add location permissions to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access for field visit tracking</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access for field visit tracking</string>
```

## Testing the App

### 1. Basic Functionality Test
- Launch the app
- Check splash screen animation
- Try login with demo credentials
- Navigate through different screens

### 2. Location Services Test
- Grant location permissions
- Test check-in functionality
- Verify location coordinates are captured
- Test journey tracking

### 3. API Integration Test
- Ensure backend is running
- Update API URL in the service
- Test login functionality
- Test visit check-in/check-out

## Performance Optimization

### 1. Reduce APK Size
```bash
flutter build apk --split-per-abi
```

### 2. Enable R8/Proguard (Release)
In `android/app/build.gradle.kts`:
```kotlin
buildTypes {
    release {
        isMinifyEnabled = true
        proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
    }
}
```

### 3. Optimize Images
- Use WebP format for images
- Compress images before adding to assets
- Use appropriate image sizes

## Debug Mode

### Enable Debug Logging
Add to your main.dart:
```dart
import 'dart:developer' as developer;

void main() {
  developer.log('App started', name: 'VMS_DEBUG');
  runApp(VMSApp(prefs: prefs));
}
```

### Check Location Services
```dart
// Add to location provider
void _debugLocationInfo(Position position) {
  developer.log('Location: ${position.latitude}, ${position.longitude}', name: 'LOCATION');
  developer.log('Accuracy: ${position.accuracy}m', name: 'LOCATION');
}
```

## Getting Help

### 1. Check Flutter Doctor
```bash
flutter doctor -v
```

### 2. Check Dependencies
```bash
flutter pub deps
```

### 3. Clean Everything
```bash
flutter clean
rm -rf android/build
rm -rf ios/build
flutter pub get
```

### 4. Rebuild
```bash
flutter build apk --debug
```

## Common Error Messages and Solutions

| Error | Solution |
|-------|----------|
| `Gradle build failed` | Clean project and rebuild |
| `Location permission denied` | Check manifest permissions |
| `API connection failed` | Verify backend URL and network |
| `Package not found` | Run `flutter pub get` |
| `Kotlin compilation error` | Update Kotlin version or remove problematic packages |
| `Android SDK not found` | Install Android SDK and set ANDROID_HOME |

## Version Compatibility

### Flutter Version
- **Minimum**: Flutter 3.8.1
- **Recommended**: Flutter 3.16.0+

### Dart Version
- **Minimum**: Dart 3.0.0
- **Recommended**: Dart 3.2.0+

### Android
- **Minimum SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Compile SDK**: 34

### iOS
- **Minimum**: iOS 12.0
- **Recommended**: iOS 15.0+
