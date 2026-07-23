import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  Future<String> analyzeFood(Uint8List imageBytes) async {
    try {
      // Pulls the key securely from your .env file
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      
      if (apiKey.isEmpty) {
        return 'AI Analysis Failed: API Key is missing from .env file.';
      }

      // Updated the model name string here to satisfy the API
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