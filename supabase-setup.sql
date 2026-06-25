-- =====================================================
-- SUPPORTIVE GUARDIANS - SUPABASE SETUP
-- Run this SQL in your Supabase project's SQL editor
-- =====================================================

-- 1. CREATE PROFILES TABLE
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 2. CREATE SESSIONS TABLE
CREATE TABLE IF NOT EXISTS sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  practitioner_id UUID,
  title TEXT NOT NULL,
  description TEXT,
  starts_at TIMESTAMP WITH TIME ZONE NOT NULL,
  duration_minutes INTEGER DEFAULT 60,
  mode TEXT CHECK (mode IN ('online', 'in_person')) DEFAULT 'online',
  join_url TEXT,
  status TEXT CHECK (status IN ('scheduled', 'completed', 'cancelled')) DEFAULT 'scheduled',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 3. CREATE MESSAGES TABLE
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  practitioner_id UUID,
  sender TEXT CHECK (sender IN ('client', 'practitioner')) NOT NULL,
  body TEXT NOT NULL,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 4. CREATE RESOURCES TABLE
CREATE TABLE IF NOT EXISTS resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  kind TEXT CHECK (kind IN ('pdf', 'worksheet', 'audio', 'guide', 'other')) DEFAULT 'pdf',
  file_path TEXT,
  shared_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;

-- PROFILES: Users can view and update their own profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- SESSIONS: Clients can view their sessions
CREATE POLICY "Clients can view own sessions" ON sessions
  FOR SELECT USING (auth.uid() = client_id);

CREATE POLICY "Clients can update own sessions" ON sessions
  FOR UPDATE USING (auth.uid() = client_id);

-- MESSAGES: Clients can view and send their own messages
CREATE POLICY "Clients can view own messages" ON messages
  FOR SELECT USING (auth.uid() = client_id);

CREATE POLICY "Clients can insert own messages" ON messages
  FOR INSERT WITH CHECK (auth.uid() = client_id AND sender = 'client');

CREATE POLICY "Clients can update own messages" ON messages
  FOR UPDATE USING (auth.uid() = client_id AND sender = 'client');

-- RESOURCES: Clients can view their shared resources
CREATE POLICY "Clients can view own resources" ON resources
  FOR SELECT USING (auth.uid() = client_id);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX idx_sessions_client_id ON sessions(client_id);
CREATE INDEX idx_sessions_starts_at ON sessions(starts_at);
CREATE INDEX idx_messages_client_id ON messages(client_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_resources_client_id ON resources(client_id);

-- =====================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================

-- Note: Replace 'your-user-id-here' with actual user IDs from your auth.users table
-- You can find these in Supabase → Authentication → Users

-- INSERT INTO profiles (id, email, full_name, phone)
-- VALUES ('your-user-id-here', 'client@example.com', 'Rachel Adeyemi', '+44 7900 123456')
-- ON CONFLICT (id) DO NOTHING;

-- INSERT INTO sessions (client_id, title, starts_at, mode, status)
-- VALUES 
--   ('your-user-id-here', '1-to-1 talking support', NOW() + INTERVAL '3 days' AT TIME ZONE 'Europe/London', 'online', 'scheduled'),
--   ('your-user-id-here', '1-to-1 talking support', NOW() + INTERVAL '10 days' AT TIME ZONE 'Europe/London', 'online', 'scheduled')
-- ON CONFLICT DO NOTHING;

-- INSERT INTO messages (client_id, sender, body)
-- VALUES ('your-user-id-here', 'practitioner', 'Hi there — lovely speaking last week. I''ve added a grounding exercise to your resources.');

-- =====================================================
-- STORAGE SETUP (For Resources)
-- =====================================================

-- Create a bucket for resources in Supabase Storage:
-- 1. Go to Supabase Dashboard → Storage
-- 2. Click "New bucket" → name it "resources"
-- 3. Make it Private (not Public)
-- 4. This is referenced in the code as: sb.storage.from('resources')

-- =====================================================
-- IMPORTANT NOTES
-- =====================================================
-- 
-- 1. RLS is ENABLED - All direct database access is restricted
-- 2. Users can only see/edit their own data
-- 3. File uploads to "resources" bucket use the same auth check
-- 4. Update the sample data with real user IDs from your auth.users table
-- 5. Set up email templates in Supabase for password resets and confirmations
-- 6. In your Supabase project settings:
--    - Enable email provider
--    - Configure SMTP or use Supabase's email service
--    - Set email templates (confirmation, password reset, magic link)
