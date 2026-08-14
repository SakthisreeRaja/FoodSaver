import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'donor_dashboard_screen.dart';
import 'donation_history_screen.dart';
import 'donor_profile_screen.dart';
import 'donation_map_screen.dart';

class DonorMainScreen extends StatefulWidget {
  const DonorMainScreen({super.key});

  @override
  State<DonorMainScreen> createState() => _DonorMainScreenState();
}

class _DonorMainScreenState extends State<DonorMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    DonorDashboardScreen(
      onViewAllPressed: () => setState(() => _currentIndex = 2),
    ),
    const DonationMapScreen(),
    const DonationHistoryScreen(),
    const DonorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/create-donation'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Donate'),
            )
          : null,
    );
  }
}