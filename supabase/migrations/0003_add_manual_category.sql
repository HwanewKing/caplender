-- =====================================================================
-- caplender — add the "설명서" (manual) category.
-- Run in Supabase SQL Editor after 0001_initial_schema.sql.
-- Idempotent: safe to re-run.
-- =====================================================================

insert into public.categories (id, name, color_hex, sort_order) values
  ('manual', '설명서', '#E5D6C7', 5)
on conflict (id) do update
  set name = excluded.name,
      color_hex = excluded.color_hex,
      sort_order = excluded.sort_order;
