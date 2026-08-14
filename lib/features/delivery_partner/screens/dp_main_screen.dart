import 'package:flutter/material.dart';
import 'dp_dashboard_screen.dart';
import 'dp_map_screen.dart';
import 'dp_history_screen.dart';
import 'dp_profile_screen.dart';

class DPMainScreen extends StatefulWidget {
  const DPMainScreen({super.key});

  @override
  State<DPMainScreen> createState() => _DPMainScreenState();
}

class _DPMainScreenState extends State<DPMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DPDashboardScreen(),
    DPMapScreen(),
    DPHistoryScreen(),
    DPProfileScreen(),
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
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor:
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.delivery_dining_outlined),
            selectedIcon: Icon(Icons.delivery_dining),
            label: 'Jobs',
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
    );
  }
}
