import 'package:flutter/material.dart';
import 'donor_dashboard_screen.dart';
// We will build the history screen later, using a placeholder for now
import 'package:go_router/go_router.dart';

class DonorMainScreen extends StatefulWidget {
  const DonorMainScreen({super.key});

  @override
  State<DonorMainScreen> createState() => _DonorMainScreenState();
}

class _DonorMainScreenState extends State<DonorMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    DonorDashboardScreen(onViewAllPressed: () => setState(() => _currentIndex = 1)),
    const Center(child: Text("Donation History (Coming Soon)")), // Placeholder
    const Center(child: Text("Profile (Coming Soon)")), // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-donation'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Donate"),
      ),
    );
  }
}