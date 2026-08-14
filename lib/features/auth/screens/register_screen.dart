import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/primary_button.dart';
import '../../../core/components/custom_text_field.dart';
import 'firebase_auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _agreeToTerms = false;

  // ── Role selection (inline) ──────────────────────────────────────────────
  String? _selectedRole; // 'donor' | 'ngo' | 'volunteer'

  static const _roles = [
    {
      'key': 'donor',
      'title': 'Donor',
      'subtitle': 'I have food to share',
      'icon': Icons.volunteer_activism,
      'color': Color(0xFF10B981),
    },
    {
      'key': 'ngo',
      'title': 'NGO / Organization',
      'subtitle': 'We receive and distribute food',
      'icon': Icons.business,
      'color': Color(0xFF6366F1),
    },
    {
      'key': 'delivery_partner',
      'title': 'Delivery Partner',
      'subtitle': 'I deliver food donations',
      'icon': Icons.delivery_dining,
      'color': Color(0xFFF59E0B),
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validate role first
    if (_selectedRole == null) {
      setState(() => _errorMessage = 'Please select your role to continue.');
      return;
    }

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'All fields are required.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    if (!_agreeToTerms) {
      setState(
          () => _errorMessage = 'Please agree to the Terms & Conditions.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuthService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: _selectedRole!,
      );

      if (!mounted) return;

      // Route directly to the correct dashboard — skip /role-selection
      switch (_selectedRole) {
        case 'donor':
          context.go('/donor-dashboard');
          break;
        case 'ngo':
          context.go('/ngo-dashboard');
          break;
        case 'delivery_partner':
          context.go('/dp-dashboard');
          break;
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Account 🚀',
                style:
                    TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Join the community and start reducing food waste.',
                style: TextStyle(
                    fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 28),

              // ── Error banner ─────────────────────────────────────────────
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Role picker (inline) ─────────────────────────────────────
              const Text(
                'I am a...',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._roles.map((role) => _buildRoleCard(role)),
              const SizedBox(height: 24),

              // ── Form fields ──────────────────────────────────────────────
              CustomTextField(
                label: 'Full Name',
                icon: Icons.person_outline,
                controller: _nameController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email Address',
                icon: Icons.email_outlined,
                controller: _emailController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Password',
                icon: Icons.lock_outline,
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Confirm Password',
                icon: Icons.lock_outline,
                isPassword: true,
                controller: _confirmPasswordController,
              ),
              const SizedBox(height: 16),

              // Terms checkbox
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _agreeToTerms,
                onChanged: (v) =>
                    setState(() => _agreeToTerms = v ?? false),
                title: const Text('I agree to Terms & Conditions',
                    style: TextStyle(fontSize: 14)),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                text: _isLoading ? 'Creating Account...' : 'Sign Up',
                onPressed: _handleRegister,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Sign In',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> role) {
    final key = role['key'] as String;
    final isSelected = _selectedRole == key;
    final color = role['color'] as Color;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                role['icon'] as IconData,
                color: isSelected ? color : Colors.grey.shade500,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role['title'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role['subtitle'] as String,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}
