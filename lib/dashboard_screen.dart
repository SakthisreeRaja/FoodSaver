import 'package:flutter/material.dart';
import 'home_screen.dart'; // Your camera screen
import 'feed_screen.dart'; // The new receiver screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(), // Index 0: Receiver view
    const HomeScreen(), // Index 1: Donor view (Camera)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: 'Find Food',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt),
            label: 'Donate',
          ),
        ],  
      ),
    );
  }
}