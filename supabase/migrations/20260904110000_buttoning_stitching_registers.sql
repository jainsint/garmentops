-- Buttoning & Button Holing entries table
CREATE TABLE IF NOT EXISTS public.buttoning_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.client_orders(id) ON DELETE SET NULL,
  style_no TEXT NOT NULL DEFAULT '',
  operation TEXT NOT NULL DEFAULT 'Buttoning',
  quantity INTEGER NOT NULL DEFAULT 0,
  representative TEXT NOT NULL DEFAULT '',
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.buttoning_entries ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'buttoning_entries' AND policyname = 'Allow all for buttoning_entries'
  ) THEN
    CREATE POLICY "Allow all for buttoning_entries"
      ON public.buttoning_entries
      FOR ALL
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

-- Stitching entries table
CREATE TABLE IF NOT EXISTS public.stitching_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.client_orders(id) ON DELETE SET NULL,
  style_no TEXT NOT NULL DEFAULT '',
  production_qty INTEGER NOT NULL DEFAULT 0,
  line_number TEXT NOT NULL DEFAULT '',
  comments TEXT NOT NULL DEFAULT '',
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.stitching_entries ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'stitching_entries' AND policyname = 'Allow all for stitching_entries'
  ) THEN
    CREATE POLICY "Allow all for stitching_entries"
      ON public.stitching_entries
      FOR ALL
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;
