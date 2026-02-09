# Voice Assistant & Memory Retrieval Module

## Overview
Complete implementation of SRS Section 6.3 - Voice Interaction and AI Memory Retrieval for MemoCare dementia care application.

## Features Implemented

### 1. Voice Assistant Screen ✅
- **Large microphone button** (160x160px) with pulse animation
- **Real-time speech-to-text** transcript display
- **AI-generated responses** with text-to-speech playback
- **Dementia-friendly UI** with calm colors and large text
- **Conversation history** viewer

### 2. Speech Recognition ✅
- **speech_to_text** package integration
- 30-second listening duration
- 3-second pause detection
- Partial results display
- Error handling with user-friendly messages

### 3. Text-to-Speech ✅
- **flutter_tts** package integration
- Slow speech rate (0.4) for better comprehension
- Moderate pitch (1.0) for calm tone
- 80% volume
- Automatic speech duration calculation

### 4. Memory Query Engine ✅
Supports the following question types:

#### Reminder Queries
- "Do I have medicine now?"
- "What reminders do I have today?"
- Returns next upcoming reminder with time

#### Past Activity Queries
- "What did I do yesterday?"
- Returns completed reminders from yesterday
- Friendly summary of activities

#### Person Queries
- "Who is visiting today?"
- "Tell me about [person name]"
- Returns person details from people_cards

#### Appointment Queries
- "What is my next appointment?"
- "When is my doctor visit?"
- Returns next scheduled appointment

#### General Queries
- Fallback responses for unclear questions
- Helpful guidance on what to ask

### 5. Data Sources
Retrieves information from:
- ✅ `reminders` table
- ✅ `reminder_logs` table (via status)
- ✅ `memory_cards` table
- ✅ `people_cards` table
- ⏳ `journal_entries` table (future enhancement)

### 6. Offline-First Behavior ✅
- **Local caching** using Hive
- **Offline query processing** with cached data
- **Sync queue** for later cloud processing
- **Graceful degradation** when no internet

### 7. Voice Query History ✅
- Stores all conversations in `voice_queries` table
- Local storage with Supabase sync
- Viewable by patient and caregiver
- Recent 50 queries cached locally

## Architecture

### Models
```
VoiceQuery
├── id: String
├── patientId: String
├── queryText: String
├── responseText: String
├── createdAt: DateTime
└── isSynced: bool
```

### Services

#### TTSService
- Initializes flutter_tts
- Configures dementia-friendly settings
- Speaks responses
- Stop/pause controls

#### MemoryQueryEngine
- Classifies query type
- Fetches relevant data from repositories
- Generates dementia-friendly responses
- Formats dates and times

### Repositories

#### VoiceAssistantRepository
- Manages voice query history
- Local Hive storage
- Supabase synchronization
- CRUD operations

### ViewModels

#### VoiceAssistantViewModel
- Manages voice assistant state
- Coordinates speech recognition
- Processes queries through engine
- Handles TTS playback
- Updates UI state

## UI Components

### VoiceAssistantScreen
**Layout:**
- AppBar with history button
- Instruction text
- Transcript card (blue)
- Response card (teal)
- Error card (red)
- Large microphone button (center)
- Status text
- History dialog

**States:**
- Idle: "Tap to ask a question"
- Listening: Pulsing microphone, "Listening... Speak now"
- Processing: Hourglass icon, "Thinking..."
- Speaking: Volume icon, "Speaking..."

**Animations:**
- Pulse effect on microphone when listening
- Smooth card transitions
- Shadow intensity changes

## Database Schema

### voice_queries Table
```sql
CREATE TABLE voice_queries (
  id TEXT PRIMARY KEY,
  patient_id TEXT NOT NULL,
  query_text TEXT NOT NULL,
  response_text TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL,
  FOREIGN KEY (patient_id) REFERENCES profiles(id)
);
```

### Row Level Security (RLS)
```sql
-- Patients can view their own queries
CREATE POLICY "Patients can view own queries"
ON voice_queries FOR SELECT
USING (auth.uid() = patient_id);

-- Caregivers can view linked patient queries
CREATE POLICY "Caregivers can view patient queries"
ON voice_queries FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM caregiver_patients
    WHERE caregiver_id = auth.uid()
    AND patient_id = voice_queries.patient_id
  )
);
```

## Usage Example

