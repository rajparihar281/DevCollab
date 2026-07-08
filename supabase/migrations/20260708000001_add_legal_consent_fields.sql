-- Migration: Add Legal Consent & Policy Acceptance Proof to Profiles Table
-- Stores explicit timestamps and consent flag for legal proof & audit records.

alter table public.profiles
add column if not exists terms_accepted_at timestamptz,
add column if not exists privacy_accepted_at timestamptz,
add column if not exists consent_given boolean default true;
