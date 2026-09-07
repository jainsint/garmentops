-- GarmentOps Register Tables Migration
-- All register modules: cutting, production, lay, ironing, checking

-- ─── Cutting Register ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.cutting_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    style_no TEXT NOT NULL,
    color TEXT NOT NULL,
    design_no TEXT NOT NULL,
    avg_consumption TEXT,
    size_s INTEGER DEFAULT 0,
    size_m INTEGER DEFAULT 0,
    size_l INTEGER DEFAULT 0,
    size_xl INTEGER DEFAULT 0,
    size_2xl INTEGER DEFAULT 0,
    size_3xl INTEGER DEFAULT 0,
    size_4xl INTEGER DEFAULT 0,
    size_5xl INTEGER DEFAULT 0,
    size_6xl INTEGER DEFAULT 0,
    total INTEGER DEFAULT 0,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ─── Production Register ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.production_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    style_no TEXT NOT NULL,
    color TEXT NOT NULL,
    line_no TEXT NOT NULL,
    operation TEXT,
    target_qty INTEGER DEFAULT 0,
    achieved_qty INTEGER DEFAULT 0,
    efficiency NUMERIC(5,2) DEFAULT 0,
    operator_name TEXT,
    remarks TEXT,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ─── Lay Register ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.lay_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    style_no TEXT NOT NULL,
    color TEXT,
    fabric_type TEXT,
    lay_length NUMERIC(8,2),
    no_of_plies INTEGER DEFAULT 0,
    total_meters NUMERIC(8,2),
    remarks TEXT,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ─── Ironing Register ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ironing_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    style_no TEXT NOT NULL,
    iron_type TEXT NOT NULL,
    quantity INTEGER DEFAULT 0,
    representative TEXT NOT NULL,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ─── Checking Register ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.checking_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    style_no TEXT NOT NULL,
    check_type TEXT NOT NULL,
    quantity INTEGER DEFAULT 0,
    representative TEXT NOT NULL,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ─── Indexes ─────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_cutting_entries_style_no ON public.cutting_entries(style_no);
CREATE INDEX IF NOT EXISTS idx_cutting_entries_entry_date ON public.cutting_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_production_entries_style_no ON public.production_entries(style_no);
CREATE INDEX IF NOT EXISTS idx_production_entries_entry_date ON public.production_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_lay_entries_style_no ON public.lay_entries(style_no);
CREATE INDEX IF NOT EXISTS idx_ironing_entries_style_no ON public.ironing_entries(style_no);
CREATE INDEX IF NOT EXISTS idx_ironing_entries_entry_date ON public.ironing_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_checking_entries_style_no ON public.checking_entries(style_no);
CREATE INDEX IF NOT EXISTS idx_checking_entries_entry_date ON public.checking_entries(entry_date);

-- ─── Enable RLS ──────────────────────────────────────────────────────────────
ALTER TABLE public.cutting_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.production_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lay_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ironing_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checking_entries ENABLE ROW LEVEL SECURITY;

-- ─── RLS Policies (open access for factory floor multi-device use) ────────────
-- All authenticated users can read/write all register entries (factory floor workers)

DROP POLICY IF EXISTS "open_access_cutting_entries" ON public.cutting_entries;
CREATE POLICY "open_access_cutting_entries"
ON public.cutting_entries FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "open_access_production_entries" ON public.production_entries;
CREATE POLICY "open_access_production_entries"
ON public.production_entries FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "open_access_lay_entries" ON public.lay_entries;
CREATE POLICY "open_access_lay_entries"
ON public.lay_entries FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "open_access_ironing_entries" ON public.ironing_entries;
CREATE POLICY "open_access_ironing_entries"
ON public.ironing_entries FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "open_access_checking_entries" ON public.checking_entries;
CREATE POLICY "open_access_checking_entries"
ON public.checking_entries FOR ALL TO public USING (true) WITH CHECK (true);
