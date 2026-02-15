# 🚀 Quick Start Guide - Patient Profile System

## Prerequisites
- Flutter SDK 3.2.0+
- Supabase project set up
- MemoCare app configured

## Step-by-Step Setup

### 1. Generate Code (Required)
```bash
cd d:\vscode\GTech\MemoCare\memocare
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `patient_profile.g.dart` (JSON serialization)
- Hive adapters

### 2. Apply Database Migration

**Option A: Supabase Dashboard**
1. Open Supabase Dashboard → SQL Editor
2. Copy contents from `supabase_migrations/patient_profile_complete.sql`
3. Execute the SQL

**Option B: Supabase CLI**
```bash
supabase db push supabase_migrations/patient_profile_complete.sql
```

### 3. Verify Database Setup

Run these queries in Supabase SQL Editor:

```sql
-- Check patients table
SELECT * FROM public.patients LIMIT 1;

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'patients';

-- Check storage bucket
SELECT * FROM storage.buckets WHERE id = 'patient-avatars';
```

### 4. Test the Implementation

**A. View Profile**
```dart
// In your navigation code
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PatientProfileScreen(),
  ),
);
```

**B. Create Profile (First Time)**
1. Launch app as patient
2. Navigate to profile
3. Click "Create Profile"
4. Fill in details
5. Upload photo (optional)
6. Click "CREATE PROFILE"

**C. Edit Profile**
1. View profile screen
2. Click edit icon (top right)
3. Modify fields
4. Click "SAVE CHANGES"

### 5. Test Offline Mode

1. Enable airplane mode
2. Edit profile
3. Verify changes save locally
4. Disable airplane mode
5. Verify sync to Supabase

## Common Commands

### Rebuild Generated Files
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run App
```bash
flutter run
```

## Troubleshooting

### Error: "No profile found"
**Cause**: User doesn't have a patient profile in database
**Fix**: 
1. Check if user is authenticated
2. Verify user role is 'patient'
3. Check if trigger created profile on signup
4. Manually create profile via edit screen

### Error: "Image upload failed"
**Cause**: Storage bucket not configured or RLS policy missing
**Fix**:
1. Verify bucket exists: `SELECT * FROM storage.buckets WHERE id = 'patient-avatars';`
2. Check RLS policies on `storage.objects`
3. Verify user has permission to upload

### Error: "Profile not syncing"
**Cause**: Network issue or RLS policy blocking update
**Fix**:
1. Check internet connection
2. Verify RLS policies allow update
3. Check Supabase logs for errors

### Error: "Build runner fails"
**Cause**: Missing dependencies or conflicting files
**Fix**:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## File Locations

```
Key Files:
├── lib/screens/patient/profile/
│   ├── patient_profile_screen.dart       ← View screen
│   └── edit_patient_profile_screen.dart  ← Edit screen
├── lib/data/repositories/
│   └── patient_profile_repository.dart   ← Data layer
├── lib/core/utils/
│   └── profile_completion_helper.dart    ← Utilities
└── supabase_migrations/
    └── patient_profile_complete.sql      ← Database setup
```

## Next Steps

1. ✅ Run code generation
2. ✅ Apply database migration
3. ✅ Test create profile flow
4. ✅ Test edit profile flow
5. ✅ Test image upload
6. ✅ Test offline mode
7. ✅ Test caregiver access

## Support

For issues or questions:
1. Check `PATIENT_PROFILE_README.md` for detailed documentation
2. Review `PATIENT_PROFILE_IMPLEMENTATION.md` for implementation details
3. Check Supabase logs for backend errors
4. Review Flutter console for client errors

---

**Ready to go!** 🎉

Your Patient Profile system is production-ready and fully integrated with the MemoCare application.
