import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/primary_button.dart';

class DonationFormScreen extends StatelessWidget {
  final String? imagePath;
  final String? analysisText;

  const DonationFormScreen({super.key, this.imagePath, this.analysisText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Donation"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/donor-dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Donated Food Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: imagePath != null
                      ? FileImage(File(imagePath!)) as ImageProvider
                      // Fallback stock photo if no image was captured (e.g. deep-linked here)
                      : const NetworkImage('https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&q=80&w=800'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text("AI Analysis Results", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // AI Results Card
            Builder(builder: (context) {
              final text = analysisText ?? 'No analysis available yet.';
              final failed = text.startsWith('AI Analysis Failed');

              return Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: failed ? Colors.orange.shade100 : Colors.green.shade100, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          failed ? Icons.error_outline : Icons.check_circle,
                          color: failed ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          failed ? "Analysis Unavailable" : "Gemini Analysis",
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(text, style: TextStyle(color: Colors.grey.shade800, height: 1.5)),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 32),
            const Text("Additional Details (Optional)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Add any specific pickup instructions or dietary notes (e.g., Contains nuts)",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            PrimaryButton(
              text: "Confirm & Donate",
              onPressed: () {
                _showSuccessBottomSheet(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 24),
            const Text("Donation Listed!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("NGOs and volunteers nearby have been notified.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            PrimaryButton(
              text: "Back to Dashboard",
              onPressed: () {
                Navigator.pop(context); // Close sheet
                context.go('/donor-dashboard'); // Go home
              },
            ),
          ],
        ),
      ),
    );
  }
}