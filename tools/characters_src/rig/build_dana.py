"""Build Dana mesh + rig -> /tmp/dana_model.blend (anim + export in author_clips.py)
blender -b -P build_dana.py"""
import sys,os; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import importlib, charlib, body, hair
from charlib import *
from body import *
from hair import wavy_long, hair_bones, hair_weights
reset()
P=dict(height=1.70,bust=1.0,hair_end=1.20,wave=1.0,head=1.12,neck=0.78,neckg=1.05)
B,J=make_joints(P); S=J['S']
E=hair_bones(J,P)
E['SweaterFront']=(V((0,-.10*S,zmap(J,1.10))),V((0,-.105*S,zmap(J,.96))),'Spine')
E['SweaterBack']=(V((0,.10*S,zmap(J,1.10))),V((0,.105*S,zmap(J,.96))),'Spine')
arm=build_armature('Dana',B,E)
# ---- sweater
def hem_extra(zb): return .004*S*smoothstep(1.0,.965,zb)
parts=[torso_shell(J,P,.955,1.41,.012*S,'sw_t',extra=hem_extra)]
for sd in(1,-1):
    p,ax=sleeve(J,P,sd,'long',.011*S,'sl',cuff=.002*S); parts+=p
sweater=join(parts,'Sweater'); remesh(sweater,.0055,smooth=5)
SW_AX=[]
for sd in(1,-1):
    N=side_name(sd); SW_AX.append((J[N+'UpperArm'][0]+V((-sd*.03,0,0)),J[N+'LowerArm'][1]))
TOR_AX=[(V((0,0,zmap(J,.9))),V((0,0,zmap(J,1.45))))]
def sweater_disp(co,n):
    d=np.zeros(len(co))
    for sd in(1,-1):
        N=side_name(sd); sj,el=J[N+'UpperArm']; _,wr=J[N+'LowerArm']
        r,t,q=seg_dist(co,sj,wr)
        on=(r<.075*S)&(co[:,0]*sd>.12*S)
        se=np.linalg.norm(co-np.array(el),axis=1); dw=np.linalg.norm(co-np.array(wr),axis=1); ds=np.linalg.norm(co-np.array(sj),axis=1)
        front=np.clip(-n[:,1]+0.3,0,None)
        dd=.0035*S*np.sin(se/.016*np.pi+sd)*gaussn(se,0,.05)*front
        dd+=.0025*S*np.sin(dw/.012*np.pi)*sstep(.10,.03,dw)
        dd+=.0015*S*np.sin(co[:,2]/.03*np.pi+co[:,1]*40)*sstep(.0,.08,ds)*sstep(.20,.12,ds)
        d+=dd*on
    zb=co[:,2]; th=np.arctan2(co[:,0],-co[:,1])
    tor=np.abs(co[:,0])<.2*S
    fold=np.sin(th*7+zb*20)*0.6+np.sin(th*11-zb*14)*0.4
    d+=tor*(.0025*S*fold*sstep(zmap(J,1.10),zmap(J,1.0),zb)*sstep(zmap(J,.955),zmap(J,.99),zb)+.003*S*gaussn(zb,zmap(J,1.0),.012))
    ax=np.abs(co[:,0])
    d+=(co[:,1]<0)*.0015*S*np.sin((co[:,2]+ax*1.4)/.03*np.pi)*gaussn(co[:,2],zmap(J,1.17),.06)*sstep(.06*S,.12*S,ax)*tor
    return d
displace_np(sweater,sweater_disp); apply_mod(sweater,'SMOOTH',factor=0.4,iterations=1)
decimate(sweater,min(1.0,9000/len(sweater.data.polygons)))
cyl_uv_np(sweater,TOR_AX+SW_AX,.036,.036)
# ---- trousers')
# ---- trousers
parts=[torso_shell(J,P,.78,1.01,.008*S,'tr_t')]
for sd in(1,-1): parts.append(pants(J,P,sd,'wide',.006*S,'leg'))
trousers=join(parts,'Trousers'); remesh(trousers,.0055,smooth=5)
LEG_AX=[]
for sd in(1,-1):
    hj,kn,an=leg_axis(J,sd); LEG_AX.append((hj+V((0,0,.05)),V((an.x,an.y,0))))
