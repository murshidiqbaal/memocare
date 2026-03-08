import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech service for speaking responses to patients
/// Provides calm, clear voice output optimized for dementia patients
class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  /// Initialize TTS with dementia-friendly settings
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Set language
      await _tts.setLanguage('en-US');

      // Slower speech rate for better comprehension
      await _tts.setSpeechRate(0.4); // 0.0 (slow) to 1.0 (fast)

      // Moderate pitch for calm, friendly tone
      await _tts.setPitch(1.0); // 0.5 to 2.0

      // Set volume
      await _tts.setVolume(0.8); // 0.0 to 1.0

      _isInitialized = true;
      print('TTS Service initialized successfully');
    } catch (e) {
      print('TTS initialization error: $e');
    }
  }

  /// Speak the given text
  /// Returns true if speech started successfully
  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      // Stop any ongoing speech
      await stop();

      // Speak the text
      final result = await _tts.speak(text);
      return result == 1; // 1 means success
    } catch (e) {
      print('TTS speak error: $e');
      return false;
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      print('TTS stop error: $e');
    }
  }

  /// Check if currently speaking
  Future<bool> isSpeaking() async {
    try {
      // Note: This might not be available in all platforms
      return false; // Fallback
    } catch (e) {
      return false;
    }
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
    } catch (e) {
      print('TTS setSpeechRate error: $e');
    }
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    try {
      await _tts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (e) {
      print('TTS setPitch error: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _tts.stop();
  }
}
