# FoodSaver Backend & Flutter Integration Guide

## 📦 Complete Setup Instructions

### Part 1: Backend Setup (Firebase Cloud Functions)

#### 1. Deploy Cloud Functions

```bash
cd backend/functions
npm install
npm run build
firebase deploy --only functions
```

#### 2. Environment Variables

Create a `.env.local` file in `backend/functions`:

```env
# Optional: Add any required API keys
```

#### 3. Firestore Security Rules

Deploy security rules:

```bash
firebase deploy --only firestore:rules
```

### Part 2: Flutter App Integration

#### 1. Install Dependencies

```bash
flutter pub get
```

#### 2. Android Setup

**android/app/build.gradle:**
```gradle
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}

dependencies {
    // Google Play Services for Maps
    implementation 'com.google.android.gms:play-services-maps:18.2.0'
    implementation 'com.google.android.gms:play-services-location:21.1.0'
}
```

#### 3. iOS Setup

**ios/Podfile:**
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_LOCATION=1'
      ]
    end
  end
end
```

**ios/Runner/Info.plist:**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>FoodSaver needs your location to find nearby food donations and manage pickups.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>FoodSaver needs your location to find nearby food donations and manage pickups.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>FoodSaver needs your location to find nearby food donations and manage pickups.</string>
```

#### 4. Initialize Firebase

In your Flutter project:

```bash
flutterfire configure
```

This will:
- Create `lib/firebase_options.dart`
- Configure Firebase for Android and iOS

### Part 3: App Navigation Integration

Update your routing to include the new screens:

**lib/core/routing/app_router.dart:**

```dart
import 'package:foodsaver/features/donor/screens/donation_map_screen.dart';
import 'package:foodsaver/features/volunteer/screens/pickup_map_screen.dart';

final appRouter = GoRouter(
  routes: [
    // ... existing routes ...
    
    GoRoute(
      path: '/donations-map',
      builder: (context, state) => const DonationMapScreen(),
    ),
    
    GoRoute(
      path: '/pickups-map',
      builder: (context, state) => PickupMapScreen(
        userId: state.extra as String,
        userRole: 'volunteer', // or 'ngo'
      ),
    ),
  ],
);
```

### Part 4: Feature Usage

#### Donor Flow

```dart
// 1. Browse donations on map
GestureDetector(
  onTap: () => context.go('/donations-map'),
  child: const Text('Browse Donations'),
)

// 2. Post a donation
final donationService = DonationService();
await donationService.createDonation(
  foodType: 'Vegetables',
  quantity: 5,
  unit: 'kg',
  description: 'Fresh vegetables',
  pickupLocation: 'Downtown Market',
  latitude: 28.6139,
  longitude: 77.2090,
  category: 'Vegetables',
);
```

#### NGO/Volunteer Flow

```dart
// 1. View pickups on map
GestureDetector(
  onTap: () => context.go('/pickups-map?userId=user_id&role=ngo'),
  child: const Text('View Pickups'),
)

// 2. Update pickup status
final pickupService = PickupService();
await pickupService.updatePickupStatus(
  pickupId: 'pickup_123',
  status: 'completed',
  notes: 'Food collected successfully',
);
```

### Part 5: State Management (Riverpod)

Use providers for reactive updates:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodsaver/core/providers/service_providers.dart';

class DonationsListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch available donations
    final donationsAsync = ref.watch(
      availableDonationsProvider({
        'latitude': 28.6139,
        'longitude': 77.2090,
        'radiusKm': 10,
      }),
    );

    return donationsAsync.when(
      data: (donations) => ListView(
        children: donations.map((d) => DonationCard(donation: d)).toList(),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### Part 6: Notifications

Initialize notifications in your app:

```dart
import 'package:foodsaver/core/services/notification_service.dart';

void initNotifications() async {
  final notificationService = NotificationService();
  await notificationService.initialize();
}
```

Listen to notifications:

```dart
// In your widget
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Got message: ${message.notification?.title}');
  // Handle notification in foreground
});

FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Handle notification tap
  // Navigate to relevant screen
});
```

### Part 7: Location Permissions

Add location permission handlers:

**Android (android/app/src/main/AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

**iOS (ios/Runner/Info.plist):**
Already configured in Part 2

### Part 8: Testing

#### 1. Test Backend Functions

```bash
# Start emulator
firebase emulators:start

# In another terminal, test functions
firebase functions:shell
```

#### 2. Test Frontend

```bash
flutter run
```

#### 3. Test Maps

- Navigate to `/donations-map`
- Check if map loads
- Verify markers appear
- Test filtering and searching

## 📱 API Reference

### Core Services

#### DonationService
```dart
// Create donation
createDonation({...})

// Get available donations
getAvailableDonations(latitude, longitude, radiusKm)

// Claim donation
claimDonation(donationId, ngoId)

// Rate donation
rateDonation(donationId, rating, review, reviewerType)

// Search donations
searchDonations(query, latitude, longitude)
```

#### PickupService
```dart
// Schedule pickup
schedulePickup(pickupId, volunteerId, pickupTime)

// Get pending pickups
getPendingPickups()

// Update status
updatePickupStatus(pickupId, status)

// Stream pickups
streamUserPickups(userId)
```

#### LocationService
```dart
// Get current location
getCurrentLocation()

// Calculate distance
calculateDistance(lat1, lon1, lat2, lon2)

// Check if within radius
isWithinRadius(lat1, lon1, lat2, lon2, radiusKm)

// Track location updates
startLocationUpdates(onLocationUpdate)
```

#### NotificationService
```dart
// Initialize
initialize()

// Get notifications
getNotifications()

// Mark as read
markAsRead(notificationId)

// Stream notifications
streamNotifications()
```

## 🔐 Security Checklist

- [x] Firebase authentication enabled
- [x] Cloud Functions validated with auth
- [x] Firestore rules restrict access
- [x] Location data encrypted
- [x] API keys in environment variables
- [ ] Terms of Service implemented
- [ ] Privacy Policy added
- [ ] Data retention policy set

## 🐛 Troubleshooting

### Maps not loading
- Check Flutter Map dependencies
- Verify API keys in AndroidManifest.xml
- Clear cache: `flutter clean`

### Location not working
- Grant location permissions in app settings
- Check location service enabled on device
- Verify LocationSettings in location_service.dart

### Notifications not received
- Check FCM token is saved
- Verify Firebase Messaging permissions
- Test in Firebase Console

### Cloud Functions errors
- Check Firebase project quota
- Verify function logs: `firebase functions:log`
- Test with Postman/Insomnia

## 📚 Additional Resources

- [Flutter Map Documentation](https://pub.dev/packages/flutter_map)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Riverpod State Management](https://riverpod.dev/)
- [Firebase Messaging](https://firebase.google.com/docs/cloud-messaging)

## 🚀 Deployment

### Deploy Flutter App

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

### Deploy Backend

```bash
firebase deploy --only functions,firestore:rules,firestore:indexes
```

## ✅ Verification Checklist

- [ ] Flutter dependencies installed
- [ ] Firebase configured
- [ ] Cloud Functions deployed
- [ ] Firestore rules set
- [ ] Location permissions granted
- [ ] Maps display correctly
- [ ] Notifications working
- [ ] Backend API calls successful
- [ ] State management working
- [ ] Routing configured

## 🎯 Next Steps

1. Implement user authentication UI
2. Add donation creation form
3. Create NGO dashboard
4. Implement volunteer assignment
5. Add rating/review system
6. Setup analytics
7. Create admin panel
8. Test in production

---

**For support, check the backend functions logs and Flutter console output.**
