import 'package:flutter/material.dart';
import 'ngo_dashboard_screen.dart';
import 'ngo_statistics_screen.dart';
import 'ngo_profile_screen.dart';
import 'ngo_map_screen.dart';

class NgoMainScreen extends StatefulWidget {
  const NgoMainScreen({super.key});

  @override
  State<NgoMainScreen> createState() => _NgoMainScreenState();
}

class _NgoMainScreenState extends State<NgoMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    NgoDashboardScreen(),
    NgoMapScreen(),        // Role-specific map for NGO
    NgoStatisticsScreen(),
    NgoProfileScreen(),
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
        indicatorColor:
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
