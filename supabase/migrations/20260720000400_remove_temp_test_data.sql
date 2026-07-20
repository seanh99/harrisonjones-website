-- Remove the temporary test data used to verify the client login/portal flow.
delete from public.client_projects
  where client_id in (select id from public.clients where username = 'testclient');
delete from public.clients where username = 'testclient';
delete from public.projects where name = 'Test Project';
