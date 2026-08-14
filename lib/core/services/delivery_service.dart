import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:foodsaver/core/services/notification_service.dart';

// ─── Fare Model ───────────────────────────────────────────────────────────────

class DeliveryFare {
  final double distanceKm;
  final double originalFare;
  final double csrSubsidy;
  final double ngoPays;

  const DeliveryFare({
    required this.distanceKm,
    required this.originalFare,
    required this.csrSubsidy,
    required this.ngoPays,
  });

  /// Formatted rupee string
  String get originalFareStr => '₹${originalFare.toStringAsFixed(0)}';
  String get csrSubsidyStr => '₹${csrSubsidy.toStringAsFixed(0)}';
  String get ngoPaysStr => '₹${ngoPays.toStringAsFixed(0)}';
}

// ─── ETA Model ───────────────────────────────────────────────────────────────

class DeliveryEta {
  final int minutes;
  final double distanceKm;

  const DeliveryEta({required this.minutes, required this.distanceKm});

  String get label {
    if (minutes < 60) return '~$minutes mins';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '~${h}h ${m}m';
  }
}

// ─── Service ─────────────────────────────────────────────────────────────────

class DeliveryService {
  static const double _baseFare = 20.0;
  static const double _perKmRate = 8.0;
  static const double _csrCoverageRatio = 0.70; // 70% funded by app
  static const double _avgSpeedKmh = 25.0; // assumed avg delivery speed

  static final _firestore = FirebaseFirestore.instance;

  // ─── Fare Calculation ───────────────────────────────────────────────────────

  /// Calculate delivery fare given distance in km.
  static DeliveryFare calculateFare(double distanceKm) {
    final original = _baseFare + (_perKmRate * distanceKm);
    final subsidy = original * _csrCoverageRatio;
    final ngoPays = original - subsidy;
    return DeliveryFare(
      distanceKm: distanceKm,
      originalFare: original,
      csrSubsidy: subsidy,
      ngoPays: ngoPays,
    );
  }

  // ─── ETA Calculation ───────────────────────────────────────────────────────

  /// Estimate delivery time in minutes given distance in km.
  static DeliveryEta calculateEta(double distanceKm) {
    final hours = distanceKm / _avgSpeedKmh;
    final minutes = (hours * 60).ceil();
    return DeliveryEta(minutes: minutes, distanceKm: distanceKm);
  }

  // ─── Haversine distance ─────────────────────────────────────────────────────

  static double haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;

  // ─── Firestore: Create Delivery Job ────────────────────────────────────────

  /// Creates a delivery_job document when NGO chooses Delivery Partner.
  Future<String> createDeliveryJob({
    required String donationId,
    required String ngoId,
    required String donorId,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required DeliveryFare fare,
  }) async {
    try {
      final ref = _firestore.collection('delivery_jobs').doc();
      await ref.set({
        'id': ref.id,
        'donationId': donationId,
        'ngoId': ngoId,
        'donorId': donorId,
        'status': 'open',
        'deliveryPartnerId': null,
        'pickupCoords': {
          'latitude': pickupLat,
          'longitude': pickupLng,
        },
        'dropoffCoords': {
          'latitude': dropoffLat,
          'longitude': dropoffLng,
        },
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'distanceKm': fare.distanceKm,
        'fareOriginal': fare.originalFare,
        'csrSubsidy': fare.csrSubsidy,
        'ngoPays': fare.ngoPays,
        'estimatedMinutes': null,
        'partnerLocation': null,
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'deliveredAt': null,
      });
      return ref.id;
    } catch (e) {
      throw Exception('Failed to create delivery job: $e');
    }
  }

  // ─── Firestore: Accept Job ──────────────────────────────────────────────────

