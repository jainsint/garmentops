-- Add sent_dc_no and received_dc_no columns to washing_entries
ALTER TABLE public.washing_entries
  ADD COLUMN IF NOT EXISTS sent_dc_no TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS received_dc_no TEXT DEFAULT '';
