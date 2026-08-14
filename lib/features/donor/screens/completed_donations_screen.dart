import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompletedDonationsScreen extends StatelessWidget {
  const CompletedDonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Donations'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: uid == null
            ? const Stream.empty()
            : FirebaseFirestore.instance
                .collection('donations')
                .where('donorId', isEqualTo: uid)
                .where('status', whereIn: ['completed', 'cancelled'])
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_outlined,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No completed donations yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          // Summary banner
          final completed =
              docs.where((d) => (d.data() as Map)['status'] == 'completed').length;
          final totalQty = docs.fold<int>(0, (acc, d) {
            final data = d.data() as Map<String, dynamic>;
            return acc + ((data['quantity'] as int?) ?? 0);
          });

          return Column(
            children: [
              // Impact banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _impactStat('$completed', 'Completed', '✅'),
                    Container(width: 1, height: 40, color: Colors.white30),
                    _impactStat('$totalQty', 'Units Given', '🍽️'),
                    Container(width: 1, height: 40, color: Colors.white30),
                    _impactStat('${(totalQty * 3)}', 'Meals Est.', '❤️'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = {
                      ...docs[i].data() as Map<String, dynamic>,
                      'id': docs[i].id
                    };
                    return _donationTile(context, d);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _impactStat(String value, String label, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _donationTile(BuildContext context, Map<String, dynamic> d) {
    final status = d['status'] as String? ?? 'completed';
    final color = status == 'completed' ? Colors.green : Colors.red;
    final icon = status == 'completed' ? Icons.check_circle : Icons.cancel;

    final ts = d['createdAt'];
    String date = '';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      date = '${dt.day}/${dt.month}/${dt.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100, blurRadius: 8)
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(d['foodType'] as String? ?? 'Donation',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${d['quantity'] ?? 0} ${d['unit'] ?? ''} • $date',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(status.toUpperCase(),
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        onTap: () => context.push('/donation-details', extra: d),
      ),
    );
  }
}
