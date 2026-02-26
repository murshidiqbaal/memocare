import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../data/models/voice_query.dart';
import '../../../../data/repositories/voice_assistant_repository.dart';
import '../../../../services/llm_memory_query_engine.dart';
import '../../../../services/tts_service.dart';

/// Voice assistant state
class VoiceAssistantState {
  final bool isListening;
  final bool isProcessing;
  final bool isSpeaking;
  final String currentTranscript;
  final String? lastResponse;
  final List<VoiceQuery> queryHistory;
  final String? error;

  VoiceAssistantState({
    this.isListening = false,
    this.isProcessing = false,
    this.isSpeaking = false,
    this.currentTranscript = '',
    this.lastResponse,
    this.queryHistory = const [],
    this.error,
  });

  VoiceAssistantState copyWith({
    bool? isListening,
    bool? isProcessing,
    bool? isSpeaking,
    String? currentTranscript,
    String? lastResponse,
    List<VoiceQuery>? queryHistory,
    String? error,
  }) {
    return VoiceAssistantState(
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      currentTranscript: currentTranscript ?? this.currentTranscript,
      lastResponse: lastResponse ?? this.lastResponse,
      queryHistory: queryHistory ?? this.queryHistory,
      error: error,
    );
  }
}

/// Voice Assistant ViewModel
/// Manages speech recognition, memory queries, and TTS
class VoiceAssistantViewModel extends StateNotifier<VoiceAssistantState> {
  final VoiceAssistantRepository _repository;
  final TTSService _ttsService;
  final LLMMemoryQueryEngine _queryEngine;
  final String patientId;

  late stt.SpeechToText _speech;
  bool _speechInitialized = false;

  VoiceAssistantViewModel(
    this._repository,
    this._ttsService,
    this._queryEngine,
    this.patientId,
  ) : super(VoiceAssistantState()) {
    _initServices();
  }

  /// Initialize speech recognition and TTS
  Future<void> _initServices() async {
    try {
      // Initialize TTS
      await _ttsService.init();

      // Initialize Speech Recognition
      _speech = stt.SpeechToText();
      _speechInitialized = await _speech.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          state = state.copyWith(
            isListening: false,
            error: 'Could not understand. Please try again.',
          );
        },
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            state = state.copyWith(isListening: false);
          }
        },
      );

      // Load query history
      await _loadHistory();
    } catch (e) {
      print('Voice assistant init error: $e');
      state = state.copyWith(error: 'Could not start voice assistant');
    }
  }

  /// Load query history from repository
  Future<void> _loadHistory() async {
    try {
      final history = await _repository.getQueries(patientId);
      state = state.copyWith(queryHistory: history);
    } catch (e) {
      print('Load history error: $e');
    }
  }

  /// Start listening to patient's voice
  Future<void> startListening() async {
    if (!_speechInitialized) {
      state = state.copyWith(error: 'Voice assistant not ready. Please wait.');
      return;
    }

    if (state.isListening) return;

    // Stop any ongoing speech
    await _ttsService.stop();

    state = state.copyWith(
      isListening: true,
      currentTranscript: '',
      error: null,
      isSpeaking: false,
    );

    try {
      await _speech.listen(
        onResult: (result) {
          state = state.copyWith(
            currentTranscript: result.recognizedWords,
          );

          // If speech is finalized, process the query
          if (result.finalResult) {
            processQuery(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      );
    } catch (e) {
      print('Start listening error: $e');
      state = state.copyWith(
        isListening: false,
        error: 'Could not start listening. Please try again.',
      );
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!state.isListening) return;

    await _speech.stop();
    state = state.copyWith(isListening: false);

    // Process the query if we have transcript
    if (state.currentTranscript.isNotEmpty) {
      await processQuery(state.currentTranscript);
    }
  }

  /// Process the patient's query
  Future<void> processQuery(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        isListening: false,
        error: 'I didn\'t hear anything. Please try again.',
      );
      return;
    }

    state = state.copyWith(
      isListening: false,
      isProcessing: true,
      error: null,
    );

    try {
      // Generate response using memory query engine
      final response = await _queryEngine.processQuery(query, patientId);

      // Save to repository
      final voiceQuery = VoiceQuery(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: patientId,
        queryText: query,
        responseText: response,
        createdAt: DateTime.now(),
      );

      await _repository.addQuery(voiceQuery);

      // Update state
      state = state.copyWith(
        isProcessing: false,
        lastResponse: response,
        queryHistory: [voiceQuery, ...state.queryHistory],
      );

      // Speak the response
      await speakResponse(response);
    } catch (e) {
      print('Process query error: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'I had trouble understanding. Can you ask again?',
      );
    }
  }

  /// Speak a response using TTS
  Future<void> speakResponse(String text) async {
    state = state.copyWith(isSpeaking: true);

    try {
      await _ttsService.speak(text);
      // Note: We don't have a reliable way to know when TTS finishes
      // So we'll just wait a reasonable time based on text length
      await Future.delayed(Duration(seconds: (text.length / 10).ceil() + 2));
    } catch (e) {
      print('Speak response error: $e');
    } finally {
      state = state.copyWith(isSpeaking: false);
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _ttsService.stop();
    state = state.copyWith(isSpeaking: false);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh history
  Future<void> refreshHistory() async {
    await _loadHistory();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _speech.stop();
    super.dispose();
  }
}
