import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/ai_service.dart';

class AiAnalyzingScreen extends StatefulWidget {
  final String? imagePath;

  const AiAnalyzingScreen({super.key, this.imagePath});

  @override
  State<AiAnalyzingScreen> createState() => _AiAnalyzingScreenState();
}

class _AiAnalyzingScreenState extends State<AiAnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final List<String> _steps = [
    'Identifying food items...',
    'Estimating quantity...',
    'Checking freshness...',
    'Preparing your form...',
  ];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _runAnalysis();
    _cycleSteps();
  }

  void _cycleSteps() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _currentStep = (_currentStep + 1) % _steps.length);
      _cycleSteps();
    });
  }

  Future<void> _runAnalysis() async {
    final imagePath = widget.imagePath;

    // Run AI analysis + ensure at least 2s of animation
    final results = await Future.wait([
      if (imagePath != null)
        AiService.analyzeFoodImage(imagePath)
      else
        Future.value(FoodAnalysisResult.fromRawText('No image provided.')),
      Future.delayed(const Duration(milliseconds: 2000)),
    ]);

    final analysisResult = results[0] as FoodAnalysisResult;

    if (mounted) {
      context.go('/donation-form', extra: {
        'imagePath': imagePath,
        'analysisResult': analysisResult,
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
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primary.withOpacity(0.15),
                          primary.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 60,
                      color: primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Analyzing with AI',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  _steps[_currentStep],
                  key: ValueKey(_currentStep),
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 15, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentStep == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentStep == i
                          ? primary
                          : primary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
