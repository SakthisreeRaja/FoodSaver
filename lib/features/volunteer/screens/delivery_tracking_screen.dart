import 'package:flutter/material.dart';
import 'package:foodsaver/core/components/timeline_widget.dart';
import 'package:foodsaver/models/pickup.dart';
import 'package:go_router/go_router.dart';

class DeliveryTrackingScreen extends StatelessWidget {
  final Pickup pickup;

  const DeliveryTrackingScreen({super.key, required this.pickup});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Delivery'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Map Placeholder
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.map, size: 100, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TimelineWidget(
                    children: [
                      TimelineTile(
                        title: 'Pickup from ${pickup.donation.location}',
                        subtitle: 'On your way to pick up the donation.',
                        isFirst: true,
                        isCompleted: true,
                      ),
                      TimelineTile(
                        title: 'Deliver to Green Valley Community',
                        subtitle: 'Drop off the donation at the NGO.',
                        isLast: true,
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark as Delivered'),
                      onPressed: () {
                        context.push('/delivery-completed', extra: pickup);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
