import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Create a new food donation — saves directly to Firestore
  Future<Map<String, dynamic>> createDonation({
    required String foodType,
    required int quantity,
    required String unit,
    required String description,
    required String pickupLocation,
    required double latitude,
    required double longitude,
    String? imageUrl,
    String? expiryDate,
    String? availableFrom,
    String? availableTo,
    String? category,
    Map<String, dynamic>? aiAnalysis,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final doc = _db.collection('donations').doc();
    final data = {
      'id': doc.id,
      'donorId': uid,
      'foodType': foodType,
      'quantity': quantity,
      'unit': unit,
      'description': description,
      'pickupLocation': pickupLocation,
      'coordinates': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'imageUrl': imageUrl,
      'expiryDate': expiryDate,
      'availableFrom': availableFrom,
      'availableTo': availableTo,
      'category': category ?? 'other',
      'status': 'available',
      'rating': 0.0,
      'reviewCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (aiAnalysis != null) 'aiAnalysis': aiAnalysis,
    };

    await doc.set(data);
    return {...data, 'id': doc.id};
  }

  /// Get available donations near a location (Firestore query)
  Future<List<Map<String, dynamic>>> getAvailableDonations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    String? category,
    int limit = 50,
  }) async {
    try {
      Query query = _db
          .collection('donations')
          .where('status', isEqualTo: 'available')
          .limit(limit);

      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();
      final donations = snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();

      // Client-side distance filtering
      return donations.where((d) {
        final coords = d['coordinates'] as Map<String, dynamic>?;
        if (coords == null) return true;
        final lat2 = (coords['latitude'] as num?)?.toDouble() ?? 0;
        final lng2 = (coords['longitude'] as num?)?.toDouble() ?? 0;
        final dist = _haversine(latitude, longitude, lat2, lng2);
        d['distance'] = dist;
        return dist <= radiusKm;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching donations: $e');
    }
  }

  /// Get details for a single donation
  Future<Map<String, dynamic>> getDonationDetails(String donationId) async {
    final doc = await _db.collection('donations').doc(donationId).get();
    if (!doc.exists) throw Exception('Donation not found');
    return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
  }

  /// Get all donations created by the current logged-in donor
  Future<List<Map<String, dynamic>>> getDonorDonations() async {
    final uid = _uid;
    if (uid == null) return [];
    final snapshot = await _db
        .collection('donations')
        .where('donorId', isEqualTo: uid)
        .get();
    return snapshot.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList();
  }

  /// Claim a donation (NGO action)
  Future<void> claimDonation({
    required String donationId,
    required String ngoId,
  }) async {
    final batch = _db.batch();
    final donRef = _db.collection('donations').doc(donationId);
    final pickupRef = _db.collection('pickups').doc();

    batch.update(donRef, {
      'status': 'claimed',
      'claimedBy': ngoId,
      'claimedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(pickupRef, {
      'id': pickupRef.id,
      'donationId': donationId,
      'ngoId': ngoId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Update donation status
  Future<void> updateDonationStatus({
    required String donationId,
    required String status,
  }) async {
    await _db.collection('donations').doc(donationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Rate a donation
  Future<void> rateDonation({
    required String donationId,
    required int rating,
    required String review,
    required String reviewerType,
  }) async {
    final uid = _uid;
    final doc = _db.collection('donations').doc(donationId);
    await doc.collection('reviews').add({
      'rating': rating,
      'review': review,
      'reviewerType': reviewerType,
      'reviewerId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Update average
    final reviews = await doc.collection('reviews').get();
    final avg = reviews.docs
            .fold<int>(0, (acc, d) => acc + (d['rating'] as int? ?? 0)) /
        reviews.docs.length;
    await doc.update({'rating': avg, 'reviewCount': reviews.docs.length});
  }

  /// Search donations by keyword
  Future<List<Map<String, dynamic>>> searchDonations({
    required String query,
    double? latitude,
    double? longitude,
    double radiusKm = 10,
  }) async {
    final lower = query.toLowerCase();
    final snapshot = await _db
        .collection('donations')
        .where('status', isEqualTo: 'available')
        .get();
    return snapshot.docs
        .map((d) => {...d.data(), 'id': d.id})
        .where((d) =>
            (d['foodType'] as String? ?? '').toLowerCase().contains(lower) ||
            (d['description'] as String? ?? '').toLowerCase().contains(lower))
        .toList();
  }

  /// Real-time stream of available donations
  Stream<List<Map<String, dynamic>>> streamAvailableDonations() {
    return _db
        .collection('donations')
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  // ── Haversine distance (km) ────────────────────────────────────────────────
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double d) => d * math.pi / 180;
}

