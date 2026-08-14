import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class UserService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String name,
    required String email,
    required String phoneNumber,
    required String userType,
    String? address,
    double? latitude,
    double? longitude,
    String? profileImage,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');

      await _functions.httpsCallable('updateUserProfile').call({
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'userType': userType,
        'address': address,
        'coordinates': latitude != null && longitude != null
            ? {
                'latitude': latitude,
                'longitude': longitude,
              }
            : null,
        'profileImage': profileImage,
      });
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) throw Exception('User not found');
      return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return getUserProfile(user.uid);
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  /// Update FCM token
  Future<void> updateFCMToken(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');

      await _functions.httpsCallable('updateFCMToken').call({
        'fcmToken': token,
      });
    } catch (e) {
      throw Exception('Error updating FCM token: $e');
    }
  }

  /// Get donation statistics
  Future<Map<String, dynamic>> getDonationStats() async {
    try {
      final result = await _functions.httpsCallable('getDonationStats').call();
      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error fetching stats: $e');
    }
  }

  /// Search users by role
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: role)
          .get();

      return snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  /// Stream user profile updates
  Stream<Map<String, dynamic>?> streamUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
    });
  }

  /// Rate a user (donor/NGO/volunteer)
  Future<void> rateUser({
    required String userId,
    required int rating,
    required String review,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('Not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ratings')
          .add({
            'rating': rating,
            'review': review,
            'ratedBy': currentUserId,
            'createdAt': DateTime.now(),
          });

      // Update user's average rating
      final ratings = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ratings')
          .get();

      final totalRating =
          ratings.docs.fold<int>(0, (acc, doc) => acc + (doc['rating'] as int));
      final averageRating = totalRating / ratings.docs.length;

      await _firestore.collection('users').doc(userId).update({
        'rating': averageRating,
        'ratingCount': ratings.docs.length,
      });
    } catch (e) {
      throw Exception('Error rating user: $e');
    }
  }

  /// Get user ratings
  Future<List<Map<String, dynamic>>> getUserRatings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ratings')
          .get();

      return snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      throw Exception('Error fetching ratings: $e');
    }
  }
}
