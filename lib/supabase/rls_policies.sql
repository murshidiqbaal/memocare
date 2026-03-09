-- =============================================================================
-- MemoCare — Definitive Non-Recursive RLS Policies
-- Execute this entire script in the Supabase SQL Editor.
-- =============================================================================

-- ─── 0. Enable RLS ────────────────────────────────────────────────────────
ALTER TABLE public.patients                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregiver_profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregiver_patient_links ENABLE ROW LEVEL SECURITY;

-- ─── 1. Reset Policies ────────────────────────────────────────────────────
-- This loop drops all EXISTING policies to clear the "recursion" error state.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public' 
              AND tablename IN ('patients', 'caregiver_profiles', 'caregiver_patient_links'))
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
    END LOOP;
END $$;

-- ─── 2. caregiver_profiles (The Anchor) ───────────────────────────────────
-- These policies never reference other tables, so they can't cause recursion.
CREATE POLICY "caregiver_profiles_select_own" ON public.caregiver_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "caregiver_profiles_insert_own" ON public.caregiver_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "caregiver_profiles_update_own" ON public.caregiver_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "caregiver_profiles_delete_own" ON public.caregiver_profiles
    FOR DELETE USING (auth.uid() = user_id);

-- ─── Helper Functions to Break RLS Recursion ──────────────────────────────
-- By using SECURITY DEFINER, these functions bypass RLS and prevent infinite loops.

CREATE OR REPLACE FUNCTION get_my_caregiver_id()
RETURNS uuid
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $$
    SELECT id FROM caregiver_profiles WHERE user_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION get_my_patient_id()
RETURNS uuid
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $$
    SELECT id FROM patients WHERE user_id = auth.uid() LIMIT 1;
$$;

-- ─── 3. caregiver_patient_links ───────────────────────────────────────────
-- Non-recursive: subqueries utilize the security definer functions above.
CREATE POLICY "cpl_caregiver_all" ON public.caregiver_patient_links
    FOR ALL USING (
        caregiver_id = get_my_caregiver_id()
    );

CREATE POLICY "cpl_patient_select" ON public.caregiver_patient_links
    FOR SELECT USING (
        patient_id = get_my_patient_id()
    );

-- ─── 4. patients ──────────────────────────────────────────────────────────
-- Patient: full access to own data (no joins).
CREATE POLICY "patients_self_all" ON public.patients
    FOR ALL USING (auth.uid() = user_id);

-- Caregiver: read-only access to LINKED patients.
-- NON-RECURSIVE: uses security definer function to avoid querying caregiver_profiles with RLS.
CREATE POLICY "patients_linked_caregiver_read" ON public.patients
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.caregiver_patient_links cpl
            WHERE cpl.patient_id = patients.id
              AND cpl.caregiver_id = get_my_caregiver_id()
        )
    );

-- ─── 5. Performance Indexes ───────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_caregiver_profiles_user_id ON public.caregiver_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_patients_user_id           ON public.patients(user_id);
CREATE INDEX IF NOT EXISTS idx_cpl_caregiver_id           ON public.caregiver_patient_links(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_cpl_patient_id             ON public.caregiver_patient_links(patient_id);
