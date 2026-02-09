import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'voice_assistant_viewmodel.dart';
import '../../../providers/service_providers.dart';

/// Provider for voice assistant
final voiceAssistantProvider = StateNotifierProvider.family<
    VoiceAssistantViewModel, VoiceAssistantState, String>((ref, patientId) {
  final repository = ref.watch(voiceAssistantRepositoryProvider);
  final ttsService = ref.watch(ttsServiceProvider);
  final queryEngine = ref.watch(memoryQueryEngineProvider);
  return VoiceAssistantViewModel(
      repository, ttsService, queryEngine, patientId);
});

/// Voice Assistant Screen - Main UI for voice interactions
///
/// Features:
/// - Large microphone button for easy access
/// - Real-time speech transcript display
/// - AI-generated response display
/// - Text-to-speech playback
/// - Dementia-friendly calm design
class VoiceAssistantScreen extends ConsumerStatefulWidget {
  final String patientId;

  const VoiceAssistantScreen({super.key, required this.patientId});

  @override
  ConsumerState<VoiceAssistantScreen> createState() =>
      _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends ConsumerState<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceAssistantProvider(widget.patientId));
    final viewModel =
        ref.read(voiceAssistantProvider(widget.patientId).notifier);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Voice Assistant',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context, state.queryHistory),
            tooltip: 'View History',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Instruction text
              const SizedBox(height: 20),
              Text(
                'Ask me anything about your day',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the microphone and speak clearly',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Transcript display
              if (state.currentTranscript.isNotEmpty)
                _buildTranscriptCard(state.currentTranscript),

              // Response display
              if (state.lastResponse != null && !state.isListening)
                _buildResponseCard(state.lastResponse!),

              // Error display
              if (state.error != null) _buildErrorCard(state.error!, viewModel),

              const Spacer(),

              // Microphone button
              _buildMicrophoneButton(
                state: state,
                onPressed: () {
                  if (state.isListening) {
                    viewModel.stopListening();
                  } else {
                    viewModel.startListening();
                  }
                },
              ),

              const SizedBox(height: 24),

              // Status text
              _buildStatusText(state),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Build microphone button with pulse animation
  Widget _buildMicrophoneButton({
    required VoiceAssistantState state,
    required VoidCallback onPressed,
  }) {
    final isActive =
        state.isListening || state.isProcessing || state.isSpeaking;

    return GestureDetector(
      onTap: state.isProcessing || state.isSpeaking ? null : onPressed,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isActive
                    ? [Colors.teal.shade400, Colors.teal.shade700]
                    : [Colors.teal.shade300, Colors.teal.shade500],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(
                    state.isListening
                        ? 0.3 + (_pulseController.value * 0.2)
                        : 0.2,
                  ),
                  blurRadius: state.isListening
                      ? 20 + (_pulseController.value * 10)
                      : 15,
                  spreadRadius:
                      state.isListening ? 5 + (_pulseController.value * 5) : 3,
                ),
              ],
            ),
            child: Icon(
              state.isListening
                  ? Icons.mic
                  : (state.isProcessing
                      ? Icons.hourglass_empty
                      : (state.isSpeaking ? Icons.volume_up : Icons.mic_none)),
              size: 72,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  /// Build transcript card
  Widget _buildTranscriptCard(String transcript) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'You said:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            transcript,
            style: const TextStyle(
              fontSize: 20,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Build response card
  Widget _buildResponseCard(String response) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assistant, color: Colors.teal.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Assistant:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            response,
            style: const TextStyle(
              fontSize: 20,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error card
  Widget _buildErrorCard(String error, VoiceAssistantViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                fontSize: 18,
                color: Colors.red.shade900,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: viewModel.clearError,
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  /// Build status text
  Widget _buildStatusText(VoiceAssistantState state) {
    String statusText;
    Color statusColor;

    if (state.isListening) {
      statusText = 'Listening... Speak now';
      statusColor = Colors.teal.shade700;
    } else if (state.isProcessing) {
      statusText = 'Thinking...';
      statusColor = Colors.orange.shade700;
    } else if (state.isSpeaking) {
      statusText = 'Speaking...';
      statusColor = Colors.blue.shade700;
    } else {
      statusText = 'Tap to ask a question';
      statusColor = Colors.grey.shade600;
    }

    return Text(
      statusText,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: statusColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Show query history dialog
  void _showHistory(BuildContext context, List queryHistory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recent Conversations'),
        content: SizedBox(
          width: double.maxFinite,
          child: queryHistory.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No conversations yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: queryHistory.length,
                  itemBuilder: (context, index) {
                    final query = queryHistory[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Q: ${query.queryText}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'A: ${query.responseText}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
