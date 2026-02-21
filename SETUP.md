# MemoCare - Setup Instructions

## Firebase Configuration (Required for Push Notifications)

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select existing project
3. Enter project name: **MemoCare** (or your preferred name)
4. Disable Google Analytics (optional for MVP)
5. Click "Create project"

### Step 2: Add Android App
1. In Firebase Console, click the Android icon to add an Android app
2. Enter Android package name: `com.example.memocare`
   - ⚠️ **Must match exactly** the `applicationId` in `android/app/build.gradle.kts`
3. App nickname (optional): "MemoCare Android"
4. Debug signing certificate SHA-1 (optional for now, required for release)
5. Click "Register app"

### Step 3: Download Configuration File
1. Download `google-services.json`
2. **Replace** the placeholder file at: `android/app/google-services.json`
3. Verify the file contains actual JSON (not instructions)

### Step 4: Verify Setup
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --debug

# Check for Firebase initialization in logs
flutter run
# Look for: "FCM Token: ..." in console output
```

### Step 5: Test Push Notifications
1. Run app on physical Android device (emulators unreliable for FCM)
2. Login as caregiver
3. Check Supabase `caregivers` table for `fcm_token` column populated
4. Trigger SOS alert from patient device
5. Verify caregiver receives notification

---

## Supabase Configuration

### Database Migrations
Run the following SQL files in Supabase SQL Editor:

1. **FCM Tokens** (`supabase_migrations/fcm_tokens.sql`)
   - Adds FCM token columns to caregivers and patients tables
   - Creates notification_log table
   - Sets up RLS policies

2. **Game Sessions** (`supabase_migrations/game_sessions.sql`)
   - Creates game_sessions table for Memory Match analytics
   - RLS policies for patient insert and caregiver view

3. **Memory Cards** (`supabase_migrations/memory_cards.sql`)
   - Creates memory_cards table for photo memories
   - Storage bucket configuration
   - RLS policies

### Edge Function (Optional - For Production FCM)
Create `supabase/functions/send-fcm-notification/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const { patient_id, notification_type, title, body, data } = await req.json()

  // Get caregivers with FCM tokens
  const { data: caregivers } = await supabase
    .from('caregivers')
    .select('fcm_token')
    .eq('patient_id', patient_id)
    .not('fcm_token', 'is', null)

  // Send FCM messages using Firebase Admin SDK
  // (Implementation depends on your Firebase setup)

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

---

## Development Setup

### Prerequisites
- Flutter SDK 3.2.0+
- Android Studio / VS Code
- Physical Android device (for FCM testing)
- Supabase account
- Firebase account

### Environment Variables
Create `.env` file in project root:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

### Install Dependencies
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run the App
```bash
# Debug mode
flutter run

# Release mode (requires signing)
flutter run --release
```

---

## Testing Checklist

### FCM Integration
- [ ] Firebase project created
- [ ] `google-services.json` added
- [ ] App builds without errors
- [ ] FCM token appears in logs
- [ ] Token saved in Supabase
- [ ] Foreground notifications work
- [ ] Background notifications work
- [ ] Notification tap opens correct screen

### Background Location
- [ ] Location permission granted
- [ ] Background location permission granted
- [ ] Foreground notification appears when tracking
- [ ] Location updates logged to Supabase
- [ ] Safe zone breach triggers notification
- [ ] Tracking continues with screen locked
- [ ] Battery optimization exemption requested

### Games Module
- [ ] Memory Match game loads
- [ ] Cards flip correctly
- [ ] Matching logic works
- [ ] Score calculated correctly
- [ ] Game session saved to database
- [ ] Caregiver can view game analytics

### Memories Module
- [ ] Caregiver can upload photos
- [ ] Patient can view memories
- [ ] Pull-to-refresh syncs data
- [ ] Offline mode works (airplane mode test)
- [ ] Photos cached locally

---

## Troubleshooting

### FCM Not Working
**Symptom:** No FCM token in logs
**Solutions:**
1. Verify `google-services.json` is valid JSON
2. Check package name matches exactly
3. Run `flutter clean && flutter pub get`
4. Test on physical device (not emulator)
5. Check Firebase Console → Cloud Messaging is enabled

### Background Location Stops
**Symptom:** Location updates stop after screen lock
**Solutions:**
1. Grant "Allow all the time" location permission
2. Disable battery optimization for MemoCare
3. Verify foreground notification is showing
4. Check Android version (14+ requires FOREGROUND_SERVICE_LOCATION)

### Build Errors
**Symptom:** Gradle build fails
**Solutions:**
1. Update Android SDK to latest
2. Check `build.gradle.kts` syntax
3. Verify Google Services plugin version
4. Run `flutter doctor` and fix issues

---

## Production Deployment

### Android Release Build
1. Generate signing key:
```bash
keytool -genkey -v -keystore memocare-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias memocare
```

2. Create `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=memocare
storeFile=../memocare-release-key.jks
```

3. Update `android/app/build.gradle.kts` with signing config

4. Build release APK:
```bash
flutter build apk --release
flutter build appbundle --release  # For Play Store
```

### Google Play Store
1. Create developer account ($25 one-time fee)
2. Prepare store listing:
   - App name: MemoCare
   - Short description
   - Full description
   - Screenshots (phone + tablet)
   - Feature graphic
   - App icon
3. Upload AAB file
4. Complete privacy policy
5. Submit for review

---

## Support & Resources

- **Flutter Docs:** https://docs.flutter.dev
- **Firebase Docs:** https://firebase.google.com/docs
- **Supabase Docs:** https://supabase.com/docs
- **Project Issues:** [GitHub Issues](your-repo-url)

---

## License

[Your License Here]
