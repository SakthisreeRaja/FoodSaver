import 'package:foodsaver/models/donation.dart';
import 'package:foodsaver/models/pickup.dart';
import 'package:foodsaver/models/dummy_data.dart';

final List<Pickup> dummyPickups = [
  Pickup(
    id: 'p1',
    donation: dummyDonations[4], // Pasta and Sauce
    status: 'Pending',
    pickupTime: DateTime.now().add(const Duration(hours: 1)),
  ),
  Pickup(
    id: 'p2',
    donation: dummyDonations[3], // Fresh Milk
    status: 'In Progress',
    pickupTime: DateTime.now().subtract(const Duration(minutes: 30)),
  ),
  Pickup(
    id: 'p3',
    donation: dummyDonations[0], // Fresh Apples
    status: 'Completed',
    pickupTime: DateTime.now().subtract(const Duration(days: 1)),
  ),
];
