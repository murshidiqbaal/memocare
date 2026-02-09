# Dementia Care Application

A Flutter application designed to assist dementia patients and their caregivers with daily routines, reminders, memory exercises, and location tracking.

## Features

### For Patients
- **Voice Reminders**: Personalized reminders with familiar voices (family members).
- **Daily Journal**: Easy methods to capture photos and daily moments.
- **Cognitive Games**: Memory matching, face recognition, and word association games to stimulate cognitive function.
- **Simplified Interface**: High contrast, large buttons, and intuitive navigation.

### For Caregivers
- **Location Tracking**: Real-time GPS tracking and geofencing with safe zones.
- **Remote Management**: Manage reminders, view activity logs, and monitor health metrics.
- **Analytics**: Track reminder adherence, game performance, and location history.
- **Crisis Alerts**: Notifications for safe zone exits or missed critical reminders.

## Tech Stack

- **Framework**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime)
- **State Management**: Riverpod
- **Local Storage**: Hive (Offline-first architecture)
- **Maps**: Google Maps & Flutter Background Geolocation

## Setup Instructions

1. **Prerequisites**:
   - Flutter SDK >=3.0.0
   - Supabase project setup (SQL scripts provided in documentation)

2. **Environment Variables**:
   - The `.env` file is included with Supabase credentials.

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the App**:
   ```bash
   flutter run
   ```

## Architecture

The project follows **Clean Architecture** principles:
- **Presentation Layer**: Screens, Widgets, Providers (Riverpod)
- **Domain Layer**: Entities (Models), Repositories (Interfaces), Use cases
- **Data Layer**: Data Sources (Local/Remote), Models (DTOs), Repository Implementations

## Testing

Run tests with:
```bash
flutter test
```
