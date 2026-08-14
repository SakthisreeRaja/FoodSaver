import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:foodsaver/core/services/location_service.dart';
import 'package:foodsaver/core/services/map_service.dart';
import 'package:foodsaver/features/ngo/screens/pickup_mode_dialog.dart';

/// NGO-specific map:
/// - 🍎 Green  = Available donations from donors (can claim)
/// - 📦 Blue   = My claimed donations (already taken)
/// - 📍 Teal   = My location
class NgoMapScreen extends StatefulWidget {
  const NgoMapScreen({super.key});

  @override
  State<NgoMapScreen> createState() => _NgoMapScreenState();
}

class _NgoMapScreenState extends State<NgoMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  LatLng? _userLocation;
  bool _isLoading = true;

  bool _showAvailable = true;
  bool _showMyClaimed = true;
  double _radiusKm = 25.0;
  bool _isMapReady = false;
  String? _locationError;
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Grains',
    'Dairy',
    'Meat',
    'Bakery',
    'Processed',
  ];

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
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
          _userLocation = const LatLng(20.5937, 78.9629);
          _locationError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
    await _loadMarkers();
    if (mounted) setState(() => _isLoading = false);
    if (_userLocation != null && _isMapReady) {
      _mapController.move(_userLocation!, 13.0);
    }
  }

  Future<void> _loadMarkers() async {
    final List<Marker> markers = [];

    // Available donations from donors
    if (_showAvailable) {
      try {
        Query query = FirebaseFirestore.instance
            .collection('donations')
            .where('status', isEqualTo: 'available');

        // Apply category filter at Firestore level
        if (_selectedCategory != null && _selectedCategory != 'All') {
          query = query.where('category', isEqualTo: _selectedCategory);
        }

        final snap = await query.limit(100).get();

        for (final doc in snap.docs) {
          final d = {...doc.data() as Map<String, dynamic>, 'id': doc.id};
          final coords = d['coordinates'] as Map<String, dynamic>?;
          if (coords == null) continue;
          final lat = (coords['latitude'] as num?)?.toDouble();
          final lng = (coords['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;

          // Distance filter — only apply if we have user location
          if (_userLocation != null) {
            final dist = _haversine(_userLocation!.latitude,
                _userLocation!.longitude, lat, lng);
            if (dist > _radiusKm) continue;
            d['distance'] = dist;
          }

          markers.add(Marker(
            point: LatLng(lat, lng),
            width: 56,
            height: 56,
            child: GestureDetector(
              onTap: () => _showDonationSheet(d, canClaim: true),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2)
                  ],
                ),
                child: const Center(
                    child: Text('🍎', style: TextStyle(fontSize: 22))),
              ),
            ),
          ));
        }
      } catch (e) {
        debugPrint('Error loading available donations: $e');
      }
    }

    // My claimed donations
    if (_showMyClaimed && _uid != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('donations')
            .where('claimedBy', isEqualTo: _uid)
            .where('status', whereIn: ['claimed', 'completed'])
            .get();

        for (final doc in snap.docs) {
          final d = {...doc.data(), 'id': doc.id};
          final coords = d['coordinates'] as Map<String, dynamic>?;
          if (coords == null) continue;
          final lat = (coords['latitude'] as num?)?.toDouble();
          final lng = (coords['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;

          // Distance filter for claimed donations too
          if (_userLocation != null) {
            final dist = _haversine(_userLocation!.latitude,
                _userLocation!.longitude, lat, lng);
            if (dist > _radiusKm) continue;
          }

          markers.add(Marker(
            point: LatLng(lat, lng),
            width: 56,
            height: 56,
            child: GestureDetector(
              onTap: () => _onClaimedTap(d),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2)
                  ],
                ),
                child: const Center(
                    child: Text('📦', style: TextStyle(fontSize: 22))),
              ),
            ),
          ));
        }
      } catch (e) {
        debugPrint('Error loading my claimed: $e');
      }
    }

    // My location
    if (_userLocation != null) {
      markers.add(MapService.createUserLocationMarker(
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
      ));
    }

    if (mounted) setState(() => _markers = markers);
  }

  void _showDonationSheet(Map<String, dynamic> donation,
      {required bool canClaim}) {
    final foodType = donation['foodType'] as String? ?? 'Food';
    final location = donation['pickupLocation'] as String? ?? 'N/A';
    final qty = donation['quantity'] as int? ?? 0;
    final unit = donation['unit'] as String? ?? '';
    final status = donation['status'] as String? ?? 'available';
    final dist = donation['distance'] as double?;
    final category = donation['category'] as String? ?? '';
    final donId = donation['id'] as String;
    final aiData = donation['aiAnalysis'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.75,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
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
                    margin: const EdgeInsets.only(bottom: 16),
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
                        color: (canClaim ? Colors.green : Colors.blue)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.restaurant_menu,
                          color: canClaim ? Colors.green : Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(foodType,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          if (category.isNotEmpty)
                            Text(category,
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(height: 24),
                _row('📍', location),
                const SizedBox(height: 6),
                _row('📦', '$qty $unit'),
                if (dist != null) ...[
                  const SizedBox(height: 6),
                  _row('📏', '${dist.toStringAsFixed(1)} km away'),
                ],
                const SizedBox(height: 6),
                _row('📋', status.toUpperCase()),

                // AI Analysis Section — show Gemini results from donor
                if (aiData != null) ...[
                  const SizedBox(height: 16),
                  _aiAnalysisCard(aiData),
                ],

                const SizedBox(height: 20),
                if (canClaim)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await PickupModeDialog.show(context, donation);
                        await _loadMarkers();
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Claim This Donation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text('Already claimed by your NGO',
                                style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _drawRouteToLocation(donation);
                          },
                          icon: const Icon(Icons.route),
                          label: const Text('Show Route to Pickup'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: BorderSide(color: Colors.blue.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (status == 'claimed') ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _markAsPickedUp(donId);
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Mark as Picked Up'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// AI / Gemini Analysis card shown for available donations
  Widget _aiAnalysisCard(Map<String, dynamic> ai) {
    final safeToEat = ai['safeToEat'] as bool? ?? true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.08),
            const Color(0xFF3F51B5).withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text('Gemini AI Report',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: safeToEat
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  safeToEat ? '✅ Safe to Eat' : '⚠️ Check Quality',
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          safeToEat ? Colors.green.shade700 : Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (ai['foodType'] != null) ...[
            const SizedBox(height: 8),
            Text('Detected: ${ai['foodType']}',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500)),
          ],
          if (ai['notes'] != null && (ai['notes']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(ai['notes'].toString(),
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }

  Widget _row(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ),
      ],
    );
  }

  /// Tap on a claimed donation — show sheet and option to draw route
  void _onClaimedTap(Map<String, dynamic> donation) {
    _showDonationSheet(donation, canClaim: false);
  }

  /// Draw a route from NGO's location to the donation pickup point
  void _drawRouteToLocation(Map<String, dynamic> donation) {
    final coords = donation['coordinates'] as Map<String, dynamic>?;
    if (coords == null || _userLocation == null) return;
    final lat = (coords['latitude'] as num?)?.toDouble();
    final lng = (coords['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    final destination = LatLng(lat, lng);
    setState(() {
      _polylines = [
        Polyline(
          points: [_userLocation!, destination],
          color: Colors.blue.shade700,
          strokeWidth: 4.0,
          borderColor: Colors.white,
          borderStrokeWidth: 1.5,
        ),
      ];
    });

    // Fit map
    if (_isMapReady) {
      final minLat = _userLocation!.latitude < lat ? _userLocation!.latitude : lat;
      final maxLat = _userLocation!.latitude > lat ? _userLocation!.latitude : lat;
      final minLng = _userLocation!.longitude < lng ? _userLocation!.longitude : lng;
      final maxLng = _userLocation!.longitude > lng ? _userLocation!.longitude : lng;
      _mapController.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat - 0.005, minLng - 0.005),
          LatLng(maxLat + 0.005, maxLng + 0.005),
        ),
        padding: const EdgeInsets.all(60),
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🚗 Route to pickup shown on map'),
          backgroundColor: Colors.blue.shade700,
          action: SnackBarAction(
            label: 'Clear',
            textColor: Colors.white,
            onPressed: () => setState(() => _polylines = []),
          ),
        ),
      );
    }
  }

  /// Mark a self-pickup as completed
  Future<void> _markAsPickedUp(String donationId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final donRef = FirebaseFirestore.instance.collection('donations').doc(donationId);
      
      batch.update(donRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Also update the linked pickup if it exists
      final pickupSnap = await FirebaseFirestore.instance
          .collection('pickups')
          .where('donationId', isEqualTo: donationId)
          .where('deliveryType', isEqualTo: 'self')
          .limit(1)
          .get();

      if (pickupSnap.docs.isNotEmpty) {
        batch.update(pickupSnap.docs.first.reference, {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pickup completed! Thank you.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadMarkers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Correct haversine formula using dart:math
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Donations'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _polylines = []);
                _loadMarkers();
              },
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
                    initialCenter: _userLocation ?? const LatLng(20.5937, 78.9629),
                    initialZoom: 13.0,
                    maxZoom: 18.0,
                    onMapReady: () {
                      _isMapReady = true;
                      if (_userLocation != null) {
                        _mapController.move(_userLocation!, 13.0);
                      }
                    },
                  ),
                  children: [
                    MapService.openStreetMapTileLayer,
                    // Visual radius circle
                    if (_userLocation != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _userLocation!,
                            radius: _radiusKm * 1000, // meters
                            useRadiusInMeter: true,
                            color: Colors.green.withOpacity(0.06),
                            borderColor: Colors.green.withOpacity(0.3),
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    if (_polylines.isNotEmpty)
                      PolylineLayer(polylines: _polylines),
                    MarkerLayer(markers: _markers),
                  ],
                ),

                // Location error banner
                if (_locationError != null)
                  Positioned(
                    top: 16,
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

                // Controls
                Positioned(
                  top: _locationError != null ? 80 : 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8)
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            _toggle('🍎 Available', _showAvailable,
                                Colors.green, (v) {
                              setState(() => _showAvailable = v);
                              _loadMarkers();
                            }),
                            const SizedBox(width: 10),
                            _toggle('📦 My Claimed', _showMyClaimed,
                                Colors.blue, (v) {
                              setState(() => _showMyClaimed = v);
                              _loadMarkers();
                            }),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Radius: ${_radiusKm.toInt()} km',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Expanded(
                              child: Slider(
                                value: _radiusKm,
                                min: 2,
                                max: 50,
                                divisions: 48,
                                label: '${_radiusKm.toInt()} km',
                                onChanged: (v) =>
                                    setState(() => _radiusKm = v),
                                onChangeEnd: (_) => _loadMarkers(),
                              ),
                            ),
                          ],
                        ),
                        // Category filter chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((category) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  label: Text(category,
                                      style: const TextStyle(fontSize: 11)),
                                  selected: _selectedCategory == category ||
                                      (_selectedCategory == null &&
                                          category == 'All'),
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory =
                                          selected && category != 'All'
                                              ? category
                                              : null;
                                    });
                                    _loadMarkers();
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Legend
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
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Legend',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('🍎  Donor\'s Food (tap to claim)',
                            style: TextStyle(fontSize: 11)),
                        SizedBox(height: 2),
                        Text('📦  My claimed donations',
                            style: TextStyle(fontSize: 11)),
                        SizedBox(height: 2),
                        Text('📍  My location',
                            style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),

                // My location FAB
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      if (_userLocation != null && _isMapReady) {
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

  Widget _toggle(
      String label, bool value, Color color, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: value ? color : Colors.grey.shade300),
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
