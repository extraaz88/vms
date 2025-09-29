# VMS - Field Visit Tracker

A comprehensive Flutter application for field visit tracking and journey monitoring with real-time location tracking capabilities.

## Features

### 🔐 Authentication
- Token-based authentication with Laravel Sanctum/JWT
- Secure login with email/password validation
- Persistent session management

### 📍 Location Tracking
- Real-time GPS location tracking
- Background location monitoring
- Location accuracy and battery level tracking
- Journey path visualization

### 🏢 Visit Management
- Field visit check-in/check-out functionality
- Client information management
- Visit notes and status tracking
- Visit history and analytics

### 📊 Dashboard & Analytics
- Real-time dashboard with visit statistics
- Journey tracking with distance calculation
- Live team location monitoring
- Visit duration and performance metrics

### 🎨 Modern UI/UX
- Beautiful Material Design 3 interface
- Smooth animations and transitions
- Responsive design for all screen sizes
- Dark/light theme support

## Technical Architecture

### State Management
- **Provider Pattern**: Centralized state management
- **AuthProvider**: User authentication and session management
- **LocationProvider**: GPS tracking and location services
- **VisitProvider**: Visit management and history

### API Integration
- RESTful API communication with Laravel backend
- Token-based authentication
- Offline data storage with sync capabilities
- Error handling and retry mechanisms

### Location Services
- GPS tracking with configurable intervals
- Background location monitoring
- Location permission handling
- Battery optimization

## Project Structure

```
lib/
├── core/
│   ├── providers/          # State management providers
│   ├── router/            # Navigation routing
│   └── theme/             # App theming and colors
├── models/                # Data models
├── screens/               # UI screens
│   ├── auth/             # Authentication screens
│   ├── home/             # Dashboard and main screens
│   ├── visits/           # Visit management screens
│   ├── tracking/         # Location tracking screens
│   └── profile/          # User profile screens
├── services/             # API and external services
└── widgets/              # Reusable UI components
```

## API Endpoints

### Authentication
- `POST /api/login` - User login
- `PUT /api/profile` - Update user profile

### Visit Management
- `POST /api/visits/checkin` - Check-in to a visit
- `POST /api/visits/{id}/checkout` - Check-out from a visit
- `GET /api/visits` - Get visit history
- `PUT /api/visits/{id}` - Update visit notes

### Location Tracking
- `POST /api/location/log` - Log location data
- `GET /api/location/journey` - Get journey data
- `GET /api/location/live` - Get live tracking data

## Getting Started

### Prerequisites
- Flutter SDK (>=3.8.1)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Laravel backend API

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd vms
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   Update the base URL in `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'https://your-api-domain.com/api';
   ```

4. **Configure permissions**
   Update Android permissions in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## Configuration

### Location Tracking Settings
- **Tracking Interval**: 1-5 minutes (configurable)
- **Distance Filter**: 10 meters minimum
- **Background Tracking**: Enabled
- **Battery Optimization**: Automatic

### API Configuration
- **Authentication**: Bearer Token
- **Content-Type**: application/json
- **Timeout**: 30 seconds
- **Retry Logic**: 3 attempts

## Features in Detail

### 🚀 Splash Screen
- Animated logo and loading indicators
- Authentication state initialization
- Smooth transition to main app

### 🔐 Login Screen
- Email/password validation
- Demo credentials support
- Loading states and error handling
- Beautiful gradient design

### 📊 Dashboard
- Real-time visit status
- Quick action cards
- Statistics overview
- Recent activity feed

### 📍 Visit Check-in
- GPS location acquisition
- Client information form
- Notes and additional details
- Real-time location display

### 📍 Visit Check-out
- Visit duration calculation
- Check-out notes
- Visit summary display
- Completion confirmation

### 🗺️ Journey Tracking
- Historical location data
- Distance calculation
- Time-based filtering
- Interactive timeline

### 👥 Live Tracking
- Real-time team locations
- Status indicators (Online/Away/Offline)
- Location details modal
- Refresh functionality

### 👤 Profile Management
- User information display
- Settings and preferences
- App version information
- Logout functionality

## Dependencies

### Core Dependencies
- `flutter`: Flutter SDK
- `provider`: State management
- `go_router`: Navigation routing
- `http`: HTTP client
- `dio`: Advanced HTTP client

### Location & Maps
- `geolocator`: GPS location services
- `geocoding`: Address geocoding
- `google_maps_flutter`: Maps integration
- `permission_handler`: Permission management

### Storage & Utilities
- `shared_preferences`: Local storage
- `sqflite`: Local database
- `intl`: Internationalization
- `uuid`: Unique identifiers

### UI & Animations
- `flutter_animate`: Animation library
- `lottie`: Lottie animations
- `flutter_svg`: SVG support

### Background Tasks
- `workmanager`: Background processing

## Backend Requirements

### Laravel API Endpoints
The Flutter app expects the following Laravel API structure:

```php
// Authentication
Route::post('/login', [AuthController::class, 'login']);

// Visit Management
Route::post('/visits/checkin', [VisitController::class, 'checkin']);
Route::post('/visits/{id}/checkout', [VisitController::class, 'checkout']);
Route::get('/visits', [VisitController::class, 'index']);

// Location Tracking
Route::post('/location/log', [LocationController::class, 'log']);
Route::get('/location/journey', [LocationController::class, 'journey']);
Route::get('/location/live', [LocationController::class, 'live']);
```

### Database Schema
```sql
-- Users table
CREATE TABLE users (
    id BIGINT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    role VARCHAR(50),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Visits table
CREATE TABLE visits (
    id BIGINT PRIMARY KEY,
    user_id BIGINT,
    client_name VARCHAR(255),
    check_in_time TIMESTAMP,
    check_out_time TIMESTAMP,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    notes TEXT,
    status VARCHAR(50),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Location logs table
CREATE TABLE location_logs (
    id BIGINT PRIMARY KEY,
    user_id BIGINT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    accuracy DECIMAL(8,2),
    battery INT,
    logged_at TIMESTAMP,
    created_at TIMESTAMP
);
```

## Security Considerations

- **Token Security**: Bearer tokens stored securely
- **Location Privacy**: User consent for location tracking
- **Data Encryption**: Sensitive data encrypted in transit
- **Permission Management**: Granular permission requests
- **Offline Security**: Local data protection

## Performance Optimizations

- **Location Batching**: Efficient location data collection
- **Background Processing**: Optimized background tasks
- **Memory Management**: Proper widget disposal
- **Image Caching**: Optimized image loading
- **Database Indexing**: Fast query performance

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

## Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## Version History

- **v1.0.0** - Initial release with core functionality
  - Authentication system
  - Visit management
  - Location tracking
  - Dashboard and analytics

---

**Built with ❤️ using Flutter**