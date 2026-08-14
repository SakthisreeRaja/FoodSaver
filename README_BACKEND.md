# 🍎 FoodSaver - Complete Backend & Frontend Integration

**A comprehensive Flutter app with Firebase Cloud Functions backend for food donation management with real-time maps, location services, and push notifications.**

## ✨ Features Completed

### 🎯 Core Features
- ✅ Food donation listings with real-time updates
- ✅ Interactive map with donation markers
- ✅ Distance-based filtering (nearby donations)
- ✅ Category filtering (vegetables, fruits, grains, dairy, etc.)
- ✅ Pickup tracking with status updates
- ✅ Volunteer/NGO assignment system
- ✅ User ratings and reviews
- ✅ Push notifications (FCM)
- ✅ Real-time location tracking
- ✅ Comprehensive user profiles

### 🗺️ Map Features
- ✅ OpenStreetMap integration
- ✅ Custom markers for donations and locations
- ✅ Donation details on marker tap
- ✅ Color-coded status indicators
- ✅ User location tracking
- ✅ Radius-based filtering
- ✅ Multiple tile layer options

### 🔔 Notification System
- ✅ Push notifications via FCM
- ✅ In-app notification center
- ✅ Real-time notification streaming
- ✅ Event-based alerts (claimed, scheduled, completed)
- ✅ Notification management (read, delete)

### 👥 User Management
- ✅ Role-based access (Donor, NGO, Volunteer, Admin)
- ✅ User profiles with ratings
- ✅ Location-based search
- ✅ User reputation system
- ✅ Profile images support

### 📱 Technical Stack
- ✅ Flutter with Riverpod state management
- ✅ Firebase Authentication
- ✅ Firestore real-time database
- ✅ Cloud Functions (TypeScript)
- ✅ Firebase Cloud Messaging
- ✅ Geolocator for location services
- ✅ Flutter Map for interactive maps

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.5.0+
- Dart 3.5.0+
- Node.js 20+
- Firebase CLI
- Android Studio / Xcode

### Setup (Automated)

**On macOS/Linux:**
```bash
chmod +x setup.sh
./setup.sh
```

**On Windows:**
```bash
setup.bat
```

### Manual Setup

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Configure Firebase:**
   ```bash
   flutterfire configure
   ```

3. **Install backend dependencies:**
   ```bash
   cd backend/functions
   npm install
   cd ../..
   ```

4. **Update .env file:**
   ```env
   GEMINI_API_KEY=your_api_key_here
   ```

5. **Deploy backend:**
   ```bash
   cd backend/functions
   npm run build
   firebase deploy --only functions
   cd ../..
   ```

6. **Run app:**
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

```
foodsaver/
├── lib/
│   ├── core/
│   │   ├── services/              # Service layer
│   │   │   ├── donation_service.dart
│   │   │   ├── pickup_service.dart
│   │   │   ├── location_service.dart
│   │   │   ├── notification_service.dart
│   │   │   ├── user_service.dart
│   │   │   └── map_service.dart
│   │   ├── providers/              # Riverpod providers
│   │   │   └── service_providers.dart
│   │   ├── init/                   # App initialization
│   │   │   └── app_init.dart
│   │   ├── components/
│   │   ├── routing/
│   │   └── theme/
│   ├── features/
│   │   ├── donor/
│   │   │   └── screens/
│   │   │       └── donation_map_screen.dart
│   │   ├── volunteer/
│   │   │   └── screens/
│   │   │       └── pickup_map_screen.dart
│   │   ├── ngo/
│   │   ├── admin/
│   │   ├── auth/
│   │   ├── onboarding/
│   │   └── settings/
│   ├── models/
│   └── main.dart
├── backend/
│   └── functions/
│       ├── src/
│       │   ├── donations.ts        # Donation functions
│       │   ├── pickups.ts          # Pickup functions
│       │   ├── notifications.ts    # Notification services
│       │   ├── users.ts            # User management
│       │   ├── location.ts         # Location utilities
│       │   └── index.ts            # Entry point
│       ├── package.json
│       └── tsconfig.json
├── android/                        # Android native code
├── ios/                            # iOS native code
├── docs/
│   ├── INTEGRATION_GUIDE.md
│   ├── CONFIGURATION.md
│   ├── API_REFERENCE.md
│   └── COMPLETION_SUMMARY.md
├── pubspec.yaml
└── firebase.json
```

