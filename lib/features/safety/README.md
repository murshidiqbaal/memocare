# Emergency SOS Alert System - Implementation Guide

## 🚨 Overview

The Emergency SOS Alert System is a critical safety feature for MemoCare that enables patients to instantly alert all linked caregivers and share their live location in emergency situations.

## 📋 Architecture

### Database Schema

#### 1. `sos_alerts` Table
```sql
- id (UUID, primary key)
- patient_id (UUID → patients.id)
- latitude (double precision)
- longitude (double precision)
- status (text: 'active' | 'resolved')
- created_at (timestamp)
- resolved_at (timestamp, nullable)
```

#### 2. `live_locations` Table
```sql
- id (UUID, primary key)
- patient_id (UUID → patients.id)
- latitude (double precision)
- longitude (double precision)
- recorded_at (timestamp)
```

### Row Level Security (RLS)

**Patient Permissions:**
- ✅ Create SOS alerts
- ✅ Insert live location updates
- ✅ View own SOS history

**Caregiver Permissions:**
- ✅ View SOS alerts for linked patients only
- ✅ Stream live location of linked patients
- ✅ Resolve (mark as safe) SOS alerts

**Security Enforcement:**
```sql
EXISTS (
  SELECT 1 FROM caregiver_patient_links link
  JOIN caregivers c ON link.caregiver_id = c.id
  WHERE link.patient_id = sos_alerts.patient_id
  AND c.user_id = auth.uid()
)
```

## 🔄 SOS Flow

### Patient Side

1. **Trigger SOS**
   - Patient taps large red SOS button
   - Confirmation dialog appears
   - On confirm:
     - Request location permission
     - Get current GPS coordinates
     - Insert into `sos_alerts` table
     - Start continuous location tracking

2. **Location Tracking**
   - Updates every 10 meters
   - Inserts into `live_locations` table
   - Also updates latest position in active alert

3. **Cancel SOS**
   - Patient can cancel if safe
   - Stops location tracking
   - Marks alert as resolved

### Caregiver Side

1. **Receive Alert**
   - Realtime subscription triggers
   - Push notification sent
   - Red emergency banner appears in app

2. **View Live Map**
   - Tap alert card → opens live map
   - Shows patient's current position
   - Real-time marker updates
   - Distance calculation from caregiver

3. **Resolve Emergency**
   - Tap "Mark as Safe" button
   - Updates alert status to 'resolved'
   - Stops live tracking
   - Removes from active alerts list

## 📱 Flutter Components

### Models

**`SosAlert`** (`lib/features/safety/data/models/sos_alert.dart`)
```dart
class SosAlert {
  final String id;
  final String patientId;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  
  bool get isActive => status == 'active';
}
```

**`LiveLocation`** (`lib/features/safety/data/models/live_location.dart`)
```dart
class LiveLocation {
  final String id;
  final String patientId;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
}
```

### Repository

**`SosRepository`** (`lib/features/safety/data/repositories/sos_repository.dart`)

Methods:
- `createSosAlert()` - Create new SOS alert
- `updateLiveLocation()` - Update patient location
- `getActiveAlert()` - Get active alert for patient
- `streamActiveAlerts()` - Stream all active alerts (caregiver)
- `resolveSosAlert()` - Mark alert as resolved
- `streamLiveLocation()` - Stream live location for patient

### Controllers & Providers

**`SosController`** (`lib/features/safety/presentation/controllers/sos_controller.dart`)

State Management:
- `activeSosAlertProvider` - Current active alert
- `sosControllerProvider` - SOS actions controller
- `activeAlertsStreamProvider` - Stream of active alerts
- `liveLocationStreamProvider` - Stream of live locations

Methods:
- `triggerSos()` - Start emergency alert
- `cancelSos()` - Cancel active alert
- `resolveSos()` - Resolve alert (caregiver)

### UI Components

#### Patient UI

**`SosButton`** (`lib/features/safety/presentation/widgets/sos_button.dart`)
- Large circular red button
- Animated when active
- Confirmation dialog
- Shows "SOS ACTIVE" when tracking

Usage:
```dart
// In patient home screen
SosButton()
```

#### Caregiver UI

**`CaregiverAlertScreen`** (`lib/features/safety/presentation/screens/caregiver_alert_screen.dart`)
- Lists all active SOS alerts
- Shows patient name and time
- "Track Live Location" button
- Empty state when all safe

**`LiveMapScreen`** (`lib/features/safety/presentation/screens/live_map_screen.dart`)
- Google Maps integration
- Real-time marker updates
- Distance calculation
- "Mark as Safe" button

