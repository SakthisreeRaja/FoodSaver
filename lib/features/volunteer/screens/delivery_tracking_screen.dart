import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:foodsaver/core/services/location_service.dart';
import 'package:foodsaver/core/services/map_service.dart';
import 'package:go_router/go_router.dart';

/// Full delivery tracking with FlutterMap, truck marker, timeline, and Firestore updates.
/// Accepts a Map<String,dynamic> of pickup data (id, donationId, status…).
class DeliveryTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> pickupData;
  const DeliveryTrackingScreen({super.key, required this.pickupData});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  LatLng? _myLocation;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  List<Polyline> _routePolylines = [];
  bool _isLoading = true;
  String _status = 'scheduled';
  bool _isSaving = false;

  Map<String, dynamic> _donation = {};

  @override
  void initState() {
    super.initState();
    _status = widget.pickupData['status'] as String? ?? 'scheduled';
    _loadData();
  }

  Future<void> _loadData() async {
    // Get my location
    try {
      final pos = await _locationService.getCurrentLocation();
      _myLocation = LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      _myLocation = const LatLng(20.5937, 78.9629);
    }

    // Load donation details
    final donationId = widget.pickupData['donationId'] as String?;
    if (donationId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('donations')
            .doc(donationId)
            .get();
        if (doc.exists) {
          _donation = {...doc.data()!, 'id': doc.id};
          final coords = _donation['coordinates'] as Map<String, dynamic>?;
          if (coords != null) {
            _pickupLocation = LatLng(
              (coords['latitude'] as num?)?.toDouble() ?? 0,
              (coords['longitude'] as num?)?.toDouble() ?? 0,
            );
          }
        }
      } catch (_) {}
    }

    // Load NGO location
    final ngoId = widget.pickupData['ngoId'] as String?;
    if (ngoId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(ngoId)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            _dropoffLocation = LatLng(lat, lng);
          }
        }
      } catch (_) {}
    }

    setState(() => _isLoading = false);

    // Build route polylines
    _buildRoutePolylines();

    // Fit map to show all points
    _fitMapToRoute();
  }

  void _buildRoutePolylines() {
    final polylines = <Polyline>[];

    // Segment 1: volunteer → pickup (blue)
    if (_myLocation != null && _pickupLocation != null) {
      polylines.add(Polyline(
        points: [_myLocation!, _pickupLocation!],
        color: Colors.blue.shade700,
        strokeWidth: 4.0,
        borderColor: Colors.white,
        borderStrokeWidth: 1.5,
      ));
    }

    // Segment 2: pickup → NGO dropoff (purple)
    if (_pickupLocation != null && _dropoffLocation != null) {
      polylines.add(Polyline(
        points: [_pickupLocation!, _dropoffLocation!],
        color: const Color(0xFF9C27B0),
        strokeWidth: 4.0,
        borderColor: Colors.white,
        borderStrokeWidth: 1.5,
        isDotted: true,
      ));
    }

    setState(() => _routePolylines = polylines);
  }

  /// Fit map camera to show all route points.
  void _fitMapToRoute() {
    final points = [
      if (_myLocation != null) _myLocation!,
      if (_pickupLocation != null) _pickupLocation!,
      if (_dropoffLocation != null) _dropoffLocation!,
    ];
    if (points.length < 2) {
      final center = _pickupLocation ?? _myLocation;
      if (center != null) _mapController.move(center, 13.0);
      return;
    }
    final lats = points.map((p) => p.latitude).toList();
    final lngs = points.map((p) => p.longitude).toList();
    lats.sort();
    lngs.sort();
    final bounds = LatLngBounds(
      LatLng(lats.first - 0.005, lngs.first - 0.005),
      LatLng(lats.last + 0.005, lngs.last + 0.005),
    );
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    final pickupId = widget.pickupData['id'] as String?;
    if (pickupId == null) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('pickups')
          .doc(pickupId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (newStatus == 'completed')
          'completedAt': FieldValue.serverTimestamp(),
      });

      if (newStatus == 'completed') {
        final donationId = widget.pickupData['donationId'] as String?;
        if (donationId != null) {
          await FirebaseFirestore.instance
              .collection('donations')
              .doc(donationId)
              .update({'status': 'completed'});
        }
        if (mounted) {
          context.pushReplacement('/delivery-completed',
              extra: {
                ...widget.pickupData,
                'donation': _donation,
                'status': newStatus,
              });
        }
        return;
      }

      setState(() => _status = newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Status updated: ${newStatus.toUpperCase()}'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodType =
        _donation['foodType'] as String? ?? 'Food Pickup';
    final pickupAddr =
        _donation['pickupLocation'] as String? ?? 'Pickup Location';
    final qty = _donation['quantity'] as int? ?? 0;
    final unit = _donation['unit'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Delivery'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Map ────────────────────────────────────────────────
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.42,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _pickupLocation ??
                              _myLocation ??
                              const LatLng(20.5937, 78.9629),
                          initialZoom: 14.0,
                          maxZoom: 18.0,
                        ),
                        children: [
                          MapService.openStreetMapTileLayer,
                          if (_routePolylines.isNotEmpty)
                            PolylineLayer(polylines: _routePolylines),
                          MarkerLayer(
                            markers: _buildMarkers(),
                          ),
                        ],
                      ),
                      // My location button
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'locate',
                          onPressed: () {
                            if (_myLocation != null) {
                              _mapController.move(_myLocation!, 14.0);
                            }
                          },
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                      // Legend
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🍎  Pickup point (green)',
                                  style: TextStyle(fontSize: 11)),
                              SizedBox(height: 2),
                              Text('🏢  Drop-off NGO (purple)',
                                  style: TextStyle(fontSize: 11)),
                              SizedBox(height: 2),
                              Text('🚚  You (blue)',
                                  style: TextStyle(fontSize: 11)),
                              SizedBox(height: 2),
                              Text('━━  Your route',
                                  style: TextStyle(fontSize: 11, color: Colors.blue)),
                              SizedBox(height: 2),
                              Text('┅┅  To NGO',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF9C27B0))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Details + Timeline ─────────────────────────────────
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
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.restaurant_menu,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(foodType,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    Text('$qty $unit • $pickupAddr',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              _statusBadge(_status),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Timeline
                        const Text('Delivery Timeline',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        _buildTimeline(),
                        const SizedBox(height: 24),

                        // Action button
                        if (_status == 'scheduled')
                          _actionButton(
                            'Start Transit',
                            Icons.local_shipping,
                            Colors.blue,
                            () => _updateStatus('in_progress'),
                          ),
                        if (_status == 'in_progress')
                          _actionButton(
                            'Mark as Delivered ✓',
                            Icons.check_circle,
                            Colors.green,
                            () => _updateStatus('completed'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];

    // 🍎 Pickup location
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
              BoxShadow(
                  color: Colors.green.withOpacity(0.4), blurRadius: 8)
            ],
          ),
          child: const Center(
              child: Text('🍎', style: TextStyle(fontSize: 22))),
        ),
      ));
    }

    // 🏢 NGO drop-off
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

    // 🚚 My (truck) location
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
              child: Text('🚚', style: TextStyle(fontSize: 24))),
        ),
      ));
    }

    return markers;
  }

  Widget _buildTimeline() {
    final steps = [
      _TimelineStep(
        emoji: '📋',
        title: 'Pickup Scheduled',
        subtitle: 'Pickup assigned to you',
        isDone: true,
      ),
      _TimelineStep(
        emoji: '🚚',
        title: 'In Transit',
        subtitle: 'Heading to pickup location',
        isDone: _status == 'in_progress' || _status == 'completed',
      ),
      _TimelineStep(
        emoji: '🏢',
        title: 'Delivered',
        subtitle: 'Drop-off at NGO complete',
        isDone: _status == 'completed',
        isLast: true,
      ),
    ];

    return Column(
      children: steps
          .map((step) => _buildTimelineItem(step))
          .toList(),
    );
  }

  Widget _buildTimelineItem(_TimelineStep step) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: step.isDone
                    ? Colors.green
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(step.emoji,
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
            if (!step.isLast)
              Container(
                width: 2,
                height: 40,
                color: step.isDone ? Colors.green : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: step.isDone
                          ? Colors.green
                          : Colors.grey.shade700)),
              Text(step.subtitle,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
              SizedBox(height: step.isLast ? 0 : 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final color = status == 'completed'
        ? Colors.green
        : status == 'in_progress'
            ? Colors.blue
            : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Text(status.replaceAll('_', ' ').toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _actionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : onPressed,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold),
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

class _TimelineStep {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isLast;
  _TimelineStep({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.isDone = false,
    this.isLast = false,
  });
}
