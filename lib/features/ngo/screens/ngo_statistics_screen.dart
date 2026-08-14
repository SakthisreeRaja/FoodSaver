import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ngoStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return {};

  // Pickups
  final pickupsSnap = await FirebaseFirestore.instance
      .collection('pickups')
      .where('ngoId', isEqualTo: uid)
      .get();
  final all = pickupsSnap.docs.map((d) => d.data()).toList();
  final completed = all.where((p) => p['status'] == 'completed').length;
  final active = all.where((p) => p['status'] == 'pending' || p['status'] == 'scheduled').length;

  // Donations claimed
  final donSnap = await FirebaseFirestore.instance
      .collection('donations')
      .where('claimedBy', isEqualTo: uid)
      .get();
  final donList = donSnap.docs.map((d) => d.data()).toList();
  final totalQty = donList.fold<int>(
      0, (s, d) => s + ((d['quantity'] as int?) ?? 0));

  // Category breakdown
  final Map<String, int> byCategory = {};
  for (final d in donList) {
    final cat = d['category'] as String? ?? 'Other';
    byCategory[cat] = (byCategory[cat] ?? 0) + 1;
  }

  return {
    'totalPickups': all.length,
    'completed': completed,
    'active': active,
    'totalDonations': donList.length,
    'totalQty': totalQty,
    'estMeals': totalQty * 3,
    'byCategory': byCategory,
  };
});

class NgoStatisticsScreen extends ConsumerWidget {
  const NgoStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(ngoStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: statsAsync.when(
        data: (stats) => _buildBody(context, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> stats) {
    final byCategory = stats['byCategory'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Impact banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF3F51B5)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text('Your Impact 🌱',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _impactBadge('${stats['totalDonations'] ?? 0}',
                      'Donations', '📦'),
                  _vDivider(),
                  _impactBadge('${stats['estMeals'] ?? 0}', 'Est. Meals',
                      '🍽️'),
                  _vDivider(),
                  _impactBadge('${stats['totalQty'] ?? 0}', 'Units', '⚖️'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Pickup stats
        const Text('Pickup Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _statCard(context, '${stats['totalPickups'] ?? 0}',
                    'Total', Colors.blue, Icons.local_shipping)),
            const SizedBox(width: 12),
            Expanded(
                child: _statCard(context, '${stats['completed'] ?? 0}',
                    'Completed', Colors.green, Icons.check_circle)),
            const SizedBox(width: 12),
            Expanded(
                child: _statCard(context, '${stats['active'] ?? 0}',
                    'Active', Colors.orange, Icons.pending_actions)),
          ],
        ),
        const SizedBox(height: 24),

        // Category breakdown
        if (byCategory.isNotEmpty) ...[
          const Text('Donations by Category',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...byCategory.entries
              .toList()
              .map((e) => _categoryBar(context, e.key, e.value as int,
                  byCategory.values.fold<int>(
                      0, (s, v) => s + (v as int)))),
        ],

        const SizedBox(height: 24),

        // Completion rate
        if ((stats['totalPickups'] as int? ?? 0) > 0) ...[
          const Text('Completion Rate',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _completionRate(
            context,
            (stats['completed'] as int? ?? 0),
            (stats['totalPickups'] as int? ?? 1),
          ),
        ],
      ],
    );
  }

  Widget _impactBadge(String value, String label, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 50, color: Colors.white30);

  Widget _statCard(BuildContext context, String value, String label,
      Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _categoryBar(
      BuildContext context, String category, int count, int total) {
    final pct = total > 0 ? count / total : 0.0;
    final colors = {
      'Vegetables': Colors.green,
      'Fruits': Colors.orange,
      'Grains': Colors.amber,
      'Dairy': Colors.blue,
      'Meat': Colors.red,
      'Bakery': Colors.brown,
      'Processed': Colors.purple,
    };
    final color = colors[category] ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('$count (${(pct * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _completionRate(
      BuildContext context, int completed, int total) {
    final rate = total > 0 ? completed / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pickup Completion Rate',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${(rate * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: Colors.green.withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text('$completed of $total pickups completed',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
