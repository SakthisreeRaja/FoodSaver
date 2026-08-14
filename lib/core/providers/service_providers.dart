import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:foodsaver/core/services/donation_service.dart';
import 'package:foodsaver/core/services/pickup_service.dart';
import 'package:foodsaver/core/services/location_service.dart';
import 'package:foodsaver/core/services/notification_service.dart';
import 'package:foodsaver/core/services/user_service.dart';

// Services
final donationServiceProvider = Provider((_) => DonationService());
final pickupServiceProvider = Provider((_) => PickupService());
final locationServiceProvider = Provider((_) => LocationService());
final notificationServiceProvider = Provider((_) => NotificationService());
final userServiceProvider = Provider((_) => UserService());

// User Location
final userLocationProvider = FutureProvider<Position>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getCurrentLocation();
});

// Available Donations
final availableDonationsProvider = FutureProvider.family<
    List<Map<String, dynamic>>,
    Map<String, dynamic>>((ref, params) async {
  final donationService = ref.watch(donationServiceProvider);
  return donationService.getAvailableDonations(
    latitude: params['latitude'] as double,
    longitude: params['longitude'] as double,
    radiusKm: params['radiusKm'] as double? ?? 10.0,
    category: params['category'] as String?,
  );
});

// Donation Details
final donationDetailsProvider = FutureProvider.family<
    Map<String, dynamic>,
    String>((ref, donationId) async {
  final donationService = ref.watch(donationServiceProvider);
  return donationService.getDonationDetails(donationId);
});

// User's Donations
final userDonationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final donationService = ref.watch(donationServiceProvider);
  return donationService.getDonorDonations();
});

// Pending Pickups
final pendingPickupsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final pickupService = ref.watch(pickupServiceProvider);
  return pickupService.getPendingPickups();
});

// Pickup Details
final pickupDetailsProvider = FutureProvider.family<
    Map<String, dynamic>,
    String>((ref, pickupId) async {
  final pickupService = ref.watch(pickupServiceProvider);
  return pickupService.getPickupDetails(pickupId);
});

// Notifications
final notificationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final notificationService = ref.watch(notificationServiceProvider);
  yield* notificationService.streamNotifications();
});

// Claim Donation
final claimDonationProvider = FutureProvider.family<void, Map<String, dynamic>>(
  (ref, params) async {
    final donationService = ref.watch(donationServiceProvider);
    await donationService.claimDonation(
      donationId: params['donationId'] as String,
      ngoId: params['ngoId'] as String,
    );
  },
);

// Rate Donation
final rateDonationProvider = FutureProvider.family<void, Map<String, dynamic>>(
  (ref, params) async {
    final donationService = ref.watch(donationServiceProvider);
    await donationService.rateDonation(
      donationId: params['donationId'] as String,
      rating: params['rating'] as int,
      review: params['review'] as String,
      reviewerType: params['reviewerType'] as String,
    );
  },
);

// Update Pickup Status
final updatePickupStatusProvider = FutureProvider.family<void, Map<String, dynamic>>(
  (ref, params) async {
    final pickupService = ref.watch(pickupServiceProvider);
    await pickupService.updatePickupStatus(
      pickupId: params['pickupId'] as String,
      status: params['status'] as String,
      notes: params['notes'] as String?,
    );
  },
);

// Search Donations
final searchDonationsProvider = FutureProvider.family<
    List<Map<String, dynamic>>,
    Map<String, dynamic>>((ref, params) async {
  final donationService = ref.watch(donationServiceProvider);
  return donationService.searchDonations(
    query: params['query'] as String,
    latitude: params['latitude'] as double?,
    longitude: params['longitude'] as double?,
    radiusKm: params['radiusKm'] as double? ?? 10.0,
  );
});
