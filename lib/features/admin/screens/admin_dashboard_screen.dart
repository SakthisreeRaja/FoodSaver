import 'package:flutter/material.dart';
import 'package:foodsaver/core/components/statistic_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDashboardItem(
                  context,
                  title: 'Manage Users',
                  icon: Icons.people,
                  onTap: () => context.push('/admin-manage-users'),
                ),
                _buildDashboardItem(
                  context,
                  title: 'Manage NGOs',
                  icon: Icons.business,
                  onTap: () => context.push('/admin-manage-ngos'),
                ),
                _buildDashboardItem(
                  context,
                  title: 'Manage Volunteers',
                  icon: Icons.person_pin,
                  onTap: () => context.push('/admin-manage-volunteers'),
                ),
                _buildDashboardItem(
                  context,
                  title: 'Manage Donations',
                  icon: Icons.card_giftcard,
                  onTap: () => context.push('/admin-manage-donations'),
                ),
                _buildDashboardItem(
                  context,
                  title: 'Reports',
                  icon: Icons.bar_chart,
                  onTap: () => context.push('/admin-reports'),
                ),
                _buildDashboardItem(
                  context,
                  title: 'Analytics',
                  icon: Icons.pie_chart,
                  onTap: () => context.push('/admin-analytics'),
                ),
                _buildDashboardItem(
                  context,
                  title: 'Settings',
                  icon: Icons.settings,
                  onTap: () => context.push('/admin-settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
