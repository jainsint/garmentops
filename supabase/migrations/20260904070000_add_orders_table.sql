-- GarmentOps Orders Table + order_id FK on all register tables
-- Migration: 20260904070000_add_orders_table.sql

-- ─── Orders Table ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_no TEXT NOT NULL,
    style_no TEXT NOT NULL,
    buyer TEXT,
    description TEXT,
    quantity INTEGER DEFAULT 0,
    delivery_date DATE,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_order_no ON public.orders(order_no);
CREATE INDEX IF NOT EXISTS idx_orders_style_no ON public.orders(style_no);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);

-- ─── Add order_id FK to all register tables ──────────────────────────────────
ALTER TABLE public.cutting_entries
  ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL;

ALTER TABLE public.production_entries
  ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL;

ALTER TABLE public.lay_entries
  ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL;

ALTER TABLE public.ironing_entries
  ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL;

ALTER TABLE public.checking_entries
  ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL;

-- ─── Indexes for FK columns ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_cutting_entries_order_id ON public.cutting_entries(order_id);
CREATE INDEX IF NOT EXISTS idx_production_entries_order_id ON public.production_entries(order_id);
CREATE INDEX IF NOT EXISTS idx_lay_entries_order_id ON public.lay_entries(order_id);
CREATE INDEX IF NOT EXISTS idx_ironing_entries_order_id ON public.ironing_entries(order_id);
CREATE INDEX IF NOT EXISTS idx_checking_entries_order_id ON public.checking_entries(order_id);

-- ─── Enable RLS on orders ────────────────────────────────────────────────────
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "open_access_orders" ON public.orders;
CREATE POLICY "open_access_orders"
ON public.orders FOR ALL TO public USING (true) WITH CHECK (true);

-- ─── Sample Orders (mock data) ───────────────────────────────────────────────
DO $$
BEGIN
    INSERT INTO public.orders (id, order_no, style_no, buyer, description, quantity, delivery_date, status)
    VALUES
        (gen_random_uuid(), 'ORD-2401', 'ST-2401', 'Buyer A', 'Men Polo T-Shirt', 5000, CURRENT_DATE + 30, 'active'),
        (gen_random_uuid(), 'ORD-2402', 'ST-2402', 'Buyer B', 'Women Kurti', 3000, CURRENT_DATE + 45, 'active'),
        (gen_random_uuid(), 'ORD-2403', 'ST-2403', 'Buyer C', 'Kids Shorts', 2000, CURRENT_DATE + 20, 'active')
    ON CONFLICT (order_no) DO NOTHING;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Sample orders insertion skipped: %', SQLERRM;
END $$;
