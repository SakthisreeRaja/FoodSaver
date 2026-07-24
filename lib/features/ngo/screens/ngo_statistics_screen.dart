import 'package:flutter/material.dart';
import 'package:foodsaver/core/components/statistic_card.dart';
import 'package:google_fonts/google_fonts.dart';

class NgoStatisticsScreen extends StatelessWidget {
  const NgoStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Overall Performance",
              style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                StatisticCard(
                  title: 'Total Donations',
                  value: '152',
                  icon: Icons.check_circle_outline,
                  color: Colors.blue,
                ),
                StatisticCard(
                  title: 'Meals Served',
                  value: '4,560',
                  icon: Icons.restaurant_menu,
                  color: Colors.green,
                ),
                StatisticCard(
                  title: 'Active Volunteers',
                  value: '12',
                  icon: Icons.people,
                  color: Colors.orange,
                ),
                StatisticCard(
                  title: 'Community Rating',
                  value: '4.8/5',
                  icon: Icons.star,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "Donations by Category (Placeholder)",
              style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Placeholder for a chart
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Chart will be displayed here",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
