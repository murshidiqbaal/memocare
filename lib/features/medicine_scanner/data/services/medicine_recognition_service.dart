import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/medicine_model.dart';

/// Service that sends medicine images to Gemini Vision API and parses results.
///
/// Add your key to your .env / app config and inject via constructor.
class MedicineRecognitionService {
  MedicineRecognitionService({required String geminiApiKey})
      : _apiKey = geminiApiKey;

  final String _apiKey;

  // ── Cooldown & Protection ──────────────────────────────────────────────────
  static DateTime? _lastGeminiCall;
  static const _cooldown = Duration(seconds: 5);
  static const _maxRetries = 2;
  static const _retryDelay = Duration(seconds: 7);

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1/models/'
      'gemini-2.0-flash:generateContent';

  static const String _systemPrompt = '''
You are a medical assistant specialized in identifying medicines from photos.
Analyze the provided image and extract ALL visible medicine information.

Respond ONLY with a valid JSON object (no markdown, no explanation) in this exact structure:
{
  "name": "Full medicine name as printed on the label",
  "dosage": "Exact dosage e.g. 500mg, 10mg/5ml",
  "activeIngredient": "Main active ingredient if visible",
  "manufacturer": "Manufacturer name if visible",
  "instructions": "Short usage instructions if visible e.g. Take 1 tablet twice daily",
  "warnings": ["Warning 1 if visible", "Warning 2 if visible"],
  "confidence": "high | medium | low",
  "isRecognized": true or false
}

Rules:
- If you cannot read the label clearly, set isRecognized to false and confidence to "low"
- Keep all text SHORT and SIMPLE (patient may have dementia)
- If a field is not visible on the label, use an empty string ""
- warnings should be a JSON array of strings
''';

  /// Analyzes a medicine image and returns structured [MedicineInfo].
  Future<MedicineInfo> recognizeMedicine(File imageFile) async {
    // 1. Cooldown Guard
    final now = DateTime.now();
    if (_lastGeminiCall != null &&
        now.difference(_lastGeminiCall!) < _cooldown) {
      final wait = _cooldown - now.difference(_lastGeminiCall!);
      throw MedicineRecognitionException(
        "Please wait ${wait.inSeconds + 1}s before scanning again",
      );
    }
    _lastGeminiCall = now;

    int retryCount = 0;

    while (true) {
      try {
        // 2. Offload heavy image processing (Base64 + File Read) to background isolate
        final base64Image = await compute(_readAndEncodeImage, imageFile.path);
        final mimeType = _getMimeType(imageFile.path);

        final requestBody = {
          'contents': [
            {
              'parts': [
                {'text': _systemPrompt},
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Image,
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.1,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 1024,
          },
        };

        final response = await http.post(
          Uri.parse('$_baseUrl?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        // 3. Quota Exceeded (429) Handling
        if (response.statusCode == 429) {
          if (retryCount < _maxRetries) {
            retryCount++;
            debugPrint(
              'Gemini Quota Exceeded. Retrying in ${_retryDelay.inSeconds}s (Attempt $retryCount/$_maxRetries)...',
            );
            await Future.delayed(_retryDelay);
            continue;
          }
          throw MedicineRecognitionException(
            'Daily scan limit reached. Please try again tomorrow.',
          );
        }

        if (response.statusCode != 200) {
          debugPrint(
              'Gemini API error ${response.statusCode}: ${response.body}');
          throw MedicineRecognitionException(
            'API request failed with status ${response.statusCode}',
          );
        }

        // 4. Offload JSON parsing to background isolate
        return await compute(_parseGeminiResponseStatic, response.body);
      } on MedicineRecognitionException {
        rethrow;
      } catch (e) {
        debugPrint('Medicine recognition error: $e');
        if (e is SocketException || e is http.ClientException) {
          throw MedicineRecognitionException('Network error. Check connection');
        }
        throw MedicineRecognitionException('Failed to analyze image: $e');
      }
    }
  }

  // ── Compute Helpers ────────────────────────────────────────────────────────

  static Future<String> _readAndEncodeImage(String path) async {
    final bytes = await File(path).readAsBytes();
    return base64Encode(bytes);
  }

  static MedicineInfo _parseGeminiResponseStatic(String body) {
    // Note: Can't call instance method _parseGeminiResponse from static compute
    // So we redirect logic.
    return MedicineRecognitionService(geminiApiKey: '')
        ._parseGeminiResponse(body);
  }

  MedicineInfo _parseGeminiResponse(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

      final candidates = decoded['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return MedicineInfo.unrecognized();
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        return MedicineInfo.unrecognized();
      }

      final rawText = (parts[0]['text'] as String? ?? '').trim();
      debugPrint('Gemini raw response: $rawText');

      // Strip any accidental markdown fences
      final cleanJson = rawText
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      final medicineJson = jsonDecode(cleanJson) as Map<String, dynamic>;

      return MedicineInfo(
        name: medicineJson['name'] as String? ?? 'Unknown',
        dosage: medicineJson['dosage'] as String? ?? 'Not detected',
        activeIngredient: medicineJson['activeIngredient'] as String? ?? '',
        manufacturer: medicineJson['manufacturer'] as String? ?? '',
        instructions: medicineJson['instructions'] as String? ?? '',
        warnings: (medicineJson['warnings'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        confidence: _parseConfidence(
          medicineJson['confidence'] as String? ?? 'low',
        ),
        isRecognized: medicineJson['isRecognized'] as bool? ?? false,
        // rawGeminiResponse: rawText,
      );
    } catch (e) {
      debugPrint('Failed to parse Gemini response: $e\nBody: $responseBody');
      return MedicineInfo.unrecognized();
    }
  }

  RecognitionConfidence _parseConfidence(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return RecognitionConfidence.high;
      case 'medium':
        return RecognitionConfidence.medium;
      default:
        return RecognitionConfidence.low;
    }
  }

  String _getMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

class MedicineRecognitionException implements Exception {
  MedicineRecognitionException(this.message);
  final String message;

  @override
  String toString() => 'MedicineRecognitionException: $message';
}
