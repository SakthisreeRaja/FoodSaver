import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/donor/screens/donor_main_screen.dart';
import '../../features/donor/screens/create_donation_screen.dart';
import '../../features/ai_camera/screens/ai_analyzing_screen.dart';
import '../../features/ai_camera/screens/donation_form_screen.dart';
import '../../features/ngo/screens/ngo_dashboard_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/otp-verification', builder: (context, state) => const OtpVerificationScreen()),
    GoRoute(path: '/profile-setup', builder: (context, state) => const ProfileSetupScreen()),
    GoRoute(path: '/role-selection', builder: (context, state) => const RoleSelectionScreen()),
    GoRoute(path: '/donor-dashboard', builder: (context, state) => const DonorMainScreen()),
    GoRoute(path: '/create-donation', builder: (context, state) => const CreateDonationScreen()),
    GoRoute(path: '/analyze', builder: (context, state) => const AiAnalyzingScreen()),
    GoRoute(path: '/donation-form', builder: (context, state) => const DonationFormScreen()),
    GoRoute(path: '/ngo-dashboard', builder: (context, state) => const NgoDashboardScreen()),
  ],
);