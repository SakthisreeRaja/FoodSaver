import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Donor notifications screen — streams in-app notifications from Firestore.
/// Shows pickup accepted, delivery status updates, etc.
class DonorNotificationsScreen extends StatelessWidget {
  const DonorNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (uid != null)
            TextButton(
              onPressed: () => _markAllRead(uid),
              child: const Text('Mark all read',
                  style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Please log in to see notifications.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.red.shade300),
                          const SizedBox(height: 12),
                          Text('Error loading notifications',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('No notifications yet',
                            style:
                                TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('You\'ll be notified when NGOs claim your donations.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final data = {
                      ...docs[i].data() as Map<String, dynamic>,
                      'id': docs[i].id,
                    };
                    return _NotificationCard(
                      data: data,
                      onTap: () => _handleNotificationTap(context, data),
                    );
                  },
                );
              },
            ),
    );
  }

  void _handleNotificationTap(
      BuildContext context, Map<String, dynamic> data) async {
    // Mark as read
    final notifId = data['id'] as String?;
    if (notifId != null) {
      FirebaseFirestore.instance
          .collection('notifications')
          .doc(notifId)
          .update({'read': true});
    }

    // Navigate to the related donation if available
    final donationId = data['donationId'] as String?;
    final pickupId = data['pickupId'] as String?;

    if (donationId != null) {
      try {
        final donDoc = await FirebaseFirestore.instance
            .collection('donations')
            .doc(donationId)
            .get();
        if (donDoc.exists && context.mounted) {
          context.push('/donation-details',
              extra: {...donDoc.data()!, 'id': donDoc.id});
        }
      } catch (_) {}
    } else if (pickupId != null) {
      // Try to find donation via pickup
      try {
        // pickupId might be a delivery_job id
        final jobDoc = await FirebaseFirestore.instance
            .collection('delivery_jobs')
            .doc(pickupId)
            .get();
        if (jobDoc.exists) {
          final donId = jobDoc.data()?['donationId'] as String?;
          if (donId != null) {
            final donDoc = await FirebaseFirestore.instance
                .collection('donations')
                .doc(donId)
                .get();
            if (donDoc.exists && context.mounted) {
              context.push('/donation-details',
                  extra: {...donDoc.data()!, 'id': donDoc.id});
            }
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _markAllRead(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _NotificationCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';
    final isRead = data['read'] as bool? ?? false;
    final type = data['type'] as String? ?? '';
    final ts = data['createdAt'];

    String timeAgo = '';
    if (ts is Timestamp) {
      final diff = DateTime.now().difference(ts.toDate());
      if (diff.inMinutes < 1) {
        timeAgo = 'Just now';
      } else if (diff.inHours < 1) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = '${diff.inDays}d ago';
      }
    }

    final (icon, color) = _typeStyle(type);

    return Material(
      color: isRead ? Colors.white : Colors.blue.shade50,
      borderRadius: BorderRadius.circular(14),
      elevation: isRead ? 0 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead ? Colors.grey.shade200 : Colors.blue.shade100,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (timeAgo.isNotEmpty)
                          Text(timeAgo,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4),
                    ),
                    if (!isRead) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('NEW',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _typeStyle(String type) {
    switch (type) {
      case 'pickup_accepted':
        return (Icons.local_shipping, Colors.blue);
      case 'self_pickup':
        return (Icons.directions_car, Colors.green);
      case 'pickup_status':
        return (Icons.update, Colors.orange);
      default:
        return (Icons.notifications, Colors.grey);
    }
  }
}
