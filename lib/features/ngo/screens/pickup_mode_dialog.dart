import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodsaver/core/services/delivery_service.dart';
import 'package:foodsaver/core/services/location_service.dart';

/// Bottom-sheet dialog shown to the NGO when they claim a donation.
/// Let them choose: 🚗 Self-Pickup (free) or 🛵 Delivery Partner (CSR subsidised).
class PickupModeDialog extends StatefulWidget {
  final Map<String, dynamic> donation;

  const PickupModeDialog({super.key, required this.donation});

  /// Show the dialog and return true if claiming succeeded, null if dismissed.
  static Future<bool?> show(
      BuildContext context, Map<String, dynamic> donation) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PickupModeDialog(donation: donation),
    );
  }

  @override
  State<PickupModeDialog> createState() => _PickupModeDialogState();
}

class _PickupModeDialogState extends State<PickupModeDialog> {
  bool _isCalculating = false;
  bool _isClaiming = false;
  DeliveryFare? _fare;
  double? _distanceKm;
  String? _errorMsg;

  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _calculateFare();
  }

  Future<void> _calculateFare() async {
    setState(() => _isCalculating = true);
    try {
      // Get NGO current location
      final pos = await _locationService.getCurrentLocation();
      final ngoLat = pos.latitude;
      final ngoLng = pos.longitude;

      // Get donation pickup coords
      final coords =
          widget.donation['coordinates'] as Map<String, dynamic>?;
      if (coords == null) {
        setState(() {
          _errorMsg = 'Donation location not available.';
          _isCalculating = false;
        });
        return;
      }
      final donorLat = (coords['latitude'] as num).toDouble();
      final donorLng = (coords['longitude'] as num).toDouble();

      final dist = DeliveryService.haversineKm(ngoLat, ngoLng, donorLat, donorLng);
      final fare = DeliveryService.calculateFare(dist);

      setState(() {
        _distanceKm = dist;
        _fare = fare;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Could not get location: $e';
        _isCalculating = false;
        // Fallback with a 5km estimate
        _distanceKm = 5.0;
        _fare = DeliveryService.calculateFare(5.0);
      });
    }
  }

  Future<void> _chooseSelfPickup() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final donId = widget.donation['id'] as String?;
    if (donId == null) return;

    setState(() => _isClaiming = true);
    try {
      // Get NGO location for storing on donation
      double ngoLat = 0, ngoLng = 0;
      try {
        final pos = await _locationService.getCurrentLocation();
        ngoLat = pos.latitude;
        ngoLng = pos.longitude;
      } catch (_) {}

      final batch = FirebaseFirestore.instance.batch();
      final donRef =
          FirebaseFirestore.instance.collection('donations').doc(donId);
      final pickupRef = FirebaseFirestore.instance.collection('pickups').doc();

      // Get NGO name
      final ngoDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final ngoName = ngoDoc.data()?['name'] as String? ?? 'An NGO';

      batch.update(donRef, {
        'status': 'claimed',
        'claimedBy': uid,
        'claimedAt': FieldValue.serverTimestamp(),
        'ngoName': ngoName,
        if (ngoLat != 0 && ngoLng != 0)
          'ngoCoordinates': {
            'latitude': ngoLat,
            'longitude': ngoLng,
          },
      });
      batch.set(pickupRef, {
        'id': pickupRef.id,
        'donationId': donId,
        'ngoId': uid,
        'deliveryType': 'self',
        'status': 'self_pickup',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      // Notify donor (no DP notification for self-pickup)
      final donorId = widget.donation['donorId'] as String?;
      final foodType = widget.donation['foodType'] as String? ?? 'Food';
      if (donorId != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': donorId,
          'type': 'self_pickup',
          'title': '🚗 NGO is Coming!',
          'body': '$ngoName will self-collect your "$foodType" donation.',
          'donationId': donId,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isClaiming = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _chooseDeliveryPartner() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _fare == null) return;
    final donId = widget.donation['id'] as String?;
    if (donId == null) return;

    setState(() => _isClaiming = true);
    try {
      // Get donor coords
      final coords = widget.donation['coordinates'] as Map<String, dynamic>?;
      final donorLat = (coords?['latitude'] as num?)?.toDouble() ?? 0.0;
      final donorLng = (coords?['longitude'] as num?)?.toDouble() ?? 0.0;
      final pickupAddr =
          widget.donation['pickupLocation'] as String? ?? 'Donor Location';

      // Get NGO location and address
      final pos = await _locationService.getCurrentLocation();
      final ngoDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final dropoffAddr = ngoDoc.data()?['address'] as String? ?? 'NGO Location';
      final ngoName = ngoDoc.data()?['name'] as String? ?? 'NGO';
      final donorId = widget.donation['donorId'] as String?;

      // Create delivery job
      final jobId = await DeliveryService().createDeliveryJob(
        donationId: donId,
        ngoId: uid,
        donorId: donorId ?? '',
        pickupLat: donorLat,
        pickupLng: donorLng,
        pickupAddress: pickupAddr,
        dropoffLat: pos.latitude,
        dropoffLng: pos.longitude,
        dropoffAddress: dropoffAddr,
        fare: _fare!,
      );

      // Create linked pickup doc + update donation with NGO info
      final batch = FirebaseFirestore.instance.batch();
      final donRef =
          FirebaseFirestore.instance.collection('donations').doc(donId);
      final pickupRef = FirebaseFirestore.instance.collection('pickups').doc();

      batch.update(donRef, {
        'status': 'claimed',
        'claimedBy': uid,
        'claimedAt': FieldValue.serverTimestamp(),
        'ngoName': ngoName,
        'ngoCoordinates': {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        },
      });
      batch.set(pickupRef, {
        'id': pickupRef.id,
        'donationId': donId,
        'ngoId': uid,
        'donorId': donorId ?? '',
        'deliveryType': 'delivery_partner',
        'deliveryJobId': jobId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      // Notify donor with donationId for tap-to-view
      final foodType = widget.donation['foodType'] as String? ?? 'Food';
      if (donorId != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': donorId,
          'type': 'pickup_accepted',
          'title': '😴 Pickup Accepted!',
          'body': '$ngoName claimed your "$foodType" via Delivery Partner.',
          'donationId': donId,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isClaiming = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodType = widget.donation['foodType'] as String? ?? 'Food';
    final qty = widget.donation['quantity'] as int? ?? 0;
    final unit = widget.donation['unit'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restaurant_menu,
                          color: Colors.green, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(foodType,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17)),
                          Text('$qty $unit',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text('How will you collect this donation?',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800)),
                const SizedBox(height: 16),

                // ── Option 1: Self Pickup ───────────────────────────────────
                _optionCard(
                  emoji: '🚗',
                  title: 'Self-Pickup',
                  subtitle: 'Your team collects from the donor',
                  tag: 'FREE',
                  tagColor: Colors.green,
                  detail: _isCalculating
                      ? 'Calculating distance…'
                      : _distanceKm != null
                          ? '~${_distanceKm!.toStringAsFixed(1)} km from your location'
                          : '',
                  borderColor: Colors.green,
                  onTap: _isClaiming ? null : _chooseSelfPickup,
                  isLoading: _isClaiming,
                ),
                const SizedBox(height: 12),

                // ── Option 2: Delivery Partner ──────────────────────────────
                _fare == null && _isCalculating
                    ? _loadingCard()
                    : _optionCard(
                        emoji: '🛵',
                        title: 'Delivery Partner',
                        subtitle: 'FoodSaver dispatches a delivery partner',
                        tag: 'CSR Funded',
                        tagColor: Colors.indigo,
                        detail: _fare != null
                            ? _buildFareDetail(_fare!)
                            : 'Location needed to calculate fare',
                        borderColor: Colors.indigo,
                        onTap: _isClaiming ? null : _chooseDeliveryPartner,
                        isLoading: _isClaiming,
                        fareWidget: _fare != null ? _fareBreakdown(_fare!) : null,
                      ),

                if (_errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.orange.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location unavailable — fare estimated for 5 km',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text('Cancel',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionCard({
    required String emoji,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required String detail,
    required Color borderColor,
    required VoidCallback? onTap,
    required bool isLoading,
    Widget? fareWidget,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: tagColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(tag,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: tagColor)),
                          ),
                        ],
                      ),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: borderColor),
              ],
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(detail,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
            if (fareWidget != null) ...[
              const SizedBox(height: 8),
              fareWidget,
            ],
          ],
        ),
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Calculating delivery fare…',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _buildFareDetail(DeliveryFare fare) {
    return '${fare.distanceKm.toStringAsFixed(1)} km • You pay only ${fare.ngoPaysStr}';
  }

  Widget _fareBreakdown(DeliveryFare fare) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _fareRow('Delivery fare', fare.originalFareStr, Colors.grey.shade700),
          const SizedBox(height: 4),
          _fareRow(
              '🏛️ CSR Subsidy (70%)', '− ${fare.csrSubsidyStr}', Colors.green),
          const Divider(height: 12),
          _fareRow('You Pay', fare.ngoPaysStr, Colors.indigo,
              bold: true),
        ],
      ),
    );
  }

  Widget _fareRow(String label, String value, Color color,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
