-- Migration Step 1: Add 'deleted' to item_status ENUM type
-- This must be executed FIRST and committed before running step 2
-- Only needed if you're using ENUM type for status column

-- Add 'deleted' to item_status ENUM type
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'item_status') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_enum 
      WHERE enumlabel = 'deleted' 
      AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'item_status')
    ) THEN
      ALTER TYPE item_status ADD VALUE 'deleted';
    END IF;
  END IF;
END $$;

