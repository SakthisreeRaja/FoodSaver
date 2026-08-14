import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:foodsaver/core/services/notification_service.dart';

/// Pickup details for volunteers — accepts Map<String,dynamic>, shows enriched donation,
/// lets volunteer accept, start, or complete the pickup.
class PickupDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> pickupData;
  const PickupDetailsScreen({super.key, required this.pickupData});

  @override
  State<PickupDetailsScreen> createState() => _PickupDetailsScreenState();
}

class _PickupDetailsScreenState extends State<PickupDetailsScreen> {
  Map<String, dynamic>? _donation;
  bool _isLoading = true;
  bool _isSaving = false;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.pickupData['status'] as String? ?? 'pending';
    _loadDonation();
  }

  Future<void> _loadDonation() async {
    final donId = widget.pickupData['donationId'] as String?;
    if (donId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('donations')
            .doc(donId)
            .get();
        if (doc.exists) {
          setState(() =>
              _donation = {...doc.data()!, 'id': doc.id});
        }
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  Future<void> _acceptPickup() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final pickupId = widget.pickupData['id'] as String?;
    if (pickupId == null) return;

    setState(() => _isSaving = true);
    try {
      // Get volunteer name
      final volunteerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final volunteerName =
          volunteerDoc.data()?['name'] as String? ?? 'A volunteer';

      await FirebaseFirestore.instance
          .collection('pickups')
          .doc(pickupId)
          .update({
        'volunteerId': uid,
        'status': 'scheduled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      setState(() => _status = 'scheduled');

      // Notify the donor
      final donorId = _donation?['donorId'] as String?;
      final foodType = _donation?['foodType'] as String? ?? 'Food';
      if (donorId != null) {
        await NotificationService().sendPickupAcceptedNotification(
          donorUid: donorId,
          pickupId: pickupId,
          foodType: foodType,
          volunteerName: volunteerName,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Pickup accepted! Donor notified.'),
              backgroundColor: Colors.green),
        );
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
        final donId = widget.pickupData['donationId'] as String?;
        if (donId != null) {
          await FirebaseFirestore.instance
              .collection('donations')
              .doc(donId)
              .update({'status': 'completed'});
        }
        if (mounted) {
          context.pushReplacement('/delivery-completed', extra: {
            ...widget.pickupData,
            'donation': _donation ?? {},
            'status': 'completed',
          });
        }
        return;
      }

      setState(() => _status = newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status: ${newStatus.toUpperCase()}')),
        );
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

  @override
  Widget build(BuildContext context) {
    final d = _donation ?? {};
    final foodType = d['foodType'] as String? ?? 'Food Pickup';
    final qty = d['quantity'] as int? ?? 0;
    final unit = d['unit'] as String? ?? '';
    final location = d['pickupLocation'] as String? ?? 'N/A';
    final category = d['category'] as String? ?? '';
    final notes = d['description'] as String? ?? '';
    final aiData = d['aiAnalysis'] as Map<String, dynamic>?;

    final statusColor = _color(_status);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Pickup Details' : foodType),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(_icon(_status), color: statusColor, size: 28),
                        const SizedBox(width: 12),
                        Text(_status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Details
                  _card([
                    _row(Icons.fastfood_outlined, 'Food Type', foodType),
                    _div(),
                    _row(Icons.category_outlined, 'Category',
                        category.isNotEmpty ? category : '—'),
                    _div(),
                    _row(Icons.scale, 'Quantity', '$qty $unit'),
                    _div(),
                    _row(Icons.location_on_outlined, 'Pickup Location',
                        location),
                    if (notes.isNotEmpty) ...[
                      _div(),
                      _row(Icons.notes_outlined, 'Notes', notes),
                    ],
                  ]),

                  // AI card
                  if (aiData != null) ...[
                    const SizedBox(height: 16),
                    _aiCard(aiData),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  if (_status == 'pending') ...[
                    _btn('Accept Pickup', Icons.check_circle,
                        Colors.green, _acceptPickup),
                  ],
                  if (_status == 'scheduled') ...[
                    _btn('Start Transit 🚚', Icons.local_shipping,
                        Colors.blue, () => _updateStatus('in_progress')),
                    const SizedBox(height: 10),
                    _btn(
                        'Track on Map',
                        Icons.map_outlined,
                        Colors.teal,
                        () => context.push('/delivery-tracking', extra: {
                              ...widget.pickupData,
                              'status': _status,
                            })),
                  ],
                  if (_status == 'in_progress') ...[
                    _btn('Mark Delivered ✓', Icons.check_circle,
                        Colors.green, () => _updateStatus('completed')),
                    const SizedBox(height: 10),
                    _btn(
                        'View on Map 🗺️',
                        Icons.map_outlined,
                        Colors.teal,
                        () => context.push('/delivery-tracking', extra: {
                              ...widget.pickupData,
                              'status': _status,
                            })),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade100, blurRadius: 8)
          ]),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children)),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _div() => Divider(height: 1, color: Colors.grey.shade100);

  Widget _aiCard(Map<String, dynamic> ai) {
    final safe = ai['safeToEat'] as bool? ?? true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Verified',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (ai['notes'] != null)
                  Text(ai['notes'] as String,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: safe ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(safe ? '✅ Safe' : '⚠️ Check',
                style: TextStyle(
                    fontSize: 11,
                    color: safe ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : onTap,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _color(String s) {
    switch (s) {
      case 'completed': return Colors.green;
      case 'scheduled': return Colors.blue;
      case 'in_progress': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _icon(String s) {
    switch (s) {
      case 'completed': return Icons.check_circle;
      case 'scheduled': return Icons.calendar_today;
      case 'in_progress': return Icons.local_shipping;
      case 'cancelled': return Icons.cancel;
      default: return Icons.pending_actions;
    }
  }
}
