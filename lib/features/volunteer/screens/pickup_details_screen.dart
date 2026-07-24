import 'package:flutter/material.dart';
import 'package:foodsaver/models/pickup.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class PickupDetailsScreen extends StatelessWidget {
  final Pickup pickup;

  const PickupDetailsScreen({super.key, required this.pickup});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pickup.donation.foodName),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildDetailCard(context),
            const SizedBox(height: 24),
            if (pickup.status == 'Pending') _buildAcceptButton(context),
            if (pickup.status == 'In Progress') _buildTrackButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.fastfood, 'Food Type', pickup.donation.foodName),
            const Divider(height: 24),
            _buildDetailRow(Icons.description, 'Description', pickup.donation.description),
            const Divider(height: 24),
            _buildDetailRow(Icons.location_on, 'Pickup Location', pickup.donation.location),
            const Divider(height: 24),
            _buildDetailRow(Icons.business, 'Deliver To', 'Green Valley Community'), // Dummy data
            const Divider(height: 24),
            _buildDetailRow(Icons.category, 'Status', pickup.status),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.local_shipping),
        label: const Text('Accept Pickup'),
        onPressed: () {
          // In a real app, you would update the pickup status here
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pickup accepted!')),
          );
          context.go('/volunteer-dashboard');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTrackButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.map),
        label: const Text('Track Delivery'),
        onPressed: () {
          context.push('/delivery-tracking', extra: pickup);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
