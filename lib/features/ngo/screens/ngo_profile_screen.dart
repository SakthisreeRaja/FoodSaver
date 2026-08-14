import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:foodsaver/core/components/user_profile_header.dart';
import 'package:foodsaver/features/auth/screens/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Provider for NGO pickups
final ngoPickupsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];
  final snapshot = await FirebaseFirestore.instance
      .collection('pickups')
      .where('ngoId', isEqualTo: uid)
      .get();
  return snapshot.docs
      .map((d) => {...d.data(), 'id': d.id})
      .toList();
});

class NgoProfileScreen extends ConsumerWidget {
  const NgoProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickupsAsync = ref.watch(ngoPickupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/ngo-settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const UserProfileHeader(avatarIcon: Icons.business),
            const SizedBox(height: 24),

            pickupsAsync.when(
              data: (pickups) {
                final received =
                    pickups.where((p) => p['status'] == 'completed').length;
                final active = pickups
                    .where((p) =>
                        p['status'] == 'pending' ||
                        p['status'] == 'scheduled')
                    .length;
                return _buildStats(context, received, active, pickups.length);
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => _buildStats(context, 0, 0, 0),
            ),
            const SizedBox(height: 24),
            _buildMenuList(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(
      BuildContext context, int completed, int active, int total) {
    return Row(
      children: [
        Expanded(child: _statCard(context, '$completed', 'Received', Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(context, '$active', 'Active', Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(context, '$total', 'Total', Colors.purple)),
      ],
    );
  }

  Widget _statCard(BuildContext context, String value, String label, Color color) {
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

  Widget _buildMenuList(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _tile(context, Icons.bar_chart, 'View Statistics',
            () => context.push('/ngo-statistics')),
        _tile(context, Icons.map_outlined, 'View Map',
            () => context.push('/ngo-dashboard')),
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
            color: isLogout ? Colors.red : Theme.of(context).colorScheme.primary),
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
