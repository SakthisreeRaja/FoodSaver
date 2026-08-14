import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// Real-time stream of this volunteer's pickups
final myPickupsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('pickups')
      .where('volunteerId', isEqualTo: uid)
      .snapshots()
      .asyncMap((snapshot) async {
    final List<Map<String, dynamic>> enriched = [];
    for (final doc in snapshot.docs) {
      final data = {...doc.data(), 'id': doc.id};
      final donationId = data['donationId'] as String?;
      if (donationId != null) {
        try {
          final don = await FirebaseFirestore.instance
              .collection('donations')
              .doc(donationId)
              .get();
          if (don.exists) data['donation'] = {...don.data()!, 'id': don.id};
        } catch (_) {}
      }
      enriched.add(data);
    }
    return enriched;
  });
});

class VolunteerHistoryScreen extends ConsumerWidget {
  const VolunteerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickupsAsync = ref.watch(myPickupsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pickups'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: pickupsAsync.when(
        data: (pickups) {
          if (pickups.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_outlined, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No pickups yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Accept a pickup from the dashboard to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            );
          }

          final completed =
              pickups.where((p) => p['status'] == 'completed').toList();
          final active = pickups
              .where((p) =>
                  p['status'] == 'scheduled' || p['status'] == 'in_progress')
              .toList();
          final pending =
              pickups.where((p) => p['status'] == 'pending').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                _sectionHeader(context, '🚗 Active', Colors.blue, active.length),
                ...active.map((p) => _pickupCard(context, p)),
                const SizedBox(height: 8),
              ],
              if (pending.isNotEmpty) ...[
                _sectionHeader(
                    context, '⏳ Pending', Colors.orange, pending.length),
                ...pending.map((p) => _pickupCard(context, p)),
                const SizedBox(height: 8),
              ],
              if (completed.isNotEmpty) ...[
                _sectionHeader(
                    context, '✅ Completed', Colors.green, completed.length),
                ...completed.map((p) => _pickupCard(context, p)),
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
                onPressed: () => ref.refresh(myPickupsStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
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

  Widget _pickupCard(BuildContext context, Map<String, dynamic> pickup) {
    final donation = pickup['donation'] as Map<String, dynamic>?;
    final foodType = donation?['foodType'] as String? ?? 'Food Pickup';
    final location = donation?['pickupLocation'] as String? ?? 'N/A';
    final quantity = donation?['quantity'] as int? ?? 0;
    final unit = donation?['unit'] as String? ?? '';
    final status = pickup['status'] as String? ?? 'pending';

    final statusColor = status == 'completed'
        ? Colors.green
        : status == 'scheduled' || status == 'in_progress'
            ? Colors.blue
            : Colors.orange;

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
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.local_shipping,
                color: Theme.of(context).colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(foodType,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 3),
                Text('$location • $quantity $unit',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.replaceAll('_', ' ').toUpperCase(),
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
