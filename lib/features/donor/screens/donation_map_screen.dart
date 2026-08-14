import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:foodsaver/core/services/location_service.dart';
import 'package:foodsaver/core/services/map_service.dart';
import 'package:foodsaver/core/services/user_service.dart';

/// Donor-specific map:
/// - 🏢 Purple = Nearby NGOs
/// - 🍎 Green  = My available donations
/// - 📦 Blue   = My claimed donations (shows NGO location when tapped)
/// - ✅ Grey   = My completed donations
/// - 📍 Teal   = My location
class DonationMapScreen extends StatefulWidget {
  const DonationMapScreen({super.key});

  @override
  State<DonationMapScreen> createState() => _DonationMapScreenState();
}

class _DonationMapScreenState extends State<DonationMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();

  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  LatLng? _userLocation;
  bool _isLoading = true;
  bool _isMapReady = false;
  double _radiusKm = 15.0;
  String? _locationError;

  // Layer toggles — Donor sees NGOs + own donations
  bool _showNGOs = true;
  bool _showMyDonations = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
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

    await _loadAllMarkers();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (_isMapReady && _userLocation != null && mounted) {
      _mapController.move(_userLocation!, 13.0);
    }
  }

  Future<void> _loadAllMarkers() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final List<Marker> markers = [];

    // --- Nearby NGO markers (purple 🏢) ---
    if (_showNGOs) {
      try {
        final ngos = await _userService.getUsersByRole('ngo');
        for (final ngo in ngos) {
          final coords = ngo['coordinates'] as Map<String, dynamic>?;
          if (coords != null) {
            final lat = (coords['latitude'] as num?)?.toDouble();
            final lng = (coords['longitude'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              // Distance filter
              if (_userLocation != null) {
                final dist = _locationService.calculateDistance(
                    _userLocation!.latitude, _userLocation!.longitude,
                    lat, lng);
                if (dist > _radiusKm) continue;
              }
              markers.add(
                MapService.createNGOMarker(
                  id: ngo['id'] as String? ?? '',
                  latitude: lat,
                  longitude: lng,
                  ngoName: ngo['name'] as String? ?? 'NGO',
                  onTap: () => _showNgoInfo(ngo),
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading NGO markers: $e');
      }
    }

    // --- My own donations (color-coded by status) ---
    if (_showMyDonations && uid != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('donations')
            .where('donorId', isEqualTo: uid)
            .get();

        for (final doc in snap.docs) {
          final d = {...doc.data(), 'id': doc.id};
          final coords = d['coordinates'] as Map<String, dynamic>?;
          if (coords == null) continue;
          final lat = (coords['latitude'] as num?)?.toDouble();
          final lng = (coords['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;

          final status = d['status'] as String? ?? 'available';
          final (color, emoji) = _statusStyle(status);

          markers.add(Marker(
            point: LatLng(lat, lng),
            width: 56,
            height: 56,
            child: GestureDetector(
              onTap: () => _showDonationSheet(d),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2)
                  ],
                ),
                child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
            ),
          ));
        }
      } catch (e) {
        debugPrint('Error loading my donations: $e');
      }
    }

    // --- User location marker (blue 📍) ---
    if (_userLocation != null) {
      markers.add(
        MapService.createUserLocationMarker(
          latitude: _userLocation!.latitude,
          longitude: _userLocation!.longitude,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  (Color, String) _statusStyle(String status) {
    switch (status) {
      case 'claimed':
        return (const Color(0xFF2196F3), '📦');
      case 'completed':
        return (const Color(0xFF9E9E9E), '✅');
      case 'cancelled':
        return (const Color(0xFFE53935), '❌');
      default: // available
        return (const Color(0xFF4CAF50), '🍎');
    }
  }

  void _showDonationSheet(Map<String, dynamic> donation) {
    final foodType = donation['foodType'] as String? ?? 'Food';
    final location = donation['pickupLocation'] as String? ?? 'N/A';
    final qty = donation['quantity'] as int? ?? 0;
    final unit = donation['unit'] as String? ?? '';
    final status = donation['status'] as String? ?? 'available';
    final claimedBy = donation['claimedBy'] as String?;
    final ngoCoords = donation['ngoCoordinates'] as Map<String, dynamic>?;
    final ngoName = donation['ngoName'] as String?;

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _statusStyle(status).$1.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(_statusStyle(status).$2,
                      style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(foodType,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(status.toUpperCase(),
                          style: TextStyle(
                              color: _statusStyle(status).$1,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(height: 24),
            _infoRow('📍', location),
            const SizedBox(height: 6),
            _infoRow('📦', '$qty $unit'),

            // Show NGO info if claimed
            if (status == 'claimed' && (ngoName != null || claimedBy != null)) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business, color: Colors.blue.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Claimed by ${ngoName ?? 'an NGO'}',
                          style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ],
                    ),
                    if (ngoCoords != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showRouteToNgo(donation);
                          },
                          icon: const Icon(Icons.route, size: 16),
                          label: const Text('View NGO Location'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: BorderSide(color: Colors.blue.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ] else if (claimedBy != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _fetchAndShowNgoLocation(donation, claimedBy);
                          },
                          icon: const Icon(Icons.route, size: 16),
                          label: const Text('View NGO Location'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: BorderSide(color: Colors.blue.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show route from donation to NGO location stored on donation doc
  void _showRouteToNgo(Map<String, dynamic> donation) {
    final ngoCoords = donation['ngoCoordinates'] as Map<String, dynamic>?;
    final donCoords = donation['coordinates'] as Map<String, dynamic>?;
    if (ngoCoords == null || donCoords == null) return;

    final ngoLat = (ngoCoords['latitude'] as num).toDouble();
    final ngoLng = (ngoCoords['longitude'] as num).toDouble();
    final donLat = (donCoords['latitude'] as num).toDouble();
    final donLng = (donCoords['longitude'] as num).toDouble();

    setState(() {
      _polylines = [
        Polyline(
          points: [LatLng(donLat, donLng), LatLng(ngoLat, ngoLng)],
          color: Colors.blue.shade700,
          strokeWidth: 4.0,
          borderColor: Colors.white,
          borderStrokeWidth: 1.5,
        ),
      ];
      // Add NGO marker temporarily
      _markers = [
        ..._markers,
        Marker(
          point: LatLng(ngoLat, ngoLng),
          width: 56,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.purple.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2)
              ],
            ),
            child: const Center(
                child: Icon(Icons.business, color: Colors.white, size: 22)),
          ),
        ),
      ];
    });

    _fitBounds(donLat, donLng, ngoLat, ngoLng);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🚗 Route to NGO shown on map'),
          backgroundColor: Colors.blue.shade700,
          action: SnackBarAction(
            label: 'Clear',
            textColor: Colors.white,
            onPressed: () {
              setState(() => _polylines = []);
              _loadAllMarkers();
            },
          ),
        ),
      );
    }
  }

  /// Fetch NGO coordinates from user doc and show route
  Future<void> _fetchAndShowNgoLocation(
      Map<String, dynamic> donation, String ngoUid) async {
    try {
      final ngoDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ngoUid)
          .get();
      if (!ngoDoc.exists) return;
      final ngoData = ngoDoc.data()!;
      final coords = ngoData['coordinates'] as Map<String, dynamic>?;
      if (coords != null) {
        donation['ngoCoordinates'] = coords;
        donation['ngoName'] = ngoData['name'] as String? ?? 'NGO';
        _showRouteToNgo(donation);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('NGO location not available'),
                backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching NGO location: $e');
    }
  }

  void _fitBounds(double lat1, double lng1, double lat2, double lng2) {
    if (!_isMapReady) return;
    final minLat = lat1 < lat2 ? lat1 : lat2;
    final maxLat = lat1 > lat2 ? lat1 : lat2;
    final minLng = lng1 < lng2 ? lng1 : lng2;
    final maxLng = lng1 > lng2 ? lng1 : lng2;
    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(
        LatLng(minLat - 0.005, minLng - 0.005),
        LatLng(maxLat + 0.005, maxLng + 0.005),
      ),
      padding: const EdgeInsets.all(60),
    ));
  }

  void _showNgoInfo(Map<String, dynamic> ngo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.business,
                      color: Color(0xFF9C27B0), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ngo['name'] as String? ?? 'NGO',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold),
                      ),
                      if (ngo['address'] != null)
                        Text(
                          ngo['address'] as String,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 24),
            if (ngo['email'] != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined, color: Colors.grey),
                title: Text(ngo['email'] as String),
              ),
            if (ngo['phoneNumber'] != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.phone_outlined, color: Colors.grey),
                title: Text(ngo['phoneNumber'] as String),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String emoji, String text) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Map'),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _polylines = []);
              _loadAllMarkers();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Map Layer
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _userLocation ?? const LatLng(20.5937, 78.9629),
                    initialZoom: 13.0,
                    maxZoom: 18.0,
                    minZoom: 3.0,
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
                            color: Colors.purple.withOpacity(0.06),
                            borderColor: Colors.purple.withOpacity(0.3),
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

                // Filter Panel
                Positioned(
                  top: _locationError != null ? 80 : 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Layer toggles
                        Row(
                          children: [
                            _buildLayerToggle(
                              '🏢 NGOs',
                              _showNGOs,
                              const Color(0xFF9C27B0),
                              (v) => setState(() {
                                _showNGOs = v;
                                _loadAllMarkers();
                              }),
                            ),
                            const SizedBox(width: 8),
                            _buildLayerToggle(
                              '🍎 My Donations',
                              _showMyDonations,
                              const Color(0xFF4CAF50),
                              (v) => setState(() {
                                _showMyDonations = v;
                                _loadAllMarkers();
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Radius Slider (for NGO filtering)
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 18, color: Colors.grey),
                            const SizedBox(width: 4),
                            const Text('Radius:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Expanded(
                              child: Slider(
                                value: _radiusKm,
                                min: 1,
                                max: 50,
                                divisions: 49,
                                label: '${_radiusKm.toStringAsFixed(0)} km',
                                onChanged: (value) {
                                  setState(() => _radiusKm = value);
                                },
                                onChangeEnd: (_) => _loadAllMarkers(),
                              ),
                            ),
                            Text(
                              '${_radiusKm.toStringAsFixed(0)}km',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
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
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Legend',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text('🏢  Nearby NGOs',
                            style: TextStyle(fontSize: 11)),
                        SizedBox(height: 2),
                        Text('🍎  My Available',
                            style: TextStyle(fontSize: 11)),
                        SizedBox(height: 2),
                        Text('📦  My Claimed',
                            style: TextStyle(fontSize: 11)),
                        SizedBox(height: 2),
                        Text('📍  My Location',
                            style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),

                // My Location button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      if (_userLocation != null) {
                        _mapController.move(_userLocation!, 14.0);
                      } else {
                        _initializeMap();
                      }
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLayerToggle(
    String label,
    bool value,
    Color color,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? color : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.visibility : Icons.visibility_off,
              size: 14,
              color: value ? color : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: value ? color : Colors.grey,
                  fontWeight: FontWeight.w500),
            ),
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
