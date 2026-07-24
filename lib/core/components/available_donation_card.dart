import 'package:flutter/material.dart';
import 'package:foodsaver/models/donation.dart';
import 'package:google_fonts/google_fonts.dart';

class AvailableDonationCard extends StatelessWidget {
  final Donation donation;
  final VoidCallback onAccept;
  final VoidCallback onTap;
  final bool isAccepted;

  const AvailableDonationCard({
    super.key,
    required this.donation,
    required this.onAccept,
    required this.onTap,
    this.isAccepted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                donation.foodName,
                style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                donation.description,
                style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      donation.location,
                      style: GoogleFonts.lato(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expires in 4 hours', // Dummy data
                    style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[700]),
                  ),
                  ElevatedButton(
                    onPressed: isAccepted ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: Text(isAccepted ? "Accepted" : "Accept Donation"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