def trouser_disp(co,n):
    d=np.zeros(len(co)); z=co[:,2]
    for sd in(1,-1):
        hj,kn,an=leg_axis(J,sd)
        m=(co[:,0]*sd)>0
        th=np.arctan2(co[:,0]-an.x,-(co[:,1]-an.y))
        below=z<J['zh']-.03
        A=.0055*S*sstep(kn.z+.02,J['za']+.05,z)+.0012*S
        f=0.6*np.sin(5*th+sd*0.7+z*3)+0.4*np.sin(9*th-sd*1.1-z*5)
        dd=A*f+.0022*S*np.exp(-(th/0.12)**2)
        dd+=(co[:,1]-kn.y>0)*.0018*S*np.sin((z-kn.z)/.018*np.pi)*gaussn(z,kn.z,.04)
        dd+=.003*S*np.sin(th*3+1)*sstep(J['za']+.06,J['za'],z)
        dd*=below
        dd+=(co[:,1]<0)*.0015*S*np.sin((z+np.abs(co[:,0])*0.8)/.022*np.pi)*gaussn(z,J['zh']-.05,.04)
        d+=dd*m
    return d
displace_np(trousers,trouser_disp); apply_mod(trousers,'SMOOTH',factor=0.4,iterations=1)
decimate(trousers,min(1.0,7000/len(trousers.data.polygons)))
cyl_uv_np(trousers,LEG_AX+[(V((0,0,J['zh']-.05)),V((0,0,J['zp']+.1)))],.016,.016)
# ---- shoes')
# ---- shoes
shoes=[]
for sd in(1,-1):
    a=shoe(J,P,sd,'loafer','sh'); remesh(a,.005,smooth=3); decimate(a,min(1.0,2500/len(a.data.polygons))); shoes.append(a)
    b=sole(J,P,sd,'loafer','so'); shoes.append(b)
tick('# ---- head, hands')
# ---- head, hands
head,G=head_neck(J,P); decimate(head,min(1.0,6500/len(head.data.polygons)))
hands=[]
for sd in(1,-1): h=hand(J,P,sd,'Hand'+side_name(sd)); decimate(h,min(1.0,2000/len(h.data.polygons))); hands.append(h)
tick('# ---- collar')
# ---- collar (Peter Pan) on sweater
for sd in(1,-1):
    zc=J['zn']+.035*S
    def gf(u,v,sd=sd):
        a=math.radians(4+u*150)
        r0=.050*S; lobe=.040*S*(0.55+0.45*math.cos(math.radians(max(0,(u*150-20))*0.55)))
        r=r0+v*lobe
        return (sd*math.sin(a)*r,-math.cos(a)*r*1.05+.01*S,zc+.02)
    c=surface_patch('Collar',sweater,gf,26,7,.003*S,.004*S); shoes.append(None); 
    if sd==1: collarL=c
    else: collarR=c
collar=join([collarL,collarR],'Collar')
tick('# ---- earrings')
# ---- earrings
ear=[]
for sd in(1,-1):
    ear.append(torus('hoop',(sd*G['hx']*0.96,G['yc']+.012*G['sh'],G['eye']-.042*G['sh']),.0095*S,.0014*S,rot=Euler((0,math.radians(90),math.radians(sd*15))).to_matrix()))
