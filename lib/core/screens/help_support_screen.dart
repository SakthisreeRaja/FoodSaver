import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                const Text('Search help topics...',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _faq('How do I donate food?',
              'Tap the camera/donate button on your dashboard. Take a photo of your food — our AI will analyze it automatically. Review the pre-filled form and tap "Confirm & Donate".'),
          _faq('How does the AI food analysis work?',
              'Our AI-powered scanner analyzes your food photo to identify type, quantity, and freshness. Results pre-fill your donation form so you don\'t have to type everything manually.'),
          _faq('How do NGOs claim donations?',
              'NGOs see available donations on their dashboard map. They can tap any green marker and press "Claim This Donation" to reserve it.'),
          _faq('How are volunteers assigned to pickups?',
              'After an NGO claims a donation, it creates a pending pickup. Volunteers see these on their dashboard and map — they tap "Accept Pickup" to take it.'),
          _faq('Is my location data stored?',
              'Your GPS coordinates are only stored with your donations to help NGOs and volunteers find pickup locations. They are never sold or shared with third parties.'),
          _faq('What food types can I donate?',
              'You can donate vegetables, fruits, grains, dairy, bakery items, and more. The AI helps categorize them correctly. Please do not donate food that is visibly spoiled.'),
          _faq('How do I change my role (Donor/NGO/Volunteer)?',
              'Your role is set at registration. To change it, please contact support below.'),

          const SizedBox(height: 24),
          const Text('Contact Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _contactTile(Icons.email_outlined, 'Email Support',
              'support@foodsaver.app', Colors.blue),
          _contactTile(Icons.chat_bubble_outline, 'Live Chat',
              'Available 9 AM – 6 PM', Colors.green),
          _contactTile(Icons.phone_outlined, 'Phone',
              '+91 1800-FOOD-SAVE', Colors.orange),

          const SizedBox(height: 24),
          Center(
            child: Text('FoodSaver v1.0.0 — Making a difference together 🌱',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _faq(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4)],
      ),
      child: ExpansionTile(
        title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Text(a,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _contactTile(
      IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4)],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade300),
      ),
    );
  }
}
