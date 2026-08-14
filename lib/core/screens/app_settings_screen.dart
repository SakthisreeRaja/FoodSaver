import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:foodsaver/features/auth/screens/firebase_auth_service.dart';

/// Shared settings screen for all roles — pass [role] string for cosmetic differences
class AppSettingsScreen extends ConsumerStatefulWidget {
  final String role; // 'donor' | 'ngo' | 'volunteer'
  const AppSettingsScreen({super.key, this.role = 'user'});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _isChangingPassword = false;

  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final oldPass = _oldPasswordCtrl.text.trim();
    final newPass = _newPasswordCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill both fields.')),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: oldPass);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPass);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Password changed successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  void _showChangePasswordDialog() {
    _oldPasswordCtrl.clear();
    _newPasswordCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password (min 6 chars)',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isChangingPassword ? null : _changePassword,
            child: _isChangingPassword
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Change'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          _sectionHeader('Account'),
          _tile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: 'Update your name and details',
            onTap: () => context.push('/edit-profile'),
          ),
          _tile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your login password',
            onTap: _showChangePasswordDialog,
          ),

          const Divider(height: 1),
          _sectionHeader('Notifications'),
          SwitchListTile(
            secondary: Icon(Icons.notifications_outlined, color: primary),
            title: const Text('Push Notifications',
                style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text('Receive alerts on this device'),
            value: _pushNotifications,
            activeColor: primary,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          SwitchListTile(
            secondary: Icon(Icons.email_outlined, color: primary),
            title: const Text('Email Notifications',
                style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text('Receive updates via email'),
            value: _emailNotifications,
            activeColor: primary,
            onChanged: (v) => setState(() => _emailNotifications = v),
          ),

          const Divider(height: 1),
          _sectionHeader('About'),
          _tile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => context.push('/privacy-policy'),
          ),
          _tile(
            icon: Icons.gavel_outlined,
            title: 'Terms & Conditions',
            onTap: () => context.push('/terms-conditions'),
          ),
          _tile(
            icon: Icons.info_outline,
            title: 'About FoodSaver',
            onTap: () => context.push('/about'),
          ),

          const Divider(height: 1),
          _sectionHeader('Account Actions'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () async {
              await FirebaseAuthService.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () => _showDeleteAccountDialog(),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'FoodSaver v1.0.0',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey.shade500,
              letterSpacing: 0.8)),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading:
          Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?',
            style: TextStyle(color: Colors.red)),
        content: const Text(
            'This will permanently delete your account and all data. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseAuth.instance.currentUser?.delete();
                if (context.mounted) context.go('/login');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
