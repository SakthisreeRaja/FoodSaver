import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodsaver/core/services/delivery_service.dart';

// Stream provider for this DP's delivery history
final myDeliveryJobsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return DeliveryService().streamMyJobs(uid);
});

class DPHistoryScreen extends ConsumerWidget {
  const DPHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(myDeliveryJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Deliveries'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delivery_dining, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No deliveries yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Accept a job from the Jobs tab to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            );
          }

          final delivered = jobs
              .where((j) => j['status'] == 'delivered')
              .toList();
          final active = jobs
              .where((j) =>
                  ['accepted', 'picked_up', 'in_transit'].contains(j['status']))
              .toList();
          final open = jobs
              .where((j) => j['status'] == 'open')
              .toList();

          // Earnings
          double totalEarnings = 0;
          for (final j in delivered) {
            totalEarnings +=
                (j['fareOriginal'] as num?)?.toDouble() ?? 0.0;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Earnings summary card
              _earningsCard(context, delivered.length, totalEarnings),
              const SizedBox(height: 20),

              if (active.isNotEmpty) ...[
                _sectionHeader(context, '🚛 Active', Colors.blue, active.length),
                ...active.map((j) => _jobCard(context, j)),
                const SizedBox(height: 8),
              ],
              if (open.isNotEmpty) ...[
                _sectionHeader(context, '⏳ Pending', Colors.orange, open.length),
                ...open.map((j) => _jobCard(context, j)),
                const SizedBox(height: 8),
              ],
              if (delivered.isNotEmpty) ...[
                _sectionHeader(
                    context, '✅ Delivered', Colors.green, delivered.length),
                ...delivered.map((j) => _jobCard(context, j)),
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
                onPressed: () => ref.refresh(myDeliveryJobsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _earningsCard(
      BuildContext context, int count, double totalEarnings) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const Text('🏛️', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CSR Contribution',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12)),
                Text('₹${(totalEarnings * 0.70).toStringAsFixed(0)} subsidised',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(
                    '$count deliveries completed  •  ₹${totalEarnings.toStringAsFixed(0)} total value',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
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
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color)),
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

  Widget _jobCard(BuildContext context, Map<String, dynamic> job) {
    final donation = job['donation'] as Map<String, dynamic>?;
    final foodType = donation?['foodType'] as String? ?? 'Delivery';
    final pickupAddr = job['pickupAddress'] as String? ?? 'Pickup';
    final distKm = (job['distanceKm'] as num?)?.toDouble() ?? 0.0;
    final status = job['status'] as String? ?? 'open';
    final fareOriginal = (job['fareOriginal'] as num?)?.toDouble() ?? 0.0;
    final ngoPays = (job['ngoPays'] as num?)?.toDouble() ?? 0.0;

    final statusColor = status == 'delivered'
        ? Colors.green
        : ['accepted', 'picked_up', 'in_transit'].contains(status)
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.delivery_dining,
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
                const SizedBox(height: 2),
                Text(
                    '$pickupAddr  •  ${distKm.toStringAsFixed(1)} km',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (status == 'delivered')
                  Text(
                      'Fare: ₹${fareOriginal.toStringAsFixed(0)} (NGO paid ₹${ngoPays.toStringAsFixed(0)})',
                      style: TextStyle(
                          fontSize: 11, color: Colors.green.shade600)),
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
