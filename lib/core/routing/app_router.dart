import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Models
import '../../models/donation.dart';
import '../../models/pickup.dart';

// Onboarding
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';

// Auth
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';

// Donor
import '../../features/donor/screens/donor_main_screen.dart';
import '../../features/donor/screens/create_donation_screen.dart';
import '../../features/donor/screens/donation_history_screen.dart';
import '../../features/donor/screens/donation_details_screen.dart';
import '../../features/donor/screens/edit_donation_screen.dart';
import '../../features/donor/screens/active_donations_screen.dart';
import '../../features/donor/screens/completed_donations_screen.dart';
import '../../features/donor/screens/donor_profile_screen.dart';
import '../../features/donor/screens/donor_settings_screen.dart';

// AI Camera
import '../../features/ai_camera/screens/ai_analyzing_screen.dart';
import '../../features/ai_camera/screens/camera_screen.dart';
import '../../features/ai_camera/screens/donation_form_screen.dart';

// NGO
import '../../features/ngo/screens/ngo_dashboard_screen.dart';
import '../../features/ngo/screens/ngo_profile_screen.dart';
import '../../features/ngo/screens/ngo_settings_screen.dart';
import '../../features/ngo/screens/ngo_statistics_screen.dart';

// Volunteer
import '../../features/volunteer/screens/volunteer_dashboard_screen.dart';
import '../../features/volunteer/screens/pickup_details_screen.dart';
import '../../features/volunteer/screens/delivery_tracking_screen.dart';
import '../../features/volunteer/screens/delivery_completed_screen.dart';
import '../../features/volunteer/screens/qr_scan_screen.dart';
import '../../features/volunteer/screens/volunteer_history_screen.dart';
import '../../features/volunteer/screens/volunteer_profile_screen.dart';
import '../../features/volunteer/screens/volunteer_settings_screen.dart';

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
    
    // Donor Routes
    GoRoute(path: '/donor-dashboard', builder: (context, state) => const DonorMainScreen()),
    GoRoute(path: '/create-donation', builder: (context, state) => const CreateDonationScreen()),
    GoRoute(path: '/active-donations', builder: (context, state) => const ActiveDonationsScreen()),
    GoRoute(path: '/completed-donations', builder: (context, state) => const CompletedDonationsScreen()),
    GoRoute(path: '/donor-profile', builder: (context, state) => const DonorProfileScreen()),
    GoRoute(path: '/donor-settings', builder: (context, state) => const DonorSettingsScreen()),
    GoRoute(path: '/donation-history', builder: (context, state) => const DonationHistoryScreen()),
    GoRoute(path: '/edit-donation', builder: (context, state) => EditDonationScreen(donation: state.extra as Donation)),
    GoRoute(path: '/donation-details', builder: (context, state) => DonationDetailsScreen(donation: state.extra as Donation)),
    
    // Camera Routes
    GoRoute(path: '/camera', builder: (context, state) => const CameraScreen()),
    GoRoute(path: '/analyze', builder: (context, state) => AiAnalyzingScreen(imagePath: state.extra as String?)),
    GoRoute(path: '/donation-form', builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return DonationFormScreen(imagePath: extra?['imagePath'] as String?, analysisText: extra?['analysisText'] as String?);
    }),
    
    // NGO Routes
    GoRoute(path: '/ngo-dashboard', builder: (context, state) => const NgoDashboardScreen()),
    GoRoute(path: '/ngo-profile', builder: (context, state) => const NgoProfileScreen()),
    GoRoute(path: '/ngo-settings', builder: (context, state) => const NgoSettingsScreen()),
    GoRoute(path: '/ngo-statistics', builder: (context, state) => const NgoStatisticsScreen()),
    
    // Volunteer Routes
    GoRoute(path: '/volunteer-dashboard', builder: (context, state) => const VolunteerDashboardScreen()),
    GoRoute(path: '/qr-scan', builder: (context, state) => const QrScanScreen()),
    GoRoute(path: '/volunteer-history', builder: (context, state) => const VolunteerHistoryScreen()),
    GoRoute(path: '/volunteer-profile', builder: (context, state) => const VolunteerProfileScreen()),
    GoRoute(path: '/volunteer-settings', builder: (context, state) => const VolunteerSettingsScreen()),
    GoRoute(path: '/pickup-details', builder: (context, state) => PickupDetailsScreen(pickup: state.extra as Pickup)),
    GoRoute(path: '/delivery-tracking', builder: (context, state) => DeliveryTrackingScreen(pickup: state.extra as Pickup)),
    GoRoute(path: '/delivery-completed', builder: (context, state) => DeliveryCompletedScreen(pickup: state.extra as Pickup)),

    // Missing Sub-screens (Inlined here to avoid creating new directories)
    GoRoute(path: '/edit-profile', builder: (context, state) => const Scaffold(body: Center(child: Text("Edit Profile Screen")))),
    GoRoute(path: '/help-support', builder: (context, state) => const Scaffold(body: Center(child: Text("Help & Support Screen")))),
    GoRoute(path: '/privacy-policy', builder: (context, state) => const Scaffold(body: Center(child: Text("Privacy Policy")))),
    GoRoute(path: '/terms-conditions', builder: (context, state) => const Scaffold(body: Center(child: Text("Terms & Conditions")))),
    GoRoute(path: '/about', builder: (context, state) => const Scaffold(body: Center(child: Text("About Us")))),
  ],
);