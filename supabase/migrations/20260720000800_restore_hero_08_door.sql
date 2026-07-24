-- Restore the hero_images row for hero-08-door.jpg, accidentally deleted
-- while testing the new admin upload/delete feature.
insert into public.hero_images (filename, format, caption, is_active, sort_order)
values ('hero-08-door.jpg', 'horizontal', 'Private Residence', true, 8)
on conflict (filename) do update set
  format = excluded.format,
  is_active = excluded.is_active,
  sort_order = excluded.sort_order;
