import 'package:flutter/material.dart';
import 'package:foodsaver/core/components/donation_card.dart';
import 'package:foodsaver/models/dummy_data.dart';
import 'package:foodsaver/models/donation.dart';
import 'package:go_router/go_router.dart';

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Donation> donationHistory = dummyDonations
        .where((d) => d.status == 'Completed' || d.status == 'Cancelled')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation History'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: donationHistory.length,
        itemBuilder: (context, index) {
          final donation = donationHistory[index];
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
