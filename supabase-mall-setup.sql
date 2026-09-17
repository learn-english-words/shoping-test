-- WESAM SMART: run once in Supabase SQL Editor. Re-running preserves existing data.
begin;
create table if not exists public.shop_admins(user_id uuid primary key references auth.users(id) on delete cascade);
alter table public.shop_admins enable row level security;
create or replace function public.shop_is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.shop_admins where user_id=(select auth.uid()));
$$;
revoke all on function public.shop_is_admin() from public;
grant execute on function public.shop_is_admin() to anon,authenticated;
drop policy if exists admin_self on public.shop_admins;
create policy admin_self on public.shop_admins for select to authenticated using(user_id=(select auth.uid()));
grant select on public.shop_admins to authenticated;
revoke insert,update,delete on public.shop_admins from anon,authenticated;

create table if not exists public.shop_settings(
 id integer primary key default 1 check(id=1),
 name text not null default 'WESAM SMART' check(length(name) between 1 and 80),
 slogan text not null default 'اكتشف ما يناسبك' check(length(slogan)<=120),
 store_url text not null default '', logo_url text not null default '',
 floor_color text not null default '#eeeae2' check(floor_color ~ '^#[0-9a-fA-F]{6}$'),
 wall_color text not null default '#b6a28b' check(wall_color ~ '^#[0-9a-fA-F]{6}$'),
 shelf_color text not null default '#253347' check(shelf_color ~ '^#[0-9a-fA-F]{6}$'),
 accent_color text not null default '#bda783' check(accent_color ~ '^#[0-9a-fA-F]{6}$'),
 light_color text not null default '#fff6ec' check(light_color ~ '^#[0-9a-fA-F]{6}$'),
 light_intensity real not null default 1.8 check(light_intensity between .2 and 4),
 room_width real not null default 34 check(room_width between 20 and 100),
 room_depth real not null default 34 check(room_depth between 20 and 100),
 room_height real not null default 12 check(room_height between 8 and 30),
 spawn_x real not null default 0,spawn_z real not null default -5,
 spawn_yaw real not null default 0,walk_speed real not null default 4 check(walk_speed between 1 and 8),
 multiplayer_enabled boolean not null default true
);
create table if not exists public.shop_shelves(
 id text primary key,name text not null check(length(name) between 1 and 80),
 category text not null default 'إكسسوارات',x real not null,z real not null,
 rotation real not null default 0,width real not null default 5 check(width between 3 and 8),
 height real not null default 6.2 check(height between 5 and 8),depth real not null default 1.1 check(depth between .6 and 2),
 enabled boolean not null default true
);
create table if not exists public.shop_products(
 id text primary key,name text not null check(length(name) between 1 and 120),
 price numeric(12,2) not null check(price>=0),category text not null default 'إكسسوارات',
 description text not null default '' check(length(description)<=4000),
 image_url text not null default '',product_url text not null default '',
 visible boolean not null default true,
 shelf_id text references public.shop_shelves(id) on delete set null,
 row_index integer not null default 0 check(row_index between 0 and 2),
 slot_index integer not null default 0 check(slot_index between 0 and 2),
 page_index integer not null default 0 check(page_index between 0 and 999)
);
create unique index if not exists shop_unique_position on public.shop_products(shelf_id,page_index,row_index,slot_index) where visible and shelf_id is not null;
do $$ declare t text; begin
 foreach t in array array['shop_settings','shop_shelves','shop_products'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('drop policy if exists shop_read on public.%I',t);
 execute format('create policy shop_read on public.%I for select to anon,authenticated using (true)',t);
 execute format('drop policy if exists shop_admin_write on public.%I',t);
 execute format('create policy shop_admin_write on public.%I for all to authenticated using (public.shop_is_admin()) with check (public.shop_is_admin())',t);
 execute format('grant select on public.%I to anon,authenticated',t);
 execute format('grant insert,update,delete on public.%I to authenticated',t);
 end loop;
end $$;
insert into public.shop_settings(id) values(1) on conflict do nothing;
insert into public.shop_shelves(id,name,category,x,z,rotation,width,height,depth,enabled) values('shelf-1','كفرات 1','كفرات',-11,-14.5,0,5,6.2,1.1,true) on conflict(id) do nothing;
insert into public.shop_shelves(id,name,category,x,z,rotation,width,height,depth,enabled) values('shelf-2','كفرات 2','كفرات',-5.5,-14.5,0,5,6.2,1.1,true) on conflict(id) do nothing;
insert into public.shop_shelves(id,name,category,x,z,rotation,width,height,depth,enabled) values('shelf-3','سماعات 3','سماعات',0,-14.5,0,5,6.2,1.1,true) on conflict(id) do nothing;
insert into public.shop_shelves(id,name,category,x,z,rotation,width,height,depth,enabled) values('shelf-4','سماعات 4','سماعات',5.5,-14.5,0,5,6.2,1.1,true) on conflict(id) do nothing;
insert into public.shop_shelves(id,name,category,x,z,rotation,width,height,depth,enabled) values('shelf-5','شواحن 5','شواحن',11,-14.5,0,5,6.2,1.1,true) on conflict(id) do nothing;
insert into public.shop_shelves(id,name,category,x,z,rotation,width,height,depth,enabled) values('shelf-6','شواحن 6','شواحن',-14.5,-8,90,5,6.2,1.1,true) on conflict(id) do nothing;
insert into public.shop_shelves(id,name,category,x,z,rotation,width,height,depth,enabled) values('shelf-7','حماية 7','حماية',-14.5,-2,90,5,6.2,1.1,true) on conflict(id) do nothing;
insert into public.shop_shelves(id,name,category,x,z,rotation,width,height,depth,enabled) values('shelf-8','حماية 8','حماية',-14.5,4,90,5,6.2,1.1,true) on conflict(id) do nothing;
insert into public.shop_shelves(id,name,category,x,z,rotation,width,height,depth,enabled) values('shelf-9','إكسسوارات 9','إكسسوارات',14.5,-8,-90,5,6.2,1.1,true) on conflict(id) do nothing;
insert into public.shop_shelves(id,name,category,x,z,rotation,width,height,depth,enabled) values('shelf-10','إكسسوارات 10','إكسسوارات',14.5,-2,-90,5,6.2,1.1,true) on conflict(id) do nothing;
insert into public.shop_shelves(id,name,category,x,z,rotation,width,height,depth,enabled) values('shelf-11','كفرات 11','كفرات',14.5,4,-90,5,6.2,1.1,true) on conflict(id) do nothing;
insert into public.shop_shelves(id,name,category,x,z,rotation,width,height,depth,enabled) values('shelf-12','إكسسوارات 12','إكسسوارات',14.5,10,-90,5,6.2,1.1,true) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('k1','كفر نيون — آيفون 15',59,'كفرات','كفر سيليكون مضاد للصدمات بتصميم نيون متوهج، حماية كاملة للكاميرا والشاشة.','shelf-1',0,0,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('k2','كفر شفاف ماجنتك',45,'كفرات','كفر شفاف يدعم الشحن المغناطيسي MagSafe مع حواف مرتفعة لحماية إضافية.','shelf-2',0,0,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('k3','كفر ألعاب LED',79,'كفرات','كفر للقيمرز بإضاءة LED متغيرة الألوان مع أزرار إضافية قابلة للبرمجة.','shelf-11',0,0,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('s1','سماعة بلوتوث Pro',199,'سماعات','سماعة رأس لاسلكية بعزل ضوضاء نشط وبطارية تدوم 40 ساعة مع ميكروفون نقي.','shelf-3',0,0,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('s2','سماعات أذن لاسلكية',149,'سماعات','سماعات TWS صغيرة بجودة صوت استوديو وعلبة شحن سريع، مقاومة للماء IPX5.','shelf-4',0,0,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('s3','سماعة ألعاب RGB',229,'سماعات','سماعة قيمنق بصوت محيطي 7.1 ومايك بإلغاء الضوضاء وإضاءة RGB متزامنة.','shelf-3',0,1,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('c1','شاحن سريع 65W',99,'شواحن','شاحن GaN صغير بقوة 65 واط يشحن الجوال واللابتوب، بمنفذين USB-C وUSB-A.','shelf-5',0,0,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('c2','كيبل مغناطيسي 3 في 1',39,'شواحن','كيبل شحن مغناطيسي يدعم Lightning وUSB-C وMicro بطول 2 متر وقوة 100W.','shelf-6',0,0,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('c3','باور بانك 20000mAh',129,'شواحن','بطارية متنقلة بسعة كبيرة وشاشة عرض رقمية، تشحن 3 أجهزة بنفس الوقت.','shelf-5',0,1,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('g1','حماية شاشة سيراميك',35,'حماية','استيكر حماية سيراميك ناعم الملمس، مضاد للخدوش والبصمات وتركيب سهل.','shelf-7',0,0,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('g2','عدسة حماية الكاميرا',25,'حماية','حلقة حماية معدنية للكاميرا بجودة لا تؤثر على جودة الصور، تركيب دقيق.','shelf-8',0,0,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('g3','جراب حماية عسكري',69,'حماية','جراب بمعايير عسكرية مقاوم للسقوط من 3 أمتار مع حواف مطاطية ممتصة للصدمات.','shelf-7',0,1,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('a1','حامل سيارة مغناطيسي',49,'إكسسوارات','حامل مغناطيسي قوي للسيارة مع دوران 360 درجة، ثبات عالي على الطريق.','shelf-9',0,0,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('a2','حامل مكتب ألمنيوم',55,'إكسسوارات','حامل مكتبي من الألمنيوم بزوايا قابلة للتعديل، متوافق مع الجوال والتابلت.','shelf-10',0,0,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('a3','قلم لمس ذكي',89,'إكسسوارات','قلم Stylus بدقة عالية وبطارية تدوم 10 ساعات، مثالي للرسم والتدوين.','shelf-12',0,0,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('a4','استيكرات سكين نيون',19,'إكسسوارات','حزمة استيكرات مقاومة للماء بتصاميم نيون، تناسب الجوال واللابتوب.','shelf-9',0,1,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('a5','كفر تبريد للقيمنق',75,'كفرات','كفر بشريط تبريد نحاسي يخفض حرارة الجوال أثناء الألعاب الطويلة.','shelf-1',0,1,0) on conflict(id) do nothing;
insert into public.shop_products(id,name,price,category,description,shelf_id,row_index,slot_index,page_index) values('a6','سبيكر بلوتوث محمول',119,'سماعات','مكبر صوت صغير بصوت قوي 360 درجة وبطارية 12 ساعة ومقاومة للماء.','shelf-4',0,1,0) on conflict(id) do nothing;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('shop-images','shop-images',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do nothing;
drop policy if exists shop_images_read on storage.objects;
create policy shop_images_read on storage.objects for select to anon,authenticated using(bucket_id='shop-images');
drop policy if exists shop_images_admin on storage.objects;
create policy shop_images_admin on storage.objects for all to authenticated using(bucket_id='shop-images' and public.shop_is_admin()) with check(bucket_id='shop-images' and public.shop_is_admin());

-- Invitation rooms: authenticated guests can only enter with the random invitation token.
create table if not exists public.shop_rooms(
 id uuid primary key default gen_random_uuid(), invite_token uuid not null default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 expires_at timestamptz not null default (now()+interval '24 hours')
);
create table if not exists public.shop_room_members(
 room_id uuid references public.shop_rooms(id) on delete cascade,
 user_id uuid references auth.users(id) on delete cascade,primary key(room_id,user_id)
);
alter table public.shop_rooms enable row level security;
alter table public.shop_room_members enable row level security;
revoke all on public.shop_rooms,public.shop_room_members from anon,authenticated;
create or replace function public.shop_create_room() returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.shop_rooms; begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 if not coalesce((select multiplayer_enabled from public.shop_settings where id=1),false) then raise exception 'Multiplayer disabled'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(auth.uid()::text,73143));
 if (select count(*) from public.shop_rooms where owner_id=auth.uid() and expires_at>now())>=3 then raise exception 'Room limit reached'; end if;
 insert into public.shop_rooms(owner_id) values(auth.uid()) returning * into r;
 insert into public.shop_room_members(room_id,user_id) values(r.id,auth.uid());
 return jsonb_build_object('id',r.id,'token',r.invite_token);
end $$;
create or replace function public.shop_join_room(room uuid,token uuid) returns boolean language plpgsql security definer set search_path='' as $$
declare r public.shop_rooms; begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 if not coalesce((select multiplayer_enabled from public.shop_settings where id=1),false) then raise exception 'Multiplayer disabled'; end if;
 select * into r from public.shop_rooms where id=room for update;
 if room is null or token is null or r.id is null or r.invite_token is distinct from token or r.expires_at<now() then raise exception 'Invalid or expired invitation'; end if;
 if (select count(*) from public.shop_room_members where room_id=room)>=12 and not exists(select 1 from public.shop_room_members where room_id=room and user_id=auth.uid()) then raise exception 'Room is full'; end if;
 insert into public.shop_room_members(room_id,user_id) values(room,auth.uid()) on conflict do nothing;return true;
end $$;
create or replace function public.shop_can_join_topic(topic text) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.shop_room_members m join public.shop_rooms r on r.id=m.room_id
 where m.user_id=(select auth.uid()) and 'shop:'||r.id::text=topic and r.expires_at>now())
 and coalesce((select multiplayer_enabled from public.shop_settings where id=1),false);
$$;
revoke all on function public.shop_create_room(),public.shop_join_room(uuid,uuid),public.shop_can_join_topic(text) from public;
grant execute on function public.shop_create_room(),public.shop_join_room(uuid,uuid),public.shop_can_join_topic(text) to authenticated;
drop policy if exists shop_room_receive on realtime.messages;
create policy shop_room_receive on realtime.messages for select to authenticated using(public.shop_can_join_topic(realtime.topic()));
drop policy if exists shop_room_send on realtime.messages;
create policy shop_room_send on realtime.messages for insert to authenticated with check(public.shop_can_join_topic(realtime.topic()));
-- Publish database changes for shop reloads.
do $$ declare t text;begin
 foreach t in array array['shop_settings','shop_shelves','shop_products'] loop
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
 execute format('alter publication supabase_realtime add table public.%I',t);end if;
 end loop;
end $$;
commit;

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
