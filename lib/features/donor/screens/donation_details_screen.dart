import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Accepts Map<String,dynamic> from Firestore — no more old Donation model.
class DonationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> donation;
  const DonationDetailsScreen({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    final status = donation['status'] as String? ?? 'available';
    final foodType = donation['foodType'] as String? ?? 'Donation';
    final qty = donation['quantity'] as int? ?? 0;
    final unit = donation['unit'] as String? ?? '';
    final category = donation['category'] as String? ?? '';
    final description = donation['description'] as String? ?? '';
    final location = donation['pickupLocation'] as String? ?? '';
    final donId = donation['id'] as String? ?? '';
    final aiData = donation['aiAnalysis'] as Map<String, dynamic>?;

    final ts = donation['createdAt'];
    String dateStr = '';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      dateStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }

    final statusColor = _statusColor(status);

    return Scaffold(
      appBar: AppBar(
        title: Text(foodType),
        centerTitle: true,
        actions: [
          if (status == 'available')
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/edit-donation', extra: donation),
              tooltip: 'Edit',
            ),
        ],
      ),
      body: SingleChildScrollView(
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
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon(status), color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(status.toUpperCase(),
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      if (dateStr.isNotEmpty)
                        Text(dateStr,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Details card
            _card(children: [
              _row(Icons.fastfood_outlined, 'Food Type', foodType),
              _divider(),
              _row(Icons.category_outlined, 'Category', category.isNotEmpty ? category : '—'),
              _divider(),
              _row(Icons.inventory_2_outlined, 'Quantity', '$qty $unit'),
              _divider(),
              _row(Icons.location_on_outlined, 'Pickup Location',
                  location.isNotEmpty ? location : '—'),
              if (description.isNotEmpty) ...[
                _divider(),
                _row(Icons.notes_outlined, 'Notes', description),
              ],
            ]),

            // AI Analysis card
            if (aiData != null) ...[
              const SizedBox(height: 16),
              _aiAnalysisCard(aiData),
            ],

            const SizedBox(height: 24),

            // Cancel button (only for available donations)
            if (status == 'available')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmCancel(context, donId),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text('Cancel Donation',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
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

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100, blurRadius: 8, spreadRadius: 1)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
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

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade100);

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
          if (ai['notes'] != null && (ai['notes']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(ai['notes'].toString(),
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600)),
          ],
          // Show AI-detected food type
          if (ai['foodType'] != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 14, color: Colors.indigo.shade300),
                const SizedBox(width: 6),
                Text('Detected: ${ai['foodType']}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, String donationId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Donation?'),
        content: const Text(
            'This will mark the donation as cancelled. NGOs will no longer be able to claim it.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep it')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('donations')
                    .doc(donationId)
                    .update({
                  'status': 'cancelled',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Donation cancelled.'),
                        backgroundColor: Colors.red),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Cancel Donation',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed': return Colors.green;
      case 'claimed': return Colors.blue;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'completed': return Icons.check_circle;
      case 'claimed': return Icons.local_shipping;
      case 'cancelled': return Icons.cancel;
      default: return Icons.pending_actions;
    }
  }
}
