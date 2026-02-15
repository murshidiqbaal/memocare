# Caregiver System - MemoCare

This module provides a production-grade Caregiver management system, including profile management and patient connection workflows.

## 📁 Architecture

- **Models**: `Caregiver`, `Patient` (minimal read-only)
- **Repositories**: `CaregiverRepository`, `PatientConnectionRepository`
- **State Management**: Riverpod (`caregiverProfileProvider`, `caregiverPatientsProvider`)
- **Database**: Supabase with Row Level Security (RLS)

## 🚀 Key Features

### 1. Caregiver Profile
- **View Profile**: Large avatar, info cards, and quick stats.
- **Edit Profile**: Image picker, relationship settings, and notification toggle.
- **Photo Upload**: Securely uploads to Supabase Storage bucket `caregiver-avatars`.

### 2. Patient Connection (Invite System)
- **Invite Based Linking**: Patients generate codes, caregivers enter them.
- **Multi-Patient Support**: A single caregiver can monitor multiple patients.
- **Real-time Ready**: Refresh logic built into providers.
- **Security**: Granular RLS policies ensure caregivers only access their linked patients.

## 🛠 Setup

### 1. Database Migrations
Run the SQL script `supabase_migrations/complete_schema.sql` (if not already run).

### 2. Code Generation
Run the following command to generate model code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🔐 Security (RLS)
The system uses strict RLS policies:
- **Caregivers**: Can only read/update their own profile.
- **Links**: Can only be created using a valid, non-expired, unused invite code.
- **Patient Data**: Caregivers can ONLY see patient profiles for patients they are linked to.

## 🎨 UI/UX
- **Colors**: Calm teal healthcare palette.
- **Accessibility**: Large touch targets (>=48px) and high-contrast typography.
- **Transitions**: Smooth Hero animations for profile photos.
