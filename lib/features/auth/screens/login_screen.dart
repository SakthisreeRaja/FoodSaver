import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/primary_button.dart';
import '../../../core/components/custom_text_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
              const Text("Welcome Back 👋", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Sign in to continue making an impact.", style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 48),
              
              const CustomTextField(label: "Email Address", icon: Icons.email_outlined),
              const SizedBox(height: 16),
              const CustomTextField(label: "Password", icon: Icons.lock_outline, isPassword: true),
              
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showForgotPasswordDialog(context),
                  child: const Text("Forgot Password?", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
              
              PrimaryButton(
                text: "Sign In",
                onPressed: () => context.go('/role-selection'),
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter your email address and we'll send you a reset link."),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email Address",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('If an account exists for "${emailController.text}", a reset link has been sent.')),
              );
            },
            child: const Text("Send Link"),
          ),
        ],
      ),
    );
  }
}