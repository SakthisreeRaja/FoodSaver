import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// Real-time stream of donor's own donations
final myDonationsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('donations')
      .where('donorId', isEqualTo: uid)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
});

class DonationHistoryScreen extends ConsumerWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(myDonationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Donations'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: donationsAsync.when(
        data: (donations) {
          if (donations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volunteer_activism,
                      size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No donations yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Tap the Donate button to add your first donation!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            );
          }

          final active = donations
              .where((d) =>
                  d['status'] == 'available' || d['status'] == 'claimed')
              .toList();
          final completed = donations
              .where((d) => d['status'] == 'completed')
              .toList();
          final cancelled = donations
              .where((d) => d['status'] == 'cancelled')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary stats
              _buildSummaryRow(context, active.length,
                  completed.length, donations.length),
              const SizedBox(height: 20),

              if (active.isNotEmpty) ...[
                _sectionHeader(context, '🟡 Active', Colors.orange, active.length),
                ...active.map((d) => _donationCard(context, d)),
                const SizedBox(height: 8),
              ],
              if (completed.isNotEmpty) ...[
                _sectionHeader(
                    context, '✅ Completed', Colors.green, completed.length),
                ...completed.map((d) => _donationCard(context, d)),
                const SizedBox(height: 8),
              ],
              if (cancelled.isNotEmpty) ...[
                _sectionHeader(
                    context, '❌ Cancelled', Colors.red, cancelled.length),
                ...cancelled.map((d) => _donationCard(context, d)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error: $e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(myDonationsStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, int active, int completed, int total) {
    return Row(
      children: [
        Expanded(
          child: _summaryTile('$total', 'Total', Colors.blue, context),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryTile('$active', 'Active', Colors.orange, context),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryTile('$completed', 'Done', Colors.green, context),
        ),
      ],
    );
  }

  Widget _summaryTile(
      String value, String label, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _sectionHeader(
      BuildContext context, String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
        ],
      ),
    );
  }

  Widget _donationCard(
      BuildContext context, Map<String, dynamic> donation) {
    final status = donation['status'] as String? ?? 'available';
    final statusColor = status == 'completed'
        ? Colors.green
        : status == 'cancelled'
            ? Colors.red
            : Colors.orange;

    final ts = donation['createdAt'];
    String dateStr = '';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      dateStr =
          '${dt.day}/${dt.month}/${dt.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade100, blurRadius: 6, spreadRadius: 1)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              status == 'completed'
                  ? Icons.check_circle
                  : status == 'cancelled'
                      ? Icons.cancel
                      : Icons.pending_actions,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation['foodType'] as String? ?? 'Donation',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  '${donation['quantity'] ?? 0} ${donation['unit'] ?? ''} • ${donation['category'] ?? ''}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
                if (dateStr.isNotEmpty)
                  Text(dateStr,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
