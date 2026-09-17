
import {createDB,httpURL,allRows,requireOK} from './config.js';
const $=id=>document.getElementById(id);
let db,products=[],shelves=[],settings={},stores=[],screens=[],user=null,busy=false;
function message(text){$('message').textContent=text;}
function fail(error){const text=error.message||String(error);message(/unique|duplicate/i.test(text)?'هذه الخانة مشغولة بمنتج آخر. اختر خانة أو صفحة أخرى.':/schema|relation|table|PGRST/i.test(text)?'قاعدة البيانات غير مجهزة بعد. شغّل supabase-mall-setup.sql للمشروع الجديد أو mall-upgrade.sql للقاعدة الموجودة، ثم حدّث الصفحة.':/permission|row-level/i.test(text)?'ليس لهذا الحساب صلاحية إدارة المول. راجع admin-access.sql.':text);}
async function action(fn){
 if(busy)return;busy=true;document.querySelectorAll('form button').forEach(b=>b.disabled=true);
 try{await fn();}catch(e){fail(e);}finally{busy=false;document.querySelectorAll('form button').forEach(b=>b.disabled=false);}
}
const val=id=>$(id).value,num=id=>Number(val(id));
function set(id,value){$(id).value=value??'';}
function checkURL(id){const v=val(id).trim();if(v&&!httpURL(v))throw new Error('استخدم رابطاً يبدأ بـ https:// أو http://');return v;}
async function upload(file){
 if(!['image/jpeg','image/png','image/webp'].includes(file.type)||file.size>5242880)throw new Error('اختر صورة JPG أو PNG أو WebP أصغر من 5 ميجابايت.');
 const ext={'image/jpeg':'jpg','image/png':'png','image/webp':'webp'}[file.type];
 const path=crypto.randomUUID()+'.'+ext;
 requireOK(await db.storage.from('shop-images').upload(path,file,{contentType:file.type,upsert:false}));
 return db.storage.from('shop-images').getPublicUrl(path).data.publicUrl;
}
async function load(){
 
 [products,shelves,settings,stores,screens]=await Promise.all([
 allRows(db,'shop_products'),allRows(db,'shop_shelves'),db.from('shop_settings').select('*').eq('id',1).single().then(requireOK),allRows(db,'mall_stores'),allRows(db,'mall_screens')]);
 for(const id of ['pstore','sstore']){
  const selected=val(id);$(id).replaceChildren();stores.forEach(s=>$(id).add(new Option(s.name,s.id)));
  set(id,stores.some(s=>s.id===selected)?selected:(stores.find(s=>s.id==='accessories')?.id||stores[0]?.id||''));
 }

 $('stats').textContent=stores.length+' محل · '+screens.length+' شاشة · '+products.length+' منتج · '+shelves.length+' رف · '+products.filter(p=>p.visible&&p.shelf_id).length+' منتج موزّع';
 const previous=val('pshelf');$('pshelf').replaceChildren(new Option('بدون رف',''));
 shelves.filter(s=>s.store_id===val('pstore')).forEach(s=>$('pshelf').add(new Option(s.name+(s.enabled?'':' — مخفي'),s.id)));set('pshelf',previous);
 listProducts();listShelves();drawMap();renderSlots();renderSettings();listStores();listScreens();drawMallMap();
}
function listProducts(){
 const q=val('product-search').toLowerCase();$('product-list').replaceChildren();
 for(const p of products.filter(p=>(p.name+' '+p.category).toLowerCase().includes(q))){
  const item=document.createElement('div');item.className='item';
  if(httpURL(p.image_url)){const img=document.createElement('img');img.src=httpURL(p.image_url);img.alt='';img.loading='lazy';item.append(img);}
  const text=document.createElement('div');text.className='text';const name=document.createElement('b');name.textContent=p.name;
  const sub=document.createElement('small');sub.textContent=(stores.find(s=>s.id===p.store_id)?.name||'')+' · '+p.price+' ر.س · '+p.category+' · '+(p.visible?'ظاهر':'مخفي');
  text.append(name,sub);const button=document.createElement('button');button.textContent='تعديل';button.onclick=()=>editProduct(p);item.append(text,button);$('product-list').append(item);
 }
}
function editProduct(p={}){
 set('pstore',p.store_id||val('pstore')||stores[0]?.id||'');storeShelfOptions();

 for(const [id,key] of Object.entries({pid:'id',pname:'name',pprice:'price',pcat:'category',pdesc:'description',purl:'product_url',pimage:'image_url',pshelf:'shelf_id',prow:'row_index',pslot:'slot_index'}))set(id,p[key]??(id==='pcat'?'إكسسوارات':id==='prow'||id==='pslot'?0:''));
 set('ppage',(p.page_index??0)+1);$('pvisible').checked=p.visible??true;$('pfile').value='';
 $('delete-product').disabled=!p.id;imagePreview();renderSlots();
}
function imagePreview(){const url=httpURL(val('pimage'));$('pimage-preview').hidden=!url;if(url)$('pimage-preview').src=url;}
function renderSlots(){
 $('slot-picker').replaceChildren();
 for(let row=2;row>=0;row--)for(let slot=0;slot<3;slot++){
  const other=products.find(p=>p.id!==val('pid')&&p.visible&&p.shelf_id===val('pshelf')&&p.page_index===num('ppage')-1&&p.row_index===row&&p.slot_index===slot);
  const b=document.createElement('button');b.type='button';b.className=(num('prow')===row&&num('pslot')===slot?'selected ':'')+(other?'occupied':'');b.textContent=(row===2?'علوي':row===1?'وسط':'سفلي')+' / '+(slot+1);
  if(other){const small=document.createElement('small');small.textContent=other.name;b.append(small);}
  b.onclick=()=>{set('prow',row);set('pslot',slot);renderSlots();};$('slot-picker').append(b);
 }
}
$('new-product').onclick=()=>editProduct();$('product-search').oninput=listProducts;
$('pshelf').onchange=renderSlots;$('ppage').oninput=renderSlots;$('pimage').oninput=imagePreview;
$('product-form').onsubmit=e=>{e.preventDefault();action(async()=>{
 const id=val('pid')||crypto.randomUUID();
 let image=checkURL('pimage');if($('pfile').files[0])image=await upload($('pfile').files[0]);
 const p={id,store_id:val('pstore'),name:val('pname').trim(),price:num('pprice'),category:val('pcat').trim(),description:val('pdesc'),product_url:checkURL('purl'),image_url:image,visible:$('pvisible').checked,shelf_id:val('pshelf')||null,row_index:num('prow'),slot_index:num('pslot'),page_index:num('ppage')-1};
 if(!p.name||!p.category||!Number.isFinite(p.price)||p.price<0||!Number.isInteger(p.page_index))throw new Error('راجع البيانات المدخلة.');
 requireOK(await db.from('shop_products').upsert(p).select());await load();editProduct(p);message('تم حفظ المنتج. يظهر التحديث في المحل خلال ثوانٍ.');
});};
$('delete-product').onclick=()=>action(async()=>{const id=val('pid');if(!id||!confirm('حذف المنتج نهائياً؟'))return;requireOK(await db.from('shop_products').delete().eq('id',id).select());await load();editProduct();message('تم حذف المنتج.');});
function listShelves(){
 $('shelf-list').replaceChildren();for(const s of shelves){
  const item=document.createElement('div');item.className='item';const text=document.createElement('div');text.className='text';
  const title=document.createElement('b');title.textContent=(stores.find(st=>st.id===s.store_id)?.name||'')+' · '+s.name;const small=document.createElement('small');small.textContent=products.filter(p=>p.shelf_id===s.id).length+' منتج · '+(s.enabled?'ظاهر':'مخفي');
  text.append(title,small);const b=document.createElement('button');b.textContent='اختيار';b.onclick=()=>editShelf(s);item.append(text,b);$('shelf-list').append(item);
 }
}
function editShelf(s={}){
 set('sstore',s.store_id||val('sstore')||stores[0]?.id||'');

 for(const [id,key] of Object.entries({sid:'id',sname:'name',scat:'category',sx:'x',sz:'z',srotation:'rotation',swidth:'width',sheight:'height',sdepth:'depth'}))set(id,s[key]??({sx:0,sz:0,srotation:0,swidth:5,sheight:6.2,sdepth:1.1,scat:'إكسسوارات'}[id]??''));
 $('senabled').checked=s.enabled??true;drawMap();
}
function shelfData(){return{id:val('sid')||crypto.randomUUID(),store_id:val('sstore'),name:val('sname').trim(),category:val('scat').trim(),x:num('sx'),z:num('sz'),rotation:num('srotation'),width:num('swidth'),height:num('sheight'),depth:num('sdepth'),enabled:$('senabled').checked};}
function inside(s,w=settings.room_width,d=settings.room_depth){
 const a=s.rotation*Math.PI/180;
 for(const x of [-s.width/2,s.width/2])for(const z of [-s.depth*.18,s.depth*1.05]){
  const px=s.x+Math.cos(a)*x+Math.sin(a)*z,pz=s.z-Math.sin(a)*x+Math.cos(a)*z;
  if(Math.abs(px)>w/2-.3||Math.abs(pz)>d/2-.3)return false;
 }return true;
}
$('new-shelf').onclick=()=>editShelf();
$('shelf-form').onsubmit=e=>{e.preventDefault();action(async()=>{
 const s=shelfData();if(!s.name||!inside(s))throw new Error('أعط الرف اسماً وضعه بالكامل داخل حدود المحل.');
 const spawnX=0,spawnZ=settings.room_depth/2-4,a=s.rotation*Math.PI/180;
 const dx=spawnX-s.x,dz=spawnZ-s.z,lx=Math.cos(a)*dx-Math.sin(a)*dz,lz=Math.sin(a)*dx+Math.cos(a)*dz;
 if(s.enabled&&Math.abs(lx)<s.width/2+.4&&lz>-.4&&lz<s.depth+.4)throw new Error('الرف يغطي نقطة بداية الزائر. غيّر موقعه.');
 requireOK(await db.from('shop_shelves').upsert(s).select());await load();editShelf(s);message('تم حفظ الرف.');
});};
$('delete-shelf').onclick=()=>action(async()=>{const id=val('sid');if(!id||!confirm('حذف الرف؟ ستصبح منتجاته بدون رف حتى تعيد توزيعها.'))return;requireOK(await db.from('shop_shelves').delete().eq('id',id).select());await load();editShelf();message('تم حذف الرف.');});
const map=$('map'),ctx=map.getContext('2d');let mapDrag=null;
function mapScale(){return 700/Math.max(settings.room_width||34,settings.room_depth||34);}
function drawMap(){
 const k=mapScale();ctx.clearRect(0,0,800,800);ctx.fillStyle='#eeeae2';ctx.fillRect(0,0,800,800);
 ctx.strokeStyle='#b6a28b';ctx.lineWidth=4;ctx.strokeRect(400-settings.room_width*k/2,400-settings.room_depth*k/2,settings.room_width*k,settings.room_depth*k);
 const current=val('sid');const list=shelves.filter(s=>s.store_id===val('sstore')).map(s=>s.id===current?{...s,x:num('sx'),z:num('sz'),rotation:num('srotation')}:s);
 for(const s of list){ctx.save();ctx.translate(400+s.x*k,400+s.z*k);ctx.rotate(-s.rotation*Math.PI/180);ctx.fillStyle=s.id===current?'#8c7753':s.enabled?'#26374d':'#bec4cc';ctx.fillRect(-s.width*k/2,-s.depth*k*.15,s.width*k,s.depth*k*1.15);ctx.fillStyle='#d8c39e';ctx.fillRect(-s.width*k/2,s.depth*k*.75,s.width*k,3);ctx.restore();ctx.fillStyle='#26374d';ctx.font='14px Tahoma';ctx.textAlign='center';ctx.fillText(s.name,400+s.x*k,400+s.z*k-12);}
 ctx.fillStyle='#43836c';ctx.beginPath();ctx.arc(400,400+(settings.room_depth/2-4)*k,8,0,Math.PI*2);ctx.fill();ctx.font='15px Tahoma';ctx.fillText('بداية الزائر',400+settings.spawn_x*k,400+settings.spawn_z*k+25);
}
function mapPoint(e){const r=map.getBoundingClientRect(),k=mapScale();return{x:((e.clientX-r.left)*800/r.width-400)/k,z:((e.clientY-r.top)*800/r.height-400)/k};}
map.onpointerdown=e=>{
 const p=mapPoint(e),s=shelves.find(s=>{if(s.store_id!==val('sstore'))return false;const a=s.rotation*Math.PI/180,dx=p.x-s.x,dz=p.z-s.z;return Math.abs(Math.cos(a)*dx-Math.sin(a)*dz)<s.width/2+.3&&Math.abs(Math.sin(a)*dx+Math.cos(a)*dz)<s.depth+.4;});
 if(!s)return;editShelf(s);mapDrag={id:e.pointerId,dx:p.x-s.x,dz:p.z-s.z};map.setPointerCapture(e.pointerId);
};
map.onpointermove=e=>{if(!mapDrag||mapDrag.id!==e.pointerId)return;const p=mapPoint(e);set('sx',(p.x-mapDrag.dx).toFixed(1));set('sz',(p.z-mapDrag.dz).toFixed(1));drawMap();};
for(const type of ['pointerup','pointercancel','lostpointercapture'])map.addEventListener(type,()=>mapDrag=null);
['sx','sz','srotation','swidth','sdepth'].forEach(id=>$(id).oninput=drawMap);
const settingDefs=[
 ['name','اسم المول','text'],['slogan','عبارة المول','text'],['store_url','رابط المتجر في سلة','url'],['logo_url','رابط الشعار','url'],
 ['floor_color','لون الأرضية','color'],['wall_color','لون الجدران','color'],['shelf_color','لون الأرفف','color'],['accent_color','لون التفاصيل','color'],['light_color','لون الإضاءة','color'],
 ['light_intensity','قوة الإضاءة','number',.2,4,.1],['room_width','عرض غرف المحلات','number',20,100,.1],['room_depth','طول غرف المحلات','number',20,100,.1],['room_height','ارتفاع غرف المحلات','number',8,30,.1],
 ['spawn_x','بداية الزائر في المول X','number',-12,12,.1],['spawn_z','بداية الزائر في المول Z','number',-33.5,33.5,.1],['spawn_yaw','اتجاه الزائر بالدرجات','number',-360,360,1],['walk_speed','سرعة المشي','number',1,8,.1],['multiplayer_enabled','تفعيل التسوق المشترك','checkbox']
];
function renderSettings(){
 $('settings-fields').replaceChildren();
 for(const [key,label,type,min,max,step] of settingDefs){const l=document.createElement('label');l.textContent=label;const input=document.createElement('input');input.id='setting-'+key;input.type=type;if(type==='checkbox')input.checked=settings[key];else input.value=settings[key]??'';if(type==='number'){input.min=min;input.max=max;input.step=step;}if(type!=='checkbox'&&type!=='url')input.required=true;l.append(input);$('settings-fields').append(l);}
}
$('settings-form').onsubmit=e=>{e.preventDefault();action(async()=>{
 const data={id:1};for(const [key,,type] of settingDefs){const i=$('setting-'+key);data[key]=type==='checkbox'?i.checked:type==='number'?Number(i.value):i.value.trim();}
 for(const key of ['store_url','logo_url'])if(data[key]&&!httpURL(data[key]))throw new Error('راجع الرابط.');
 if(Math.abs(data.spawn_x)>12||Math.abs(data.spawn_z)>33.5)throw new Error('نقطة البداية يجب أن تكون داخل المحل.');
 if(shelves.some(s=>s.enabled&&!inside(s,data.room_width,data.room_depth)))throw new Error('بعض الأرفف ستصبح خارج المحل بهذه الأبعاد. انقلها أولاً.');
 for(const s of shelves.filter(s=>s.enabled)){
 const a=s.rotation*Math.PI/180,dx=-s.x,dz=(data.room_depth/2-4)-s.z,lx=Math.cos(a)*dx-Math.sin(a)*dz,lz=Math.sin(a)*dx+Math.cos(a)*dz;
 if(Math.abs(lx)<s.width/2+.4&&lz>-.4&&lz<s.depth+.4)throw new Error('مدخل المحل داخل أحد الأرفف.');
 }
 if($('logo-file').files[0])data.logo_url=await upload($('logo-file').files[0]);
 requireOK(await db.from('shop_settings').upsert(data).select());$('logo-file').value='';await load();message('تم حفظ إعدادات المحل.');
});};
async function images(){
 const files=[];for(let offset=0;offset<10000;offset+=1000){const batch=requireOK(await db.storage.from('shop-images').list('',{limit:1000,offset,sortBy:{column:'created_at',order:'desc'}}));files.push(...batch);if(batch.length<1000)break;}
 $('image-list').replaceChildren();
 for(const f of files){const url=db.storage.from('shop-images').getPublicUrl(f.name).data.publicUrl;const article=document.createElement('article'),img=document.createElement('img');img.src=url;img.alt=f.name;img.loading='lazy';
 const copy=document.createElement('button');copy.textContent='نسخ الرابط';copy.onclick=async()=>{try{await navigator.clipboard.writeText(url);message('تم نسخ رابط الصورة.');}catch{message(url);}};
 const remove=document.createElement('button');remove.textContent='حذف';remove.className='danger';remove.onclick=()=>action(async()=>{if(products.some(p=>p.image_url===url)||settings.logo_url===url||screens.some(a=>a.image_url===url))throw new Error('الصورة مستخدمة. استبدلها في المنتج أو الشعار أولاً.');if(!confirm('حذف هذه الصورة نهائياً؟'))return;requireOK(await db.storage.from('shop-images').remove([f.name]));await images();message('تم حذف الصورة.');});article.append(img,copy,remove);$('image-list').append(article);}
}
$('library-files').onchange=e=>action(async()=>{for(const f of e.target.files)await upload(f);e.target.value='';await images();message('تم رفع الصور.');});
$('export-button').onclick=()=>{
 const blob=new Blob([JSON.stringify({settings,shelves,products,stores,screens},null,2)],{type:'application/json'}),url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='wesam-backup.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
};
$('import-button').onclick=()=>$('import-file').click();
$('import-file').onchange=e=>action(async()=>{
 const file=e.target.files[0];if(!file)return;if(file.size>5242880)throw new Error('حجم ملف المنتجات أكبر من 5 ميجابايت.');
 const raw=JSON.parse(await file.text()),rows=Array.isArray(raw)?raw:raw.products;
 if(!Array.isArray(rows)||!rows.length||rows.length>2000)throw new Error('الملف يجب أن يحتوي من 1 إلى 2000 منتج.');
 const ids=new Set(),positions=new Set();
 const data=rows.map((p,i)=>{
  const id=String(p.id??crypto.randomUUID());if(ids.has(id))throw new Error('معرف مكرر في الملف.');ids.add(id);
  if(typeof p.name!=='string'||!p.name.trim()||!Number.isFinite(Number(p.price))||Number(p.price)<0)throw new Error('راجع المنتج رقم '+(i+1));
  const row={id,store_id:p.store_id||val('pstore')||'accessories',name:p.name.slice(0,120),price:Number(p.price),category:String(p.category||p.cat||'إكسسوارات'),description:String(p.description||p.desc||'').slice(0,4000),image_url:httpURL(p.image_url||p.image),product_url:httpURL(p.product_url||p.url),visible:p.visible??true,shelf_id:p.shelf_id||null,row_index:p.row_index??0,slot_index:p.slot_index??0,page_index:p.page_index??0};
  if(!stores.some(s=>s.id===row.store_id))throw new Error('المحل المشار إليه غير موجود.');
  if(row.shelf_id&&!shelves.some(s=>s.id===row.shelf_id&&s.store_id===row.store_id))throw new Error('الرف المشار إليه غير موجود.');
  if(row.shelf_id&&row.visible){const key=[row.shelf_id,row.page_index,row.row_index,row.slot_index].join(':');if(positions.has(key))throw new Error('خانتان متطابقتان في الملف.');positions.add(key);}
  return row;
 });
 if(!confirm('استيراد '+data.length+' منتج؟ المنتجات ذات المعرف نفسه سيتم تحديثها.'))return;
 // One transaction at the database: a conflict rejects the whole batch.
 requireOK(await db.from('shop_products').upsert(data).select());e.target.value='';await load();message('تم استيراد '+data.length+' منتج. المنتجات بدون موقع تحتاج توزيعاً على الأرفف.');
});
document.querySelectorAll('nav button').forEach(b=>b.onclick=()=>{
 document.querySelectorAll('nav button').forEach(x=>x.classList.toggle('active',x===b));
 for(const id of ['products','shelves','settings','images','preview','stores','screens'])$(id).hidden=id!==b.dataset.tab;
 if(b.dataset.tab==='images')action(images);if(b.dataset.tab==='preview')preview();if(b.dataset.tab==='shelves')drawMap();if(b.dataset.tab==='stores')drawMallMap();
});
function preview(){$('preview-frame').src='./index.html?preview=1&t='+Date.now();}
$('refresh-preview').onclick=preview;
async function authorize(session){
 user=session?.user??null;
 if(!user){$('dashboard').hidden=true;$('login').hidden=false;$('logout').hidden=true;return;}
 const admin=requireOK(await db.from('shop_admins').select('user_id').eq('user_id',user.id).maybeSingle());
 if(!admin){$('dashboard').hidden=true;$('login').hidden=false;$('logout').hidden=false;message('تم الدخول، لكن الحساب ليس أدمن. شغّل admin-access.sql لبريد هذا الحساب.');return;}
 await load();$('dashboard').hidden=false;$('login').hidden=true;$('logout').hidden=false;editProduct();editShelf();editStore();editScreen();message('متصل بقاعدة البيانات. تغييراتك تُحفظ للمول. حدّث المعاينة لعرضها.');
}
$('login').onsubmit=e=>{e.preventDefault();action(async()=>{
 const result=await db.auth.signInWithPassword({email:val('email').trim(),password:val('password')});if(result.error)throw new Error('تعذر الدخول: '+result.error.message);
 $('password').value='';await authorize(result.data.session);
});};
$('logout').onclick=()=>action(async()=>{requireOK(await db.auth.signOut());await authorize(null);message('تم تسجيل الخروج.');});