```dart
// Navigate to voice assistant
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => VoiceAssistantScreen(
      patientId: currentPatientId,
    ),
  ),
);
```

## Dependencies Added

```yaml
dependencies:
  speech_to_text: ^7.3.0  # Already present
  flutter_tts: ^4.0.2      # Added
```

## Files Created

### Models
- `lib/data/models/voice_query.dart`
- `lib/data/models/voice_query.g.dart` (generated)

### Services
- `lib/services/tts_service.dart`
- `lib/services/memory_query_engine.dart`

### Repositories
- `lib/data/repositories/voice_assistant_repository.dart`

### Screens
- `lib/screens/patient/voice_assistant/voice_assistant_screen.dart`
- `lib/screens/patient/voice_assistant/voice_assistant_viewmodel.dart`

### Providers
- Updated `lib/providers/service_providers.dart`

### Configuration
- Updated `lib/main.dart` (Hive adapter registration)
- Updated `pubspec.yaml` (flutter_tts dependency)

## Testing Checklist

- [ ] Test speech recognition on device
- [ ] Test TTS playback
- [ ] Test reminder queries
- [ ] Test past activity queries
- [ ] Test person queries
- [ ] Test appointment queries
- [ ] Test offline mode
- [ ] Test history viewer
- [ ] Test error handling
- [ ] Test with dementia patients
- [ ] Verify RLS policies in Supabase
- [ ] Test sync functionality

## Caregiver Dashboard Integration

To view patient voice queries in caregiver dashboard:

```dart
// In caregiver dashboard
final queries = await supabase
  .from('voice_queries')
  .select()
  .eq('patient_id', selectedPatientId)
  .order('created_at', ascending: false)
  .limit(20);
```

## Future Enhancements

1. **Journal Entry Integration**
   - Query journal entries for past activities
   - "What did I write about yesterday?"

2. **Advanced AI**
   - Integration with GPT/Gemini for more natural responses
   - Context-aware conversations
   - Multi-turn dialogue

3. **Voice Profiles**
   - Recognize different speakers
   - Personalized responses

4. **Multilingual Support**
   - Multiple language TTS
   - Translation services

5. **Voice Commands**
   - "Create a reminder for..."
   - "Add to my journal..."

## Performance Considerations

- **Speech Recognition**: 30-second max listening time
- **TTS Duration**: Calculated as (text.length / 10) + 2 seconds
- **Query History**: Limited to 50 most recent queries
- **Offline Cache**: All queries cached locally
- **Sync**: Background sync on app resume

## Accessibility Features

- ✅ Large touch targets (160x160px microphone)
- ✅ High contrast colors
- ✅ Large text (18-24px)
- ✅ Clear visual feedback
- ✅ Slow, clear speech output
- ✅ Simple, calm UI
- ✅ Error messages in plain language

## Security & Privacy

- ✅ All queries encrypted in transit (HTTPS)
- ✅ RLS policies enforce data access
- ✅ Local data encrypted by Hive
- ✅ No third-party AI services (privacy-first)
- ✅ Caregiver read-only access

## Build & Run

```bash
# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run app
flutter run
```

## Notes for Final Year Viva

**Key Points to Explain:**

1. **Offline-First Architecture**: All data cached locally, works without internet
2. **Dementia-Friendly Design**: Large buttons, slow speech, calm colors
3. **AI Memory Retrieval**: Rule-based classification + data fetching
4. **Privacy & Security**: RLS policies, local encryption
5. **MVVM Architecture**: Clean separation of concerns
6. **State Management**: Riverpod for reactive UI
7. **Accessibility**: Designed for elderly users with cognitive impairment

**Demo Flow:**
1. Open voice assistant
2. Ask "Do I have medicine now?"
3. Show real-time transcript
4. Show AI response
5. Demonstrate TTS playback
6. Show conversation history
7. Demonstrate offline mode

## Troubleshooting

**Speech recognition not working:**
- Check microphone permissions
- Ensure device has internet (for STT initialization)
- Test on physical device (not emulator)

**TTS not speaking:**
- Check device volume
- Verify TTS engine installed on device
- Test with different text

**Queries not syncing:**
- Check internet connection
- Verify Supabase credentials
- Check RLS policies

## License & Credits

Built for MemoCare - Dementia Care Application
Final Year Project - 2026
