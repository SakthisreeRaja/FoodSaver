import 'package:flutter/material.dart';
import 'package:foodsaver/core/components/donation_card.dart';
import 'package:foodsaver/models/dummy_data.dart';
import 'package:foodsaver/models/donation.dart';
import 'package:go_router/go_router.dart';

class CompletedDonationsScreen extends StatelessWidget {
  const CompletedDonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Donation> completedDonations =
        dummyDonations.where((d) => d.status == 'Completed').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Donations'),
        centerTitle: true,
      ),
      body: completedDonations.isEmpty
          ? const Center(
              child: Text(
                'You have no completed donations.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: completedDonations.length,
              itemBuilder: (context, index) {
                final donation = completedDonations[index];
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
