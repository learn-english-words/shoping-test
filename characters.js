import * as THREE from 'three';
import {FBXLoader} from 'three/addons/loaders/FBXLoader.js';
import {clone} from 'three/addons/utils/SkeletonUtils.js';
let cached;
export function loadCharacter(){
 if(!cached)cached=(async()=>{
  const base=new URL('./assets/characters/standard-walk/',import.meta.url);
  const response=await fetch(new URL('manifest.json',base));if(!response.ok)throw Error('Character manifest missing');
  const manifest=await response.json();
  const buffers=await Promise.all(manifest.parts.map(async name=>{const r=await fetch(new URL(name,base));if(!r.ok)throw Error('Character part missing: '+name);return new Uint8Array(await r.arrayBuffer())}));
  const bytes=new Uint8Array(manifest.byteLength);let offset=0;for(const b of buffers){bytes.set(b,offset);offset+=b.length}if(offset!==bytes.length)throw Error('Character size mismatch');
  const model=new FBXLoader().parse(bytes.buffer,base.href);
  let meshes=0;model.traverse(o=>{if(o.isMesh){meshes++;o.castShadow=true;o.frustumCulled=false;}});
  if(!meshes)throw Error('FBX contains animation without a visible character');
  const bounds=new THREE.Box3().setFromObject(model),size=bounds.getSize(new THREE.Vector3()),center=bounds.getCenter(new THREE.Vector3());
  if(!Number.isFinite(size.y)||size.y<=0)throw Error('Invalid character size');
  const scale=1.78/size.y;
  const clip=model.animations[0]?.clone();
  // Keep the walk in place: the multiplayer position controls translation.
  if(clip)for(const track of clip.tracks)if(/Hips.*position$/.test(track.name)){for(let j=3;j<track.values.length;j+=3){track.values[j]=track.values[0];track.values[j+2]=track.values[2];}}
  console.info('Character loaded',{meshes,height:size.y,animations:model.animations.length,tracks:clip?.tracks.map(t=>t.name).slice(0,5)});
  return{model,clip,scale,center,minY:bounds.min.y,meshes};
 })().catch(error=>{cached=null;throw error});
 return cached;
}
export async function createCharacter(){
 const asset=await loadCharacter(),model=clone(asset.model),root=new THREE.Group(),pivot=new THREE.Group();
 model.scale.setScalar(asset.scale);model.position.set(-asset.center.x*asset.scale,-asset.minY*asset.scale,-asset.center.z*asset.scale);
 pivot.rotation.y=Math.PI;pivot.add(model);root.add(pivot);
 root.traverse(o=>{o.userData.sharedAvatar=true;});
 const mixer=new THREE.AnimationMixer(model),action=asset.clip?mixer.clipAction(asset.clip):null;
 if(action){action.play();action.paused=true;mixer.update(0);}
 let walking=false;
 return{root,update(dt,speed){const moving=speed>.1;if(action){if(!moving&&walking){action.reset();action.play();action.paused=true;mixer.update(0);}else action.paused=!moving;action.timeScale=Math.max(.5,Math.min(2.5,speed/1.8));}walking=moving;if(moving)mixer.update(dt);},dispose(){mixer.stopAllAction();mixer.uncacheRoot(model);root.removeFromParent();}};
}
