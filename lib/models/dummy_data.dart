import 'donation.dart';

final List<Donation> dummyDonations = [
  Donation(
    id: '1',
    foodName: 'Fresh Apples',
    description: 'A box of 20 fresh red apples.',
    location: '123 Apple St, Fruit City',
    status: 'Completed',
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Donation(
    id: '2',
    foodName: 'Homemade Bread Loaves',
    description: '5 loaves of whole wheat bread.',
    location: '456 Bake Ave, Grainsville',
    status: 'Completed',
    timestamp: DateTime.now().subtract(const Duration(days: 5)),
  ),
  Donation(
    id: '3',
    foodName: 'Canned Vegetables',
    description: 'A variety pack of canned corn, peas, and beans.',
    location: '789 Preserve Ln, Townsville',
    status: 'Cancelled',
    timestamp: DateTime.now().subtract(const Duration(days: 10)),
  ),
    Donation(
    id: '4',
    foodName: 'Fresh Milk',
    description: '5 Gallons of whole milk.',
    location: '123 Dairy St, Milk City',
    status: 'Active',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  Donation(
    id: '5',
    foodName: 'Pasta and Sauce',
    description: '10 boxes of spaghetti and 10 jars of marinara sauce.',
    location: '456 Pasta Ave, Rome',
    status: 'Active',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
  ),
];