earr=join(ear,'Earrings')
tick('# ---- hair')
# ---- hair
hairob,cap=wavy_long(J,P,[sweater,head],'HairClumps')
tick('# ---- materials')
# ---- materials
SK='#ECBEA0'
mSkin=mat('M_Skin',SK,rough=.55,sss=.25,normal=f"{TEX}/skin_n.png",nstrength=.15,extras={'godot_sss':0.35})
mFace=mat('M_Face',(1,1,1,1),rough=.55,sss=.25,tex=f"{TEX}/dana_face_atlas7.png",extras={'godot_sss':0.35,'atlas_cells':7})
mSw=mat('M_Sweater','#7FA3B8',rough=.9,sheen=.4,normal=f"{TEX}/knit_rib_n.png",nstrength=.8)
mTr=mat('M_Trousers','#D3BE9C',rough=.85,normal=f"{TEX}/twill_n.png",nstrength=.4)
mSh=mat('M_Shoes','#6B4A3A',rough=.45,normal=f"{TEX}/leather_n.png",nstrength=.3)
mSole=mat('M_Sole','#3E2E26',rough=.7)
mCol=mat('M_Collar','#F2E6D3',rough=.8,sheen=.3,normal=f"{TEX}/jersey_n.png",nstrength=.3)
mGold=mat('M_Gold','#C9A24A',rough=.3,metal=1.0)
mHair=mat('M_Hair',(1,1,1,1),rough=.5,tex=hair_texture('#4E3224','dana'),normal=f"{TEX}/hair_n.png",nstrength=.5)
set_mat(sweater,mSw); set_mat(trousers,mTr); set_mat(collar,mCol); set_mat(earr,mGold); set_mat(hairob,mHair); set_mat(cap,mat('M_Scalp','#3A2418',rough=.9))
for h in hands: set_mat(h,mSkin)
for o in shoes:
    if o and o.name.startswith('so'): set_mat(o,mSole)
    elif o: set_mat(o,mSh)
head.data.materials.append(mSkin); head.data.materials.append(mFace)
assign_face(head,G)
planar_uv(collar,'Z',.05)
for o in [o for o in shoes if o]: planar_uv(o,'X',.05)
for h in hands: planar_uv(h,'Y',.04)
shoes=join([o for o in shoes if o],'Shoes')
hands=join(hands,'Hands')
hairall=join([hairob,cap],'Hair')
body_parts=[sweater,trousers,shoes,head,hands,collar]
tick('# ---- weights')
# ---- weights
skin(body_parts,arm)
for o in [earr,hairall]: parent_arm(o,arm)
set_weights(earr,arm,lambda co:{'Head':1.0})
set_weights(hairall,arm,hair_weights(hairall,J,P,E))
# head/neck: keep heat but ensure skull is fully Head
def headfix(co):
    if co.z>J['zhd']+.02*S: return {'Head':1.0}
    return None
set_weights(head,arm,headfix)
# sweater hem helper bones
vg=None
def hemw(co):
    zb=co.z
    w=.65*smoothstep(zmap(J,1.08),zmap(J,.965),zb)
    if w<=0: return None
    return {'_scale':1-w,('SweaterFront' if co.y<0 else 'SweaterBack'):w}
def apply_scaled(ob,fn):
    names=[g.name for g in ob.vertex_groups]
    for n in ['SweaterFront','SweaterBack']:
        if n not in ob.vertex_groups: ob.vertex_groups.new(name=n)
    for v in ob.data.vertices:
        r=fn(v.co)
        if not r: continue
        sc=r.pop('_scale')
        for g in v.groups: g.weight*=sc
        for k,x in r.items(): ob.vertex_groups[k].add([v.index],x,'REPLACE')
apply_scaled(sweater,hemw)
for o in body_parts+[hairall]: limit_weights(o,4)
tick('# ---- AO')
# ---- AO to vertex colours
allm=body_parts+[earr,hairall]
for o in allm: shade_smooth(o)
bake_ao(allm,strength=.45,samples=16)
# hair: per-clump tint variation
hairall.data.update()
r=random.Random(3)
cl=hairall.data.attributes.get('clump')
tints={}
def ht(co,poly):
    return None
bpy.context.scene.render.engine='BLENDER_EEVEE_NEXT'
for o in allm: print(o.name,tris(o))
print('TOTAL TRIS',sum(tris(o) for o in allm))
import json
json.dump({k:[list(v[0]),list(v[1])] for k,v in J.items() if isinstance(v,tuple) and len(v)==2 and isinstance(v[0],V)},open('/tmp/dana_joints.json','w'))
bpy.ops.wm.save_as_mainfile(filepath='/tmp/dana_model.blend')
print('SAVED')
