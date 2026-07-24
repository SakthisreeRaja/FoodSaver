import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  /// Reads the image at [imagePath] and sends it to Gemini for analysis.
  /// Returns a human-readable summary, or a friendly error message if
  /// the key is missing or the request fails (never throws).
  static Future<String> analyzeFoodImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      return _analyzeBytes(bytes);
    } catch (e) {
      return 'AI Analysis Failed: could not read the captured image ($e)';
    }
  }

  /// Same as [analyzeFoodImage] but takes raw bytes directly (e.g. if you
  /// already have the image in memory and don't want to re-read the file).
  static Future<String> analyzeFoodBytes(Uint8List imageBytes) => _analyzeBytes(imageBytes);

  static Future<String> _analyzeBytes(Uint8List imageBytes) async {
    try {
      // Pulls the key securely from your .env file
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      if (apiKey.isEmpty) {
        return 'AI Analysis Failed: API Key is missing from .env file.';
      }

      final model = GenerativeModel(
        model: 'gemini-3.5-flash',
        apiKey: apiKey,
      );

      final prompt = TextPart(
        'You are an AI assistant for a food donation app. Analyze this image. '
        '1. Identify the food items. '
        '2. Estimate the quantity (e.g., roughly how many meals or people it can feed). '
        '3. Check for any visible signs of spoilage. '
        'Keep the response concise and formatted with bullet points.'
      );

      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      return response.text ?? 'Could not analyze the image.';
    } catch (e) {
      return 'AI Analysis Failed: $e';
    }
  }
}
