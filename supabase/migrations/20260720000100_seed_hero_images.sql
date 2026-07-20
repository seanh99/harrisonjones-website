-- Seed the initial hero rotation so the homepage works immediately,
-- before the admin makes any selection changes in the dashboard.
insert into public.hero_images (filename, format, caption, is_active, sort_order) values
  ('hero-01-entrance.jpg',  'vertical',   'Private Residence', true, 1),
  ('hero-02-dining.jpg',    'horizontal', 'Private Residence', true, 2),
  ('hero-03-living.jpg',    'vertical',   'Private Residence', true, 3),
  ('hero-06-spiral.jpg',    'square',     'Private Residence', true, 4),
  ('hero-04-sculpture.jpg', 'vertical',   'Private Residence', true, 5),
  ('hero-07-stairs.jpg',    'horizontal', 'Private Residence', true, 6),
  ('hero-05-staircase.jpg', 'vertical',   'Private Residence', true, 7),
  ('hero-08-door.jpg',      'horizontal', 'Private Residence', true, 8)
on conflict (filename) do nothing;