  /// Delivery partner accepts a job — saves their location, calculates ETA.
  Future<DeliveryEta> acceptDeliveryJob({
    required String jobId,
    required double partnerLat,
    required double partnerLng,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    try {
      final jobDoc = await _firestore.collection('delivery_jobs').doc(jobId).get();
      if (!jobDoc.exists) throw Exception('Job not found');

      final data = jobDoc.data()!;
      final pickup = data['pickupCoords'] as Map<String, dynamic>;
      final pickupLat = (pickup['latitude'] as num).toDouble();
      final pickupLng = (pickup['longitude'] as num).toDouble();

      // Distance from partner to pickup
      final distKm = haversineKm(partnerLat, partnerLng, pickupLat, pickupLng);
      final eta = calculateEta(distKm);

      // Partner name for notification
      final partnerDoc = await _firestore.collection('users').doc(uid).get();
      final partnerName = partnerDoc.data()?['name'] as String? ?? 'Delivery Partner';

      await _firestore.collection('delivery_jobs').doc(jobId).update({
        'status': 'accepted',
        'deliveryPartnerId': uid,
        'partnerName': partnerName,
        'partnerLocation': {
          'latitude': partnerLat,
          'longitude': partnerLng,
        },
        'estimatedMinutes': eta.minutes,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Also update the linked pickup doc
      final pickupSnap = await _firestore
          .collection('pickups')
          .where('deliveryJobId', isEqualTo: jobId)
          .limit(1)
          .get();
      if (pickupSnap.docs.isNotEmpty) {
        await pickupSnap.docs.first.reference.update({
          'status': 'scheduled',
          'volunteerId': uid, // backward compat field
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Notify NGO
      final ngoId = data['ngoId'] as String?;
      final donorId = data['donorId'] as String?;
      final donationId = data['donationId'] as String?;
      final foodType = await _getFoodType(donationId);

      if (ngoId != null) {
        await NotificationService().sendPickupAcceptedNotification(
          donorUid: ngoId,
          pickupId: jobId,
          foodType: foodType,
          volunteerName: partnerName,
        );
      }
      if (donorId != null) {
        await NotificationService().sendPickupAcceptedNotification(
          donorUid: donorId,
          pickupId: jobId,
          foodType: foodType,
          volunteerName: partnerName,
        );
      }

      return eta;
    } catch (e) {
      throw Exception('Failed to accept job: $e');
    }
  }

  // ─── Firestore: Update Job Status ──────────────────────────────────────────

  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      final Map<String, dynamic> update = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (status == 'delivered') {
        update['deliveredAt'] = FieldValue.serverTimestamp();
      }
      await _firestore.collection('delivery_jobs').doc(jobId).update(update);

      // Mirror status to linked pickup
      final pickupSnap = await _firestore
          .collection('pickups')
          .where('deliveryJobId', isEqualTo: jobId)
          .limit(1)
          .get();
      if (pickupSnap.docs.isNotEmpty) {
        final newPickupStatus = status == 'delivered' ? 'completed' : status;
        await pickupSnap.docs.first.reference.update({
          'status': newPickupStatus,
          'updatedAt': FieldValue.serverTimestamp(),
          if (status == 'delivered')
            'completedAt': FieldValue.serverTimestamp(),
        });

        // If delivered, mark donation as completed
        if (status == 'delivered') {
          final jobDoc =
              await _firestore.collection('delivery_jobs').doc(jobId).get();
          final donationId = jobDoc.data()?['donationId'] as String?;
          final donorId = jobDoc.data()?['donorId'] as String?;
          final ngoId = jobDoc.data()?['ngoId'] as String?;
          if (donationId != null) {
            await _firestore
                .collection('donations')
                .doc(donationId)
                .update({'status': 'completed'});
          }
          final foodType = await _getFoodType(donationId);
          for (final uid in [donorId, ngoId]) {
            if (uid != null) {
              await NotificationService().sendPickupStatusNotification(
                recipientUid: uid,
                status: 'completed',
                foodType: foodType,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating job status: $e');
      rethrow;
    }
  }

  // ─── Stream helpers ─────────────────────────────────────────────────────────

  /// Stream of open delivery jobs (for DP dashboard).
  Stream<List<Map<String, dynamic>>> streamOpenJobs() {
    return _firestore
        .collection('delivery_jobs')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .asyncMap(_enrichJobs);
  }

  /// Stream of jobs accepted by this DP.
  Stream<List<Map<String, dynamic>>> streamMyJobs(String uid) {
    return _firestore
        .collection('delivery_jobs')
        .where('deliveryPartnerId', isEqualTo: uid)
        .snapshots()
        .asyncMap(_enrichJobs);
  }

  /// Stream of delivery jobs related to an NGO.
  Stream<List<Map<String, dynamic>>> streamNgoJobs(String ngoId) {
    return _firestore
        .collection('delivery_jobs')
        .where('ngoId', isEqualTo: ngoId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap(_enrichJobs);
  }

  Future<List<Map<String, dynamic>>> _enrichJobs(QuerySnapshot snap) async {
    final List<Map<String, dynamic>> result = [];
    for (final doc in snap.docs) {
      final data = {...doc.data() as Map<String, dynamic>, 'id': doc.id};
      final donationId = data['donationId'] as String?;
      if (donationId != null) {
        try {
          final don =
              await _firestore.collection('donations').doc(donationId).get();
          if (don.exists) data['donation'] = {...don.data()!, 'id': don.id};
        } catch (_) {}
      }
      result.add(data);
    }
    return result;
  }

  Future<String> _getFoodType(String? donationId) async {
    if (donationId == null) return 'Food';
    try {
      final doc =
          await _firestore.collection('donations').doc(donationId).get();
      return doc.data()?['foodType'] as String? ?? 'Food';
    } catch (_) {
      return 'Food';
    }
  }
}
