-- After creating your admin user in Supabase Authentication > Users > Add user,
-- replace YOUR_EMAIL_HERE with that user's email, then run this in SQL Editor.
insert into public.shop_admins(user_id)
select id from auth.users where email='YOUR_EMAIL_HERE'
on conflict do nothing;
-- Verify one result is returned:
select u.email from auth.users u join public.shop_admins a on a.user_id=u.id;
