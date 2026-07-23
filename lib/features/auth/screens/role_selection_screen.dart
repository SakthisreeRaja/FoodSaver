import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/primary_button.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  int? _selectedIndex;

  final List<Map<String, dynamic>> _roles = [
    {"title": "Donor", "desc": "I want to donate excess food", "icon": Icons.restaurant},
    {"title": "NGO", "desc": "I want to receive and distribute", "icon": Icons.business},
    {"title": "Volunteer", "desc": "I want to help with deliveries", "icon": Icons.directions_bike},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Your Role")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _roles.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(_roles[index]['icon'], size: 40, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade500),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_roles[index]['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(_roles[index]['desc'], style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            PrimaryButton(
              text: "Continue",
              onPressed: _selectedIndex == null 
                  ? () {} // Disabled state logic can be added here
                  : () {
                      if (_selectedIndex == 0) context.go('/donor-dashboard');
                      // Add NGO and Volunteer routes later
                    },
            ),
          ],
        ),
      ),
    );
  }
}