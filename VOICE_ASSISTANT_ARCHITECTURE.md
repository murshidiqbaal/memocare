# Voice Assistant Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    PATIENT INTERFACE                             │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │         VoiceAssistantScreen (UI Layer)                   │  │
│  │                                                             │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐  │  │
│  │  │ Microphone  │  │  Transcript  │  │    Response     │  │  │
│  │  │   Button    │  │    Card      │  │     Card        │  │  │
│  │  │  (160x160)  │  │   (Blue)     │  │    (Teal)       │  │  │
│  │  └─────────────┘  └──────────────┘  └─────────────────┘  │  │
│  │                                                             │  │
│  │  Status: Listening | Thinking | Speaking | Idle            │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │      VoiceAssistantViewModel (State Management)           │  │
│  │                                                             │  │
│  │  State:                                                     │  │
│  │  • isListening: bool                                        │  │
│  │  • isProcessing: bool                                       │  │
│  │  • isSpeaking: bool                                         │  │
│  │  • currentTranscript: String                                │  │
│  │  • lastResponse: String?                                    │  │
│  │  • queryHistory: List<VoiceQuery>                           │  │
│  │                                                             │  │
│  │  Methods:                                                   │  │
│  │  • startListening()                                         │  │
│  │  • stopListening()                                          │  │
│  │  • processQuery(query)                                      │  │
│  │  • speakResponse(text)                                      │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SERVICE LAYER                                 │
│                                                                   │
│  ┌──────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │  TTSService  │  │ MemoryQueryEngine│  │ SpeechToText SDK │  │
│  │              │  │                  │  │                  │  │
│  │ • init()     │  │ • processQuery() │  │ • listen()       │  │
│  │ • speak()    │  │ • classify()     │  │ • stop()         │  │
│  │ • stop()     │  │ • generate()     │  │                  │  │
│  │              │  │                  │  │                  │  │
│  │ flutter_tts  │  │  Rule-Based AI   │  │ speech_to_text   │  │
│  └──────────────┘  └──────────────────┘  └──────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│                    Query Classification                          │
│                    ┌─────────────────┐                          │
│                    │ Reminder        │                          │
│                    │ PastActivity    │                          │
│                    │ Person          │                          │
│                    │ Appointment     │                          │
│                    │ General         │                          │
│                    └─────────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  REPOSITORY LAYER                                │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │        VoiceAssistantRepository                          │   │
│  │                                                            │   │
│  │  • getQueries(patientId)                                  │   │
│  │  • addQuery(query)                                        │   │
│  │  • syncQueries(patientId)                                 │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│         ┌────────────────────┼────────────────────┐             │
│         ▼                    ▼                    ▼             │
│  ┌─────────────┐  ┌──────────────────┐  ┌─────────────────┐   │
│  │  Reminder   │  │     People       │  │     Memory      │   │
│  │ Repository  │  │   Repository     │  │   Repository    │   │
│  │             │  │                  │  │                 │   │
│  │ • get()     │  │ • getPeople()    │  │ • getMemories() │   │
│  │ • sync()    │  │ • sync()         │  │ • sync()        │   │
│  └─────────────┘  └──────────────────┘  └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                    │
│                                                                   │
│  ┌──────────────────────┐         ┌──────────────────────────┐  │
│  │   Local Storage      │         │   Remote Storage         │  │
│  │      (Hive)          │  ◄────► │     (Supabase)           │  │
│  │                      │         │                          │  │
│  │ • voice_queries box  │  Sync   │ • voice_queries table    │  │
│  │ • reminders box      │         │ • reminders table        │  │
│  │ • people box         │         │ • people_cards table     │  │
│  │ • memories box       │         │ • memory_cards table     │  │
│  │                      │         │                          │  │
│  │ Offline-First        │         │ RLS Policies Enabled     │  │
│  └──────────────────────┘         └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                  CAREGIVER INTERFACE                             │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │       PatientVoiceHistoryScreen (Read-Only)               │  │
│  │                                                             │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  Query 1: "Do I have medicine now?"                 │  │  │
│  │  │  Response: "Yes, you have Take Medicine at 2:00 PM" │  │  │
│  │  │  Time: 2026-02-09 14:15                             │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │                                                             │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  Query 2: "What did I do yesterday?"                │  │  │
│  │  │  Response: "Yesterday you completed: Take Medicine, │  │  │
│  │  │             Walk in Park. You had a productive day!" │  │  │
│  │  │  Time: 2026-02-09 10:30                             │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  Access controlled by RLS:                                       │
│  • SELECT only (no INSERT/UPDATE/DELETE)                         │
│  • Filtered by caregiver_patients link                           │
└─────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════
                        DATA FLOW EXAMPLE
═══════════════════════════════════════════════════════════════════

1. Patient taps microphone button
   │
   ▼
2. VoiceAssistantViewModel.startListening()
   │
   ▼
3. SpeechToText SDK starts listening
   │
   ▼
4. Real-time transcript updates UI
   │
   ▼
5. Speech finalized → processQuery("Do I have medicine now?")
   │
   ▼
6. MemoryQueryEngine.processQuery()
   │
   ├─► Classify: QueryType.reminder
   │
   ├─► ReminderRepository.getReminders(patientId)
   │   │
   │   ├─► Check Hive cache first (offline-first)
   │   │
   │   └─► Return today's pending reminders
   │
   ├─► Generate response: "Yes, you have Take Medicine at 2:00 PM"
   │
   └─► Return response
   │
   ▼
7. Save to VoiceAssistantRepository
   │
   ├─► Save to Hive (local)
   │
   └─► Sync to Supabase (if online)
   │
   ▼
8. Update UI with response
   │
   ▼
9. TTSService.speak("Yes, you have Take Medicine at 2:00 PM")
   │
   ▼
10. Patient hears response through device speaker

═══════════════════════════════════════════════════════════════════
                      SECURITY FLOW
═══════════════════════════════════════════════════════════════════

Patient Query:
  auth.uid() = patient_id
  │
  ├─► Can INSERT own queries ✓
  ├─► Can SELECT own queries ✓
  └─► Cannot SELECT other patients ✗

Caregiver View:
  auth.uid() = caregiver_id
  │
  ├─► Check caregiver_patients link
  │   │
  │   └─► If linked: Can SELECT patient queries ✓
  │
  ├─► Cannot INSERT queries ✗
  ├─► Cannot UPDATE queries ✗
  └─► Cannot DELETE queries ✗

═══════════════════════════════════════════════════════════════════
```

## Component Responsibilities

### UI Layer
- **VoiceAssistantScreen**: Display interface, handle user interactions
- **Animations**: Pulse effect, card transitions
- **Feedback**: Visual and audio feedback

### State Management
- **VoiceAssistantViewModel**: Coordinate all services, manage state
- **Riverpod**: Reactive state updates, dependency injection

### Service Layer
- **TTSService**: Text-to-speech conversion
- **MemoryQueryEngine**: Query classification and response generation
- **SpeechToText**: Voice recognition

### Repository Layer
- **VoiceAssistantRepository**: Voice query CRUD and sync
- **ReminderRepository**: Reminder data access
- **PeopleRepository**: People card data access
- **MemoryRepository**: Memory card data access

### Data Layer
- **Hive**: Local offline storage
- **Supabase**: Remote cloud storage with RLS

## Key Design Patterns

1. **Repository Pattern**: Abstraction over data sources
2. **MVVM**: Separation of UI and business logic
3. **Offline-First**: Local cache with background sync
4. **Provider Pattern**: Dependency injection via Riverpod
5. **State Notifier**: Immutable state management
