import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PickupService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Get pending pickups (for volunteers: all pending; for NGO: filtered by ngoId)
  Future<List<Map<String, dynamic>>> getPendingPickups({
    String? ngoId,
    String? volunteerId,
  }) async {
    try {
      Query query = _db.collection('pickups');

      if (ngoId != null) {
        query = query.where('ngoId', isEqualTo: ngoId);
      } else if (volunteerId != null) {
        query = query.where('volunteerId', isEqualTo: volunteerId);
      } else {
        // For volunteers browsing — show pending pickups not yet assigned
        query = query.where('status', isEqualTo: 'pending');
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
          .toList();
    } catch (e) {
      throw Exception('Error fetching pickups: $e');
    }
  }

  /// Accept a pickup (volunteer takes it)
  Future<void> acceptPickup({
    required String pickupId,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    await _db.collection('pickups').doc(pickupId).update({
      'volunteerId': uid,
      'status': 'scheduled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Schedule a pickup
  Future<void> schedulePickup({
    required String pickupId,
    required String volunteerId,
    required DateTime pickupTime,
    String? notes,
  }) async {
    await _db.collection('pickups').doc(pickupId).update({
      'volunteerId': volunteerId,
      'pickupTime': pickupTime.toIso8601String(),
      'notes': notes,
      'status': 'scheduled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update pickup status
  Future<void> updatePickupStatus({
    required String pickupId,
    required String status,
    String? notes,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (notes != null) updates['notes'] = notes;
    if (status == 'completed') {
      updates['completedAt'] = FieldValue.serverTimestamp();
    }
    await _db.collection('pickups').doc(pickupId).update(updates);

    // If completed, also mark donation as completed
    final pickup =
        await _db.collection('pickups').doc(pickupId).get();
    final donationId = pickup.data()?['donationId'] as String?;
    if (donationId != null && status == 'completed') {
      await _db.collection('donations').doc(donationId).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get pickup details
  Future<Map<String, dynamic>> getPickupDetails(String pickupId) async {
    final doc = await _db.collection('pickups').doc(pickupId).get();
    if (!doc.exists) throw Exception('Pickup not found');
    return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
  }

  /// Get donation data for a pickup
  Future<Map<String, dynamic>> getDonationForPickup(String donationId) async {
    final doc = await _db.collection('donations').doc(donationId).get();
    if (!doc.exists) throw Exception('Donation not found');
    return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
  }

  /// Get all pickups for a volunteer
  Future<List<Map<String, dynamic>>> getVolunteerPickups() async {
    final uid = _uid;
    if (uid == null) return [];
    final snapshot = await _db
        .collection('pickups')
        .where('volunteerId', isEqualTo: uid)
        .get();
    return snapshot.docs
        .map((d) => {...d.data(), 'id': d.id})
        .toList();
  }

  /// Get all pickups for an NGO
  Future<List<Map<String, dynamic>>> getNgoPickups() async {
    final uid = _uid;
    if (uid == null) return [];
    final snapshot = await _db
        .collection('pickups')
        .where('ngoId', isEqualTo: uid)
        .get();
    return snapshot.docs
        .map((d) => {...d.data(), 'id': d.id})
        .toList();
  }

  /// Stream pickups for a volunteer
  Stream<List<Map<String, dynamic>>> streamUserPickups(String userId) {
    return _db
        .collection('pickups')
        .where('volunteerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  /// Stream pickups for an NGO
  Stream<List<Map<String, dynamic>>> streamNGOPickups(String ngoId) {
    return _db
        .collection('pickups')
        .where('ngoId', isEqualTo: ngoId)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  /// Rate a pickup
  Future<void> ratePickup({
    required String pickupId,
    required int rating,
    required String feedback,
  }) async {
    await _db.collection('pickups').doc(pickupId).update({
      'rating': rating,
      'feedback': feedback,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