function storeShelfOptions(){
 const previous=val('pshelf');$('pshelf').replaceChildren(new Option('بدون رف',''));
 shelves.filter(s=>s.store_id===val('pstore')).forEach(s=>$('pshelf').add(new Option(s.name+(s.enabled?'':' — مخفي'),s.id)));
 set('pshelf',shelves.some(s=>s.id===previous&&s.store_id===val('pstore'))?previous:'');renderSlots();
}
$('pstore').onchange=storeShelfOptions;
$('sstore').onchange=drawMap;
function itemList(target,rows,title,detail,select){
 $(target).replaceChildren();
 for(const row of rows){
  const item=document.createElement('div');item.className='item';const text=document.createElement('div');text.className='text';
  const b=document.createElement('b');b.textContent=title(row);
  const small=document.createElement('small');small.textContent=detail(row);
  text.append(b,small);const button=document.createElement('button');button.textContent='تعديل';button.onclick=()=>select(row);item.append(text,button);$(target).append(item);
 }
}
function listStores(){itemList('store-list',stores,s=>s.name,s=>(s.floor?'الأول':'الأرضي')+' · '+(s.side===1?'يمين':'يسار')+' · '+(s.open?'مفتوح':'قريباً')+(s.enabled?'':' · مخفي'),editStore);}
function editStore(s={}){
 for(const [id,key] of Object.entries({'store-id':'id','store-name':'name','store-floor':'floor','store-side':'side','store-z':'z','store-color':'color','store-url':'store_url'}))set(id,s[key]??({'store-floor':0,'store-side':-1,'store-z':-27,'store-color':'#d4a94e'}[id]??''));
 $('store-open').checked=s.open??false;$('store-enabled').checked=s.enabled??true;drawMallMap();
}
$('new-store').onclick=()=>editStore();
$('store-form').onsubmit=e=>{e.preventDefault();action(async()=>{
 const row={id:val('store-id')||crypto.randomUUID(),name:val('store-name').trim(),floor:num('store-floor'),side:num('store-side'),z:num('store-z'),color:val('store-color'),store_url:checkURL('store-url'),open:$('store-open').checked,enabled:$('store-enabled').checked};
 if(!row.name)throw new Error('أدخل اسم المحل.');
 if(row.enabled&&stores.some(s=>s.id!==row.id&&s.enabled&&s.floor===row.floor&&s.side===row.side&&Math.abs(s.z-row.z)<7))throw new Error('الواجهة قريبة من محل آخر. اجعل المسافة 7 أمتار أو أكثر.');
 if(row.enabled&&screens.some(a=>a.enabled&&a.floor===row.floor&&Math.sign(a.x)===row.side&&Math.abs(a.x)>11&&Math.abs(a.z-row.z)<3.3+Math.abs(Math.sin(a.rotation*Math.PI/180))*a.width/2))throw new Error('الواجهة تتداخل مع شاشة جدارية. انقل الشاشة أولاً.');
 requireOK(await db.from('mall_stores').upsert(row).select());await load();editStore(row);message('تم حفظ المحل. أضف له الأرفف والمنتجات من الأقسام الأخرى.');
});};
$('delete-store').onclick=()=>action(async()=>{
 const id=val('store-id');if(!id)return;
 if(products.some(p=>p.store_id===id)||shelves.some(s=>s.store_id===id))throw new Error('المحل يحتوي منتجات أو أرفف. انقلها أو احذفها أولاً، أو أخف المحل بدلاً من حذفه.');
 if(!confirm('حذف هذا المحل نهائياً؟'))return;
 requireOK(await db.from('mall_stores').delete().eq('id',id).select());await load();editStore();message('تم حذف المحل.');
});
function listScreens(){itemList('screen-list',screens,a=>a.title,a=>(a.floor?'الأول':'الأرضي')+' · '+(a.hanging?'معلقة':'جدارية')+(a.enabled?'':' · مخفية'),editScreen);}
function editScreen(a={}){
 for(const [id,key] of Object.entries({'ad-id':'id','ad-title':'title','ad-subtitle':'subtitle','ad-url':'link_url','ad-image':'image_url','ad-floor':'floor','ad-rotation':'rotation','ad-x':'x','ad-z':'z','ad-y':'center_y','ad-width':'width','ad-height':'height'}))
 set(id,a[key]??({'ad-floor':0,'ad-rotation':0,'ad-x':0,'ad-z':-27,'ad-y':3.15,'ad-width':2.9,'ad-height':1.7}[id]??''));
 $('ad-hanging').checked=a.hanging??true;$('ad-enabled').checked=a.enabled??true;$('ad-file').value='';
}
$('new-screen').onclick=()=>editScreen();
$('screen-form').onsubmit=e=>{e.preventDefault();action(async()=>{
 const row={id:val('ad-id')||crypto.randomUUID(),title:val('ad-title').trim(),subtitle:val('ad-subtitle'),link_url:checkURL('ad-url'),image_url:checkURL('ad-image'),floor:num('ad-floor'),rotation:num('ad-rotation'),x:num('ad-x'),z:num('ad-z'),center_y:num('ad-y'),width:num('ad-width'),height:num('ad-height'),hanging:$('ad-hanging').checked,enabled:$('ad-enabled').checked};
 const ceiling=row.floor===0?4.7:4.15;
 if(!row.title||row.center_y+row.height/2>=ceiling||row.center_y-row.height/2<=.15)throw new Error('ارتفاع الشاشة يتجاوز مساحة الدور. خفّض المركز أو ارتفاع الشاشة.');
 
 const a=row.rotation*Math.PI/180,halfX=Math.abs(Math.cos(a))*row.width/2+.1,halfZ=Math.abs(Math.sin(a))*row.width/2+.1;
 if(row.x-halfX<4&&row.x+halfX>-4&&row.z-halfZ<12&&row.z+halfZ>-5)throw new Error('الشاشة تدخل في منطقة السلالم.');
 if(Math.abs(row.x)+halfX>=13||Math.abs(row.z)+halfZ>=35)throw new Error('الشاشة تتجاوز جدران المول.');
 if(row.enabled&&stores.some(s=>s.enabled&&s.floor===row.floor&&s.side===Math.sign(row.x)&&Math.abs(row.x)>11&&Math.abs(s.z-row.z)<3.3+Math.abs(Math.sin(a))*row.width/2))throw new Error('الشاشة تغطي واجهة محل. اختر الفراغ بين المحلات.');
 if($('ad-file').files[0])row.image_url=await upload($('ad-file').files[0]);
 requireOK(await db.from('mall_screens').upsert(row).select());await load();editScreen(row);message('تم حفظ الإعلان وموقع الشاشة.');
});};
$('delete-screen').onclick=()=>action(async()=>{const id=val('ad-id');if(!id||!confirm('حذف الشاشة نهائياً؟'))return;requireOK(await db.from('mall_screens').delete().eq('id',id).select());await load();editScreen();message('تم حذف الشاشة.');});
const mallMap=$('mall-map'),mallCtx=mallMap.getContext('2d');let mallDrag=null;
const mallScale=12;
function drawMallMap(){
 if(!mallMap)return;
 const c=mallCtx,floor=num('mall-map-floor');c.clearRect(0,0,600,1000);c.fillStyle='#f3f0e9';c.fillRect(0,0,600,1000);
 c.strokeStyle='#a9997c';c.lineWidth=3;c.strokeRect(300-13*mallScale,500-35*mallScale,26*mallScale,70*mallScale);
 c.fillStyle='#d2d4d7';c.fillRect(300-3.2*mallScale,500-2.2*mallScale,6.4*mallScale,10.5*mallScale);
 c.fillStyle='#646d7a';c.font='15px Tahoma';c.textAlign='center';c.fillText('السلالم',300,500+4*mallScale);
 for(const s of stores.filter(s=>s.floor===floor)){
 const z=s.id===val('store-id')?num('store-z'):s.z;
 c.fillStyle=s.id===val('store-id')?'#8c7753':s.enabled?s.color:'#ccc';
 c.fillRect(300+s.side*12.3*mallScale-6,500+(z-3.25)*mallScale,12,6.5*mallScale);
 c.fillStyle='#26374d';c.font='11px Tahoma';c.textAlign=s.side<0?'right':'left';c.fillText(s.name,300+s.side*13.3*mallScale,500+z*mallScale);
 }
 for(const a of screens.filter(a=>a.floor===floor&&a.enabled)){c.fillStyle='#b88d37';c.beginPath();c.arc(300+a.x*mallScale,500+a.z*mallScale,6,0,Math.PI*2);c.fill();}
 c.fillStyle='#43836c';c.beginPath();c.arc(300+settings.spawn_x*mallScale,500+settings.spawn_z*mallScale,5,0,Math.PI*2);c.fill();
}
$('mall-map-floor').onchange=drawMallMap;
function mallPoint(e){const r=mallMap.getBoundingClientRect();return{x:((e.clientX-r.left)*600/r.width-300)/mallScale,z:((e.clientY-r.top)*1000/r.height-500)/mallScale};}
mallMap.onpointerdown=e=>{
 const p=mallPoint(e),f=num('mall-map-floor'),s=stores.find(s=>s.floor===f&&Math.abs(s.side*12.3-p.x)<1.5&&Math.abs(s.z-p.z)<3.4);
 if(!s)return;editStore(s);mallDrag={pointer:e.pointerId,offset:p.z-s.z};mallMap.setPointerCapture(e.pointerId);
};
mallMap.onpointermove=e=>{if(!mallDrag||mallDrag.pointer!==e.pointerId)return;const p=mallPoint(e);set('store-z',Math.max(-29,Math.min(29,p.z-mallDrag.offset)).toFixed(1));drawMallMap();};
for(const type of ['pointerup','pointercancel','lostpointercapture'])mallMap.addEventListener(type,()=>mallDrag=null);
['store-z','store-floor','store-side'].forEach(id=>$(id).oninput=drawMallMap);

try{db=await createDB('wesam-admin');db.auth.onAuthStateChange((event,session)=>{if(['SIGNED_OUT','TOKEN_REFRESHED'].includes(event))setTimeout(()=>authorize(session).catch(fail),0);});const {data,error}=await db.auth.getSession();if(error)throw error;await authorize(data.session);}catch(e){fail(e);}
