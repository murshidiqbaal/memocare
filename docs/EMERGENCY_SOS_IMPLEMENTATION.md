# Emergency SOS System - Complete Implementation Guide

## 📋 Overview

This document provides a complete implementation of an emergency SOS system for the MemoCare dementia care application. The system features a **curved bottom navigation bar** with a **central SOS button** that triggers a **5-second countdown** before automatically sending an emergency alert to linked caregivers.

---

## 🏗️ Architecture

### Technology Stack
- **Frontend**: Flutter 3.2+ with Riverpod state management
- **Backend**: Supabase (PostgreSQL + Realtime)
- **Location**: Geolocator package
- **Notifications**: Real-time subscriptions via Supabase Realtime

### Clean Architecture Layers
```
├── Data Layer
│   ├── models/emergency_alert.dart
│   └── repositories/emergency_alert_repository.dart
├── Domain Layer
│   └── providers/emergency_alert_provider.dart
└── Presentation Layer
    ├── screens/
    │   ├── patient/patient_main_screen.dart
    │   └── caregiver/alerts/caregiver_alerts_screen.dart
    └── widgets/
        ├── curved_bottom_nav_bar.dart
        └── sos_countdown_dialog.dart
```

---

## 📁 Folder Structure

```
lib/
├── data/
│   ├── models/
│   │   └── emergency_alert.dart          # Alert model with status enum
│   └── repositories/
│       └── emergency_alert_repository.dart # CRUD + Realtime operations
├── providers/
│   └── emergency_alert_provider.dart      # Riverpod state management
├── screens/
│   ├── patient/
│   │   └── patient_main_screen.dart       # Main screen with nav bar
│   └── caregiver/
│       └── alerts/
│           └── caregiver_alerts_screen.dart # Real-time alert listener
└── widgets/
    ├── curved_bottom_nav_bar.dart         # Custom nav bar with SOS
    └── sos_countdown_dialog.dart          # Full-screen countdown UI

supabase/
└── migrations/
    └── emergency_alerts_schema.sql        # Database schema + RLS
```

---

## 🗄️ Database Schema

### Table: `emergency_alerts`

```sql
CREATE TABLE emergency_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES auth.users(id),
    caregiver_id UUID REFERENCES auth.users(id),
    status TEXT NOT NULL DEFAULT 'sent' 
           CHECK (status IN ('sent', 'cancelled', 'resolved')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    patient_name TEXT,
    patient_phone TEXT
);
```

### Row Level Security (RLS) Policies

1. **Patients can INSERT their own alerts**
2. **Patients can SELECT their own alerts**
3. **Patients can UPDATE (cancel) their own alerts**
4. **Caregivers can SELECT alerts from linked patients**
5. **Caregivers can UPDATE (resolve) alerts from linked patients**

### Realtime Publication
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE emergency_alerts;
```

---

## 🔄 User Flow

### Patient Side

1. **User taps central SOS button** on curved bottom nav bar
2. **Full-screen countdown dialog appears** (red theme, 5 seconds)
3. **User can cancel** within 5 seconds by pressing "CANCEL" button
4. **If countdown reaches 0**:
   - Current location is captured (if available)
   - Alert is inserted into `emergency_alerts` table
   - Status is set to `'sent'`
   - Trigger auto-assigns primary caregiver
5. **Success message** is shown briefly
6. **Dialog closes** automatically

### Caregiver Side

1. **Real-time subscription** listens to `emergency_alerts` table
2. **New alert appears** instantly in caregiver alerts screen
3. **Caregiver sees**:
   - Patient name
   - Time elapsed since alert
   - Patient phone number
   - Location coordinates (if available)
4. **Caregiver can**:
   - **Call patient** directly (tap-to-call)
   - **Resolve alert** (marks as resolved)
5. **Resolved alerts** are removed from active list

---

## 🎨 UI/UX Features

### Elderly-Friendly Design
- ✅ **Large fonts** (28-36px for critical text)
- ✅ **High contrast** (red on white, white on red)
- ✅ **Large touch targets** (minimum 70px height)
- ✅ **Clear visual hierarchy**
- ✅ **Minimal cognitive load**

### Animations
- ✅ **Pulsing SOS button** (attracts attention)
- ✅ **Countdown scale animation** (elastic bounce)
- ✅ **Warning icon pulse** (during countdown)
- ✅ **Smooth state transitions**

### Accessibility
- ✅ **Semantic labels** for screen readers
- ✅ **Color-blind safe** (not relying solely on color)
- ✅ **Haptic feedback** (via button press)

---

## 🔌 Integration Steps

### Step 1: Run Database Migration

```bash
# Apply the SQL schema to your Supabase project
# Option A: Via Supabase Dashboard
# - Go to SQL Editor
# - Paste contents of emergency_alerts_schema.sql
# - Run

# Option B: Via Supabase CLI
supabase db push
```

### Step 2: Generate Model Code

```bash
# Generate JSON serialization code
dart run build_runner build --delete-conflicting-outputs
```

### Step 3: Update Main App

Replace your patient home screen navigation with `PatientMainScreen`:

```dart
// In your router or main.dart
import 'package:dementia_care_app/screens/patient/patient_main_screen.dart';

// Use PatientMainScreen instead of individual screens
MaterialApp(
  home: PatientMainScreen(), // This includes the curved nav bar
)
```

### Step 4: Add Caregiver Alerts to Navigation

```dart
// In caregiver dashboard or navigation
import 'package:dementia_care_app/screens/caregiver/alerts/caregiver_alerts_screen.dart';

// Add to caregiver menu
ListTile(
  leading: Icon(Icons.emergency),
  title: Text('Emergency Alerts'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CaregiverAlertsScreen(),
    ),
  ),
)
```

### Step 5: Request Location Permissions

Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Add to `Info.plist` (iOS):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to send emergency alerts</string>
```

