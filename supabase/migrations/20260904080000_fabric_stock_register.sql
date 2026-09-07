-- Fabric Stock Register Table + Storage Bucket
-- Migration: 20260904080000_fabric_stock_register.sql

-- ─── Fabric Stock Register Table ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.fabric_stock_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    style TEXT NOT NULL,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    design TEXT,
    colour TEXT,
    rolls JSONB NOT NULL DEFAULT '[]'::JSONB,
    total_rolls INTEGER DEFAULT 0,
    total_mtrs NUMERIC(10,2) DEFAULT 0,
    total_used NUMERIC(10,2) DEFAULT 0,
    balance NUMERIC(10,2) DEFAULT 0,
    remarks TEXT,
    swatch_photo_path TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ─── Indexes ─────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_fabric_stock_entries_style ON public.fabric_stock_entries(style);
CREATE INDEX IF NOT EXISTS idx_fabric_stock_entries_entry_date ON public.fabric_stock_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_fabric_stock_entries_order_id ON public.fabric_stock_entries(order_id);

-- ─── Enable RLS ──────────────────────────────────────────────────────────────
ALTER TABLE public.fabric_stock_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "open_access_fabric_stock_entries" ON public.fabric_stock_entries;
CREATE POLICY "open_access_fabric_stock_entries"
ON public.fabric_stock_entries FOR ALL TO public USING (true) WITH CHECK (true);

-- ─── Storage Bucket for Fabric Swatch Photos ─────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'fabric-swatches',
    'fabric-swatches',
    true,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- ─── Storage RLS Policies ─────────────────────────────────────────────────────
DROP POLICY IF EXISTS "public_read_fabric_swatches" ON storage.objects;
CREATE POLICY "public_read_fabric_swatches" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'fabric-swatches');

DROP POLICY IF EXISTS "public_upload_fabric_swatches" ON storage.objects;
CREATE POLICY "public_upload_fabric_swatches" ON storage.objects
FOR INSERT TO public
WITH CHECK (bucket_id = 'fabric-swatches');

DROP POLICY IF EXISTS "public_delete_fabric_swatches" ON storage.objects;
CREATE POLICY "public_delete_fabric_swatches" ON storage.objects
FOR DELETE TO public
USING (bucket_id = 'fabric-swatches');
