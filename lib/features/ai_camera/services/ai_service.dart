import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Structured result from AI food image analysis.
class FoodAnalysisResult {
  final String foodType;
  final String category;
  final int estimatedQuantity;
  final String unit;
  final bool safeToEat;
  final String notes;
  final String rawText;

  const FoodAnalysisResult({
    required this.foodType,
    required this.category,
    required this.estimatedQuantity,
    required this.unit,
    required this.safeToEat,
    required this.notes,
    required this.rawText,
  });

  /// Parse from the JSON that the AI model returns.
  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisResult(
      foodType: (json['foodType'] as String?) ?? 'Mixed Food',
      category: (json['category'] as String?) ?? 'other',
      estimatedQuantity:
          (json['estimatedQuantity'] as num?)?.toInt() ?? 1,
      unit: (json['unit'] as String?) ?? 'kg',
      safeToEat: (json['safeToEat'] as bool?) ?? true,
      notes: (json['notes'] as String?) ?? '',
      rawText: '',
    );
  }

  /// Fallback when JSON parsing fails — fill what we can from raw text.
  factory FoodAnalysisResult.fromRawText(String raw) {
    return FoodAnalysisResult(
      foodType: 'Food Donation',
      category: 'other',
      estimatedQuantity: 1,
      unit: 'kg',
      safeToEat: !raw.toLowerCase().contains('spoil') &&
          !raw.toLowerCase().contains('mold') &&
          !raw.toLowerCase().contains('rotten'),
      notes: raw,
      rawText: raw,
    );
  }

  bool get hasError => rawText.startsWith('AI Analysis Failed');
}

class AiService {
  /// Reads the image at [imagePath] and returns a [FoodAnalysisResult].
  /// Never throws — on any error, returns a safe fallback result.
  static Future<FoodAnalysisResult> analyzeFoodImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      return _analyzeBytes(bytes);
    } catch (e) {
      return FoodAnalysisResult.fromRawText(
          'AI Analysis Failed: could not read the captured image ($e)');
    }
  }

  /// Same as [analyzeFoodImage] but accepts raw bytes.
  static Future<FoodAnalysisResult> analyzeFoodBytes(Uint8List imageBytes) =>
      _analyzeBytes(imageBytes);

  static Future<FoodAnalysisResult> _analyzeBytes(Uint8List imageBytes) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      if (apiKey.isEmpty) {
        return FoodAnalysisResult.fromRawText(
            'AI Analysis Failed: AI API key is missing from .env file.');
      }

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      final prompt = TextPart(
        'You are an AI assistant for a food donation app. '
        'Analyze this food image and respond ONLY with a valid JSON object '
        '(no markdown, no code fences, no extra text) with these exact keys:\n'
        '{\n'
        '  "foodType": "short name of the food (e.g. Rice, Mixed Curry, Bread)",\n'
        '  "category": "one of: Vegetables, Fruits, Grains, Dairy, Meat, Bakery, Processed, other",\n'
        '  "estimatedQuantity": <integer number>,\n'
        '  "unit": "one of: kg, g, litres, pieces, portions, servings",\n'
        '  "safeToEat": <true or false>,\n'
        '  "notes": "one-sentence quality note or pickup instruction"\n'
        '}',
      );

      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final text = response.text ?? '';
      return _parseJsonResponse(text);
    } catch (e) {
      return FoodAnalysisResult.fromRawText('AI Analysis Failed: $e');
    }
  }

  static FoodAnalysisResult _parseJsonResponse(String text) {
    try {
      // Strip any accidental markdown fences the AI model might add
      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) {
        return FoodAnalysisResult.fromRawText(text);
      }

      final jsonStr = cleaned.substring(jsonStart, jsonEnd + 1);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return FoodAnalysisResult.fromJson(map);
    } catch (_) {
      return FoodAnalysisResult.fromRawText(text);
    }
  }
}