---

## 🧪 Testing

### Manual Testing Checklist

#### Patient Flow
- [ ] SOS button is visible and centered in nav bar
- [ ] SOS button pulses continuously
- [ ] Tapping SOS opens full-screen countdown
- [ ] Countdown displays 5 → 4 → 3 → 2 → 1 → 0
- [ ] Cancel button stops countdown
- [ ] Countdown reaching 0 sends alert
- [ ] Success message appears after sending
- [ ] Dialog closes automatically

#### Caregiver Flow
- [ ] Alerts screen shows "No Active Alerts" when empty
- [ ] New alert appears instantly (real-time)
- [ ] Alert shows patient name, phone, time
- [ ] Call button launches phone dialer
- [ ] Resolve button marks alert as resolved
- [ ] Resolved alerts disappear from list

#### Edge Cases
- [ ] Works without location permission (sends without coords)
- [ ] Works offline (queues alert, sends when online)
- [ ] Multiple alerts from same patient
- [ ] Multiple caregivers receive same alert
- [ ] Alert persists across app restarts

---

## 🔐 Security Considerations

### RLS Policies
- ✅ Patients can only create/view/cancel their own alerts
- ✅ Caregivers can only view/resolve alerts from linked patients
- ✅ No unauthorized access to other patients' alerts

### Data Privacy
- ✅ Location data is optional (graceful degradation)
- ✅ Phone numbers are denormalized (no joins needed)
- ✅ Resolved alerts are kept for audit trail

---

## 🚀 Performance Optimizations

### Database
- ✅ Indexes on `patient_id`, `caregiver_id`, `status`, `created_at`
- ✅ Denormalized patient name/phone (avoid joins)
- ✅ Trigger auto-assigns caregiver (one query)

### Frontend
- ✅ `autoDispose` providers (automatic cleanup)
- ✅ Stream subscription (only active alerts)
- ✅ Optimistic UI updates (instant feedback)

### Offline Support
- ✅ Location timeout (3 seconds max)
- ✅ Graceful error handling
- ✅ Retry logic for failed sends

---

## 📱 Screenshots & Behavior

### Curved Bottom Nav Bar
```
┌─────────────────────────────────────┐
│  Home    Reminders  [SOS]  Memories  Profile  │
│   🏠        🔔       🆘      📷       👤    │
└─────────────────────────────────────┘
```
- SOS button floats above nav bar
- Pulsing red circle with white icon
- 80x80px touch target

### Countdown Dialog
```
┌─────────────────────────────────────┐
│                                     │
│         ⚠️ (pulsing icon)            │
│                                     │
│      EMERGENCY ALERT                │
│                                     │
│  Sending alert to your caregiver... │
│                                     │
│          ┌─────────┐                │
│          │    5    │ (animated)     │
│          └─────────┘                │
│                                     │
│     ┌─────────────────┐             │
│     │     CANCEL      │             │
│     └─────────────────┘             │
│                                     │
└─────────────────────────────────────┘
```

### Caregiver Alert Card
```
┌─────────────────────────────────────┐
│ 🆘  John Doe              ● (pulse) │
│     2 minutes ago                   │
├─────────────────────────────────────┤
│ 📍 Location: 40.7128, -74.0060      │
│ 📞 Phone: +1 234 567 8900           │
│                                     │
│ ┌──────────┐  ┌──────────┐          │
│ │   CALL   │  │ RESOLVE  │          │
│ └──────────┘  └──────────┘          │
└─────────────────────────────────────┘
```

---

## 🐛 Troubleshooting

### Issue: Alerts not appearing in real-time
**Solution**: Ensure Realtime is enabled in Supabase dashboard:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE emergency_alerts;
```

### Issue: Location always null
**Solution**: Check permissions and add timeout handling:
```dart
await Geolocator.requestPermission();
```

### Issue: RLS blocking queries
**Solution**: Verify user is authenticated and linked in `caregiver_patient_links`

---

## 📚 API Reference

### EmergencyAlertRepository

```dart
// Send emergency alert
Future<EmergencyAlert> sendEmergencyAlert()

// Cancel alert (patient)
Future<void> cancelEmergencyAlert(String alertId)

// Resolve alert (caregiver)
Future<void> resolveEmergencyAlert(String alertId)

// Get active alerts (patient)
Future<List<EmergencyAlert>> getMyActiveAlerts()

// Get linked patients' alerts (caregiver)
Future<List<EmergencyAlert>> getLinkedPatientsActiveAlerts()

// Real-time stream (caregiver)
Stream<List<EmergencyAlert>> watchLinkedPatientsAlerts()
```

### EmergencySOSController

```dart
// Start countdown
void startCountdown()

// Cancel countdown
void cancelCountdown()

// Resolve alert (caregiver)
Future<void> resolveAlert(String alertId)
```

---

## 🎯 Future Enhancements

- [ ] Push notifications for caregivers (FCM)
- [ ] SMS fallback if app is closed
- [ ] Voice call integration
- [ ] Map view of patient location
- [ ] Alert history analytics
- [ ] Multi-language support
- [ ] Customizable countdown duration
- [ ] Emergency contacts list
- [ ] Auto-call after countdown
- [ ] Geofencing alerts

---

## 📄 License

This implementation is part of the MemoCare dementia care application.

---

## 👥 Support

For issues or questions:
1. Check troubleshooting section
2. Review Supabase logs
3. Test with Supabase SQL Editor
4. Verify RLS policies

---

**Implementation Status**: ✅ Production Ready

**Last Updated**: 2026-02-15

**Version**: 1.0.0
