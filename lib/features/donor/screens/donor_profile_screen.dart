import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:foodsaver/core/components/user_profile_header.dart';
import 'package:foodsaver/core/providers/service_providers.dart';
import 'package:foodsaver/features/auth/screens/firebase_auth_service.dart';

class DonorProfileScreen extends ConsumerWidget {
  const DonorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDonationsAsync = ref.watch(userDonationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/donor-settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Real user data
            const UserProfileHeader(avatarIcon: Icons.volunteer_activism),
            const SizedBox(height: 24),

            // Stats from real donations
            userDonationsAsync.when(
              data: (donations) {
                final completed =
                    donations.where((d) => d['status'] == 'completed').length;
                final active = donations
                    .where((d) =>
                        d['status'] == 'available' || d['status'] == 'claimed')
                    .length;
                final meals = donations.fold<int>(
                    0, (s, d) => s + ((d['quantity'] as int?) ?? 0));
                return _buildStats(context, completed, active, meals);
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
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
      BuildContext context, int completed, int active, int meals) {
    return Row(
      children: [
        Expanded(child: _statCard(context, '$completed', 'Completed', Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(context, '$active', 'Active', Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(context, '$meals', 'Meals', Colors.orange)),
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
        _tile(context, Icons.history, 'Donation History',
            () => context.push('/donation-history')),
        _tile(context, Icons.map_outlined, 'View Map',
            () => context.push('/donor-dashboard')),
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
