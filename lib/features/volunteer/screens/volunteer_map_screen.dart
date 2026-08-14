import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:foodsaver/core/services/location_service.dart';
import 'package:foodsaver/core/services/map_service.dart';
import 'package:foodsaver/core/services/notification_service.dart';

/// Volunteer map screen:
/// - 🚴 Blue  = My assigned pickups (scheduled)
/// - ⏳ Orange = Pending pickups (available to accept)
/// - 📍 Green  = My location
/// - 🗺️  Polyline drawn from your location → selected pickup
class VolunteerMapScreen extends StatefulWidget {
  const VolunteerMapScreen({super.key});

  @override
  State<VolunteerMapScreen> createState() => _VolunteerMapScreenState();
}

class _VolunteerMapScreenState extends State<VolunteerMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  LatLng? _userLocation;
  LatLng? _selectedPickupLocation;
  bool _isLoading = true;
  bool _isMapReady = false;
  bool _showMyPickups = true;
  bool _showPending = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    // Try to get real location
    try {
      final pos = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _locationError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Default to center of India as fallback
          _userLocation = const LatLng(20.5937, 78.9629);
          _locationError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }

    await _loadMarkers();
    if (mounted) setState(() => _isLoading = false);

    // Move map to user location once it's ready
    if (_userLocation != null && _isMapReady && mounted) {
      _mapController.move(_userLocation!, 13.0);
    }
  }

  Future<void> _loadMarkers() async {
    final List<Marker> markers = [];

    // ── My assigned pickups ──────────────────────────────────────────────────
    if (_showMyPickups && _uid != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('pickups')
            .where('volunteerId', isEqualTo: _uid)
            .where('status', whereIn: ['scheduled', 'in_progress'])
            .get();

        for (final doc in snap.docs) {
          final pickup = {...doc.data(), 'id': doc.id, '_type': 'mine'};
          await _enrichPickup(pickup);
          final marker = _buildPickupMarker(pickup, Colors.blue, '🚴');
          if (marker != null) markers.add(marker);
        }
      } catch (e) {
        debugPrint('Error loading my pickups: $e');
      }
    }

    // ── Pending (unassigned) pickups ─────────────────────────────────────────
    if (_showPending) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('pickups')
            .where('status', isEqualTo: 'pending')
            .limit(30)
            .get();

        for (final doc in snap.docs) {
          final pickup = {...doc.data(), 'id': doc.id, '_type': 'pending'};
          await _enrichPickup(pickup);
          final marker = _buildPickupMarker(pickup, Colors.orange, '⏳');
          if (marker != null) markers.add(marker);
        }
      } catch (e) {
        debugPrint('Error loading pending pickups: $e');
      }
    }

    // ── User location marker ─────────────────────────────────────────────────
    if (_userLocation != null) {
      markers.add(MapService.createUserLocationMarker(
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
      ));
    }

    if (mounted) {
      setState(() {
        _markers = markers;
        // Re-draw route if a pickup is selected
        if (_selectedPickupLocation != null && _userLocation != null) {
          _updateRoute(_userLocation!, _selectedPickupLocation!);
        }
      });
    }
  }

  Future<void> _enrichPickup(Map<String, dynamic> pickup) async {
    final donationId = pickup['donationId'] as String?;
    if (donationId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .get();
      if (doc.exists) pickup['donation'] = {...doc.data()!, 'id': doc.id};
    } catch (_) {}
  }

  Marker? _buildPickupMarker(
      Map<String, dynamic> pickup, Color color, String emoji) {
    final donation = pickup['donation'] as Map<String, dynamic>?;
    final coords = donation?['coordinates'] as Map<String, dynamic>?;
    if (coords == null) return null;

    final lat = (coords['latitude'] as num?)?.toDouble();
    final lng = (coords['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final point = LatLng(lat, lng);

    return Marker(
      point: point,
      width: 56,
      height: 56,
      child: GestureDetector(
        onTap: () => _onMarkerTap(pickup, point),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: _selectedPickupLocation == point
                  ? Colors.white
                  : Colors.white.withOpacity(0.8),
              width: _selectedPickupLocation == point ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: _selectedPickupLocation == point ? 14 : 8,
                  spreadRadius: _selectedPickupLocation == point ? 3 : 2),
            ],
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );
  }

  void _onMarkerTap(Map<String, dynamic> pickup, LatLng pickupPoint) {
    setState(() {
      _selectedPickupLocation = pickupPoint;
    });

    // Draw route from user to pickup
    if (_userLocation != null) {
      _updateRoute(_userLocation!, pickupPoint);
      // Fit map to show both points
      _fitMapToBounds(_userLocation!, pickupPoint);
    }

    _showPickupSheet(pickup);
  }

  void _updateRoute(LatLng from, LatLng to) {
    setState(() {
      _polylines = [
        Polyline(
          points: [from, to],
          color: Colors.blue.shade700,
          strokeWidth: 4.0,
          isDotted: false,
          borderColor: Colors.white,
          borderStrokeWidth: 1.5,
        ),
      ];
    });
  }

  void _clearRoute() {
    setState(() {
      _polylines = [];
      _selectedPickupLocation = null;
    });
  }

  /// Fit map camera to include both [from] and [to] with padding.
  void _fitMapToBounds(LatLng from, LatLng to) {
    if (!_isMapReady) return;
    final minLat =
        from.latitude < to.latitude ? from.latitude : to.latitude;
    final maxLat =
        from.latitude > to.latitude ? from.latitude : to.latitude;
    final minLng =
        from.longitude < to.longitude ? from.longitude : to.longitude;
    final maxLng =
        from.longitude > to.longitude ? from.longitude : to.longitude;

    final bounds = LatLngBounds(
      LatLng(minLat - 0.005, minLng - 0.005),
      LatLng(maxLat + 0.005, maxLng + 0.005),
    );
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
    );
  }

  void _showPickupSheet(Map<String, dynamic> pickup) {
    final donation = pickup['donation'] as Map<String, dynamic>?;
    final foodType = donation?['foodType'] as String? ?? 'Food Pickup';
    final location = donation?['pickupLocation'] as String? ?? 'N/A';
    final quantity = donation?['quantity'] as int? ?? 0;
    final unit = donation?['unit'] as String? ?? '';
    final status = pickup['status'] as String? ?? 'pending';
    final type = pickup['_type'] as String? ?? 'pending';
    final pickupId = pickup['id'] as String;

    // Distance label
    String distanceLabel = '';
    final coords = donation?['coordinates'] as Map<String, dynamic>?;
    if (coords != null && _userLocation != null) {
      final lat = (coords['latitude'] as num?)?.toDouble();
      final lng = (coords['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        final dist = _locationService.calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          lat,
          lng,
        );
        distanceLabel = '${dist.toStringAsFixed(1)} km away';
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (type == 'mine' ? Colors.blue : Colors.orange)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_shipping,
                      color: type == 'mine' ? Colors.blue : Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(foodType,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(location,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _clearRoute();
                    }),
              ],
            ),
            const Divider(height: 24),
            _detailRow('📦', 'Quantity', '$quantity $unit'),
            const SizedBox(height: 6),
            _detailRow('📋', 'Status', status.toUpperCase()),
            if (distanceLabel.isNotEmpty) ...[
              const SizedBox(height: 6),
              _detailRow('📍', 'Distance', distanceLabel),
            ],
            const SizedBox(height: 16),

            // Route indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.route, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _userLocation != null
                        ? 'Route shown on map'
                        : 'Enable location to see route',
                    style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Accept button for pending pickups
            if (type == 'pending' && _uid != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _acceptPickup(pickupId, donation);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Accept This Pickup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

            // Status update for my pickups
            if (type == 'mine')
              Row(
                children: [
                  if (status == 'scheduled')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _updateStatus(pickupId, 'in_progress',
                              donation: donation);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white),
                        child: const Text('Start Transit'),
                      ),
                    ),
                  if (status == 'in_progress') ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _updateStatus(pickupId, 'completed',
                              donation: donation);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white),
                        child: const Text('Mark Delivered'),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    ).whenComplete(() {
      // Don't clear route — user may want to keep seeing it
    });
  }

  Widget _detailRow(String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Future<void> _acceptPickup(
      String pickupId, Map<String, dynamic>? donation) async {
    try {
      // Get current volunteer name
      final volunteerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();
      final volunteerName =
          volunteerDoc.data()?['name'] as String? ?? 'A volunteer';

      // Get the donorId from the donation to send notification
      final donorId = donation?['donorId'] as String?;
      final foodType = donation?['foodType'] as String? ?? 'Food';

      await FirebaseFirestore.instance
          .collection('pickups')
          .doc(pickupId)
          .update({
        'volunteerId': _uid,
        'status': 'scheduled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify the donor
      if (donorId != null) {
        await NotificationService().sendPickupAcceptedNotification(
          donorUid: donorId,
          pickupId: pickupId,
          foodType: foodType,
          volunteerName: volunteerName,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Pickup accepted! Donor notified.'),
            backgroundColor: Colors.green));
      }
      await _loadMarkers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateStatus(String pickupId, String status,
      {Map<String, dynamic>? donation}) async {
    try {
      await FirebaseFirestore.instance
          .collection('pickups')
          .doc(pickupId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (status == 'completed')
          'completedAt': FieldValue.serverTimestamp(),
      });

      if (status == 'completed') {
        // Mark donation as completed
        final doc = await FirebaseFirestore.instance
            .collection('pickups')
            .doc(pickupId)
            .get();
        final donationId = doc.data()?['donationId'] as String?;
        final donorId = donation?['donorId'] as String?;
        final foodType = donation?['foodType'] as String? ?? 'Food';

        if (donationId != null) {
          await FirebaseFirestore.instance
              .collection('donations')
              .doc(donationId)
              .update({'status': 'completed'});
        }

        // Notify donor about delivery completion
        if (donorId != null) {
          await NotificationService().sendPickupStatusNotification(
            recipientUid: donorId,
            status: 'completed',
            foodType: foodType,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Status updated to $status'),
            backgroundColor: Colors.green));
      }
      await _loadMarkers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Map'),
        automaticallyImplyLeading: false,
        actions: [
          if (_polylines.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear Route',
              onPressed: _clearRoute,
            ),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadMarkers,
              tooltip: 'Refresh'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        _userLocation ?? const LatLng(20.5937, 78.9629),
                    initialZoom: 13.0,
                    maxZoom: 18.0,
                    onMapReady: () {
                      _isMapReady = true;
                      if (_userLocation != null) {
                        _mapController.move(_userLocation!, 13.0);
                      }
                    },
                    onTap: (_, __) {
                      // Tapping empty map clears route
                      if (_polylines.isNotEmpty) _clearRoute();
                    },
                  ),
                  children: [
                    MapService.openStreetMapTileLayer,
                    if (_polylines.isNotEmpty)
                      PolylineLayer(polylines: _polylines),
                    MarkerLayer(markers: _markers),
                  ],
                ),

                // ── Location error banner ─────────────────────────────────
                if (_locationError != null)
                  Positioned(
                    top: 72,
                    left: 16,
                    right: 16,
                    child: Material(
                      borderRadius: BorderRadius.circular(12),
                      elevation: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_off,
                                color: Colors.orange.shade700, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _locationError!,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade800),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await _locationService.openAppSettings();
                              },
                              child: const Text('Fix'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Layer toggles (top) ───────────────────────────────────
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8)
                        ]),
                    child: Row(
                      children: [
                        _layerToggle(
                            '🚴 My Pickups', _showMyPickups, Colors.blue,
                            (v) {
                          setState(() => _showMyPickups = v);
                          _loadMarkers();
                        }),
                        const SizedBox(width: 10),
                        _layerToggle(
                            '⏳ Available', _showPending, Colors.orange, (v) {
                          setState(() => _showPending = v);
                          _loadMarkers();
                        }),
                      ],
                    ),
                  ),
                ),

                // ── Route hint ───────────────────────────────────────────
                if (_polylines.isNotEmpty)
                  Positioned(
                    bottom: 86,
                    left: 16,
                    right: 80,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8)
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.route,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Route: You → Pickup',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _clearRoute,
                            child: const Icon(Icons.close,
                                color: Colors.white70, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Legend (bottom left) ──────────────────────────────────
                if (_polylines.isEmpty)
                  Positioned(
                    bottom: 80,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6)
                          ]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Legend',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('🚴  My pickups',
                              style: TextStyle(fontSize: 11)),
                          SizedBox(height: 2),
                          Text('⏳  Tap to accept & route',
                              style: TextStyle(fontSize: 11)),
                          SizedBox(height: 2),
                          Text('📍  My location',
                              style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),

                // ── My location FAB ───────────────────────────────────────
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    heroTag: 'volunteer_locate',
                    onPressed: () {
                      if (_userLocation != null) {
                        _mapController.move(_userLocation!, 14.0);
                      } else {
                        _initMap();
                      }
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _layerToggle(
      String label, bool value, Color color, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: value ? color : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(value ? Icons.visibility : Icons.visibility_off,
                size: 14, color: value ? color : Colors.grey),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: value ? color : Colors.grey,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