---

## 📚 Documentation

### Quick Reference
- **[COMPLETION_SUMMARY.md](COMPLETION_SUMMARY.md)** - What's been built
- **[INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)** - Setup and integration steps
- **[CONFIGURATION.md](CONFIGURATION.md)** - Platform-specific configuration
- **[API_REFERENCE.md](API_REFERENCE.md)** - Cloud Functions API documentation

### Key Sections
1. Backend Services Setup
2. Flutter Integration
3. Map Configuration
4. Location Services
5. Notification System
6. State Management
7. Security Rules
8. Deployment

---

## 🔧 Core Services

### DonationService
```dart
// Create donation
await donationService.createDonation(...)

// Get available donations
final donations = await donationService.getAvailableDonations(...)

// Claim donation
await donationService.claimDonation(...)

// Rate donation
await donationService.rateDonation(...)
```

### PickupService
```dart
// Schedule pickup
await pickupService.schedulePickup(...)

// Get pending pickups
final pickups = await pickupService.getPendingPickups()

// Update status
await pickupService.updatePickupStatus(...)
```

### LocationService
```dart
// Get current location
final position = await locationService.getCurrentLocation()

// Calculate distance
final distance = locationService.calculateDistance(...)

// Check if within radius
final isNear = locationService.isWithinRadius(...)
```

### NotificationService
```dart
// Initialize
await notificationService.initialize()

// Get notifications
final notifications = await notificationService.getNotifications()

// Stream notifications
notificationService.streamNotifications()
```

---

## 🗺️ Map Screens

### DonationMapScreen
Browse and claim food donations on an interactive map.

```dart
// Navigate to donations map
context.go('/donations-map');

// Features:
// - View all available donations as markers
// - Filter by distance (1-50 km)
// - Filter by category
// - View donation details
// - Claim donation from map
```

### PickupMapScreen
Track and manage pickups with real-time status updates.

```dart
// Navigate to pickups map
context.go('/pickups-map?userId=$userId&role=volunteer');

// Features:
// - View pending/scheduled pickups
// - Color-coded status indicators
// - Update pickup status
// - View pickup details
// - Rate completed pickups
```

---

## 🔔 Notifications

### Event Types
- `donation_claimed` - Someone claimed your donation
- `pickup_scheduled` - Pickup scheduled for a donation
- `pickup_completed` - Donation successfully delivered
- `donation_rated` - Someone rated your donation

### Setup FCM

1. Download FCM credentials from Firebase Console
2. Add to Android: `android/app/google-services.json`
3. Add to iOS: Configure in Xcode
4. Tokens automatically saved and synced

---

## 📍 Location Services

### Permissions Needed
- **Android**: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`
- **iOS**: `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysUsageDescription`

### Features
- Real-time location tracking
- Distance calculations between points
- Radius-based filtering
- Geofencing support
- Background location updates

---

## 🔐 Security

### Firebase Security Rules
```javascript
// Donations: Only owner can modify
allow update, delete: if request.auth.uid == resource.data.donorId;

// Pickups: Owner, NGO, or Volunteer can update
allow update: if request.auth.uid in [resource.data.volunteerId, 
                                        resource.data.ngoId, 
                                        resource.data.donorId];

// User data: Users can only access their own data
allow read, write: if request.auth.uid == user;
```

### Authentication
- Firebase Auth (Email/Phone)
- Token-based Cloud Function access
- Role-based access control

---

## 🎯 Usage Examples

### Donor: Post a Donation
```dart
final service = DonationService();
await service.createDonation(
  foodType: 'Vegetables',
  quantity: 5,
  unit: 'kg',
  description: 'Fresh vegetables from market',
  pickupLocation: 'Downtown Market',
  latitude: 28.6139,
  longitude: 77.2090,
  imageUrl: imageUrl,
);
```

### NGO: Claim Donation
```dart
await service.claimDonation(
  donationId: 'donation_123',
  ngoId: 'ngo_456',
);
```

### Volunteer: Track Pickup
```dart
final pickups = await pickupService.getPendingPickups();
// Navigate to PickupMapScreen to view on map
```

### Rate After Delivery
```dart
await service.rateDonation(
  donationId: 'donation_123',
  rating: 5,
  review: 'Great quality, fresh food!',
  reviewerType: 'ngo',
);
```

---

## 🧪 Testing

### Local Development
```bash
# Start Firebase Emulator
firebase emulators:start

