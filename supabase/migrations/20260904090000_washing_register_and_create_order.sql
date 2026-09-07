-- Washing Register table
CREATE TABLE IF NOT EXISTS public.washing_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  style_no text NOT NULL DEFAULT '',
  colour text NOT NULL DEFAULT '',
  sent_qty integer NOT NULL DEFAULT 0,
  received_qty integer DEFAULT NULL,
  difference integer GENERATED ALWAYS AS (
    CASE WHEN received_qty IS NOT NULL THEN sent_qty - received_qty ELSE NULL END
  ) STORED,
  sent_date date NOT NULL DEFAULT CURRENT_DATE,
  received_date date DEFAULT NULL,
  vendor_name text NOT NULL DEFAULT '',
  remarks text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'sent',
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.washing_entries ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'washing_entries' AND policyname = 'Allow all washing_entries'
  ) THEN
    CREATE POLICY "Allow all washing_entries"
      ON public.washing_entries
      FOR ALL
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

-- Create Orders table (client-facing orders with full details)
CREATE TABLE IF NOT EXISTS public.client_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_name text NOT NULL DEFAULT '',
  order_number text NOT NULL DEFAULT '',
  garment_type text NOT NULL DEFAULT '',
  order_quantity integer NOT NULL DEFAULT 0,
  order_date date NOT NULL DEFAULT CURRENT_DATE,
  delivery_date date NOT NULL DEFAULT CURRENT_DATE,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.client_orders ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'client_orders' AND policyname = 'Allow all client_orders'
  ) THEN
    CREATE POLICY "Allow all client_orders"
      ON public.client_orders
      FOR ALL
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;
