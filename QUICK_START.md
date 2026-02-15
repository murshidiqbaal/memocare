# 🚀 PROFILE PHOTO UPLOAD - QUICK START GUIDE

## ⚡ 5-Minute Setup

### 1️⃣ Supabase Configuration (2 minutes)

#### A. Create Storage Bucket
1. Go to Supabase Dashboard → Storage
2. Click "New Bucket"
3. Name: `profile-photos`
4. Public: ✅ **Enabled**
5. Click "Create Bucket"

#### B. Set Storage Policies
Go to Storage → profile-photos → Policies → New Policy

**Policy 1: Patient Upload**
```sql
CREATE POLICY "Patients can upload own photo"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-photos' AND
  (storage.foldername(name))[1] = 'patients' AND
  (storage.foldername(name))[2] = auth.uid()::text
);
```

**Policy 2: Caregiver Upload**
```sql
CREATE POLICY "Caregivers can upload own photo"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-photos' AND
  (storage.foldername(name))[1] = 'caregivers' AND
  (storage.foldername(name))[2] = auth.uid()::text
);
```

**Policy 3: Public Read**
```sql
CREATE POLICY "Anyone can view photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-photos');
```

#### C. Verify Database Columns
Go to Database → Tables

**patients table:**
```sql
-- Should already exist, but verify:
ALTER TABLE patients 
ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;
```

**caregiver_profiles table:**
```sql
-- Should already exist, but verify:
ALTER TABLE caregiver_profiles 
ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;
```

---

### 2️⃣ Flutter Dependencies (1 minute)

The dependency has already been added! Verify in `pubspec.yaml`:

```yaml
dependencies:
  image_picker: ^latest
```

If not present, run:
```bash
flutter pub add image_picker
flutter pub get
```

---

### 3️⃣ Test the Feature (2 minutes)

#### Patient Profile Upload
```bash
# 1. Run the app
flutter run

# 2. Login as a patient
# 3. Navigate to Profile screen
# 4. Tap the avatar (large circle with camera icon)
# 5. Select an image from gallery
# 6. Wait for upload (spinner appears)
# 7. ✅ Avatar updates instantly!
```

#### Caregiver Profile Upload
```bash
# 1. Login as a caregiver
# 2. Navigate to Profile screen
# 3. Tap the avatar
# 4. Select an image
# 5. ✅ Avatar updates instantly!
```

---

## 🎯 Usage Examples

### Basic Usage (Already Integrated)

The upload system is **already integrated** into both profile screens. Just tap the avatar!

### Custom Implementation

If you want to add upload to another screen:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/editable_avatar.dart';
import '../providers/profile_photo_provider.dart';

class MyCustomScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(profilePhotoUploadProvider);
    final isUploading = uploadState is AsyncLoading;
    
    return Scaffold(
      body: Center(
        child: EditableAvatar(
          profilePhotoUrl: 'https://example.com/photo.jpg',
          isUploading: isUploading,
          radius: 70,
          onTap: () async {
            await ref.read(profilePhotoUploadProvider.notifier).pickAndUpload();
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✓ Photo uploaded!')),
            );
          },
        ),
      ),
    );
  }
}
```

---

## 🔍 Verify Upload

### Check Supabase Storage
1. Go to Supabase Dashboard → Storage → profile-photos
2. Navigate to:
   - `patients/{userId}/profile.jpg` (for patient)
   - `caregivers/{userId}/profile.jpg` (for caregiver)
3. ✅ Image should be visible

### Check Database
1. Go to Database → Table Editor
2. Select `patients` or `caregiver_profiles` table
3. Find your user's row
4. Check `profile_photo_url` column
5. ✅ Should contain URL like: `https://...profile.jpg?t=1234567890`

---

## 🐛 Troubleshooting

### Issue: "Permission denied" error
**Solution**: 
1. Check Supabase Storage policies are created
2. Verify user is authenticated
3. Check folder path matches user role

### Issue: Image doesn't update after upload
**Solution**:
1. Check cache-busting timestamp in URL
2. Verify `ref.invalidate()` is called
3. Check network connection

### Issue: Upload is slow
**Solution**:
1. Image is automatically compressed to 70% quality
2. Max dimensions: 1024x1024
3. Check network speed

### Issue: Gallery doesn't open
**Solution**:
1. Check gallery permissions on device
2. Verify `image_picker` package is installed
3. Check device has images in gallery

---

## 📱 Platform-Specific Setup

### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to upload profile pictures</string>
```

---

## ✅ Success Checklist

After setup, verify:

- [ ] Supabase bucket `profile-photos` exists and is public
- [ ] Storage RLS policies are created
- [ ] Database columns exist
- [ ] `image_picker` dependency is installed
- [ ] Patient can upload photo
- [ ] Caregiver can upload photo
- [ ] Photos appear in Supabase Storage
- [ ] URLs saved in database
- [ ] UI updates instantly
- [ ] No errors in console

---

## 🎉 You're Done!

The profile photo upload system is now **fully operational**!

**What works:**
✅ Patient profile photo upload  
✅ Caregiver profile photo upload  
✅ Instant UI refresh  
✅ Supabase Storage integration  
✅ Database persistence  
✅ Loading states  
✅ Error handling  
✅ Healthcare-grade UX  

**Need help?** Check:
- `PROFILE_PHOTO_UPLOAD.md` - Complete documentation
- `IMPLEMENTATION_COMPLETE.md` - Verification checklist
- `lib/examples/profile_photo_upload_examples.dart` - Code examples
- `test/profile_photo_upload_test.dart` - Testing guide

---

**Happy coding! 🚀**
