import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';

class MapService {
  /// Get tile layer for Open Street Map
  static TileLayer get openStreetMapTileLayer {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.foodsaver.app',
      retinaMode: true,
    );
  }

  /// Get tile layer for Dark theme
  static TileLayer get darkTileLayer {
    return TileLayer(
      urlTemplate: 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png',
      userAgentPackageName: 'com.foodsaver.app',
      retinaMode: true,
    );
  }

  /// Create a marker from donation data
  static Marker createDonationMarker({
    required String id,
    required double latitude,
    required double longitude,
    required String title,
    required VoidCallback onTap,
  }) {
    return Marker(
      point: LatLng(latitude, longitude),
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '🍎',
              style: TextStyle(fontSize: 32),
            ),
          ),
        ),
      ),
    );
  }

  /// Create a marker for user location
  static Marker createUserLocationMarker({
    required double latitude,
    required double longitude,
  }) {
    return Marker(
      point: LatLng(latitude, longitude),
      width: 80,
      height: 80,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.location_on,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  /// Create a marker for NGO location
  static Marker createNGOMarker({
    required String id,
    required double latitude,
    required double longitude,
    required String ngoName,
    required VoidCallback onTap,
  }) {
    return Marker(
      point: LatLng(latitude, longitude),
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.business,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }

  /// Convert list of donations to markers
  static List<Marker> donationsToMarkers({
    required List<Map<String, dynamic>> donations,
    required Function(String) onMarkerTap,
  }) {
    return donations
        .map((donation) {
          final coords = donation['coordinates'] as Map<String, dynamic>?;
          if (coords == null) return null;

          return createDonationMarker(
            id: donation['id'] ?? '',
            latitude: coords['latitude'] ?? 0.0,
            longitude: coords['longitude'] ?? 0.0,
            title: donation['foodType'] ?? 'Food Donation',
            onTap: () => onMarkerTap(donation['id'] ?? ''),
          );
        })
        .whereType<Marker>()
        .toList();
  }
}
