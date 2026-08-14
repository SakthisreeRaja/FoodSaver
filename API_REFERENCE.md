# FoodSaver API Reference

## Cloud Functions API

All functions are callable from the Flutter app using Firebase Cloud Functions.

### Authentication

All functions require user authentication via Firebase Auth. Include auth token in request headers.

---

## Donation Functions

### `createDonation`

Create a new food donation listing.

**Parameters:**
```javascript
{
  "foodType": "Vegetables",          // string, required
  "quantity": 5,                     // number, required
  "unit": "kg",                      // string, required (kg, liter, pieces, etc.)
  "description": "Fresh vegetables", // string, required
  "pickupLocation": "Downtown",      // string, required
  "coordinates": {                   // object, required
    "latitude": 28.6139,
    "longitude": 77.2090
  },
  "imageUrl": "https://...",         // string, optional
  "expiryDate": "2024-12-20",       // string, optional (ISO format)
  "availableFrom": "09:00",          // string, optional
  "availableTo": "17:00",            // string, optional
  "category": "Vegetables"           // string, optional
}
```

**Response:**
```javascript
{
  "success": true,
  "donationId": "donation_123",
  "message": "Donation created successfully"
}
```

**Dart Example:**
```dart
final donationService = DonationService();
final result = await donationService.createDonation(
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

---

### `getAvailableDonations`

Get available donations near user location with optional filtering.

**Parameters:**
```javascript
{
  "latitude": 28.6139,        // number, required
  "longitude": 77.2090,       // number, required
  "radiusKm": 10,             // number, optional (default: 10)
  "category": "Vegetables",   // string, optional
  "page": 1,                  // number, optional (default: 1)
  "limit": 20                 // number, optional (default: 20)
}
```

**Response:**
```javascript
{
  "success": true,
  "donations": [
    {
      "id": "donation_123",
      "donorId": "user_456",
      "foodType": "Vegetables",
      "quantity": 5,
      "unit": "kg",
      "status": "available",
      "rating": 4.5,
      "reviewCount": 10,
      // ... more fields
    }
  ],
  "total": 15
}
```

**Dart Example:**
```dart
final donations = await donationService.getAvailableDonations(
  latitude: 28.6139,
  longitude: 77.2090,
  radiusKm: 10,
  category: 'Vegetables',
);
```

---

### `getDonationDetails`

Get full details of a specific donation.

**Parameters:**
```javascript
{
  "donationId": "donation_123"  // string, required
}
```

**Response:**
```javascript
{
  "success": true,
  "donation": {
    "id": "donation_123",
    "donorId": "user_456",
    "foodType": "Vegetables",
    // ... all donation fields
  },
  "reviews": [
    {
      "id": "review_789",
      "rating": 5,
      "review": "Great quality!",
      "reviewerId": "user_999",
      "reviewerType": "ngo"
    }
  ]
}
```

---

### `claimDonation`

Claim a donation for your NGO.

**Parameters:**
```javascript
{
  "donationId": "donation_123",  // string, required
  "ngoId": "ngo_456"             // string, required
}
```

**Response:**
```javascript
{
  "success": true,
  "message": "Donation claimed successfully"
}
```

---

### `updateDonationStatus`

Update donation status (available → claimed → completed → cancelled).

**Parameters:**
```javascript
{
  "donationId": "donation_123",  // string, required
  "status": "completed"          // string, required (available|claimed|completed|cancelled)
}
```

**Response:**
```javascript
{
  "success": true,
  "message": "Donation status updated"
}
```

---

### `getDonorDonations`

Get all donations posted by current user.

**Parameters:**
None (uses authenticated user)

**Response:**
```javascript
{
  "success": true,
  "donations": [
    {
      "id": "donation_123",
      // ... donation fields
    }
  ]
}
```

---

### `rateDonation`

Add a rating/review for a donation.

**Parameters:**
```javascript
{
  "donationId": "donation_123",  // string, required
  "rating": 5,                   // number, required (1-5)
  "review": "Great quality!",   // string, required
  "reviewerType": "ngo"          // string, required (ngo|volunteer)
}
```

**Response:**
```javascript
{
  "success": true,
  "message": "Review added successfully"
}
```

---

### `searchDonations`

Search donations by food type or description.

**Parameters:**
```javascript
{
  "query": "vegetables",         // string, required
  "latitude": 28.6139,           // number, optional
  "longitude": 77.2090,          // number, optional
  "radiusKm": 10                 // number, optional (default: 10)
}
```

**Response:**
```javascript
{
  "success": true,
  "results": [
    {
      "id": "donation_123",
      // ... donation fields
    }
  ],
  "total": 5
}
```

---

## Pickup Functions

### `schedulePickup`

Schedule a pickup for a donation.

**Parameters:**
```javascript
{
  "pickupId": "pickup_123",           // string, required
  "volunteerId": "volunteer_456",     // string, required
  "pickupTime": "2024-12-20T14:00:00Z", // string, required (ISO format)
  "notes": "Call before arrival"      // string, optional
}
```

**Response:**
```javascript
{
  "success": true,
  "message": "Pickup scheduled successfully"
}
```

---

### `getPendingPickups`

Get all pending/scheduled pickups.

**Parameters:**
None (uses authenticated user)

**Response:**
```javascript
{
  "success": true,
  "pickups": [
    {
      "id": "pickup_123",
      "donationId": "donation_456",
      "status": "pending",
      // ... more fields
    }
  ]
}
```

---

### `updatePickupStatus`

Update pickup status.

**Parameters:**
```javascript
{
  "pickupId": "pickup_123",          // string, required
  "status": "completed",             // string, required (pending|scheduled|in-transit|completed|cancelled)
  "notes": "Completed successfully"  // string, optional
}
```

**Response:**
```javascript
{
  "success": true,
  "message": "Pickup status updated"
}
```

---

## User Functions

### `updateUserProfile`

Create or update user profile.

**Parameters:**
```javascript
{
  "name": "John Doe",                // string, required
  "email": "john@example.com",       // string, required
  "phoneNumber": "+91-9876543210",   // string, required
  "userType": "donor",               // string, required (donor|ngo|volunteer|admin)
  "address": "123 Main St",          // string, optional
  "profileImage": "https://...",     // string, optional
  "coordinates": {                   // object, optional
    "latitude": 28.6139,
    "longitude": 77.2090
  }
}
```

**Response:**
```javascript
{
  "success": true,
  "message": "Profile updated successfully"
}
```

---

### `getUserProfile`

Get current user profile.

**Parameters:**
None (uses authenticated user)

**Response:**
```javascript
{
  "success": true,
  "user": {
    "id": "user_123",
    "name": "John Doe",
    "email": "john@example.com",
    "userType": "donor",
    // ... all profile fields
  }
}
```

---

### `updateFCMToken`

Update Firebase Cloud Messaging token for notifications.

**Parameters:**
```javascript
{
  "fcmToken": "token_here"  // string, required
}
```

**Response:**
```javascript
{
  "success": true,
  "message": "FCM token updated"
}
```

---

### `getDonationStats`

Get statistics about user's donations.

**Parameters:**
None (uses authenticated user)

**Response:**
```javascript
{
  "success": true,
  "stats": {
    "totalDonations": 10,
    "availableDonations": 2,
    "completedDonations": 7,
    "cancelledDonations": 1
  }
}
```

---

## Notification Functions

### `getUserNotifications`

Get all notifications for current user.

**Parameters:**
None (uses authenticated user)

**Response:**
```javascript
{
  "success": true,
  "notifications": [
    {
      "id": "notif_123",
      "title": "Donation Claimed",
      "body": "Your donation was claimed",
      "type": "donation_claimed",
      "read": false,
      "createdAt": "2024-12-10T10:00:00Z"
    }
  ]
}
```

---

### `markNotificationAsRead`

Mark a notification as read.

**Parameters:**
```javascript
{
  "notificationId": "notif_123"  // string, required
}
```

**Response:**
```javascript
{
  "success": true,
  "message": "Notification marked as read"
}
```

---

## Error Handling

All functions follow standard error responses:

```javascript
{
  "code": "PERMISSION_DENIED",
  "message": "User must be authenticated"
}
```

### Common Error Codes

- `unauthenticated` - User not authenticated
- `permission-denied` - User doesn't have permission
- `invalid-argument` - Missing or invalid parameters
- `not-found` - Resource not found
- `internal` - Server error

---

## Rate Limiting

- Authenticated users: 100 requests/minute per function
- Anonymous: Not allowed

---

## Firestore Document Structure

### Donations Collection
```
/donations/{donationId}
  - donorId: string
  - foodType: string
  - quantity: number
  - unit: string
  - status: string
  - coordinates: GeoPoint
  - rating: number
  - reviews: subcollection
```

### Pickups Collection
```
/pickups/{pickupId}
  - donationId: string
  - volunteerId: string
  - ngoId: string
  - status: string
  - rating: number
```

### Users Collection
```
/users/{userId}
  - name: string
  - email: string
  - userType: string
  - rating: number
  - notifications: subcollection
```

---

## Testing

Use Firebase Emulator for local testing:

```bash
firebase emulators:start
```

Test functions in shell:

```bash
firebase functions:shell
> createDonation({...})
```

---

## Monitoring

Monitor function health in Firebase Console:
- Functions → Your Function → Logs
- View execution time, errors, and memory usage

---

## Support

For issues, check:
1. Firebase Console → Functions → Logs
2. Firestore Security Rules
3. User authentication status
4. Rate limiting status
