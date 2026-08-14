import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:foodsaver/core/services/delivery_service.dart';
import 'package:foodsaver/core/services/location_service.dart';
import 'package:foodsaver/core/services/map_service.dart';
import 'package:foodsaver/core/services/user_service.dart';
import 'dp_delivery_screen.dart';

/// DP Map: shows all open delivery jobs as markers on the map.
/// Tapping a marker draws a route and shows job details.
class DPMapScreen extends StatefulWidget {
  const DPMapScreen({super.key});

  @override
  State<DPMapScreen> createState() => _DPMapScreenState();
}

class _DPMapScreenState extends State<DPMapScreen> {
  final _mapController = MapController();
  final _locationService = LocationService();

  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  LatLng? _myLocation;
  bool _isLoading = true;
  bool _isMapReady = false;
  String? _locationError;
  String? _selectedCategory;
  double _radiusKm = 30.0;

  List<Map<String, dynamic>> _jobs = [];

  // Toggle layers — DP sees ALL: Jobs, Donors, NGOs
  bool _showJobs = true;
  bool _showDonors = true;
  bool _showNGOs = true;

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
    _init();
  }

  Future<void> _init() async {
    try {
      final pos = await _locationService.getCurrentLocation();
      _myLocation = LatLng(pos.latitude, pos.longitude);
      _locationError = null;
    } catch (e) {
      _myLocation = const LatLng(20.5937, 78.9629);
      _locationError = e.toString().replaceFirst('Exception: ', '');
    }
    await _loadJobs();
    if (mounted) setState(() => _isLoading = false);
    if (_isMapReady && _myLocation != null) {
      _mapController.move(_myLocation!, 12.0);
    }
  }

  /// Haversine distance in km
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

  Future<void> _loadJobs() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('delivery_jobs')
          .where('status', isEqualTo: 'open')
          .limit(30)
          .get();

      final jobs = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final data = {...doc.data(), 'id': doc.id};
        final donId = data['donationId'] as String?;
        if (donId != null) {
          try {
            final don = await FirebaseFirestore.instance
                .collection('donations')
                .doc(donId)
                .get();
            if (don.exists) data['donation'] = {...don.data()!, 'id': don.id};
          } catch (_) {}
        }
        jobs.add(data);
      }

      if (mounted) {
        setState(() => _jobs = jobs);
        _buildMarkers();
      }
    } catch (e) {
      debugPrint('Error loading jobs on map: $e');
    }
  }

  Future<void> _buildMarkers() async {
    final markers = <Marker>[];

    // --- Delivery Job markers (pickup locations) ---
    if (_showJobs) {
      for (final job in _jobs) {
        // Category filter: check linked donation's category
        if (_selectedCategory != null && _selectedCategory != 'All') {
          final donation = job['donation'] as Map<String, dynamic>?;
          final donCategory = donation?['category'] as String?;
          if (donCategory != _selectedCategory) continue;
        }

        final pickup = job['pickupCoords'] as Map<String, dynamic>?;
        if (pickup == null) continue;
        final lat = (pickup['latitude'] as num?)?.toDouble();
        final lng = (pickup['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        // Distance filter for jobs
        if (_myLocation != null) {
          final dist = _haversine(
              _myLocation!.latitude, _myLocation!.longitude, lat, lng);
          if (dist > _radiusKm) continue;
        }

        final point = LatLng(lat, lng);

        markers.add(Marker(
          point: point,
          width: 56,
          height: 56,
          child: GestureDetector(
            onTap: () => _onJobTap(job, point),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.orange.withOpacity(0.4), blurRadius: 8)
                ],
              ),
              child: const Center(
                  child: Text('🛵', style: TextStyle(fontSize: 22))),
            ),
          ),
        ));

        // Also show dropoff (NGO) marker for each job
        final dropoff = job['dropoffCoords'] as Map<String, dynamic>?;
        if (dropoff != null) {
          final dLat = (dropoff['latitude'] as num?)?.toDouble();
          final dLng = (dropoff['longitude'] as num?)?.toDouble();
          if (dLat != null && dLng != null) {
            markers.add(Marker(
              point: LatLng(dLat, dLng),
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.indigo.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                    child: Icon(Icons.flag, color: Colors.white, size: 18)),
              ),
            ));
          }
        }
      }
    }

    // --- Donor markers (available donations, not already in jobs) ---
    if (_showDonors) {
      await _loadDonorMarkers(markers);
    }

    // --- NGO markers ---
    if (_showNGOs) {
      await _loadNgoMarkers(markers);
    }

    // My location
    if (_myLocation != null) {
      markers.add(MapService.createUserLocationMarker(
        latitude: _myLocation!.latitude,
        longitude: _myLocation!.longitude,
      ));
    }

    if (mounted) setState(() => _markers = markers);
  }

  Future<void> _loadDonorMarkers(List<Marker> markers) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('donations')
          .where('status', isEqualTo: 'available')
          .limit(50)
          .get();
      for (final doc in snap.docs) {
        final d = doc.data();
        final coords = d['coordinates'] as Map<String, dynamic>?;
        if (coords == null) continue;
        final lat = (coords['latitude'] as num?)?.toDouble();
        final lng = (coords['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        markers.add(Marker(
          point: LatLng(lat, lng),
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Center(
                child: Text('🍎', style: TextStyle(fontSize: 18))),
          ),
        ));
      }
    } catch (e) {
      debugPrint('Error loading donor markers: $e');
    }
  }

  Future<void> _loadNgoMarkers(List<Marker> markers) async {
    try {
      final ngos = await UserService().getUsersByRole('ngo');
      for (final ngo in ngos) {
        final coords = ngo['coordinates'] as Map<String, dynamic>?;
        if (coords == null) continue;
        final lat = (coords['latitude'] as num?)?.toDouble();
        final lng = (coords['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        markers.add(MapService.createNGOMarker(
          id: ngo['id'] as String? ?? '',
          latitude: lat,
          longitude: lng,
          ngoName: ngo['name'] as String? ?? 'NGO',
          onTap: () {},
        ));
      }
    } catch (e) {
      debugPrint('Error loading NGO markers: $e');
    }
  }

  void _onJobTap(Map<String, dynamic> job, LatLng pickupPoint) {
    final dropoff = job['dropoffCoords'] as Map<String, dynamic>?;
    LatLng? dropoffPoint;
    if (dropoff != null) {
      final dLat = (dropoff['latitude'] as num?)?.toDouble();
      final dLng = (dropoff['longitude'] as num?)?.toDouble();
      if (dLat != null && dLng != null) {
        dropoffPoint = LatLng(dLat, dLng);
      }
    }

    final lines = <Polyline>[];

    // Route 1: DP → Pickup (solid blue)
    if (_myLocation != null) {
      lines.add(Polyline(
        points: [_myLocation!, pickupPoint],
        color: Colors.blue.shade700,
        strokeWidth: 4,
        borderColor: Colors.white,
        borderStrokeWidth: 1.5,
      ));
    }

    // Route 2: Pickup → Dropoff NGO (dotted purple)
    if (dropoffPoint != null) {
      lines.add(Polyline(
        points: [pickupPoint, dropoffPoint],
        color: const Color(0xFF9C27B0),
        strokeWidth: 4,
        borderColor: Colors.white,
        borderStrokeWidth: 1.5,
        isDotted: true,
      ));
    }

    setState(() => _polylines = lines);

    // Fit map to include all points
    final allPoints = [
      if (_myLocation != null) _myLocation!,
      pickupPoint,
      if (dropoffPoint != null) dropoffPoint,
    ];
    if (allPoints.length >= 2) {
      _fitAllPoints(allPoints);
    }

    _showJobSheet(job);
  }

  void _fitAllPoints(List<LatLng> points) {
    if (!_isMapReady || points.length < 2) return;
    final lats = points.map((p) => p.latitude).toList()..sort();
    final lngs = points.map((p) => p.longitude).toList()..sort();
    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(
        LatLng(lats.first - 0.005, lngs.first - 0.005),
        LatLng(lats.last + 0.005, lngs.last + 0.005),
      ),
      padding: const EdgeInsets.all(60),
    ));
  }




  void _showJobSheet(Map<String, dynamic> job) {
    final donation = job['donation'] as Map<String, dynamic>?;
    final foodType = donation?['foodType'] as String? ?? 'Food';
    final pickupAddr = job['pickupAddress'] as String? ?? 'Pickup';
    final dropoffAddr = job['dropoffAddress'] as String? ?? 'Drop-off';
    final distKm = (job['distanceKm'] as num?)?.toDouble() ?? 0.0;
    final ngoPays = (job['ngoPays'] as num?)?.toDouble() ?? 0.0;
    final category = donation?['category'] as String? ?? '';

    // ETA from my location
    final distFromMe = _myLocation != null
        ? DeliveryService.haversineKm(
            _myLocation!.latitude,
            _myLocation!.longitude,
            (job['pickupCoords']?['latitude'] as num?)?.toDouble() ?? 0,
            (job['pickupCoords']?['longitude'] as num?)?.toDouble() ?? 0,
          )
        : distKm;
    final eta = DeliveryService.calculateEta(distFromMe);

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
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Row(
              children: [
                Text(foodType,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                if (category.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(category,
                        style: TextStyle(
                            fontSize: 11, color: Colors.green.shade700)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, size: 14, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text('ETA: ${eta.label}',
                    style: TextStyle(
                        fontSize: 13, color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                Icon(Icons.straighten, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('${distFromMe.toStringAsFixed(1)} km from you',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
            const Divider(height: 20),
            _mapSheetRow(Icons.radio_button_checked, 'Pickup', pickupAddr,
                Colors.green),
            const SizedBox(height: 6),
            _mapSheetRow(
                Icons.location_on, 'Drop-off (NGO)', dropoffAddr, Colors.indigo),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Text('🏛️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text('CSR Subsidised — NGO pays only ₹${ngoPays.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.indigo.shade700,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Navigate to delivery screen
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _DPDeliveryScreenWrapper(job: job),
                  ));
                },
                icon: const Icon(Icons.delivery_dining),
                label: const Text('Accept & Deliver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapSheetRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.bold)),
              Text(value,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Map'),
        automaticallyImplyLeading: false,
        actions: [
          if (_polylines.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear Route',
              onPressed: () => setState(() => _polylines = []),
            ),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                setState(() => _isLoading = true);
                await _loadJobs();
                if (mounted) setState(() => _isLoading = false);
              }),
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
                        _myLocation ?? const LatLng(20.5937, 78.9629),
                    initialZoom: 12.0,
                    onMapReady: () {
                      _isMapReady = true;
                      if (_myLocation != null) {
                        _mapController.move(_myLocation!, 12.0);
                      }
                    },
                    onTap: (_, __) => setState(() => _polylines = []),
                  ),
                  children: [
                    MapService.openStreetMapTileLayer,
                    // Radius circle
                    if (_myLocation != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _myLocation!,
                            radius: _radiusKm * 1000, // meters
                            useRadiusInMeter: true,
                            color: Colors.blue.withOpacity(0.06),
                            borderColor: Colors.blue.withOpacity(0.3),
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    if (_polylines.isNotEmpty)
                      PolylineLayer(polylines: _polylines),
                    MarkerLayer(markers: _markers),
                  ],
                ),
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
                          border:
                              Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_off,
                                color: Colors.orange.shade700, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_locationError!,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade800))),
                            TextButton(
                                onPressed: _locationService.openAppSettings,
                                child: const Text('Fix')),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Controls panel (top, below error banner)
                Positioned(
                  top: _locationError != null ? 80 : 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
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
                        // Radius slider
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
                                onChangeEnd: (_) => _buildMarkers(),
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
                                    _buildMarkers();
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

                // Legend & toggles
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
                      children: [
                        const Text('Legend',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('— Blue: You → Pickup',
                            style: TextStyle(fontSize: 10, color: Colors.blue)),
                        const Text('--- Purple: Pickup → NGO',
                            style: TextStyle(fontSize: 10, color: Colors.purple)),
                        const SizedBox(height: 6),
                        _legendToggle('🛵  Delivery Jobs', _showJobs,
                            Colors.orange, (v) {
                          setState(() => _showJobs = v);
                          _buildMarkers();
                        }),
                        const SizedBox(height: 4),
                        _legendToggle('🍎  Donors', _showDonors,
                            Colors.green, (v) {
                          setState(() => _showDonors = v);
                          _buildMarkers();
                        }),
                        const SizedBox(height: 4),
                        _legendToggle('🏢  NGOs', _showNGOs,
                            Colors.purple, (v) {
                          setState(() => _showNGOs = v);
                          _buildMarkers();
                        }),
                        const SizedBox(height: 4),
                        const Text('📍  My location',
                            style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    heroTag: 'dp_map_locate',
                    onPressed: () {
                      if (_myLocation != null && _isMapReady) {
                        _mapController.move(_myLocation!, 13.0);
                      } else {
                        _init();
                      }
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _legendToggle(
    String label,
    bool value,
    Color color,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? color : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14,
              color: value ? color : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
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

// Wrapper to push DPDeliveryScreen from within the map
class _DPDeliveryScreenWrapper extends StatelessWidget {
  final Map<String, dynamic> job;
  const _DPDeliveryScreenWrapper({required this.job});

  @override
  Widget build(BuildContext context) {
    return DPDeliveryScreen(jobData: job);
  }
}
