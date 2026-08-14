import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register with email and password
  static Future<UserCredential?> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'id': credential.user!.uid,
        'email': email,
        'fullName': fullName,
        'name': fullName,
        'role': role,
        'userType': role,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'profileComplete': false,
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // Login with email and password
  static Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // Send password reset email
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
    } catch (e) {
      throw 'Failed to fetch user data: $e';
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  static String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password too weak. Use 6+ characters';
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Wrong password';
      case 'too-many-requests':
        return 'Too many login attempts. Try again later';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  static Future<void> updateCurrentUserRole(String role) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'You must be signed in to choose a role';
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'id': user.uid,
      'email': user.email,
      'role': role,
      'userType': role,
      'profileComplete': true,
      'updatedAt': DateTime.now(),
    }, SetOptions(merge: true));
  }
}
