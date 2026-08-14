import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/primary_button.dart';
import '../../../core/components/custom_text_field.dart';
import 'firebase_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Get user role and navigate accordingly
      final user = FirebaseAuthService.getCurrentUser();
      if (user != null) {
        final userData = await FirebaseAuthService.getUserData(user.uid);
        final role = userData?['role'] ?? 'donor';

        if (mounted) {
          switch (role) {
            case 'donor':
              context.go('/donor-dashboard');
              break;
            case 'ngo':
              context.go('/ngo-dashboard');
              break;
            case 'volunteer':
              context.go('/volunteer-dashboard');
              break;
            case 'admin':
              context.go('/admin-dashboard');
              break;
            default:
              context.go('/role-selection');
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage ?? 'Login failed')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text("Welcome Back 👋",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Sign in to continue making an impact.",
                  style: TextStyle(
                      fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 48),
              
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage ?? '',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              
              CustomTextField(
                label: "Email Address",
                icon: Icons.email_outlined,
                controller: _emailController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Show forgot password dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Reset Password"),
                        content: TextField(
                          decoration: const InputDecoration(
                            hintText: "Enter your email",
                          ),
                          onChanged: (email) {},
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Send Reset Link"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text("Forgot Password?",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: _isLoading ? "Signing in..." : "Sign In",
                onPressed: _handleLogin,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                      style: TextStyle(color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text("Sign Up",
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
}
