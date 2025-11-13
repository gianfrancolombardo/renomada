-- Create location_logs table for tracking all location-related events
CREATE TABLE IF NOT EXISTS location_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Event information
  event_type TEXT NOT NULL, -- 'permission_check', 'permission_request', 'permission_granted', 'permission_denied', 'permission_permanently_denied', 'gps_check', 'gps_disabled', 'location_request', 'location_success', 'location_error', 'location_timeout', 'settings_opened', 'permission_changed'
  action TEXT NOT NULL, -- 'check_permission', 'request_permission', 'get_location', 'open_settings', 'initialize', 'refresh'
  
  -- Status information
  permission_status TEXT, -- 'granted', 'denied', 'permanently_denied', 'restricted', 'limited' (iOS)
  gps_enabled BOOLEAN,
  location_obtained BOOLEAN DEFAULT FALSE,
  
  -- Location data (if obtained)
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  accuracy DOUBLE PRECISION, -- in meters
  altitude DOUBLE PRECISION,
  heading DOUBLE PRECISION,
  speed DOUBLE PRECISION,
  
  -- Error information
  error_code TEXT, -- 'gps_disabled', 'permission_denied', 'timeout', 'no_signal', 'low_accuracy', 'save_failed'
  error_message TEXT,
  error_details JSONB, -- Additional error context
  
  -- Context information
  platform TEXT, -- 'web', 'android', 'ios'
  user_agent TEXT,
  session_id TEXT, -- To group related events
  
  -- Metadata
  metadata JSONB, -- Additional context like accuracy level requested, timeout duration, etc.
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_location_logs_user_id ON location_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_location_logs_created_at ON location_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_location_logs_event_type ON location_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_location_logs_session_id ON location_logs(session_id);

-- Enable RLS
ALTER TABLE location_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see their own logs
CREATE POLICY "Users can view their own location logs"
  ON location_logs
  FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own logs
CREATE POLICY "Users can insert their own location logs"
  ON location_logs
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own logs (for session tracking)
CREATE POLICY "Users can update their own location logs"
  ON location_logs
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Add comment to table
COMMENT ON TABLE location_logs IS 'Tracks all location-related events and user interactions for debugging and analytics';
COMMENT ON COLUMN location_logs.event_type IS 'Type of event that occurred';
COMMENT ON COLUMN location_logs.action IS 'Action that triggered the event';
COMMENT ON COLUMN location_logs.session_id IS 'Groups related events in a single session';
COMMENT ON COLUMN location_logs.error_details IS 'Additional error context as JSON';
COMMENT ON COLUMN location_logs.metadata IS 'Additional context like accuracy level, timeout, etc.';

