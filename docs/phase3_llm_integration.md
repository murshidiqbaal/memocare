# Phase 3: Voice Assistant LLM Integration

## Overview
Phase 3 enhances the MemoCare Voice Assistant by integrating Google's Gemini LLM. This allows the assistant to understand natural language queries, provide context-aware responses, and interact with the patient in a more empathetic and personalized manner.

## Key Features
- **Natural Language Understanding:** Uses `gemini-1.5-flash` to interpret patient queries beyond simple keywords.
- **Context-Aware Responses:** The LLM is fed relevant patient data (reminders, people, recent memories) to generate accurate answers.
- **Empathetic Persona:** The AI is prompted to be warm, clear, and reassuring, optimized for dementia care.
- **Robust Fallback:** If the LLM is unavailable (offline or invalid API key), the system automatically falls back to the existing keyword-based engine.

## Setup Instructions

### 1. Get a Gemini API Key
1. Go to [Google AI Studio](https://aistudio.google.com/).
2. Create a new API key.
3. Copy the key.

### 2. Configure Environment
1. Open the `.env` file in the project root.
2. Add or update the `GOOGLE_GEMINI_API_KEY` variable:

```env
GOOGLE_GEMINI_API_KEY=your_copied_api_key_here
```

### 3. Verify Integration
1. Run the app.
2. Navigate to the Voice Assistant screen.
3. Tap the microphone and ask a question like:
   - "What do I have to do today?"
   - "Who is visiting me?"
   - "What did I do yesterday?"
3a. **Debug Mode:** Tap the keyboard icon in the top right to type a query directly. This is useful for testing without voice input.
4. If the LLM is working, you should get a natural, conversational response.
5. If the API key is missing or invalid, you will get a simpler, keyword-based response.

## Technical Details

### Architecture
- **`LLMMemoryQueryEngine`**: The core service that manages the Gemini model and fallback logic.
- **`VoiceAssistantViewModel`**: Updated to use the LLM engine for processing speech.
- **`service_providers.dart`**: Provides the `llmMemoryQueryEngineProvider`.

### Privacy & Safety
- **Data Privacy:** Patient data sent to the LLM is transient and used only for generating the response.
- **Safety Settings:** The model is configured with high safety thresholds to prevent harmful content.
- **Prompt Engineering:** The system prompt explicitly instructs the AI to avoid medical jargon and dementia-specific terms.

## Troubleshooting

### "I didn't hear anything"
- Ensure microphone permissions are granted.
- Speak clearly and close to the device.

### "I had trouble understanding"
- Check your internet connection.
- Verify the API key in `.env`.
- Check debug logs for `LLM generation error`.

### API Key Issues
- If you see `Error initializing Gemini model`, double-check the API key in `.env`.
- Ensure the `google_generative_ai` package is installed (`flutter pub get`).
