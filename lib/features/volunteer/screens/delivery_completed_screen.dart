import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DeliveryCompletedScreen extends StatelessWidget {
  final Map<String, dynamic> pickupData;
  const DeliveryCompletedScreen({super.key, required this.pickupData});

  @override
  Widget build(BuildContext context) {
    final donation = pickupData['donation'] as Map<String, dynamic>? ?? {};
    final foodType = donation['foodType'] as String? ?? 'Food';
    final qty = donation['quantity'] as int? ?? 0;
    final unit = donation['unit'] as String? ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF1B5E20)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success animation
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🚚', style: TextStyle(fontSize: 60)),
                  ),
                ),
                const SizedBox(height: 32),
                const Icon(Icons.check_circle, color: Colors.white, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Delivery Completed!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'You delivered $qty $unit of "$foodType" successfully.',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'You are making a real difference in your community! 🌱',
                  style: TextStyle(fontSize: 14, color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Impact card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _impactItem('🍽️', '$qty $unit', 'Delivered'),
                      Container(
                          width: 1, height: 40, color: Colors.white30),
                      _impactItem('♻️', '100%', 'Zero Waste'),
                      Container(
                          width: 1, height: 40, color: Colors.white30),
                      _impactItem('❤️', '+1', 'Impact'),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/volunteer-dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Back to Dashboard'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/volunteer-dashboard'),
                  child: const Text('View My History',
                      style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _impactItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}
