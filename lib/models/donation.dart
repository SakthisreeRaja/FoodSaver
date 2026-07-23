class Donation {
  final String id;
  final String foodName;
  final String description;
  final String location;
  final String status; // e.g., 'Available', 'Claimed'
  final DateTime timestamp;

  Donation({
    required this.id,
    required this.foodName,
    required this.description,
    required this.location,
    required this.status,
    required this.timestamp,
  });
}