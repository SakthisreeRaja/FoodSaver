import 'package:flutter/material.dart';
import 'models/donation.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  // Mock data until we connect a database
  List<Donation> get _dummyDonations => [
    Donation(
      id: '1',
      foodName: '3 Boxes of Margherita Pizza',
      description: 'Leftover from a corporate event. Perfectly fresh!',
      location: 'Downtown Tech Hub (0.5 miles away)',
      status: 'Available',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    Donation(
      id: '2',
      foodName: 'Fresh Produce Basket',
      description: 'Apples, bananas, and a loaf of bread.',
      location: 'Community Center (1.2 miles away)',
      status: 'Available',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Food'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _dummyDonations.length,
        itemBuilder: (context, index) {
          final donation = _dummyDonations[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        donation.foodName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          donation.status,
                          style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(donation.description, style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(donation.location, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement claim logic
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Claim Food', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}