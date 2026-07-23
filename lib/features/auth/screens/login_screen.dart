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
                  onPressed: () {},
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
                    onPressed: () {}, // Navigate to register
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
}