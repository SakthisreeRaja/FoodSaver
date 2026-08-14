import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/primary_button.dart';
import 'firebase_auth_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  int? _selectedIndex;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _roles = [
    {"title": "Donor", "desc": "I want to donate excess food", "icon": Icons.restaurant},
    {"title": "NGO", "desc": "I want to receive and distribute", "icon": Icons.business},
    {"title": "Delivery Partner", "desc": "I deliver food donations", "icon": Icons.delivery_dining},
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
              text: _isSaving ? "Saving..." : "Continue",
              enabled: _selectedIndex != null,
              isLoading: _isSaving,
              onPressed: _handleContinue,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    final selectedIndex = _selectedIndex;
    if (selectedIndex == null) return;

    // Map display title to Firestore role key
    final title = (_roles[selectedIndex]['title'] as String);
    final role = title == 'Delivery Partner' ? 'delivery_partner' : title.toLowerCase();
    setState(() => _isSaving = true);

    try {
      await FirebaseAuthService.updateCurrentUserRole(role);

      if (!mounted) return;
      switch (role) {
        case 'donor':
          context.go('/donor-dashboard');
          break;
        case 'ngo':
          context.go('/ngo-dashboard');
          break;
        case 'delivery_partner':
          context.go('/dp-dashboard');
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
