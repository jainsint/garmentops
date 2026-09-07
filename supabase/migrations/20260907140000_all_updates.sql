-- ─── Migration: All Updates for Jains Int. ───────────────────────────────────
-- Covers items 1-13 from the update request

-- ─── 1. Add photo_url + remarks to all register tables (item 13) ─────────────

ALTER TABLE public.fabric_stock_entries
  ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS remarks_extra TEXT DEFAULT '';

ALTER TABLE public.lay_entries
  ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS remarks TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS colours JSONB DEFAULT '[]'::jsonb;

ALTER TABLE public.cutting_entries
  ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS remarks TEXT DEFAULT '';

ALTER TABLE public.stitching_entries
  ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS remarks TEXT DEFAULT '';

ALTER TABLE public.buttoning_entries
  ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS remarks TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS design_no TEXT DEFAULT '';

ALTER TABLE public.washing_entries
  ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS design_no TEXT DEFAULT '';

ALTER TABLE public.ironing_entries
  ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS remarks TEXT DEFAULT '';

ALTER TABLE public.checking_entries
  ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS remarks TEXT DEFAULT '';

ALTER TABLE public.production_entries
  ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL;

ALTER TABLE public.subcontractor_outbound
  ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL;

ALTER TABLE public.subcontractor_inbound
  ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL;

-- ─── 2. Daily Production Register (item 6a) ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.daily_production_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    style_no TEXT NOT NULL DEFAULT '',
    production_qty INTEGER NOT NULL DEFAULT 0,
    line_number TEXT NOT NULL DEFAULT '',
    remarks TEXT DEFAULT '',
    photo_url TEXT DEFAULT NULL,
    logged_by TEXT NOT NULL DEFAULT 'Staff',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.daily_production_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "open_access_daily_production" ON public.daily_production_entries;
CREATE POLICY "open_access_daily_production"
ON public.daily_production_entries FOR ALL TO public USING (true) WITH CHECK (true);

-- ─── 3. Size-wise Production Register (item 6b) ───────────────────────────────
CREATE TABLE IF NOT EXISTS public.sizewise_production_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID,
    style_no TEXT NOT NULL DEFAULT '',
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE NOT NULL DEFAULT CURRENT_DATE,
    size_quantities JSONB NOT NULL DEFAULT '{}'::jsonb,
    total_pieces INTEGER NOT NULL DEFAULT 0,
    remarks TEXT DEFAULT '',
    photo_url TEXT DEFAULT NULL,
    logged_by TEXT NOT NULL DEFAULT 'Staff',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.sizewise_production_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "open_access_sizewise_production" ON public.sizewise_production_entries;
CREATE POLICY "open_access_sizewise_production"
ON public.sizewise_production_entries FOR ALL TO public USING (true) WITH CHECK (true);

-- ─── 4. Production Planner (item 12) ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.production_planner_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID,
    style_no TEXT NOT NULL DEFAULT '',
    design_no TEXT DEFAULT '',
    allocations JSONB NOT NULL DEFAULT '[]'::jsonb,
    total_allocated INTEGER NOT NULL DEFAULT 0,
    remarks TEXT DEFAULT '',
    photo_url TEXT DEFAULT NULL,
    logged_by TEXT NOT NULL DEFAULT 'Staff',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.production_planner_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "open_access_production_planner" ON public.production_planner_entries;
CREATE POLICY "open_access_production_planner"
ON public.production_planner_entries FOR ALL TO public USING (true) WITH CHECK (true);

-- ─── 5. Indexes ───────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_daily_production_order ON public.daily_production_entries(order_id);
CREATE INDEX IF NOT EXISTS idx_daily_production_date ON public.daily_production_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_sizewise_production_order ON public.sizewise_production_entries(order_id);
CREATE INDEX IF NOT EXISTS idx_production_planner_order ON public.production_planner_entries(order_id);

-- ─── 6. Storage bucket for register photos ────────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('register-photos', 'register-photos', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "open_access_register_photos" ON storage.objects;
CREATE POLICY "open_access_register_photos"
ON storage.objects FOR ALL TO public
USING (bucket_id = 'register-photos')
WITH CHECK (bucket_id = 'register-photos');