# Run Flutter app with emulator
flutter run
```

### Test Cloud Functions
```bash
firebase functions:shell
> createDonation({foodType: 'Vegetables', ...})
```

### View Logs
```bash
firebase functions:log
```

---

## 📊 State Management

Using **Riverpod** for reactive state management:

```dart
// Watch a provider
final donations = ref.watch(
  availableDonationsProvider({
    'latitude': 28.6139,
    'longitude': 77.2090,
  })
);

// Listen for changes
ref.listen(pendingPickupsProvider, (prev, next) {
  // Handle updates
});

// Refresh data
ref.refresh(availableDonationsProvider({...}));
```

---

## 🚀 Deployment

### Deploy Backend Functions
```bash
cd backend/functions
npm run build
firebase deploy --only functions
```

### Deploy Security Rules
```bash
firebase deploy --only firestore:rules
```

### Build APK (Android)
```bash
flutter build apk --release
```

### Build iOS App
```bash
flutter build ios --release
```

---

## 📦 Dependencies

### Key Packages
- `flutter_map: ^6.0.0` - Interactive maps
- `firebase_functions: ^7.0.0` - Cloud functions
- `firebase_messaging: ^15.1.0` - Push notifications
- `geolocator: ^13.0.0` - Location services
- `riverpod: ^2.4.0` - State management
- `latlong2: ^0.9.1` - Geolocation utilities

### See `pubspec.yaml` for complete list

---

## 🐛 Troubleshooting

### Maps Not Loading
- Clear cache: `flutter clean`
- Rebuild: `flutter pub get`
- Check tile layer URL in production

### Location Permission Issues
- Grant permissions in app settings
- Check `Info.plist` (iOS) / `AndroidManifest.xml` (Android)
- Restart app after granting

### Notifications Not Working
- Verify FCM token saved in Firestore
- Check Firebase Cloud Messaging enabled
- Test on physical device (not emulator)

### Backend Errors
- Check Firebase Console → Functions → Logs
- Verify Firestore security rules
- Check internet connection
- Validate function parameters

---

## 📞 Support Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Riverpod Guide](https://riverpod.dev/)
- [Flutter Map Documentation](https://pub.dev/packages/flutter_map)
- [Geolocator Package](https://pub.dev/packages/geolocator)

---

## ✅ Verification Checklist

Before going live:
- [x] Backend Cloud Functions deployed
- [x] Firestore database configured
- [x] Security rules set
- [x] Location permissions configured
- [x] Firebase/Firestore initialized
- [x] Maps display correctly
- [x] Notifications working
- [x] State management configured
- [ ] User authentication tested
- [ ] All features tested end-to-end
- [ ] Performance optimized
- [ ] Analytics configured
- [ ] Terms of Service added
- [ ] Privacy Policy added

---

## 🎓 Learning Resources

### Architecture
- Services layer for business logic
- Riverpod for state management
- Firebase for backend
- Modular feature-based structure

### Best Practices
- Separate concerns with services
- Use providers for reactive updates
- Handle errors gracefully
- Implement proper logging
- Test core functionality

---

## 📝 License

FoodSaver - Food Donation Platform
Copyright © 2024

---

## 🤝 Contributing

To contribute to FoodSaver:
1. Follow the project structure
2. Use the service layer for API calls
3. Implement proper error handling
4. Add documentation
5. Test your changes

---

## 🎉 Getting Started

1. **Clone/Setup:** Run `./setup.sh` (macOS/Linux) or `setup.bat` (Windows)
2. **Configure:** Update `.env` with your API keys
3. **Deploy:** Deploy backend functions
4. **Run:** `flutter run`
5. **Test:** Navigate to `/donations-map` to see it in action

**Your complete FoodSaver backend and frontend integration is ready! 🚀**

For detailed setup instructions, see [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)

For API documentation, see [API_REFERENCE.md](API_REFERENCE.md)

For configuration details, see [CONFIGURATION.md](CONFIGURATION.md)
