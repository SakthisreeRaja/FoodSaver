import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:foodsaver/core/components/user_profile_header.dart';
import 'package:foodsaver/features/auth/screens/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final volunteerPickupsStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return {'completed': 0, 'active': 0, 'total': 0};
  final snapshot = await FirebaseFirestore.instance
      .collection('pickups')
      .where('volunteerId', isEqualTo: uid)
      .get();
  final all = snapshot.docs.map((d) => d.data()).toList();
  return {
    'completed':
        all.where((p) => p['status'] == 'completed').length,
    'active':
        all.where((p) => p['status'] == 'scheduled' || p['status'] == 'pending')
            .length,
    'total': all.length,
  };
});

class VolunteerProfileScreen extends ConsumerWidget {
  const VolunteerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(volunteerPickupsStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/volunteer-settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const UserProfileHeader(avatarIcon: Icons.directions_bike),
            const SizedBox(height: 24),

            statsAsync.when(
              data: (stats) => _buildStats(
                context,
                stats['completed'] ?? 0,
                stats['active'] ?? 0,
                stats['total'] ?? 0,
              ),
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
        Expanded(child: _statCard(context, '$completed', 'Completed', Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(context, '$active', 'Active', Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(context, '$total', 'Total', Colors.orange)),
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
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
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
        _tile(context, Icons.history, 'Pickup History',
            () => context.push('/volunteer-history')),
        _tile(context, Icons.qr_code_scanner, 'Scan QR Code',
            () => context.push('/qr-scan')),
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
