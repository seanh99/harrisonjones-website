-- Storage bucket for hero images, so the admin panel can upload/delete
-- photos directly instead of being limited to a hardcoded file list.
insert into storage.buckets (id, name, public)
values ('hero-images', 'hero-images', true)
on conflict (id) do nothing;

create policy "Public read hero images"
on storage.objects for select
using (bucket_id = 'hero-images');

create policy "Admin upload hero images"
on storage.objects for insert
with check (bucket_id = 'hero-images' and public.is_admin());

create policy "Admin update hero images"
on storage.objects for update
using (bucket_id = 'hero-images' and public.is_admin())
with check (bucket_id = 'hero-images' and public.is_admin());

create policy "Admin delete hero images"
on storage.objects for delete
using (bucket_id = 'hero-images' and public.is_admin());
