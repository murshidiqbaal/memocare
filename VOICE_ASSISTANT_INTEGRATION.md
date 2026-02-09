# Voice Assistant Integration Guide

## Adding Voice Assistant to Patient Dashboard

### Step 1: Import the Voice Assistant Screen

In `patient_dashboard_tab.dart`, add the import:

```dart
import '../voice_assistant/voice_assistant_screen.dart';
```

### Step 2: Add Voice Assistant Button to Quick Actions

Update the `QuickActionGrid` widget or add a new button:

```dart
// In the Quick Actions section
QuickActionButton(
  icon: Icons.mic,
  label: 'Voice Assistant',
  color: Colors.teal,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceAssistantScreen(
          patientId: currentPatientId, // Get from auth or state
        ),
      ),
    );
  },
),
```

### Step 3: Get Patient ID

You'll need to pass the current patient ID. Options:

**Option A: From Auth State**
```dart
final userId = Supabase.instance.client.auth.currentUser?.id;
if (userId != null) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => VoiceAssistantScreen(patientId: userId),
    ),
  );
}
```

**Option B: From ViewModel**
```dart
final homeState = ref.watch(homeViewModelProvider);
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => VoiceAssistantScreen(
      patientId: homeState.patientId,
    ),
  ),
);
```

### Step 4: Update QuickActionGrid Widget

If you have a `QuickActionGrid` widget, update it to include voice assistant:

```dart
class QuickActionGrid extends StatelessWidget {
  final VoidCallback onMemoriesTap;
  final VoidCallback onGamesTap;
  final VoidCallback onLocationTap;
  final VoidCallback onSOSTrigger;
  final VoidCallback onVoiceAssistantTap; // Add this

  const QuickActionGrid({
    super.key,
    required this.onMemoriesTap,
    required this.onGamesTap,
    required this.onLocationTap,
    required this.onSOSTrigger,
    required this.onVoiceAssistantTap, // Add this
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        QuickActionButton(
          icon: Icons.mic,
          label: 'Voice Assistant',
          color: Colors.teal,
          onTap: onVoiceAssistantTap,
        ),
        QuickActionButton(
          icon: Icons.photo_library,
          label: 'Memories',
          color: Colors.blue,
          onTap: onMemoriesTap,
        ),
        QuickActionButton(
          icon: Icons.games,
          label: 'Games',
          color: Colors.purple,
          onTap: onGamesTap,
        ),
        QuickActionButton(
          icon: Icons.location_on,
          label: 'Location',
          color: Colors.green,
          onTap: onLocationTap,
        ),
        QuickActionButton(
          icon: Icons.emergency,
          label: 'SOS',
          color: Colors.red,
          onTap: onSOSTrigger,
        ),
      ],
    );
  }
}
```

### Step 5: Complete Dashboard Integration

Update `patient_dashboard_tab.dart`:

```dart
// In the build method
QuickActionGrid(
  onVoiceAssistantTap: () {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VoiceAssistantScreen(patientId: userId),
        ),
      );
    }
  },
  onMemoriesTap: () {
    // Navigate to Memories
  },
  onGamesTap: () {
    // Navigate to Games
  },
  onLocationTap: () {
    // Show Location
  },
  onSOSTrigger: () {
    _showSOSConfirmation(context, viewModel);
  },
),
```

## Alternative: Floating Action Button

For quick access, add a FAB to the dashboard:

```dart
Scaffold(
  // ... other properties
  floatingActionButton: FloatingActionButton.extended(
    onPressed: () {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceAssistantScreen(patientId: userId),
          ),
        );
      }
    },
    icon: const Icon(Icons.mic),
    label: const Text('Ask Me'),
    backgroundColor: Colors.teal,
  ),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
)
```

## Caregiver Dashboard Integration

### View Patient Voice Queries

Create a screen to view patient's voice interactions:

```dart
class PatientVoiceHistoryScreen extends ConsumerWidget {
  final String patientId;

  const PatientVoiceHistoryScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(voiceAssistantRepositoryProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Interactions')),
      body: FutureBuilder(
        future: repository.init().then((_) => repository.getQueries(patientId)),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final queries = snapshot.data as List;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: queries.length,
            itemBuilder: (context, index) {
              final query = queries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        query.createdAt.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Q: ${query.queryText}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A: ${query.responseText}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

## Permissions Setup

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<manifest>
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.INTERNET" />
  
  <application>
    <!-- ... -->
  </application>
</manifest>
```

### iOS (ios/Runner/Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to listen to your voice questions</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app needs speech recognition to understand your questions</string>
```

## Testing the Integration

1. **Run the app**: `flutter run`
2. **Navigate to patient dashboard**
3. **Tap Voice Assistant button**
4. **Grant microphone permissions**
5. **Tap microphone and speak**: "Do I have medicine now?"
6. **Verify transcript appears**
7. **Verify response is generated**
8. **Verify TTS speaks the response**
9. **Check history button**

## Troubleshooting

**Button not appearing:**
- Check import statements
- Verify QuickActionGrid is updated
- Check patient ID is available

**Navigation error:**
- Ensure VoiceAssistantScreen is imported
- Verify patient ID is not null
- Check route configuration

**Permissions denied:**
- Request permissions at runtime
- Guide user to settings
- Show helpful error message

## Next Steps

1. ✅ Add voice assistant button to dashboard
2. ✅ Test on physical device
3. ✅ Configure permissions
4. ⏳ Create Supabase table for voice_queries
5. ⏳ Set up RLS policies
6. ⏳ Test with real patient data
7. ⏳ Gather user feedback
