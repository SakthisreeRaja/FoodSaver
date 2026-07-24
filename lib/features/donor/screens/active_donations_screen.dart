import 'package:flutter/material.dart';
import 'package:foodsaver/core/components/donation_card.dart';
import 'package:foodsaver/models/dummy_data.dart';
import 'package:foodsaver/models/donation.dart';
import 'package:go_router/go_router.dart';

class ActiveDonationsScreen extends StatelessWidget {
  const ActiveDonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Donation> activeDonations =
        dummyDonations.where((d) => d.status == 'Active').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Donations'),
        centerTitle: true,
      ),
      body: activeDonations.isEmpty
          ? const Center(
              child: Text(
                'You have no active donations.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: activeDonations.length,
              itemBuilder: (context, index) {
                final donation = activeDonations[index];
                return DonationCard(
                  donation: donation,
                  onTap: () {
                    GoRouter.of(context).push('/donation-details', extra: donation);
                  },
                );
              },
            ),
    );
  }
}
