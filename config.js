export const SUPABASE_URL='https://ahfakhnrmcnhouutstrf.supabase.co';
export const SUPABASE_KEY='sb_publishable_YELX8xFw7NpaOJ93ylpQFw_I4zKnNBk';
export async function createDB(storageKey='wesam-shop'){
 const {createClient}=await import('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm');
 return createClient(SUPABASE_URL,SUPABASE_KEY,{auth:{storageKey,persistSession:true,autoRefreshToken:true,detectSessionInUrl:false}});
}
export function httpURL(value){try{const u=new URL(value);return ['http:','https:'].includes(u.protocol)?u.href:'';}catch{return '';}}
export async function allRows(db,table){
 let rows=[];for(let offset=0;offset<10000;offset+=1000){
  const {data,error}=await db.from(table).select('*').order('id').range(offset,offset+999);
  if(error)throw error;rows.push(...data);if(data.length<1000)return rows;
 }throw new Error('عدد السجلات تجاوز حد التحميل.');
}
export function requireOK(result){if(result.error)throw result.error;return result.data;}
