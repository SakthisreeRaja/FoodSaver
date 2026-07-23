import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/primary_button.dart';
import '../../../core/components/custom_text_field.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
              const Text("Create Account 🚀", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Join the community and start reducing food waste.", style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 32),
              
              const CustomTextField(label: "Full Name", icon: Icons.person_outline),
              const SizedBox(height: 16),
              const CustomTextField(label: "Email Address", icon: Icons.email_outlined),
              const SizedBox(height: 16),
              const CustomTextField(label: "Password", icon: Icons.lock_outline, isPassword: true),
              const SizedBox(height: 16),
              const CustomTextField(label: "Confirm Password", icon: Icons.lock_outline, isPassword: true),
              
              const SizedBox(height: 32),
              PrimaryButton(
                text: "Sign Up",
                onPressed: () => context.push('/otp-verification'),
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: TextStyle(color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text("Sign In", style: TextStyle(fontWeight: FontWeight.bold)),
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