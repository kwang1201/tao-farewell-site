-- ═══════════════════════════════════════════════════════════════
-- Tao Farewell Page — Supabase Schema
-- Run this once in Supabase Studio → SQL Editor
-- Project: bcggwrvmbmbfvwhehtfq (events project — shared with PBK20)
-- ═══════════════════════════════════════════════════════════════

-- ── Photos table ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tao_photos (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  caption     TEXT,
  caption_zh  TEXT,                     -- Chinese translation (auto)
  image_url   TEXT NOT NULL,           -- public URL from Supabase Storage
  storage_path TEXT,                    -- bucket path, for cleanup on delete
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tao_photos_created ON tao_photos (created_at DESC);

-- For existing installs: add the column if it's missing
ALTER TABLE tao_photos ADD COLUMN IF NOT EXISTS caption_zh TEXT;

-- Hide-from-Present flag: hide a photo from the slideshow without deleting it
ALTER TABLE tao_photos ADD COLUMN IF NOT EXISTS hidden_from_present BOOLEAN NOT NULL DEFAULT FALSE;

-- ── Messages table ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tao_messages (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  body        TEXT NOT NULL,
  body_zh     TEXT,                     -- Chinese translation (auto)
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tao_messages_created ON tao_messages (created_at DESC);

-- For existing installs: add the column if it's missing
ALTER TABLE tao_messages ADD COLUMN IF NOT EXISTS body_zh TEXT;

-- ── Row Level Security ───────────────────────────────────────
-- This is a public farewell page — anyone with the link should be able
-- to read, post, and (self-)moderate. RLS is permissive on purpose.

ALTER TABLE tao_photos   ENABLE ROW LEVEL SECURITY;
ALTER TABLE tao_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "tao_photos_select"   ON tao_photos;
DROP POLICY IF EXISTS "tao_photos_insert"   ON tao_photos;
DROP POLICY IF EXISTS "tao_photos_update"   ON tao_photos;
DROP POLICY IF EXISTS "tao_photos_delete"   ON tao_photos;
DROP POLICY IF EXISTS "tao_messages_select" ON tao_messages;
DROP POLICY IF EXISTS "tao_messages_insert" ON tao_messages;
DROP POLICY IF EXISTS "tao_messages_update" ON tao_messages;
DROP POLICY IF EXISTS "tao_messages_delete" ON tao_messages;

CREATE POLICY "tao_photos_select"   ON tao_photos   FOR SELECT USING (true);
CREATE POLICY "tao_photos_insert"   ON tao_photos   FOR INSERT WITH CHECK (true);
CREATE POLICY "tao_photos_update"   ON tao_photos   FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "tao_photos_delete"   ON tao_photos   FOR DELETE USING (true);

CREATE POLICY "tao_messages_select" ON tao_messages FOR SELECT USING (true);
CREATE POLICY "tao_messages_insert" ON tao_messages FOR INSERT WITH CHECK (true);
CREATE POLICY "tao_messages_update" ON tao_messages FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "tao_messages_delete" ON tao_messages FOR DELETE USING (true);

-- ── Storage bucket for photo files ───────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('tao-photos', 'tao-photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Storage policies (bucket-scoped)
DROP POLICY IF EXISTS "tao_photos_storage_select" ON storage.objects;
DROP POLICY IF EXISTS "tao_photos_storage_insert" ON storage.objects;
DROP POLICY IF EXISTS "tao_photos_storage_delete" ON storage.objects;

CREATE POLICY "tao_photos_storage_select"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'tao-photos');

CREATE POLICY "tao_photos_storage_insert"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'tao-photos');

CREATE POLICY "tao_photos_storage_delete"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'tao-photos');

-- ═══════════════════════════════════════════════════════════════
-- Verify: SELECT count(*) FROM tao_photos; SELECT count(*) FROM tao_messages;
-- ═══════════════════════════════════════════════════════════════
