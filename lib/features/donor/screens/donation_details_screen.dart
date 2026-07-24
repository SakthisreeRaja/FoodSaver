import 'package:flutter/material.dart';
import 'package:foodsaver/models/donation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:foodsaver/core/components/confirmation_dialog.dart';

class DonationDetailsScreen extends StatelessWidget {
  final Donation donation;

  const DonationDetailsScreen({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(donation.foodName),
        centerTitle: true,
        actions: [
          if (donation.status == 'Active')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/edit-donation', extra: donation);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildDetailCard(),
            const SizedBox(height: 24),
            if (donation.status == 'Active') _buildCancelButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.fastfood, 'Food Type', donation.foodName),
            const Divider(height: 24),
            _buildDetailRow(Icons.description, 'Description', donation.description),
            const Divider(height: 24),
            _buildDetailRow(Icons.location_on, 'Location', donation.location),
            const Divider(height: 24),
            _buildDetailRow(Icons.category, 'Status', donation.status,
                statusColor: _getStatusColor(donation.status)),
            const Divider(height: 24),
            _buildDetailRow(Icons.date_range, 'Donated On',
                '${donation.timestamp.day}/${donation.timestamp.month}/${donation.timestamp.year}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? statusColor}) {
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
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ConfirmationDialog(
          title: 'Cancel Donation',
          content: 'Are you sure you want to cancel this donation? This action cannot be undone.',
          confirmText: 'Yes, Cancel',
          onConfirm: () {
            // In a real app, you'd update the donation status here.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Donation has been cancelled.')),
            );
            // Pop details screen to go back
            context.pop();
          },
        );
      },
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.cancel),
        label: const Text('Cancel Donation'),
        onPressed: () => _showCancelDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
