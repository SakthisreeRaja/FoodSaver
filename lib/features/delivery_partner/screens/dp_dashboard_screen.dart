import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:foodsaver/core/services/delivery_service.dart';

class DPDashboardScreen extends StatefulWidget {
  const DPDashboardScreen({super.key});

  @override
  State<DPDashboardScreen> createState() => _DPDashboardScreenState();
}

class _DPDashboardScreenState extends State<DPDashboardScreen> {
  final _service = DeliveryService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _dpName = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    if (mounted) {
      setState(() {
        _dpName = doc.data()?['name'] as String? ?? 'Delivery Partner';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.1),
                  child: Icon(Icons.delivery_dining, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to deliver? 🛵',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _dpName.isNotEmpty
                            ? 'Hello, $_dpName!'
                            : 'Open delivery jobs near you',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Delivery jobs feed ─────────────────────────────────────────────
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _service.streamOpenJobs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }
              final jobs = snapshot.data ?? [];
              if (jobs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delivery_dining,
                            size: 72, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No open delivery jobs right now.',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('NGOs will post jobs when they claim donations.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _jobCard(ctx, jobs[i]),
                    childCount: jobs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _jobCard(BuildContext context, Map<String, dynamic> job) {
    final donation = job['donation'] as Map<String, dynamic>?;
    final foodType = donation?['foodType'] as String? ?? 'Food Delivery';
    final pickupAddr = job['pickupAddress'] as String? ?? 'Pickup location';
    final dropoffAddr = job['dropoffAddress'] as String? ?? 'Drop-off (NGO)';
    final distKm = (job['distanceKm'] as num?)?.toDouble() ?? 0.0;
    final ngoPays = (job['ngoPays'] as num?)?.toDouble() ?? 0.0;
    final csrSubsidy = (job['csrSubsidy'] as num?)?.toDouble() ?? 0.0;
    final fareOriginal = (job['fareOriginal'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade100, blurRadius: 10, spreadRadius: 2)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.inventory_2_outlined,
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
                      Text('${distKm.toStringAsFixed(1)} km route',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: const Text('OPEN',
                      style: TextStyle(
                          color: Colors.indigo,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Route details
            _routeStep(Icons.radio_button_checked, 'Pickup', pickupAddr,
                Colors.green),
            Container(
                margin: const EdgeInsets.only(left: 10),
                height: 16,
                width: 2,
                color: Colors.grey.shade300),
            _routeStep(
                Icons.location_on, 'Drop-off', dropoffAddr, Colors.indigo),
            const SizedBox(height: 14),

            // Fare breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('🏛️',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CSR Subsidised Delivery',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.indigo.shade700),
                        ),
                        Text(
                          'Fare: ₹${fareOriginal.toStringAsFixed(0)}  •  Subsidy: ₹${csrSubsidy.toStringAsFixed(0)}  •  NGO Pays: ₹${ngoPays.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.indigo.shade400),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Accept button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/dp-delivery', extra: job),
                icon: const Icon(Icons.delivery_dining, size: 18),
                label: const Text('Accept & Deliver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeStep(
      IconData icon, String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(address,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
