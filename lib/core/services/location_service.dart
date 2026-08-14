import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

/// Result of a location permission check
enum LocationPermissionResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class LocationService {
  /// Get current user location with full permission + service check.
  /// Throws a descriptive [Exception] on failure.
  Future<Position> getCurrentLocation() async {
    // 1. Check if location services are enabled on the device
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Location services are disabled. Please enable GPS in device settings.');
    }

    // 2. Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
            'Location permission denied. Please allow location access to use the map.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permission permanently denied. Please enable it in App Settings > Permissions.');
    }

    // 3. Fetch position
    final position = await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return position;
  }

  /// Check permission status without prompting the user.
  Future<LocationPermissionResult> checkPermissionStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionResult.serviceDisabled;

    final permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionResult.granted;
      case LocationPermission.deniedForever:
        return LocationPermissionResult.deniedForever;
      default:
        return LocationPermissionResult.denied;
    }
  }

  /// Calculate distance between two points (in kilometers) using Haversine.
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371.0; // km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRad(double deg) => deg * math.pi / 180;

  /// Check if a point is within a given radius.
  bool isWithinRadius({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
    required double radiusKm,
  }) =>
      calculateDistance(lat1, lon1, lat2, lon2) <= radiusKm;

  /// Start streaming location updates.
  Future<void> startLocationUpdates({
    required Function(Position) onLocationUpdate,
    int distanceFilter = 10,
  }) async {
    final result = await checkPermissionStatus();
    if (result != LocationPermissionResult.granted) {
      throw Exception('Location permission not granted');
    }
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).listen(onLocationUpdate);
  }

  /// Open device location settings.
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Open app settings (for permanently denied permissions).
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Show a user-friendly snackbar when location fails.
  static void showLocationErrorSnackbar(
      BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.location_off, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () => Geolocator.openAppSettings(),
        ),
      ),
    );
  }
}

// Keep the legacy LengthUnit enum so existing callers don't break
enum LengthUnit { kilometer, meter, mile }
