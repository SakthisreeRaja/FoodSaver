import 'package:flutter/material.dart';

class _DonationListing {
  final String title;
  final String description;
  final String distanceLabel;
  final double distanceKm;
  final String expiresLabel;
  bool accepted;

  _DonationListing({
    required this.title,
    required this.description,
    required this.distanceLabel,
    required this.distanceKm,
    required this.expiresLabel,
    this.accepted = false,
  });
}

enum _SortOption { nearest, expiringSoon }

class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  _SortOption _sortOption = _SortOption.nearest;

  final List<_DonationListing> _listings = [
    _DonationListing(
      title: "Prepared Meals (Buffet)",
      description: "Estimated ~20 servings. Freshly prepared and securely packed.",
      distanceLabel: "1.2 km away",
      distanceKm: 1.2,
      expiresLabel: "Expires in 4 hours",
    ),
    _DonationListing(
      title: "Bakery Assortment",
      description: "Estimated ~35 servings. Bread, pastries, and rolls from a local bakery.",
      distanceLabel: "2.8 km away",
      distanceKm: 2.8,
      expiresLabel: "Expires in 8 hours",
    ),
    _DonationListing(
      title: "Fresh Produce Box",
      description: "Estimated ~12 servings. Mixed vegetables, slightly imperfect but fresh.",
      distanceLabel: "0.6 km away",
      distanceKm: 0.6,
      expiresLabel: "Expires in 2 hours",
    ),
  ];

  List<_DonationListing> get _sortedListings {
    final sorted = [..._listings];
    if (_sortOption == _SortOption.nearest) {
      sorted.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }
    // Expiring soon just uses the original order (already roughly soonest to latest
    // isn't guaranteed by mock data, but this is a UI-only stage — real sorting
    // would use each listing's actual expiry timestamp once that data exists).
    return sorted;
  }

  void _acceptDonation(_DonationListing listing) {
    setState(() => listing.accepted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${listing.title}" accepted — pickup details sent to the donor.')),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text("Sort by", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              RadioListTile<_SortOption>(
                title: const Text("Nearest first"),
                value: _SortOption.nearest,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() => _sortOption = value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<_SortOption>(
                title: const Text("Expiring soon"),
                value: _SortOption.expiringSoon,
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
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterSheet),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final listing = listings[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade100, blurRadius: 10, spreadRadius: 1),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(listing.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(listing.distanceLabel, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(listing.description, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(listing.expiresLabel, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: listing.accepted ? null : () => _acceptDonation(listing),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Text(listing.accepted ? "Accepted" : "Accept Donation"),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
