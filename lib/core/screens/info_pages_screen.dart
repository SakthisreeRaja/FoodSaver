import 'package:flutter/material.dart';

class InfoPagesScreen extends StatelessWidget {
  final String page; // 'privacy' | 'terms' | 'about'
  const InfoPagesScreen({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final config = _config(page);
    return Scaffold(
      appBar: AppBar(title: Text(config['title'] as String), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (page == 'about') _buildAbout(context),
            if (page != 'about') _buildTextPage(config),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAbout(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF1B5E20)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Text('🌱', style: TextStyle(fontSize: 48)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text('FoodSaver',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ),
        const Center(
          child: Text('Version 1.0.0',
              style: TextStyle(color: Colors.grey)),
        ),
        const SizedBox(height: 24),
        _section('Our Mission',
            'FoodSaver connects food donors with NGOs and volunteers to reduce food waste and feed communities in need. Every donation counts — together we can make a difference.'),
        _section('How It Works',
            '1. 📸 Donors take a photo of surplus food\n2. 🤖 AI analyzes and categorizes it instantly\n3. 🏢 NGOs discover and claim donations on the map\n4. 🚴 Volunteers pick up and deliver to NGOs\n5. ❤️ Communities benefit from zero-waste food rescue'),
        _section('Technology',
            '• Flutter for cross-platform mobile\n• Firebase for real-time data sync\n• AI-powered food analysis\n• OpenStreetMap for location services'),
        _section('Contact',
            'Email: contact@foodsaver.app\nWebsite: www.foodsaver.app\nPhone: +91 1800-FOOD-SAVE'),
      ],
    );
  }

  Widget _buildTextPage(Map<String, dynamic> config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(config['title'] as String,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(config['lastUpdated'] as String,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 20),
        ...(config['sections'] as List<Map<String, String>>)
            .map((s) => _section(s['title']!, s['body']!)),
      ],
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(height: 1.6, color: Colors.black87)),
        ],
      ),
    );
  }

  Map<String, dynamic> _config(String p) {
    if (p == 'privacy') {
      return {
        'title': 'Privacy Policy',
        'lastUpdated': 'Last updated: August 2026',
        'sections': [
          {
            'title': '1. Information We Collect',
            'body':
                'We collect your name, email, and role during registration. We store donation details including food type, quantity, and pickup location coordinates. We do not collect unnecessary personal information.',
          },
          {
            'title': '2. How We Use Your Data',
            'body':
                'Your data is used solely to operate the FoodSaver platform — connecting donors, NGOs, and volunteers. We use Firebase Analytics for app improvement. We never sell your data.',
          },
          {
            'title': '3. Data Storage',
            'body':
                'All data is stored securely in Google Firebase with end-to-end encryption. Location data is only stored when you create a donation and is used only for pickup coordination.',
          },
          {
            'title': '4. Data Deletion',
            'body':
                'You can delete your account at any time via Settings → Delete Account. This permanently removes all your data from our servers within 30 days.',
          },
          {
            'title': '5. Contact',
            'body': 'For privacy concerns: privacy@foodsaver.app',
          },
        ],
      };
    } else {
      return {
        'title': 'Terms & Conditions',
        'lastUpdated': 'Last updated: August 2026',
        'sections': [
          {
            'title': '1. Acceptance',
            'body':
                'By using FoodSaver, you agree to these terms. If you do not agree, please do not use the app.',
          },
          {
            'title': '2. Donor Responsibilities',
            'body':
                'Donors must only list food that is safe for consumption. Intentionally listing spoiled or unsafe food is strictly prohibited and may result in account termination.',
          },
          {
            'title': '3. NGO Responsibilities',
            'body':
                'NGOs must be legitimate registered organizations. You are responsible for proper storage and distribution of claimed donations.',
          },
          {
            'title': '4. Volunteer Responsibilities',
            'body':
                'Volunteers must handle food with care, maintain hygiene, and deliver within agreed timelines. Repeated failures may result in account restrictions.',
          },
          {
            'title': '5. Limitation of Liability',
            'body':
                'FoodSaver is a platform connecting parties. We are not liable for food quality beyond what AI analysis detects. All parties operate in good faith.',
          },
          {
            'title': '6. Changes to Terms',
            'body':
                'We may update these terms periodically. Continued use of the app constitutes acceptance of updated terms.',
          },
        ],
      };
    }
  }
}
