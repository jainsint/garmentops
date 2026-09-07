-- Subcontractor Register Migration
-- Creates outbound and inbound tables for tracking subcontractor work

-- ─── Outbound Entries ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.subcontractor_outbound (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subcontractor_name TEXT NOT NULL,
    order_id UUID,
    style TEXT NOT NULL DEFAULT '',
    sub_type TEXT NOT NULL DEFAULT 'Cutting',
    no_of_pieces INTEGER NOT NULL DEFAULT 0,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    logged_by TEXT NOT NULL DEFAULT 'Staff',
    remarks TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ─── Inbound Entries ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.subcontractor_inbound (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subcontractor_name TEXT NOT NULL,
    order_id UUID,
    style TEXT NOT NULL DEFAULT '',
    sub_type TEXT NOT NULL DEFAULT 'Cutting',
    no_of_pieces INTEGER NOT NULL DEFAULT 0,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    logged_by TEXT NOT NULL DEFAULT 'Staff',
    remarks TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ─── Indexes ──────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_subcontractor_outbound_order ON public.subcontractor_outbound(order_id);
CREATE INDEX IF NOT EXISTS idx_subcontractor_outbound_name ON public.subcontractor_outbound(subcontractor_name);
CREATE INDEX IF NOT EXISTS idx_subcontractor_inbound_order ON public.subcontractor_inbound(order_id);
CREATE INDEX IF NOT EXISTS idx_subcontractor_inbound_name ON public.subcontractor_inbound(subcontractor_name);

-- ─── Enable RLS ───────────────────────────────────────────────────────────────
ALTER TABLE public.subcontractor_outbound ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subcontractor_inbound ENABLE ROW LEVEL SECURITY;

-- ─── RLS Policies ─────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "open_access_subcontractor_outbound" ON public.subcontractor_outbound;
CREATE POLICY "open_access_subcontractor_outbound"
ON public.subcontractor_outbound
FOR ALL
TO public
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "open_access_subcontractor_inbound" ON public.subcontractor_inbound;
CREATE POLICY "open_access_subcontractor_inbound"
ON public.subcontractor_inbound
FOR ALL
TO public
USING (true)
WITH CHECK (true);
