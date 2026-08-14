import 'package:go_router/go_router.dart';

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
import '../../features/donor/screens/donor_notifications_screen.dart';

// AI Camera
import '../../features/ai_camera/screens/ai_analyzing_screen.dart';
import '../../features/ai_camera/screens/camera_screen.dart';
import '../../features/ai_camera/screens/donation_form_screen.dart';
import '../../features/ai_camera/services/ai_service.dart';

// NGO
import '../../features/ngo/screens/ngo_main_screen.dart';
import '../../features/ngo/screens/ngo_dashboard_screen.dart';
import '../../features/ngo/screens/ngo_profile_screen.dart';
import '../../features/ngo/screens/ngo_settings_screen.dart';
import '../../features/ngo/screens/ngo_statistics_screen.dart';

// Delivery Partner (replaces Volunteer)
import '../../features/delivery_partner/screens/dp_main_screen.dart';
import '../../features/delivery_partner/screens/dp_dashboard_screen.dart';
import '../../features/delivery_partner/screens/dp_delivery_screen.dart';
import '../../features/delivery_partner/screens/dp_history_screen.dart';
import '../../features/delivery_partner/screens/dp_map_screen.dart';
import '../../features/delivery_partner/screens/dp_profile_screen.dart';

// Keep volunteer screens (backward compat — old accounts)
import '../../features/volunteer/screens/volunteer_main_screen.dart';
import '../../features/volunteer/screens/volunteer_settings_screen.dart';

// Core / Utility
import '../screens/app_settings_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/info_pages_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // ── Onboarding ────────────────────────────────────────────────────────
    GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen()),
    GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen()),

    // ── Auth ─────────────────────────────────────────────────────────────
    GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen()),
    GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen()),
    GoRoute(
        path: '/otp-verification',
        builder: (context, state) => const OtpVerificationScreen()),
    GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen()),
    GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen()),

    // ── Donor ─────────────────────────────────────────────────────────────
    GoRoute(
        path: '/donor-dashboard',
        builder: (context, state) => const DonorMainScreen()),
    GoRoute(
        path: '/create-donation',
        builder: (context, state) => const CreateDonationScreen()),
    GoRoute(
        path: '/active-donations',
        builder: (context, state) => const ActiveDonationsScreen()),
    GoRoute(
        path: '/completed-donations',
        builder: (context, state) => const CompletedDonationsScreen()),
    GoRoute(
        path: '/donor-profile',
        builder: (context, state) => const DonorProfileScreen()),
    GoRoute(
        path: '/donor-settings',
        builder: (context, state) => const DonorSettingsScreen()),
    GoRoute(
        path: '/donation-history',
        builder: (context, state) => const DonationHistoryScreen()),
    GoRoute(
        path: '/donor-notifications',
        builder: (context, state) => const DonorNotificationsScreen()),
    GoRoute(
      path: '/edit-donation',
      builder: (context, state) => EditDonationScreen(
        donation: state.extra as Map<String, dynamic>,
      ),
    ),
    GoRoute(
      path: '/donation-details',
      builder: (context, state) => DonationDetailsScreen(
        donation: state.extra as Map<String, dynamic>,
      ),
    ),

    // ── AI Camera ─────────────────────────────────────────────────────────
    GoRoute(
        path: '/camera',
        builder: (context, state) => const CameraScreen()),
    GoRoute(
      path: '/analyze',
      builder: (context, state) =>
          AiAnalyzingScreen(imagePath: state.extra as String?),
    ),
    GoRoute(
      path: '/donation-form',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return DonationFormScreen(
          imagePath: extra?['imagePath'] as String?,
          analysisResult: extra?['analysisResult'] as FoodAnalysisResult?,
          analysisText: extra?['analysisText'] as String?,
        );
      },
    ),

    // ── NGO ───────────────────────────────────────────────────────────────
    GoRoute(
        path: '/ngo-dashboard',
        builder: (context, state) => const NgoMainScreen()),
    GoRoute(
        path: '/ngo-dashboard-inner',
        builder: (context, state) => const NgoDashboardScreen()),
    GoRoute(
        path: '/ngo-profile',
        builder: (context, state) => const NgoProfileScreen()),
    GoRoute(
        path: '/ngo-settings',
        builder: (context, state) => const NgoSettingsScreen()),
    GoRoute(
        path: '/ngo-statistics',
        builder: (context, state) => const NgoStatisticsScreen()),

    // ── Delivery Partner (primary) ─────────────────────────────────────────
    GoRoute(
        path: '/dp-dashboard',
        builder: (context, state) => const DPMainScreen()),
    GoRoute(
        path: '/dp-dashboard-inner',
        builder: (context, state) => const DPDashboardScreen()),
    GoRoute(
        path: '/dp-map',
        builder: (context, state) => const DPMapScreen()),
    GoRoute(
        path: '/dp-history-full',
        builder: (context, state) => const DPHistoryScreen()),
    GoRoute(
        path: '/dp-profile',
        builder: (context, state) => const DPProfileScreen()),
    GoRoute(
        path: '/dp-settings',
        builder: (context, state) =>
            const AppSettingsScreen(role: 'delivery_partner')),
    GoRoute(
      path: '/dp-delivery',
      builder: (context, state) => DPDeliveryScreen(
        jobData: state.extra as Map<String, dynamic>,
      ),
    ),

    // ── Volunteer (kept for backward compat — old accounts with role=volunteer) ──
    GoRoute(
        path: '/volunteer-dashboard',
        builder: (context, state) => const VolunteerMainScreen()),
    GoRoute(
        path: '/volunteer-settings',
        builder: (context, state) => const VolunteerSettingsScreen()),

    // ── Utility routes ────────────────────────────────────────────────────
    GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen()),
    GoRoute(
        path: '/app-settings',
        builder: (context, state) => const AppSettingsScreen()),
    GoRoute(
        path: '/help-support',
        builder: (context, state) => const HelpSupportScreen()),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) =>
          const InfoPagesScreen(page: 'privacy'),
    ),
    GoRoute(
      path: '/terms-conditions',
      builder: (context, state) =>
          const InfoPagesScreen(page: 'terms'),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) =>
          const InfoPagesScreen(page: 'about'),
    ),
  ],
);