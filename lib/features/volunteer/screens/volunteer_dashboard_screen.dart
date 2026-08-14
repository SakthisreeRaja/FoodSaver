import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodsaver/core/services/notification_service.dart';


// Real-time stream of pending pickups (not yet assigned to any volunteer)
final pendingPickupsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('pickups')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .asyncMap((snapshot) async {
    final List<Map<String, dynamic>> enriched = [];
    for (final doc in snapshot.docs) {
      final data = {...doc.data(), 'id': doc.id};
      // Enrich with donation info
      final donationId = data['donationId'] as String?;
      if (donationId != null) {
        try {
          final don = await FirebaseFirestore.instance
              .collection('donations')
              .doc(donationId)
              .get();
          if (don.exists) {
            data['donation'] = {...don.data()!, 'id': don.id};
          }
        } catch (_) {}
      }
      enriched.add(data);
    }
    return enriched;
  });
});

class VolunteerDashboardScreen extends ConsumerWidget {
  const VolunteerDashboardScreen({super.key});

  Future<void> _acceptPickup(
      BuildContext context, String pickupId, WidgetRef ref,
      {Map<String, dynamic>? donation}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Get volunteer name for notification
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

      // Notify the donor
      final donorId = donation?['donorId'] as String?;
      final foodType = donation?['foodType'] as String? ?? 'Food';
      if (donorId != null) {
        await NotificationService().sendPickupAcceptedNotification(
          donorUid: donorId,
          pickupId: pickupId,
          foodType: foodType,
          volunteerName: volunteerName,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Pickup accepted! Donor notified.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickupsAsync = ref.watch(pendingPickupsStreamProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.1),
                  child: Icon(Icons.directions_bike, color: primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ready to deliver? 🚴',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Available pickups near you',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            automaticallyImplyLeading: false,
          ),
          SliverToBoxAdapter(
            child: pickupsAsync.when(
              data: (pickups) => _buildPickupList(context, pickups, ref),
              loading: () => const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Could not load pickups: $e',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.refresh(pendingPickupsStreamProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupList(BuildContext context,
      List<Map<String, dynamic>> pickups, WidgetRef ref) {
    if (pickups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.local_shipping_outlined, size: 72, color: Colors.grey),
              SizedBox(height: 16),
              Text('No pending pickups right now.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 8),
              Text('Check back soon — NGOs are claiming donations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pickups.length} pickup${pickups.length == 1 ? '' : 's'} available',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          ...pickups.map((pickup) => _buildPickupCard(context, pickup, ref)),
        ],
      ),
    );
  }

  Widget _buildPickupCard(BuildContext context, Map<String, dynamic> pickup,
      WidgetRef ref) {
    final donation = pickup['donation'] as Map<String, dynamic>?;
    final foodType =
        donation?['foodType'] as String? ?? 'Food Pickup';
    final location =
        donation?['pickupLocation'] as String? ?? 'Location TBD';
    final quantity = donation?['quantity'] as int? ?? 0;
    final unit = donation?['unit'] as String? ?? '';
    final category = donation?['category'] as String? ?? '';
    final pickupId = pickup['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade100, blurRadius: 8, spreadRadius: 1)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(foodType,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    if (category.isNotEmpty)
                      Text(category,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text('Pending',
                    style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.location_on_outlined, location),
          const SizedBox(height: 4),
          _infoRow(Icons.inventory_2_outlined, '$quantity $unit'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _acceptPickup(context, pickupId, ref,
                  donation: donation),
              icon: const Icon(Icons.local_shipping, size: 18),
              label: const Text('Accept Pickup'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
