-- Upgrade an existing shop schema into the two-floor mall. Preserves existing rows.
begin;
create table if not exists public.mall_stores(
 id text primary key,name text not null check(length(name) between 1 and 80),
 floor integer not null check(floor in(0,1)),side integer not null check(side in(-1,1)),
 z real not null check(z between -29 and 29),color text not null default '#d4a94e' check(color ~ '^#[0-9a-fA-F]{6}$'),
 open boolean not null default false,enabled boolean not null default true,store_url text not null default ''
);
create unique index if not exists mall_store_position on public.mall_stores(floor,side,z) where enabled;
create table if not exists public.mall_screens(
 id text primary key,title text not null check(length(title)<=120),subtitle text not null default '' check(length(subtitle)<=180),
 image_url text not null default '',link_url text not null default '',
 floor integer not null check(floor in(0,1)),x real not null check(x between -12.5 and 12.5),z real not null check(z between -33 and 33),
 center_y real not null check(center_y between .8 and 4.1),rotation real not null default 0,
 width real not null default 2.9 check(width between 1 and 4),height real not null default 1.7 check(height between .7 and 2.2),
 hanging boolean not null default true,enabled boolean not null default true,
 constraint mall_screen_below_ceiling check(center_y+height/2 < case when floor=0 then 4.7 else 4.15 end),
 constraint mall_screen_above_floor check(center_y-height/2>.15),
 constraint mall_screen_clear_escalator check(not (abs(x)<4 and z>-5 and z<12))
);
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('ground-0','🎮 قيمنق ستور',0,-1,-18,'#7b2ff7',false,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('ground-1','🎧 ساوند سيتي',0,-1,-9,'#00a8b5',false,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('ground-2','👟 سنيكرز هب',0,-1,0,'#00b36b',false,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('ground-3','☕ قهوة رقمية',0,-1,9,'#d4a94e',false,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('ground-4','💻 تك زون',0,1,-18,'#00a8b5',false,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('ground-5','👜 ستايل بوتيك',0,1,-9,'#d45494',false,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('accessories','📱 إكسسواراتك',0,1,0,'#d4a94e',true,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('ground-7','🕶️ أوبتكس',0,1,9,'#7b2ff7',false,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('upper-0','🍔 برجر نيون',1,-1,-18,'#d4543a',false,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('upper-1','🍦 آيس كريم لاب',1,-1,-9,'#d48fb0',false,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('upper-2','📚 مكتبة المول',1,-1,0,'#4a7bd4',false,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('upper-3','🎬 سينما مول',1,-1,9,'#8a2fd4',false,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('upper-4','🏋️ فتنس زون',1,1,-18,'#3ad48a',false,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('upper-5','🧸 عالم الأطفال',1,1,-9,'#d4b02f',false,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('upper-6','💈 صالون النيون',1,1,9,'#2fa8d4',false,true,'') on conflict(id) do nothing;
insert into public.mall_stores(id,name,floor,side,z,color,open,enabled,store_url) values('upper-7','🛋️ هوم ستايل',1,1,-27,'#b56a3a',false,true,'') on conflict(id) do nothing;
insert into public.mall_screens(id,title,subtitle,floor,x,z,center_y,rotation,width,height,hanging) values('ad-1','عرض اليوم','خصم 30% على الكفرات',0,0,-27,3.5,0,2.9,1.7,true) on conflict(id) do nothing;
insert into public.mall_screens(id,title,subtitle,floor,x,z,center_y,rotation,width,height,hanging) values('ad-2','شحن مجاني','للطلبات فوق 200 ر.س',0,0,23,3.5,0,2.9,1.7,true) on conflict(id) do nothing;
insert into public.mall_screens(id,title,subtitle,floor,x,z,center_y,rotation,width,height,hanging) values('ad-3','وصل حديثاً','سماعات الألعاب',1,0,-27,3.15,0,2.9,1.7,true) on conflict(id) do nothing;
insert into public.mall_screens(id,title,subtitle,floor,x,z,center_y,rotation,width,height,hanging) values('ad-4','باور بانك','سعة 20000mAh',1,0,23,3.15,0,2.9,1.7,true) on conflict(id) do nothing;
insert into public.mall_screens(id,title,subtitle,floor,x,z,center_y,rotation,width,height,hanging) values('ad-5','إعلانك هنا','مساحة إعلانية متاحة',0,-12.38,-13.5,2.35,90,2.35,1.4,false) on conflict(id) do nothing;
insert into public.mall_screens(id,title,subtitle,floor,x,z,center_y,rotation,width,height,hanging) values('ad-6','حماية شاشة','تركيب داخل المحل',0,12.38,4.5,2.35,-90,2.35,1.4,false) on conflict(id) do nothing;
insert into public.mall_screens(id,title,subtitle,floor,x,z,center_y,rotation,width,height,hanging) values('ad-7','عرض اليوم','تسوق من مكانك',1,-12.38,4.5,2.15,90,2.35,1.4,false) on conflict(id) do nothing;
insert into public.mall_screens(id,title,subtitle,floor,x,z,center_y,rotation,width,height,hanging) values('ad-8','شحن مجاني','للطلبات فوق 200 ر.س',1,12.38,-13.5,2.15,-90,2.35,1.4,false) on conflict(id) do nothing;

alter table public.shop_shelves add column if not exists store_id text not null default 'accessories' references public.mall_stores(id);
alter table public.shop_products add column if not exists store_id text not null default 'accessories' references public.mall_stores(id);
create unique index if not exists shop_shelf_store_unique on public.shop_shelves(id,store_id);
do $$ begin
 if not exists(select 1 from pg_constraint where conname='shop_product_same_store_shelf' and conrelid='public.shop_products'::regclass) then
 alter table public.shop_products add constraint shop_product_same_store_shelf foreign key(shelf_id,store_id) references public.shop_shelves(id,store_id) deferrable initially immediate;
 end if;
end $$;
do $$ declare t text;begin
 foreach t in array array['mall_stores','mall_screens'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('drop policy if exists mall_read on public.%I',t);
 execute format('create policy mall_read on public.%I for select to anon,authenticated using(true)',t);
 execute format('drop policy if exists mall_admin on public.%I',t);
 execute format('create policy mall_admin on public.%I for all to authenticated using(public.shop_is_admin()) with check(public.shop_is_admin())',t);
 execute format('grant select on public.%I to anon,authenticated',t);
 execute format('grant insert,update,delete on public.%I to authenticated',t);
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then execute format('alter publication supabase_realtime add table public.%I',t);end if;
 end loop;
end $$;
-- Only migrate untouched initial branding and spawn; custom branding stays intact.
update public.shop_settings set name='النيون مول',slogan='تسوق من مكانك',floor_color='#d9d2c4',wall_color='#e9e2d2',
 light_intensity=1.15,accent_color='#d4a94e',spawn_x=0,spawn_z=22,spawn_yaw=0
where id=1 and name='WESAM SMART';
-- Validate positions even when the API is called outside the admin UI.
create or replace function public.mall_validate_store() returns trigger language plpgsql set search_path='' as $$
begin
 perform pg_catalog.pg_advisory_xact_lock(73142,new.floor*10+new.side);
 if new.enabled and exists(select 1 from public.mall_stores s where s.id<>new.id and s.enabled and s.floor=new.floor and s.side=new.side and abs(s.z-new.z)<7) then
 raise exception 'Storefront overlaps another store';end if;
 if new.enabled and exists(select 1 from public.mall_screens a where a.enabled and a.floor=new.floor and sign(a.x)=new.side and abs(a.x)>11 and abs(a.z-new.z)<3.3+abs(sin(a.rotation*pi()/180))*a.width/2) then raise exception 'Storefront overlaps screen';end if;
 return new;
end $$;
drop trigger if exists mall_validate_store on public.mall_stores;
create trigger mall_validate_store before insert or update on public.mall_stores for each row execute function public.mall_validate_store();

-- NULL invitation tokens must be explicitly rejected.
create or replace function public.shop_join_room(room uuid,token uuid) returns boolean language plpgsql security definer set search_path='' as $$
declare r public.shop_rooms; begin
 if auth.uid() is null then raise exception 'Sign in required';end if;
 if room is null or token is null then raise exception 'Invitation required';end if;
 if not coalesce((select multiplayer_enabled from public.shop_settings where id=1),false) then raise exception 'Multiplayer disabled';end if;
 select * into r from public.shop_rooms where id=room for update;
 if r.id is null or r.invite_token is distinct from token or r.expires_at<now() then raise exception 'Invalid or expired invitation';end if;
 if (select count(*) from public.shop_room_members where room_id=room)>=12 and not exists(select 1 from public.shop_room_members where room_id=room and user_id=auth.uid()) then raise exception 'Room is full';end if;
 insert into public.shop_room_members(room_id,user_id) values(room,auth.uid()) on conflict do nothing;return true;
end $$;
create or replace function public.shop_leave_room(room uuid) returns void language sql security definer set search_path='' as $$
 delete from public.shop_room_members where room_id=room and user_id=(select auth.uid());
$$;
revoke all on function public.shop_leave_room(uuid) from public;
grant execute on function public.shop_leave_room(uuid) to authenticated;

create or replace function public.mall_validate_screen() returns trigger language plpgsql set search_path='' as $$
declare hx double precision;hz double precision;begin
 perform pg_catalog.pg_advisory_xact_lock(73142,new.floor*10+sign(new.x)::integer);
 hx=abs(cos(new.rotation*pi()/180))*new.width/2+.1;hz=abs(sin(new.rotation*pi()/180))*new.width/2+.1;
 if abs(new.x)+hx>=13 or abs(new.z)+hz>=35 then raise exception 'Screen outside mall';end if;
 if new.x-hx<4 and new.x+hx>-4 and new.z-hz<12 and new.z+hz>-5 then raise exception 'Screen overlaps escalators';end if;
 if new.enabled and exists(select 1 from public.mall_stores s where s.enabled and s.floor=new.floor and s.side=sign(new.x) and abs(new.x)>11 and abs(s.z-new.z)<3.3+abs(sin(new.rotation*pi()/180))*new.width/2) then raise exception 'Screen overlaps storefront';end if;
 return new;
end $$;
drop trigger if exists mall_validate_screen on public.mall_screens;
create trigger mall_validate_screen before insert or update on public.mall_screens for each row execute function public.mall_validate_screen();

commit;
