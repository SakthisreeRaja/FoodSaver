import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ActiveDonationsScreen extends StatelessWidget {
  const ActiveDonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Donations'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: uid == null
            ? const Stream.empty()
            : FirebaseFirestore.instance
                .collection('donations')
                .where('donorId', isEqualTo: uid)
                .where('status', whereIn: ['available', 'claimed'])
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pending_actions, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No active donations.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Donate food via the camera button!',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = {...docs[i].data() as Map<String, dynamic>, 'id': docs[i].id};
              return _donationTile(context, d);
            },
          );
        },
      ),
    );
  }

  Widget _donationTile(BuildContext context, Map<String, dynamic> d) {
    final status = d['status'] as String? ?? 'available';
    final color = status == 'claimed' ? Colors.blue : Colors.green;

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
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.restaurant_menu, color: color),
        ),
        title: Text(d['foodType'] as String? ?? 'Donation',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${d['quantity'] ?? 0} ${d['unit'] ?? ''} • ${d['category'] ?? ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            if (date.isNotEmpty)
              Text(date,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(status.toUpperCase(),
                  style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12),
          ],
        ),
        onTap: () => context.push('/donation-details', extra: d),
      ),
    );
  }
}
