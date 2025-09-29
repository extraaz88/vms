# Mock Data Guide - VMS App

## 🎯 Mock Data System

यह VMS app में mock data system implement किया गया है जो API के बिना भी पूरी functionality test करने की सुविधा देता है।

## 🔑 Demo Credentials

```
Email: कोई भी email (जैसे: test@example.com)
Password: कोई भी password (जैसे: 123, abc, etc.)
```

## 📱 Features Available with Mock Data

### ✅ Authentication
- Login with demo credentials
- User session management
- Token-based authentication simulation

### ✅ Visit Management
- Field visit check-in/check-out
- Visit history tracking
- Client information management
- Visit notes and status

### ✅ Location Tracking
- GPS location logging
- Journey path tracking
- Live location updates
- Location accuracy monitoring

### ✅ Dashboard & Analytics
- Real-time statistics
- Visit summaries
- Location tracking status
- Performance metrics

## 🛠 How to Use

### 1. Login
1. App launch करें
2. Login screen पर जाएं
3. कोई भी credentials use करें:
   - **Email**: कोई भी email (जैसे: `test@example.com`, `user@gmail.com`, `demo@test.com`)
   - **Password**: कोई भी password (जैसे: `123`, `abc`, `password`, `test`)
4. Login button press करें

**Example Login:**
```
Email: myemail@gmail.com
Password: mypassword123
```
✅ **Result**: Login successful!

### 2. Test Features
1. Dashboard से सभी features access करें
2. Visit check-in/check-out test करें
3. Journey tracking देखें
4. Live tracking functionality test करें

### 3. Mock Data Test Screen
1. Dashboard के top-right में bug icon press करें
2. Mock Data Test screen खुलेगा
3. Different tests run करें:
   - Authentication Test
   - Visit Management Test
   - Location Tracking Test

## 📊 Sample Data Included

### Users
- **Saurabh Vishwakarma** (saurabish@gmail.com) - Field Executive
- **Priya Patel** (priya@example.com) - Manager
- **Rahul Singh** (rahul@example.com) - Field Executive

### Sample Visits
- ABC Retail Store (Completed)
- XYZ Corporation (Active)

### Sample Locations
- Delhi locations with realistic coordinates
- Different timestamps
- Accuracy and battery data

## 🔄 Switching to Real API

Real API use करने के लिए `lib/services/api_service.dart` में:

```dart
static bool _useMockData = false; // Change to false
```

और API base URL update करें:
```dart
static const String baseUrl = 'https://your-api-domain.com/api';
```

## 📁 Mock Data Storage

Mock data SharedPreferences में store होता है:
- `mock_users` - User data
- `mock_visits` - Visit history
- `mock_locations` - Location logs
- `current_user` - Active user session

## 🧪 Testing Commands

### Clear All Mock Data
```dart
await MockDataService.clearAllMockData();
```

### Add Sample Data
```dart
await MockDataService.addSampleData();
```

### Get Current User
```dart
User? user = await MockDataService.getCurrentUser();
```

## 🎨 UI Features

### Login Screen
- Beautiful gradient design
- Form validation
- Demo credentials display
- Loading states

### Dashboard
- Real-time visit status
- Quick action cards
- Statistics overview
- Mock data test button

### Visit Management
- GPS location integration
- Client information forms
- Check-in/check-out workflow
- Visit history display

### Journey Tracking
- Historical location data
- Distance calculations
- Interactive timeline
- Location accuracy display

### Live Tracking
- Team member locations
- Real-time updates
- Status indicators
- Location details

## 🔧 Technical Details

### Data Models
- **User**: Name, email, role, phone
- **Visit**: Client, timing, location, notes
- **LocationLog**: Coordinates, accuracy, battery, timestamp

### Storage
- SharedPreferences for persistence
- JSON serialization
- Automatic data cleanup
- Error handling

### Performance
- Fast local data access
- Minimal memory usage
- Efficient data structures
- Background processing simulation

## 🚀 Benefits

1. **No API Dependency**: App works without backend
2. **Quick Testing**: Immediate functionality testing
3. **Offline Support**: Works without internet
4. **Demo Ready**: Perfect for demonstrations
5. **Development Friendly**: Easy to modify and extend

## 📝 Notes

- Mock data automatically initializes on app start
- Sample data is added for testing
- All features work exactly like real API
- Data persists between app sessions
- Easy to switch between mock and real API

## 🎯 Next Steps

1. **Test All Features**: Complete app workflow test करें
2. **Customize Data**: अपने requirements के अनुसार mock data modify करें
3. **API Integration**: Real API ready होने पर switch करें
4. **Production Deploy**: Mock data को disable करके production में deploy करें

---

**Happy Testing! 🎉**
