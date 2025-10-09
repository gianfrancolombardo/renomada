-- Migration: Add has_seen_onboarding to profiles
-- Execute this in Supabase SQL Editor

-- Add column to track if user has seen onboarding
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS has_seen_onboarding boolean DEFAULT false;

-- Update existing users so they don't see onboarding
-- (only new users will see it)
UPDATE public.profiles 
SET has_seen_onboarding = true 
WHERE has_seen_onboarding IS NULL OR has_seen_onboarding = false;

-- Verify migration
SELECT user_id, username, has_seen_onboarding 
FROM public.profiles 
LIMIT 5;

