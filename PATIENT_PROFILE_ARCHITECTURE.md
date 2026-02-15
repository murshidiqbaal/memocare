# Patient Profile System - Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          PATIENT PROFILE SYSTEM                          │
│                         MemoCare - Flutter + Supabase                    │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                              UI LAYER                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────┐      ┌──────────────────────────┐        │
│  │ PatientProfileScreen     │      │ EditPatientProfileScreen │        │
│  │ (View Only)              │◄─────┤ (Create/Edit)            │        │
│  ├──────────────────────────┤      ├──────────────────────────┤        │
│  │ • Hero Avatar            │      │ • Image Picker           │        │
│  │ • Completion Progress    │      │ • Form Validation        │        │
│  │ • Info Cards             │      │ • Date Picker            │        │
│  │ • Caregiver Links        │      │ • Gender Dropdown        │        │
│  │ • Settings               │      │ • Save/Cancel            │        │
│  └──────────────────────────┘      └──────────────────────────┘        │
│           │                                    │                         │
│           └────────────────┬───────────────────┘                         │
│                            ▼                                             │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         STATE MANAGEMENT LAYER                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │ PatientProfileViewModel (Riverpod StateNotifier)             │      │
│  ├──────────────────────────────────────────────────────────────┤      │
│  │ State: AsyncValue<PatientProfile?>                           │      │
│  │                                                               │      │
│  │ Methods:                                                      │      │
│  │ • loadProfile()          → Fetch profile                     │      │
│  │ • updateProfile()        → Save changes                      │      │
│  │ • updateProfileImage()   → Upload & update avatar            │      │
│  └──────────────────────────────────────────────────────────────┘      │
│           │                                                              │
│           ▼                                                              │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                          REPOSITORY LAYER                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │ PatientProfileRepository                                     │      │
│  ├──────────────────────────────────────────────────────────────┤      │
│  │ Dependencies:                                                 │      │
│  │ • SupabaseClient                                             │      │
│  │ • Hive Box<PatientProfile>                                   │      │
│  │                                                               │      │
│  │ Methods:                                                      │      │
│  │ • getProfile(userId)                                         │      │
│  │   └─► 1. Check Hive cache                                   │      │
│  │   └─► 2. Fetch from Supabase (profiles + patients)          │      │
│  │   └─► 3. Merge data                                          │      │
│  │   └─► 4. Update cache                                        │      │
│  │                                                               │      │
│  │ • updateProfile(profile)                                     │      │
│  │   └─► 1. Save to Hive (optimistic)                          │      │
│  │   └─► 2. Update Supabase (patients + profiles)              │      │
│  │   └─► 3. Mark as synced                                      │      │
│  │                                                               │      │
│  │ • uploadProfileImage(userId, file)                           │      │
│  │   └─► 1. Upload to Supabase Storage                         │      │
│  │   └─► 2. Return public URL                                   │      │
│  │                                                               │      │
│  │ • syncPendingProfiles()                                      │      │
│  │   └─► Background sync for offline changes                    │      │
│  └──────────────────────────────────────────────────────────────┘      │
│           │                                                              │
│           ▼                                                              │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                           DATA LAYER                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────┐              ┌─────────────────────┐          │
│  │ LOCAL STORAGE       │              │ REMOTE STORAGE      │          │
│  │ (Hive)              │              │ (Supabase)          │          │
│  ├─────────────────────┤              ├─────────────────────┤          │
│  │                     │              │                     │          │
│  │ Box: patient_       │◄────sync────►│ Table: patients     │          │
│  │      profiles       │              │ • id (PK)           │          │
│  │                     │              │ • date_of_birth     │          │
│  │ Model:              │              │ • gender            │          │
│  │ PatientProfile      │              │ • medical_notes     │          │
│  │ @HiveType(typeId:8) │              │ • emergency_*       │          │
│  │                     │              │ • profile_photo_url │          │
│  │ Fields:             │              │ • created_at        │          │
│  │ • id                │              │ • updated_at        │          │
│  │ • fullName          │              │                     │          │
│  │ • dateOfBirth       │              │ Table: profiles     │          │
│  │ • gender            │              │ • id (PK)           │          │
│  │ • phoneNumber       │              │ • full_name         │          │
│  │ • address           │              │ • phone_number      │          │
│  │ • emergency_*       │              │ • role              │          │
│  │ • medicalNotes      │              │                     │          │
│  │ • profileImageUrl   │              │ Bucket:             │          │
│  │ • isSynced ⚡       │              │ patient-avatars     │          │
│  │                     │              │ • Public read       │          │
│  └─────────────────────┘              │ • User upload       │          │
│                                        └─────────────────────┘          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                          SECURITY LAYER                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │ ROW LEVEL SECURITY (RLS) POLICIES                            │      │
│  ├──────────────────────────────────────────────────────────────┤      │
│  │                                                               │      │
│  │ PATIENTS TABLE:                                              │      │
│  │ ✓ Patients can view own profile (auth.uid() = id)           │      │
│  │ ✓ Patients can update own profile                           │      │
│  │ ✓ Patients can insert own profile                           │      │
│  │ ✓ Linked caregivers can view patient profile                │      │
│  │ ✓ Linked caregivers can update medical info                 │      │
│  │                                                               │      │
│  │ STORAGE (patient-avatars):                                   │      │
│  │ ✓ Patients can upload own avatar                            │      │
│  │ ✓ Patients can update own avatar                            │      │
│  │ ✓ Patients can delete own avatar                            │      │
│  │ ✓ Public read access for all avatars                        │      │
│  └──────────────────────────────────────────────────────────────┘      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         UTILITY LAYER                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │ ProfileCompletionHelper                                      │      │
│  ├──────────────────────────────────────────────────────────────┤      │
│  │ • calculateCompletion(profile) → 0-100%                      │      │
│  │ • getCompletionMessage(%) → "Almost there!"                 │      │
│  │ • getMissingFields(profile) → ["DOB", "Gender"]             │      │
│  │ • hasCriticalInfo(profile) → bool (emergency contact)       │      │
│  └──────────────────────────────────────────────────────────────┘      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                          DATA FLOW                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  READ FLOW (Offline-First):                                             │
│  ┌─────┐    ┌──────┐    ┌──────────┐    ┌──────────┐                  │
│  │ UI  │───►│ VM   │───►│ Repo     │───►│ Hive     │ (instant)         │
│  └─────┘    └──────┘    └──────────┘    └──────────┘                  │
│                              │                                           │
│                              ▼                                           │
│                         ┌──────────┐                                    │
│                         │ Supabase │ (background refresh)               │
│                         └──────────┘                                    │
│                                                                          │
│  WRITE FLOW (Optimistic):                                               │
│  ┌─────┐    ┌──────┐    ┌──────────┐    ┌──────────┐                  │
│  │ UI  │───►│ VM   │───►│ Repo     │───►│ Hive     │ (immediate)       │
│  └─────┘    └──────┘    └──────────┘    └──────────┘                  │
│                              │                 │                         │
│                              ▼                 │                         │
│                         ┌──────────┐           │                         │
│                         │ Supabase │◄──────────┘ (background sync)      │
│                         └──────────┘                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                       KEY FEATURES                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ✅ Offline-First Architecture    ✅ Hero Animations                    │
│  ✅ Real-time Sync                 ✅ Profile Completion %               │
│  ✅ Row Level Security             ✅ Elder-Friendly UI                  │
│  ✅ Image Upload                   ✅ Role-Based Access                  │
│  ✅ Form Validation                ✅ Error Handling                     │
│  ✅ Loading States                 ✅ Success Feedback                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                       PRODUCTION READY ✅                                │
└─────────────────────────────────────────────────────────────────────────┘
```

## Architecture Principles

### 1. **Separation of Concerns**
- UI Layer: Presentation only
- ViewModel: State management
- Repository: Data operations
- Model: Data structure

### 2. **Offline-First**
- Local cache (Hive) for instant UI
- Background sync to Supabase
- Optimistic updates
- Conflict resolution

### 3. **Security by Default**
- RLS on all tables
- Storage bucket policies
- No direct SQL in UI
- Role-based permissions

### 4. **User Experience**
- Loading states
- Error handling
- Success feedback
- Smooth animations

### 5. **Scalability**
- Clean architecture
- Dependency injection
- Feature-based structure
- Testable components

---

**Built for MemoCare - Dementia Care Application**
