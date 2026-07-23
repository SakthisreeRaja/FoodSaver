import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/primary_button.dart';

class CreateDonationScreen extends StatelessWidget {
  const CreateDonationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Donation"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Let AI analyze your food",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Take a clear picture of the food you wish to donate. Our AI will automatically categorize it and check for spoilage.",
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 40),
            
            // Camera / Upload Placeholder Area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text("Tap to open camera", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text("or select from gallery", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            PrimaryButton(
              text: "Analyze Image",
              onPressed: () => context.push('/analyze'), 
            ),
          ],
        ),
      ),
    );
  }
}