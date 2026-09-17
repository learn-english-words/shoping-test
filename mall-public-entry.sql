-- Run once in Supabase SQL Editor after the mall setup.
begin;
alter table public.shop_rooms add column if not exists is_public boolean not null default false;
create table if not exists public.mall_public_visits(
 room_id uuid not null,user_id uuid not null,last_seen timestamptz not null default now(),
 primary key(room_id,user_id),foreign key(room_id,user_id) references public.shop_room_members(room_id,user_id) on delete cascade
);
alter table public.mall_public_visits enable row level security;
revoke all on public.mall_public_visits from anon,authenticated;
create or replace function public.mall_join_public() returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.shop_rooms;begin
 if auth.uid() is null then raise exception 'Sign in required';end if;
 if not coalesce((select multiplayer_enabled from public.shop_settings where id=1),false) then raise exception 'Multiplayer disabled';end if;
 perform pg_catalog.pg_advisory_xact_lock(73144,1);
 delete from public.shop_room_members m using public.mall_public_visits v where m.room_id=v.room_id and m.user_id=v.user_id and v.last_seen<now()-interval '2 minutes';
 select rooms.* into r from public.shop_rooms rooms join public.shop_room_members m on m.room_id=rooms.id where rooms.is_public and rooms.expires_at>now()+interval '5 minutes' and m.user_id=auth.uid() order by rooms.expires_at,rooms.id limit 1;
 if r.id is null then
 select rooms.* into r from public.shop_rooms rooms where rooms.is_public and rooms.expires_at>now()+interval '5 minutes' and (select count(*) from public.shop_room_members m where m.room_id=rooms.id)<12 order by rooms.expires_at,rooms.id limit 1;
 end if;
 if r.id is null then insert into public.shop_rooms(owner_id,is_public) values(auth.uid(),true) returning * into r;end if;
 insert into public.shop_room_members(room_id,user_id) values(r.id,auth.uid()) on conflict do nothing;
 insert into public.mall_public_visits(room_id,user_id,last_seen) values(r.id,auth.uid(),now()) on conflict(room_id,user_id) do update set last_seen=excluded.last_seen;
 return jsonb_build_object('id',r.id,'public',true);
end $$;
create or replace function public.mall_public_heartbeat(room uuid) returns boolean language plpgsql security definer set search_path='' as $$
begin
 if not public.shop_can_join_topic('shop:'||room::text) then return false;end if;
 update public.mall_public_visits set last_seen=now() where room_id=room and user_id=auth.uid();
 return found;
end $$;
revoke all on function public.mall_join_public(),public.mall_public_heartbeat(uuid) from public;
grant execute on function public.mall_join_public(),public.mall_public_heartbeat(uuid) to authenticated;
commit;