**`SafetyMonitor`** (`lib/features/safety/presentation/widgets/safety_monitor.dart`)
- Background listener for new alerts
- Triggers push notifications
- Wraps app root widget

## 🔔 Notifications

### Setup

Wrap your app with `SafetyMonitor`:
```dart
SafetyMonitor(
  child: MaterialApp(...)
)
```

### Notification Channels

**Android:**
- Channel ID: `emergency_channel`
- Importance: MAX
- Priority: HIGH
- Full screen intent: true
- Category: ALARM

**iOS:**
- Interruption level: CRITICAL
- Present alert, sound, banner: true

## 🛠️ Setup Instructions

### 1. Apply Database Schema

Run the SQL in Supabase SQL Editor:
```bash
lib/supabase/sos_schema.sql
```

### 2. Generate Dart Code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Configure Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location for emergency SOS alerts</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location for emergency SOS alerts</string>
```

### 4. Google Maps API Key

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

### 5. Enable Realtime in Supabase

The schema already includes:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE public.sos_alerts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.live_locations;
```

## 🧪 Testing

### Patient Flow Test

1. Sign in as patient
2. Navigate to home screen
3. Tap SOS button
4. Confirm alert
5. Grant location permission
6. Verify "SOS ACTIVE" state
7. Check location is being tracked

### Caregiver Flow Test

1. Sign in as caregiver (linked to patient)
2. Trigger SOS from patient device
3. Verify push notification received
4. Check alert appears in CaregiverAlertScreen
5. Tap "Track Live Location"
6. Verify map shows patient location
7. Verify distance calculation
8. Tap "Mark as Safe"
9. Verify alert removed

## 📊 Key Features

✅ **Real-time Updates** - Supabase Realtime subscriptions
✅ **Secure Access** - RLS ensures caregivers only see linked patients
✅ **Live Tracking** - Continuous GPS updates every 10 meters
✅ **Push Notifications** - Instant alerts to caregivers
✅ **Distance Calculation** - Shows how far caregiver is from patient
✅ **Offline Handling** - Graceful error handling
✅ **Accessibility** - Large touch targets, clear UI

## 🎯 Production Considerations

1. **Battery Optimization**
   - Location tracking only during active SOS
   - Stops immediately when resolved

2. **Network Resilience**
   - Handles offline scenarios
   - Queues location updates if needed

3. **Privacy**
   - Location only shared during active SOS
   - RLS prevents unauthorized access
   - Caregivers must be linked

4. **Performance**
   - Efficient Realtime subscriptions
   - Minimal battery drain
   - Optimized map rendering

## 🚀 Integration Example

### Patient Home Screen

```dart
class PatientHomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          // Other widgets...
          SosButton(), // Add SOS button
        ],
      ),
    );
  }
}
```

### Caregiver Dashboard

```dart
// Add navigation to alerts
ListTile(
  leading: Icon(Icons.emergency, color: Colors.red),
  title: Text('Safety Alerts'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CaregiverAlertScreen(),
    ),
  ),
)
```

### App Root

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafetyMonitor(
      child: MaterialApp(
        // Your app...
      ),
    );
  }
}
```

## 📝 Viva Explanation

**Q: How does the SOS system work?**

A: When a patient presses the SOS button, the system:
1. Gets their GPS location
2. Creates an alert in Supabase with status 'active'
3. Starts continuous location tracking
4. Supabase Realtime notifies all linked caregivers instantly
5. Caregivers receive push notifications and can track live location
6. When safe, caregivers mark the alert as 'resolved'

**Q: How is security ensured?**

A: We use Supabase Row Level Security (RLS). Caregivers can only see alerts for patients they're linked to through the `caregiver_patient_links` table. The RLS policy checks this relationship before allowing access.

**Q: What happens if the patient goes offline?**

A: The last known location remains visible to caregivers. When the patient comes back online, location updates resume automatically.

**Q: How is this different from other tracking apps?**

A: This is emergency-only tracking, not constant surveillance. Location sharing only happens during active SOS, respecting patient privacy while ensuring safety.

## 🎓 Demo Script

1. **Show patient app** - "Here's the patient view with the SOS button"
2. **Trigger SOS** - "Patient presses this in emergency"
3. **Show notification** - "Caregiver instantly receives alert"
4. **Open live map** - "Caregiver can track exact location in real-time"
5. **Show distance** - "System calculates how far away they are"
6. **Resolve** - "When patient is safe, caregiver marks it resolved"
7. **Show database** - "All secured with RLS policies"

This is the **strongest demo feature** - it's life-saving, technically impressive, and shows real-world healthcare application.
