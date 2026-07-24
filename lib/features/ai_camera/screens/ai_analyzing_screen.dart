import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/ai_service.dart';

class AiAnalyzingScreen extends StatefulWidget {
  final String? imagePath;

  const AiAnalyzingScreen({super.key, this.imagePath});

  @override
  State<AiAnalyzingScreen> createState() => _AiAnalyzingScreenState();
}

class _AiAnalyzingScreenState extends State<AiAnalyzingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    final imagePath = widget.imagePath;

    // Run the real Gemini analysis alongside a minimum display time, so the
    // "Analyzing..." animation doesn't just flash by on a fast response.
    final results = await Future.wait([
      if (imagePath != null)
        AiService.analyzeFoodImage(imagePath)
      else
        Future.value('No image was provided, so this is a placeholder result.'),
      Future.delayed(const Duration(milliseconds: 1800)),
    ]);

    final analysisText = results[0] as String;

    if (mounted) {
      context.go('/donation-form', extra: {
        'imagePath': imagePath,
        'analysisText': analysisText,
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1 + (_controller.value * 0.2)),
                  ),
                  child: Icon(
                    Icons.document_scanner,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              "Analyzing Food...",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Estimating meals and checking quality",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
