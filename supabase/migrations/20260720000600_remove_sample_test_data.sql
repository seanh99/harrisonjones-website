-- Remove the sample client/project used to verify the full admin flow end-to-end.
delete from public.client_projects
  where client_id in (select id from public.clients where username = 'sample.client@example.com');
delete from public.clients where username = 'sample.client@example.com';
delete from public.projects where name = 'Sample Refurbishment';
