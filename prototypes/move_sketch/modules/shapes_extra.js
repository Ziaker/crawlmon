/* MS_Geo — formas extras do Move Sketch: arcos, coroas e linhas grossas.
   Sem dependências além do THREE global (r128) recebido em build(THREE, id, p). */
(function(root,f){if(typeof module==='object'&&module.exports)module.exports=f();else root.MS_Geo=f();})(typeof window!=='undefined'?window:globalThis,function(){
'use strict';

var TAU=Math.PI*2,D2R=Math.PI/180;

var KINDS=[
{id:'arc',name:'Arco',flat:true,params:{
  sweep:{min:20,max:360,def:270,label:'Ângulo'},
  inner:{min:0.1,max:0.9,def:0.6,label:'Raio interno'}}},
{id:'open_tube',name:'Tubo aberto',flat:false,params:{
  sweep:{min:20,max:360,def:270,label:'Ângulo'},
  sides:{min:3,max:48,def:32,label:'Lados'}}},
{id:'cap',name:'Calota',flat:false,params:{
  sweep:{min:20,max:180,def:120,label:'Abertura'}}},
{id:'tray',name:'Bandeja',flat:false,params:{}},
{id:'torus_arc',name:'Toro aberto',flat:false,params:{
  sweep:{min:20,max:360,def:270,label:'Ângulo'},
  tube:{min:0.1,max:0.6,def:0.3,label:'Espessura'}}},
{id:'crown',name:'Coroa',flat:true,params:{
  spikes:{min:3,max:24,def:8,label:'Pontas'},
  spikeLen:{min:0.1,max:0.8,def:0.35,label:'Altura da ponta'},
  inner:{min:0.1,max:0.9,def:0.6,label:'Raio interno'}}},
{id:'crown3d',name:'Coroa 3D',flat:false,params:{
  spikes:{min:3,max:24,def:8,label:'Pontas'},
  spikeLen:{min:0.1,max:0.8,def:0.4,label:'Altura da ponta'}}},
{id:'wave',name:'Onda',flat:true,params:{
  waves:{min:1,max:8,def:3,label:'Ondas'},
  amp:{min:0.05,max:0.5,def:0.25,label:'Amplitude'},
  thick:{min:0.02,max:0.3,def:0.08,label:'Espessura'}}},
{id:'zigzag',name:'Zigue-zague',flat:true,params:{
  teeth:{min:2,max:12,def:5,label:'Dentes'},
  amp:{min:0.05,max:0.5,def:0.3,label:'Amplitude'},
  thick:{min:0.02,max:0.3,def:0.08,label:'Espessura'}}},
{id:'spiral',name:'Espiral',flat:true,params:{
  turns:{min:1,max:6,def:3,label:'Voltas'},
  thick:{min:0.02,max:0.3,def:0.08,label:'Espessura'}}},
{id:'chevron',name:'Chevron',flat:true,params:{
  angle:{min:30,max:150,def:90,label:'Ângulo'},
  thick:{min:0.02,max:0.3,def:0.1,label:'Espessura'}}},
{id:'arcline',name:'Arco em linha',flat:true,params:{
  sweep:{min:20,max:360,def:180,label:'Ângulo'},
  thick:{min:0.02,max:0.3,def:0.08,label:'Espessura'}}}
];

var BY={};
KINDS.forEach(function(d){BY[d.id]=d;});

function pv(value,spec){
  var v=(value===null||value===undefined)?NaN:parseFloat(value);
  if(!isFinite(v))v=spec.def;
  if(v<spec.min)v=spec.min;
  if(v>spec.max)v=spec.max;
  return v;
}

function readParams(id,p){
  var desc=BY[id],out={},k;
  p=p||{};
  if(!desc)return out;
  for(k in desc.params){
    if(Object.prototype.hasOwnProperty.call(desc.params,k))out[k]=pv(p[k],desc.params[k]);
  }
  return out;
}

function centerGeo(g){
  if(!g)return g;
  g.computeBoundingBox();
  var b=g.boundingBox;
  if(b)g.translate(-(b.min.x+b.max.x)/2,-(b.min.y+b.max.y)/2,-(b.min.z+b.max.z)/2);
  return g;
}

function addQuad(out,a,b,c,d){
  out.push(a[0],a[1],a[2],b[0],b[1],b[2],c[0],c[1],c[2]);
  out.push(a[0],a[1],a[2],c[0],c[1],c[2],d[0],d[1],d[2]);
}

function geoFromPos(THREE,pos){
  var g=new THREE.BufferGeometry();
  g.setAttribute('position',new THREE.Float32BufferAttribute(pos,3));
  g.computeVertexNormals();
  return g;
}

function slab(THREE,shape){
  var g=new THREE.ExtrudeGeometry(shape,{depth:1,bevelEnabled:false,curveSegments:64,steps:1});
  g.translate(0,0,-0.5);
  return g;
}

function arcShape(THREE,sweepDeg,innerFrac){
  var R=0.5,r=R*innerFrac,a1=sweepDeg*D2R,s=new THREE.Shape(),hole;
  if(a1>=TAU-1e-4){
    s.absarc(0,0,R,0,TAU,false);
    hole=new THREE.Path();
    hole.absarc(0,0,r,0,TAU,true);
    s.holes.push(hole);
  }else{
    s.absarc(0,0,R,0,a1,false);
    s.absarc(0,0,r,a1,0,true);
    s.closePath();
  }
  return s;
}

function crownShape(THREE,spikes,spikeLen,innerFrac){
  var n=Math.max(3,Math.round(spikes)),Ro=0.5,tip=Ro*(1+spikeLen),ri=Ro*innerFrac,
      step=TAU/n,s=new THREE.Shape(),first=true,k,j,a0,pts,p,hole;
  function at(a,r){return [r*Math.cos(a),r*Math.sin(a)];}
  for(k=0;k<n;k++){
    a0=k*step;
    pts=[at(a0,Ro),at(a0+step*0.30,tip),at(a0+step*0.60,Ro),at(a0+step*0.80,Ro)];
    for(j=0;j<pts.length;j++){
      p=pts[j];
      if(first){s.moveTo(p[0],p[1]);first=false;}else s.lineTo(p[0],p[1]);
    }
  }
  s.closePath();
  hole=new THREE.Path();
  hole.absarc(0,0,ri,0,TAU,true);
  s.holes.push(hole);
  return s;
}

function trayGeo(THREE){
  var x0=-0.5,x1=0.5,y0=-0.5,y1=0.5,z0=-0.5,z1=0.5,pos=[];
  addQuad(pos,[x0,y0,z0],[x1,y0,z0],[x1,y0,z1],[x0,y0,z1]);
  addQuad(pos,[x0,y0,z1],[x1,y0,z1],[x1,y1,z1],[x0,y1,z1]);
  addQuad(pos,[x1,y0,z0],[x0,y0,z0],[x0,y1,z0],[x1,y1,z0]);
  addQuad(pos,[x0,y0,z0],[x0,y0,z1],[x0,y1,z1],[x0,y1,z0]);
  addQuad(pos,[x1,y0,z1],[x1,y0,z0],[x1,y1,z0],[x1,y1,z1]);
  return geoFromPos(THREE,pos);
}

function crown3dGeo(THREE,spikes,spikeLen){
  var n=Math.max(3,Math.round(spikes)),S=n*2,R=0.5,y0=-0.5,y1=0.5,tooth=spikeLen,
      pos=[],j,t0,t1,b0,b1,v0,v1;
  function ring(a,y){return [R*Math.cos(a),y,R*Math.sin(a)];}
  function topY(i){return (i%2===1)?y1+tooth:y1;}
  for(j=0;j<S;j++){
    t0=j*TAU/S;
    t1=(j+1)*TAU/S;
    b0=ring(t0,y0);b1=ring(t1,y0);
    v0=ring(t0,topY(j));v1=ring(t1,topY((j+1)%S));
    addQuad(pos,b1,b0,v0,v1);
  }
  return geoFromPos(THREE,pos);
}

function ribbonGeo(THREE,pts,thick){
  var n=pts.length,h=thick*0.5,pos=[],L=[],R=[],i,a,b,p,tx,ty,len,nx,ny;
  if(n<2)return geoFromPos(THREE,[0,0,0,0.01,0,0,0,0.01,0]);
  for(i=0;i<n;i++){
    a=pts[i>0?i-1:0];
    b=pts[i<n-1?i+1:n-1];
    tx=b[0]-a[0];ty=b[1]-a[1];
    len=Math.sqrt(tx*tx+ty*ty);
    if(len<1e-9){tx=1;ty=0;}else{tx/=len;ty/=len;}
    nx=-ty;ny=tx;
    p=pts[i];
    L.push([p[0]+nx*h,p[1]+ny*h,0]);
    R.push([p[0]-nx*h,p[1]-ny*h,0]);
  }
  for(i=0;i<n-1;i++)addQuad(pos,L[i],R[i],R[i+1],L[i+1]);
  return geoFromPos(THREE,pos);
}

function wavePts(waves,amp){
  var n=Math.max(24,Math.round(waves*32)),pts=[],i,t;
  for(i=0;i<=n;i++){
    t=i/n;
    pts.push([-0.5+t,amp*Math.sin(t*TAU*waves)]);
  }
  return pts;
}

function zigzagPts(teeth,amp){
  var n=Math.max(2,Math.round(teeth)),seg=n*2,pts=[],i,t;
  for(i=0;i<=seg;i++){
    t=i/seg;
    pts.push([-0.5+t,(i%2===0?-amp:amp)]);
  }
  return pts;
}

function spiralPts(turns){
  var n=Math.max(24,Math.round(turns*48)),r0=0.04,r1=0.48,pts=[],i,t,ang,r;
  for(i=0;i<=n;i++){
    t=i/n;
    ang=t*turns*TAU;
    r=r0+(r1-r0)*t;
    pts.push([r*Math.cos(ang),r*Math.sin(ang)]);
  }
  return pts;
}

function chevronPts(angleDeg){
  var w=0.5,half=angleDeg*D2R*0.5,h=w/Math.tan(half);
  return [[-w,-h],[0,0],[w,-h]];
}

function arcPts(sweepDeg){
  var n=Math.max(8,Math.round(sweepDeg/3)),rad=sweepDeg*D2R,r=0.45,pts=[],i,a;
  for(i=0;i<=n;i++){
    a=i/n*rad;
    pts.push([r*Math.cos(a),r*Math.sin(a)]);
  }
  return pts;
}

function build(THREE,id,p){
  if(!THREE)throw new Error('MS_Geo.build: informe o THREE como primeiro argumento.');
  var q=readParams(id,p),g,sides,arc;
  switch(id){
    case 'arc':
      g=slab(THREE,arcShape(THREE,q.sweep,q.inner));
      break;
    case 'open_tube':
      sides=Math.max(3,Math.round(q.sides));
      g=new THREE.CylinderGeometry(0.5,0.5,1,sides,1,true,0,q.sweep*D2R);
      break;
    case 'cap':
      g=new THREE.SphereGeometry(0.5,48,24,0,TAU,0,q.sweep*D2R);
      break;
    case 'tray':
      g=trayGeo(THREE);
      break;
    case 'torus_arc':
      arc=q.sweep*D2R;
      g=new THREE.TorusGeometry(0.35,q.tube*0.5,16,Math.max(8,Math.round(64*arc/TAU)),arc);
      break;
    case 'crown':
      g=slab(THREE,crownShape(THREE,q.spikes,q.spikeLen,q.inner));
      break;
    case 'crown3d':
      g=crown3dGeo(THREE,q.spikes,q.spikeLen);
      break;
    case 'wave':
      g=ribbonGeo(THREE,wavePts(q.waves,q.amp),q.thick);
      break;
    case 'zigzag':
      g=ribbonGeo(THREE,zigzagPts(q.teeth,q.amp),q.thick);
      break;
    case 'spiral':
      g=ribbonGeo(THREE,spiralPts(q.turns),q.thick);
      break;
    case 'chevron':
      g=ribbonGeo(THREE,chevronPts(q.angle),q.thick);
      break;
    case 'arcline':
      g=ribbonGeo(THREE,arcPts(q.sweep),q.thick);
      break;
    default:
      g=new THREE.BoxGeometry(0.6,0.6,0.6);
  }
  return centerGeo(g);
}

return {KINDS:KINDS,build:build};
});
