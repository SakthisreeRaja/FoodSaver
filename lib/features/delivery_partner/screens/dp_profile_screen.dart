import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodsaver/core/components/user_profile_header.dart';
import 'package:foodsaver/features/auth/screens/firebase_auth_service.dart';

// Stats provider for this delivery partner
final dpStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return {
      'delivered': 0,
      'active': 0,
      'total': 0,
      'totalFare': 0.0,
      'csrContribution': 0.0,
    };
  }
  final snap = await FirebaseFirestore.instance
      .collection('delivery_jobs')
      .where('deliveryPartnerId', isEqualTo: uid)
      .get();
  final all = snap.docs.map((d) => d.data()).toList();
  final delivered = all.where((j) => j['status'] == 'delivered').toList();
  final active = all
      .where((j) =>
          ['accepted', 'picked_up', 'in_transit'].contains(j['status']))
      .length;
  double totalFare = 0;
  for (final j in delivered) {
    totalFare += (j['fareOriginal'] as num?)?.toDouble() ?? 0.0;
  }
  return {
    'delivered': delivered.length,
    'active': active,
    'total': all.length,
    'totalFare': totalFare,
    'csrContribution': totalFare * 0.70,
  };
});

class DPProfileScreen extends ConsumerWidget {
  const DPProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dpStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/dp-settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const UserProfileHeader(avatarIcon: Icons.delivery_dining),
            const SizedBox(height: 24),

            statsAsync.when(
              data: (stats) => _buildStats(context, stats),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // CSR Impact card
            statsAsync.when(
              data: (stats) => _csrCard(context, stats),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            _buildMenu(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
            child: _statCard(context, '${stats['delivered']}',
                'Delivered', Colors.green)),
        const SizedBox(width: 12),
        Expanded(
            child:
                _statCard(context, '${stats['active']}', 'Active', Colors.blue)),
        const SizedBox(width: 12),
        Expanded(
            child:
                _statCard(context, '${stats['total']}', 'Total', Colors.orange)),
      ],
    );
  }

  Widget _statCard(
      BuildContext context, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _csrCard(BuildContext context, Map<String, dynamic> stats) {
    final csrAmt = (stats['csrContribution'] as double).toStringAsFixed(0);
    final totalFare = (stats['totalFare'] as double).toStringAsFixed(0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6366F1), const Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🏛️', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Text('CSR Fund Impact',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text('₹$csrAmt subsidised on your behalf',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
              'Of ₹$totalFare total fare value across ${stats['delivered']} deliveries',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Powered by FoodSaver CSR Fund',
                style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _tile(context, Icons.history_outlined, 'Delivery History',
            () => context.push('/dp-history-full')),
        _tile(context, Icons.person_outline, 'Edit Profile',
            () => context.push('/edit-profile')),
        _tile(context, Icons.help_outline, 'Help & Support',
            () => context.push('/help-support')),
        _tile(context, Icons.logout, 'Logout', () async {
          await FirebaseAuthService.signOut();
          if (context.mounted) context.go('/login');
        }, isLogout: true),
      ],
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title,
      VoidCallback onTap,
      {bool isLogout = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon,
            color: isLogout
                ? Colors.red
                : Theme.of(context).colorScheme.primary),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isLogout ? Colors.red : null)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}
