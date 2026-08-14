import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/donation_history_screen.dart';

final _donorNameProvider = FutureProvider<String>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return 'Donor';
  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      return (data['name'] as String?) ??
          (data['fullName'] as String?) ??
          FirebaseAuth.instance.currentUser?.displayName ??
          'Donor';
    }
  } catch (_) {}
  return FirebaseAuth.instance.currentUser?.displayName ?? 'Donor';
});

/// Stream-based provider for unread notification count
final _unreadNotifCountProvider = StreamProvider<int>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: uid)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.length);
});

class DonorDashboardScreen extends ConsumerWidget {
  final VoidCallback? onViewAllPressed;

  const DonorDashboardScreen({super.key, this.onViewAllPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use stream-based provider so dashboard auto-updates when new donations are created
    final donationsAsync = ref.watch(myDonationsStreamProvider);
    final donorNameAsync = ref.watch(_donorNameProvider);
    final donorName = donorNameAsync.valueOrNull ?? 'Donor';
    final unreadCount = ref.watch(_unreadNotifCountProvider).valueOrNull ?? 0;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.person,
                      color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $donorName 👋',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Ready to save food today?",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () => context.push('/donor-notifications'),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: donationsAsync.when(
                data: (donations) => _buildContent(context, donations),
                loading: () => _buildContent(context, null, loading: true),
                error: (_, __) => _buildContent(context, null, hasError: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Map<String, dynamic>>? donations, {
    bool loading = false,
    bool hasError = false,
  }) {
    final completed =
        donations?.where((d) => d['status'] == 'completed').length ?? 0;
    final active = donations
            ?.where((d) =>
                d['status'] == 'available' || d['status'] == 'claimed')
            .toList() ??
        [];

    final totalMeals =
        donations?.fold<int>(0, (sum, d) => sum + ((d['quantity'] as int?) ?? 0)) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Impact Stats Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                const Color(0xFF059669),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                        totalMeals > 0 ? '$totalMeals' : '–', 'Meals Saved'),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3)),
                    _buildStatColumn(
                        completed > 0 ? '$completed' : '–', 'Completed'),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3)),
                    _buildStatColumn(
                        active.isNotEmpty ? '${active.length}' : '–', 'Active'),
                  ],
                ),
        ),
        const SizedBox(height: 32),

        // Quick Actions
        Text(
          'Quick Actions',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                context,
                icon: Icons.add_circle_outline,
                label: 'New Donation',
                color: const Color(0xFF10B981),
                onTap: () => context.push('/create-donation'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickAction(
                context,
                icon: Icons.camera_alt_outlined,
                label: 'AI Camera',
                color: const Color(0xFF6366F1),
                onTap: () => context.push('/camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickAction(
                context,
                icon: Icons.history,
                label: 'History',
                color: const Color(0xFFF59E0B),
                onTap: onViewAllPressed,
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Active Donations Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Donations',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
                onPressed: onViewAllPressed, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 12),

        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (hasError)
          _buildErrorCard(context)
        else if (active.isEmpty)
          _buildEmptyState(context)
        else
          ...active.take(3).map(
                (donation) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDonationCard(
                    context,
                    donation['foodType'] ?? 'Food Donation',
                    donation['status'] ?? 'pending',
                    '${donation['quantity'] ?? 0} ${donation['unit'] ?? 'kg'}',
                    Icons.restaurant_menu,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard(
    BuildContext context,
    String title,
    String status,
    String quantity,
    IconData icon,
  ) {
    final statusColor = status == 'completed'
        ? Colors.green
        : status == 'claimed'
            ? Colors.blue
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade100, blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(quantity,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.volunteer_activism,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No active donations yet',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "New Donation" to get started!',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Could not load donations. Check your connection.',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}