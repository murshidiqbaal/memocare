-- =====================================================
-- CORE SCHEMA REDESIGN V2
-- =====================================================

-- 1. Profiles Table (Extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    role TEXT CHECK (role IN ('patient', 'caregiver', 'admin')) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Patients Table
CREATE TABLE IF NOT EXISTS public.patients (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    condition_details TEXT,
    emergency_contact TEXT
);

-- 3. Caregivers Table
CREATE TABLE IF NOT EXISTS public.caregivers (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    specialization TEXT,
    years_of_experience INTEGER
);

-- 4. Caregiver-Patient Links
CREATE TABLE IF NOT EXISTS public.caregiver_patient_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    caregiver_id UUID NOT NULL REFERENCES public.caregivers(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    relationship TEXT,
    linked_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(caregiver_id, patient_id)
);

-- 5. Safe Zones (Circular Geofences)
CREATE TABLE IF NOT EXISTS public.patient_home_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    radius_meters INTEGER NOT NULL,
    label TEXT DEFAULT 'Home',
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(patient_id)
);

-- 6. Location Change Requests
CREATE TABLE IF NOT EXISTS public.location_change_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    requested_latitude DOUBLE PRECISION NOT NULL,
    requested_longitude DOUBLE PRECISION NOT NULL,
    requested_radius_meters INTEGER NOT NULL,
    status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT now(),
    reviewed_at TIMESTAMPTZ,
    rejection_reason TEXT
);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregiver_patient_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_home_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_change_requests ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can see all profiles (needed for search), only edit their own
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Safe Zones: Patient see own, Caregiver see linked patients
CREATE POLICY "Patients view own safe zone" ON public.patient_home_locations FOR SELECT USING (auth.uid() = patient_id);
CREATE POLICY "Caregivers view linked safe zones" ON public.patient_home_locations FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.caregiver_patient_links 
        WHERE caregiver_id = auth.uid() AND patient_id = public.patient_home_locations.patient_id
    )
);

-- Requests: Patient create/view own, Caregiver view/update linked
CREATE POLICY "Patients manage own requests" ON public.location_change_requests 
FOR ALL USING (auth.uid() = patient_id);

CREATE POLICY "Caregivers manage linked requests" ON public.location_change_requests 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.caregiver_patient_links 
        WHERE caregiver_id = auth.uid() AND patient_id = public.location_change_requests.patient_id
    )
);
