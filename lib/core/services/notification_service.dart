import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Background message handler (top-level, required by FCM) ─────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background FCM: ${message.notification?.title}');
}

// ─── Android Notification Channel ────────────────────────────────────────────
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'foodsaver_high_importance',
  'FoodSaver Alerts',
  description: 'Pickup requests, donations accepted, and delivery updates.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ─── Initialize ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    await _initLocalNotifications();

    // Request permission
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get + save FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await saveFCMToken(token);
        debugPrint('✅ FCM token saved');
      }

      // Refresh token listener
      _messaging.onTokenRefresh.listen((newToken) async {
        await saveFCMToken(newToken);
        debugPrint('🔄 FCM token refreshed');
      });

      // Foreground messages → show local notification
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // App opened from notification tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was launched from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } else {
      debugPrint('⚠️ Notification permission not granted');
    }
  }

  Future<void> _initLocalNotifications() async {
    const initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await _localNotifications.initialize(initSettings);

    // Create the high-importance channel on Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  // ─── FCM Token ──────────────────────────────────────────────────────────────

  /// Save the FCM token to the current user's Firestore document.
  Future<void> saveFCMToken(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await _firestore.collection('users').doc(uid).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('⚠️ Error saving FCM token: $e');
    }
  }

  // ─── Foreground / Background handlers ───────────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 Foreground FCM: ${message.notification?.title}');
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    // Navigation can be handled here with a global navigator key if needed
  }

  // ─── In-App Notification Documents (Firestore) ───────────────────────────────

  /// Write a notification document for [recipientUid] about a pickup being accepted.
  /// This populates the in-app notification feed.
  Future<void> sendPickupAcceptedNotification({
    required String donorUid,
    required String pickupId,
    required String foodType,
    required String volunteerName,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': donorUid,
        'type': 'pickup_accepted',
        'title': '🚴 Pickup Accepted!',
        'body': '$volunteerName has accepted your "$foodType" donation pickup.',
        'pickupId': pickupId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Donor notification written to Firestore');
    } catch (e) {
      debugPrint('⚠️ Error sending pickup notification: $e');
    }
  }

  /// Write a notification when pickup status changes.
  Future<void> sendPickupStatusNotification({
    required String recipientUid,
    required String status,
    required String foodType,
  }) async {
    final (title, body) = _statusNotificationText(status, foodType);
    try {
      await _firestore.collection('notifications').add({
        'userId': recipientUid,
        'type': 'pickup_status',
        'title': title,
        'body': body,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Error sending status notification: $e');
    }
  }

  (String, String) _statusNotificationText(String status, String foodType) {
    switch (status) {
      case 'in_progress':
        return (
          '🚚 Pickup In Transit',
          'Your "$foodType" pickup is on the way!'
        );
      case 'completed':
        return (
          '✅ Delivery Complete',
          'Your "$foodType" donation was successfully delivered!'
        );
      default:
        return ('📦 Pickup Update', 'Your pickup status changed to $status');
    }
  }

  // ─── Read / Manage Notifications ────────────────────────────────────────────

  /// Get all notifications for user
  Future<List<Map<String, dynamic>>> getNotifications(
      String uid, int limit) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  /// Stream notifications in real-time for the current user.
  Stream<List<Map<String, dynamic>>> streamNotificationsForUser(String uid) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList());
  }

  /// Legacy: stream all notifications (not filtered by user — kept for backward compat).
  Stream<List<Map<String, dynamic>>> streamNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }
}
