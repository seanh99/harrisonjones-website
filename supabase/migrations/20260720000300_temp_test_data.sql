-- Temporary test data to verify the client login/portal flow end-to-end.
-- Removed by a follow-up migration once verified.
insert into public.clients (username, password_hash, display_name)
values ('testclient', extensions.crypt('testpass123', extensions.gen_salt('bf')), 'Test Client');

insert into public.projects (name, link)
values ('Test Project', 'https://www.dropbox.com/test-project-link');

insert into public.client_projects (client_id, project_id)
select c.id, p.id from public.clients c, public.projects p
where c.username = 'testclient' and p.name = 'Test Project';
