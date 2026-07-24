import 'package:foodsaver/models/donation.dart';

class Pickup {
  final String id;
  final Donation donation;
  final String status; // e.g., 'Pending', 'In Progress', 'Completed'
  final DateTime pickupTime;

  Pickup({
    required this.id,
    required this.donation,
    required this.status,
    required this.pickupTime,
  });
}
