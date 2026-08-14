import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

/// Provides the current user's Firestore profile as an async value.
final currentUserProfileProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (!doc.exists) return null;
  return {...doc.data()!, 'id': doc.id};
});

// ─── Helper widget ────────────────────────────────────────────────────────────

/// Builds a profile header (avatar + name + email) from Firebase Auth + Firestore.
/// Automatically falls back to Firebase Auth displayName / email if Firestore is
/// not yet populated.
class UserProfileHeader extends ConsumerWidget {
  final Color? avatarBg;
  final IconData avatarIcon;
  final Widget? extraBadge;

  const UserProfileHeader({
    super.key,
    this.avatarBg,
    this.avatarIcon = Icons.person,
    this.extraBadge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final authUser = FirebaseAuth.instance.currentUser;

    return profileAsync.when(
      data: (profile) {
        final name = profile?['name'] as String? ??
            profile?['fullName'] as String? ??
            authUser?.displayName ??
            'User';
        final email =
            profile?['email'] as String? ?? authUser?.email ?? '';
        final role =
            profile?['role'] as String? ?? profile?['userType'] as String? ?? '';

        return Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor:
                      avatarBg ?? Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  child: Icon(avatarIcon, size: 50,
                      color: Theme.of(context).colorScheme.primary),
                ),
                if (extraBadge != null) extraBadge!,
              ],
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            if (role.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role[0].toUpperCase() + role.substring(1),
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            child: const CircularProgressIndicator(),
          ),
          const SizedBox(height: 14),
          Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8))),
        ],
      ),
      error: (_, __) => Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            child:
                Icon(avatarIcon, size: 50, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 14),
          Text(
            authUser?.displayName ?? authUser?.email ?? 'User',
            style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
