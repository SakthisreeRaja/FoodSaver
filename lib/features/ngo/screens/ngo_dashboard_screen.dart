import 'package:flutter/material.dart';
import 'package:foodsaver/core/components/available_donation_card.dart';
import 'package:foodsaver/models/donation.dart';
import 'package:foodsaver/models/dummy_data.dart';
import 'package:go_router/go_router.dart';

enum SortOption { nearest, expiringSoon }

class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  SortOption _sortOption = SortOption.nearest;
  final List<String> _acceptedDonationIds = [];

  List<Donation> get _availableDonations {
    // In a real app, this would be a stream from a backend.
    return dummyDonations.where((d) => d.status == 'Active').toList();
  }

  List<Donation> get _sortedListings {
    final sorted = [..._availableDonations];
    if (_sortOption == SortOption.nearest) {
      // Dummy sort, in a real app you'd calculate distance
      sorted.sort((a, b) => a.location.length.compareTo(b.location.length));
    } else {
      // Dummy sort by time
      sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    return sorted;
  }

  void _acceptDonation(Donation donation) {
    setState(() {
      _acceptedDonationIds.add(donation.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${donation.foodName}" accepted!')),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text("Sort by",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              RadioListTile<SortOption>(
                title: const Text("Nearest first"),
                value: SortOption.nearest,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() => _sortOption = value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<SortOption>(
                title: const Text("Expiring soon"),
                value: SortOption.expiringSoon,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() => _sortOption = value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listings = _sortedListings;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Donations"),
        actions: [
          IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterSheet),
          IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => context.push('/ngo-profile')), // To be created
        ],
      ),
      body: listings.isEmpty
          ? const Center(child: Text("No available donations right now."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final donation = listings[index];
                final isAccepted = _acceptedDonationIds.contains(donation.id);
                return AvailableDonationCard(
                  donation: donation,
                  isAccepted: isAccepted,
                  onAccept: () => _acceptDonation(donation),
                  onTap: () => context.push('/donation-details', extra: donation),
                );
              },
            ),
    );
  }
}
