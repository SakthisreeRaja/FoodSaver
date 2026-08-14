# FoodSaver Configuration Guide

## Environment Setup

### 1. Firebase Configuration

#### Create `lib/firebase_options.dart`

Run this command to auto-generate Firebase options:

```bash
flutterfire configure
```

This will create the necessary Firebase configuration for your platform.

### 2. Environment Variables

Create `.env` file in project root:

```env
GEMINI_API_KEY=your_gemini_api_key_here
FIREBASE_PROJECT_ID=your_firebase_project_id
```

### 3. Android Configuration

**android/app/build.gradle**

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.foodsaver.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    
    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

dependencies {
    // Google Play Services
    implementation 'com.google.android.gms:play-services-maps:18.2.0'
    implementation 'com.google.android.gms:play-services-location:21.1.0'
    
    // Firebase
    implementation platform('com.google.firebase:firebase-bom:32.7.1')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-firestore'
    implementation 'com.google.firebase:firebase-functions'
    implementation 'com.google.firebase:firebase-messaging'
}
```

**android/app/src/main/AndroidManifest.xml**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    
    <application>
        <!-- ... -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_MAPS_API_KEY" />
        <!-- ... -->
    </application>
</manifest>
```

### 4. iOS Configuration

**ios/Podfile**

```ruby
platform :ios, '13.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_LOCATION=1',
        'PERMISSION_CAMERA=1'
      ]
    end
  end
end
```

**ios/Runner/Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Location Permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>FoodSaver needs your location to find nearby food donations and manage pickups.</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>FoodSaver needs your location to find nearby food donations and manage pickups.</string>
    
    <key>NSLocationAlwaysUsageDescription</key>
    <string>FoodSaver needs your location to find nearby food donations and manage pickups.</string>
    
    <!-- Camera Permission -->
    <key>NSCameraUsageDescription</key>
    <string>FoodSaver needs camera access to analyze food items using AI.</string>
    
    <!-- Photo Library Permission -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>FoodSaver needs access to your photo library to select food images.</string>
    
    <!-- Background Mode -->
    <key>UIBackgroundModes</key>
    <array>
        <string>processing</string>
        <string>location</string>
    </array>
    
    <!-- Google Maps Key -->
    <key>GMSApiKey</key>
    <string>YOUR_IOS_MAPS_API_KEY</string>
    
    <!-- Firebase Config -->
    <key>GOOGLE_APP_ID</key>
    <string>$(GOOGLE_APP_ID)</string>
    <key>FIREBASE_PROJECT_ID</key>
    <string>$(FIREBASE_PROJECT_ID)</string>
</dict>
</plist>
```

## Firestore Database Structure

### Collections

#### `donations`
```json
{
  "id": "donation_123",
  "donorId": "user_456",
  "foodType": "Vegetables",
  "quantity": 5,
  "unit": "kg",
  "description": "Fresh vegetables",
  "imageUrl": "https://...",
  "pickupLocation": "Downtown Market",
  "coordinates": {
    "latitude": 28.6139,
    "longitude": 77.2090
  },
  "availableFrom": "09:00",
  "availableTo": "17:00",
  "expiryDate": "2024-12-20",
  "category": "Vegetables",
  "status": "available",
  "rating": 4.5,
  "reviewCount": 10,
  "createdAt": "2024-12-10T10:00:00Z",
  "updatedAt": "2024-12-10T10:00:00Z",
  "claimedBy": null,
  "claimedAt": null
}
```

#### `pickups`
```json
{
  "id": "pickup_123",
  "donationId": "donation_456",
  "donorId": "user_789",
  "ngoId": "ngo_101",
  "volunteerId": "volunteer_102",
  "status": "scheduled",
  "pickupTime": "2024-12-20T14:00:00Z",
  "actualPickupTime": null,
  "notes": "Call before arrival",
  "rating": 0,
  "feedback": "",
  "createdAt": "2024-12-10T10:00:00Z",
  "updatedAt": "2024-12-10T10:00:00Z"
}
```

#### `users`
```json
{
  "id": "user_123",
  "name": "John Doe",
  "email": "john@example.com",
  "phoneNumber": "+91-9876543210",
  "userType": "donor",
  "profileImage": "https://...",
  "address": "123 Main St, City",
  "coordinates": {
    "latitude": 28.6139,
    "longitude": 77.2090
  },
  "fcmToken": "token_here",
  "rating": 4.5,
  "ratingCount": 20,
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-12-10T10:00:00Z"
}
```

#### `notifications` (sub-collection under `users`)
```json
{
  "id": "notif_123",
  "title": "Donation Claimed",
  "body": "Your food donation has been claimed",
  "type": "donation_claimed",
  "donationId": "donation_456",
  "read": false,
  "createdAt": "2024-12-10T10:00:00Z"
}
```

## Firestore Security Rules

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write for authenticated users
    match /donations/{donation} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.donorId;
      
      // Reviews sub-collection
      match /reviews/{review} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
        allow update, delete: if request.auth.uid == resource.data.reviewerId;
      }
    }

    match /pickups/{pickup} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.volunteerId || 
                      request.auth.uid == resource.data.ngoId ||
                      request.auth.uid == resource.data.donorId;
    }

    match /users/{user} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == user;
      allow update: if request.auth.uid == user;
      
      // Notifications sub-collection
      match /notifications/{notification} {
        allow read: if request.auth.uid == user;
        allow write: if request.auth.uid == user;
      }
      
      // Ratings sub-collection
      match /ratings/{rating} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
      }
    }

    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## Firebase Cloud Functions Configuration

### Environment Variables

Create `.env.local` in `backend/functions/`:

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_DATABASE_URL=https://your-project.firebaseio.com
```

### Functions Runtime

Set runtime to Node.js 20+ in `backend/functions/package.json`:

```json
{
  "engines": {
    "node": "20"
  }
}
```

## State Management Configuration

### Riverpod Setup

All providers are configured in `lib/core/providers/service_providers.dart`.

Usage example:

```dart
// Watch a provider
final donations = ref.watch(
  availableDonationsProvider({
    'latitude': 28.6139,
    'longitude': 77.2090,
  })
);

// Invalidate/Refresh
ref.refresh(availableDonationsProvider({...}));

// Get async data
ref.listen(
  pendingPickupsProvider,
  (previous, next) {
    // Handle state changes
  },
);
```

## Map Configuration

### OpenStreetMap (Free)

Already configured in `MapService.openStreetMapTileLayer`

### Google Maps (Optional)

Add to `pubspec.yaml`:

```yaml
google_maps_flutter: ^2.8.0
```

Configure API keys:
- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/Info.plist`

## Testing Configuration

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter test --verbose integration_test/
```

## Build & Deploy

### Build APK (Android)

```bash
flutter build apk --release
```

### Build iOS App

```bash
flutter build ios --release
```

### Deploy Cloud Functions

```bash
cd backend/functions
npm run build
firebase deploy --only functions
```

---

All configurations are now complete! Your FoodSaver app is ready to integrate with the backend.
