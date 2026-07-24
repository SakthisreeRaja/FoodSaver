import 'package:flutter/material.dart';
import 'package:foodsaver/models/pickup.dart';
import 'package:google_fonts/google_fonts.dart';

class PickupCard extends StatelessWidget {
  final Pickup pickup;
  final VoidCallback onTap;

  const PickupCard({
    super.key,
    required this.pickup,
    required this.onTap,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pickup.donation.foodName,
                      style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(pickup.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pickup.donation.description,
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
                      pickup.donation.location,
                      style: GoogleFonts.lato(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'in progress':
        color = Colors.blue;
        text = 'In Progress';
        break;
      case 'completed':
        color = Colors.green;
        text = 'Completed';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        text,
        style: GoogleFonts.lato(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
