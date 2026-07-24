import 'package:flutter/material.dart';
import 'package:foodsaver/core/components/pickup_card.dart';
import 'package:foodsaver/models/dummy_pickups.dart';
import 'package:foodsaver/models/pickup.dart';
import 'package:go_router/go_router.dart';

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  _VolunteerDashboardScreenState createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final List<Pickup> availablePickups =
        dummyPickups.where((p) => p.status == 'Pending').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Pickups'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/volunteer-profile'),
          ),
        ],
      ),
      body: availablePickups.isEmpty
          ? const Center(
              child: Text(
                'No pickups available right now.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: availablePickups.length,
              itemBuilder: (context, index) {
                final pickup = availablePickups[index];
                return PickupCard(
                  pickup: pickup,
                  onTap: () {
                    context.push('/pickup-details', extra: pickup);
                  },
                );
              },
            ),
    );
  }
}
