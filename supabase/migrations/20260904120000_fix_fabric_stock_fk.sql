-- Fix fabric_stock_entries foreign key: point order_id to client_orders instead of orders
-- Migration: 20260904120000_fix_fabric_stock_fk.sql

-- Drop the old foreign key constraint
ALTER TABLE public.fabric_stock_entries
  DROP CONSTRAINT IF EXISTS fabric_stock_entries_order_id_fkey;

-- Add the corrected foreign key pointing to client_orders
ALTER TABLE public.fabric_stock_entries
  ADD CONSTRAINT fabric_stock_entries_order_id_fkey
  FOREIGN KEY (order_id) REFERENCES public.client_orders(id) ON DELETE SET NULL;
