import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:foodsaver/core/services/delivery_service.dart';
import 'package:foodsaver/core/services/location_service.dart';
import 'package:foodsaver/core/services/map_service.dart';

/// Delivery Partner active delivery screen.
/// Step 1: Asks for current location.
/// Step 2: Calculates ETA to pickup, shows route.
/// Step 3: Status progression: accepted → picked_up → in_transit → delivered.
class DPDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> jobData;
  const DPDeliveryScreen({super.key, required this.jobData});

  @override
  State<DPDeliveryScreen> createState() => _DPDeliveryScreenState();
}

class _DPDeliveryScreenState extends State<DPDeliveryScreen> {
  final _mapController = MapController();
  final _locationService = LocationService();
  final _deliveryService = DeliveryService();

  LatLng? _myLocation;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  List<Polyline> _polylines = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isMapReady = false;

  String _status = 'open'; // open → accepted → picked_up → in_transit → delivered
  DeliveryEta? _eta;
  String _jobId = '';

  @override
  void initState() {
    super.initState();
    _jobId = widget.jobData['id'] as String? ?? '';
    _status = widget.jobData['status'] as String? ?? 'open';
    _loadData();
  }

  Future<void> _loadData() async {
    // Extract coords from job
    final pickup = widget.jobData['pickupCoords'] as Map<String, dynamic>?;
    final dropoff = widget.jobData['dropoffCoords'] as Map<String, dynamic>?;

    if (pickup != null) {
      _pickupLocation = LatLng(
        (pickup['latitude'] as num).toDouble(),
        (pickup['longitude'] as num).toDouble(),
      );
    }
    if (dropoff != null) {
      _dropoffLocation = LatLng(
        (dropoff['latitude'] as num).toDouble(),
        (dropoff['longitude'] as num).toDouble(),
      );
    }

    // Get my location
    try {
      final pos = await _locationService.getCurrentLocation();
      _myLocation = LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      _myLocation = _pickupLocation; // fallback
    }

    // If job is still open — accept it now
    if (_status == 'open' && _myLocation != null) {
      try {
        final eta = await _deliveryService.acceptDeliveryJob(
          jobId: _jobId,
          partnerLat: _myLocation!.latitude,
          partnerLng: _myLocation!.longitude,
        );
        setState(() {
          _eta = eta;
          _status = 'accepted';
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error accepting: $e')));
        }
      }
    } else if (_status != 'open') {
      // Already accepted: recompute eta from saved partner location
      final partnerLoc =
          widget.jobData['partnerLocation'] as Map<String, dynamic>?;
      if (partnerLoc != null && _pickupLocation != null) {
        final pLat = (partnerLoc['latitude'] as num).toDouble();
        final pLng = (partnerLoc['longitude'] as num).toDouble();
        final dist = DeliveryService.haversineKm(
            pLat, pLng, _pickupLocation!.latitude, _pickupLocation!.longitude);
        _eta = DeliveryService.calculateEta(dist);
      }
    }

    _buildPolylines();
    setState(() => _isLoading = false);
    _fitMap();
  }

  void _buildPolylines() {
    final lines = <Polyline>[];
    // Me → Pickup
    if (_myLocation != null && _pickupLocation != null) {
      lines.add(Polyline(
        points: [_myLocation!, _pickupLocation!],
        color: Colors.blue.shade700,
        strokeWidth: 4,
        borderColor: Colors.white,
        borderStrokeWidth: 1.5,
      ));
    }
    // Pickup → Dropoff
    if (_pickupLocation != null && _dropoffLocation != null) {
      lines.add(Polyline(
        points: [_pickupLocation!, _dropoffLocation!],
        color: const Color(0xFF9C27B0),
        strokeWidth: 4,
        borderColor: Colors.white,
        borderStrokeWidth: 1.5,
        isDotted: true,
      ));
    }
    setState(() => _polylines = lines);
  }

  void _fitMap() {
    final points = [
      if (_myLocation != null) _myLocation!,
      if (_pickupLocation != null) _pickupLocation!,
      if (_dropoffLocation != null) _dropoffLocation!,
    ];
    if (points.length < 2) return;
    final lats = points.map((p) => p.latitude).toList()..sort();
    final lngs = points.map((p) => p.longitude).toList()..sort();
    final bounds = LatLngBounds(
      LatLng(lats.first - 0.005, lngs.first - 0.005),
      LatLng(lats.last + 0.005, lngs.last + 0.005),
    );
    if (_isMapReady) {
      _mapController.fitCamera(
        CameraFit.bounds(
            bounds: bounds, padding: const EdgeInsets.all(60)),
      );
    }
  }

  Future<void> _advanceStatus() async {
    final nextStatus = _nextStatus(_status);
    if (nextStatus == null) return;

    setState(() => _isSaving = true);
    try {
      await _deliveryService.updateJobStatus(_jobId, nextStatus);
      setState(() => _status = nextStatus);

      if (nextStatus == 'delivered' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🎉 Delivery complete! Well done!'),
          backgroundColor: Colors.green,
        ));
        Future.delayed(const Duration(seconds: 2),
            () => context.go('/dp-dashboard'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _nextStatus(String current) {
    const flow = [
      'accepted',
      'picked_up',
      'in_transit',
      'delivered',
    ];
    final idx = flow.indexOf(current);
    if (idx == -1 || idx >= flow.length - 1) return null;
    return flow[idx + 1];
  }

  String _buttonLabel(String status) {
    switch (status) {
      case 'accepted':
        return '✅ Mark as Picked Up';
      case 'picked_up':
        return '🚛 Start Transit to NGO';
      case 'in_transit':
        return '🏢 Mark as Delivered';
      default:
        return 'Next Step';
    }
  }

  Color _buttonColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.orange;
      case 'picked_up':
        return Colors.blue;
      case 'in_transit':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    if (_pickupLocation != null) {
      markers.add(Marker(
        point: _pickupLocation!,
        width: 52,
        height: 52,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 8)
            ],
          ),
          child: const Center(
              child: Text('🍎', style: TextStyle(fontSize: 22))),
        ),
      ));
    }
    if (_dropoffLocation != null) {
      markers.add(Marker(
        point: _dropoffLocation!,
        width: 52,
        height: 52,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.purple.withOpacity(0.4), blurRadius: 8)
            ],
          ),
          child: const Center(
              child: Text('🏢', style: TextStyle(fontSize: 22))),
        ),
      ));
    }
    if (_myLocation != null) {
      markers.add(Marker(
        point: _myLocation!,
        width: 56,
        height: 56,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                  color: Colors.blue.withOpacity(0.4), blurRadius: 8)
            ],
          ),
          child: const Center(
              child: Text('🛵', style: TextStyle(fontSize: 24))),
        ),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final jobData = widget.jobData;
    final donation = jobData['donation'] as Map<String, dynamic>?;
    final foodType = donation?['foodType'] as String? ?? 'Delivery';
    final pickupAddr = jobData['pickupAddress'] as String? ?? 'Pickup';
    final dropoffAddr = jobData['dropoffAddress'] as String? ?? 'Drop-off';
    final distKm = (jobData['distanceKm'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Delivery'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Getting your location…',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                // ── ETA Banner ───────────────────────────────────────────────
                if (_eta != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: Colors.blue.shade700,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'ETA to pickup: ${_eta!.label}  •  ${_eta!.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                // ── Map ──────────────────────────────────────────────────────
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.40,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter:
                              _pickupLocation ?? const LatLng(20.5937, 78.9629),
                          initialZoom: 14.0,
                          onMapReady: () {
                            _isMapReady = true;
                            _fitMap();
                          },
                        ),
                        children: [
                          MapService.openStreetMapTileLayer,
                          if (_polylines.isNotEmpty)
                            PolylineLayer(polylines: _polylines),
                          MarkerLayer(markers: _buildMarkers()),
                        ],
                      ),
                      // Legend
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🍎 Pickup (donor)',
                                  style: TextStyle(fontSize: 11)),
                              SizedBox(height: 2),
                              Text('🏢 Drop-off (NGO)',
                                  style: TextStyle(fontSize: 11)),
                              SizedBox(height: 2),
                              Text('🛵 You',
                                  style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      // Re-center
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'dp_locate',
                          onPressed: () {
                            if (_myLocation != null) {
                              _mapController.move(_myLocation!, 14.0);
                            }
                          },
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Details & Timeline ───────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.shade100,
                                    blurRadius: 8)
                              ]),
                          child: Column(
                            children: [
                              _infoRow(Icons.restaurant_menu, foodType,
                                  isBold: true),
                              const Divider(height: 16),
                              _infoRow(Icons.radio_button_checked, pickupAddr,
                                  color: Colors.green),
                              const SizedBox(height: 4),
                              _infoRow(Icons.location_on, dropoffAddr,
                                  color: Colors.indigo),
                              const Divider(height: 16),
                              _infoRow(Icons.straighten,
                                  '${distKm.toStringAsFixed(1)} km total route'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Status timeline
                        const Text('Delivery Progress',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        _buildTimeline(),
                        const SizedBox(height: 24),

                        // Action button
                        if (_nextStatus(_status) != null)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _advanceStatus,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _buttonColor(_status),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : Text(_buttonLabel(_status)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTimeline() {
    final steps = [
      _Step('✅', 'Job Accepted', 'Delivery confirmed',
          ['accepted', 'picked_up', 'in_transit', 'delivered']
              .contains(_status)),
      _Step('🍎', 'Food Picked Up', 'Collected from donor',
          ['picked_up', 'in_transit', 'delivered'].contains(_status)),
      _Step('🚛', 'In Transit', 'On the way to NGO',
          ['in_transit', 'delivered'].contains(_status)),
      _Step('🏢', 'Delivered', 'Handed to NGO', _status == 'delivered',
          isLast: true),
    ];
    return Column(
      children: steps.map((s) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: s.done ? Colors.green : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: Text(s.emoji,
                          style: const TextStyle(fontSize: 14))),
                ),
                if (!s.isLast)
                  Container(
                      width: 2,
                      height: 36,
                      color: s.done ? Colors.green : Colors.grey.shade300),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: s.done
                              ? Colors.green
                              : Colors.grey.shade600)),
                  Text(s.subtitle,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                  SizedBox(height: s.isLast ? 0 : 18),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _infoRow(IconData icon, String label,
      {Color? color, bool isBold = false}) {
    return Row(
      children: [
        Icon(icon,
            size: 16, color: color ?? Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

class _Step {
  final String emoji;
  final String title;
  final String subtitle;
  final bool done;
  final bool isLast;
  const _Step(this.emoji, this.title, this.subtitle, this.done,
      {this.isLast = false});
}
