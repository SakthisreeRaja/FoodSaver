import 'package:flutter/material.dart';
import 'package:foodsaver/models/pickup.dart';
import 'package:go_router/go_router.dart';

class DeliveryCompletedScreen extends StatelessWidget {
  final Pickup pickup;

  const DeliveryCompletedScreen({super.key, required this.pickup});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 32),
              const Text(
                'Delivery Completed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Thank you for delivering "${pickup.donation.foodName}" to Green Valley Community.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/volunteer-dashboard'),
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
