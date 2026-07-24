import 'package:flutter/material.dart';
import 'package:foodsaver/core/components/pickup_card.dart';
import 'package:foodsaver/models/dummy_pickups.dart';
import 'package:foodsaver/models/pickup.dart';
import 'package:go_router/go_router.dart';

class VolunteerHistoryScreen extends StatelessWidget {
  const VolunteerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Pickup> pickupHistory =
        dummyPickups.where((p) => p.status == 'Completed').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup History'),
        centerTitle: true,
      ),
      body: pickupHistory.isEmpty
          ? const Center(
              child: Text(
                'You have no completed pickups.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: pickupHistory.length,
              itemBuilder: (context, index) {
                final pickup = pickupHistory[index];
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
