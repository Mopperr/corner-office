"""Corner Office character library (Blender 4.2, headless).
Skeleton (Godot SkeletonProfileHumanoid names), mesh builders (voxel-remeshed garment
shells), materials, weights, export.  Blender: Z-up, character faces -Y, her left = +X."""
import bpy, bmesh, math, os, random, time
_T0=time.time()
def tick(msg): print(f'[{time.time()-_T0:7.1f}s] {msg}',flush=True)
import numpy as np
from mathutils import Vector as V, Matrix as M, Quaternion as Q, Euler
from mathutils.bvhtree import BVHTree
A=os.path.abspath(os.path.join(os.path.dirname(__file__),"../.."))
TEX=f"{A}/textures/characters"
FINGERS=['Thumb','Index','Middle','Ring','Little']
def fseg(f): return ['Metacarpal','Proximal','Distal'] if f=='Thumb' else ['Proximal','Intermediate','Distal']
def side_name(s): return 'Left' if s>0 else 'Right'
def hexc(h,a=1.0):
    h=h.lstrip('#'); c=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    return tuple((x/12.92 if x<=0.04045 else ((x+0.055)/1.055)**2.4) for x in c)+(a,)

# ---------------------------------------------------------------- scene utils
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for c in list(bpy.data.collections): bpy.data.collections.remove(c)
def link(ob):
    bpy.context.scene.collection.objects.link(ob); return ob
def mesh_from(name,verts,faces):
    me=bpy.data.meshes.new(name); me.from_pydata([tuple(v) for v in verts],[],faces); me.update()
    return link(bpy.data.objects.new(name,me))
def activate(ob):
    for o in bpy.context.view_layer.objects: o.select_set(False)
    ob.select_set(True); bpy.context.view_layer.objects.active=ob
def apply_mod(ob,typ,**kw):
    m=ob.modifiers.new(typ.lower(),typ)
    for k,v in kw.items(): setattr(m,k,v)
    activate(ob); bpy.ops.object.modifier_apply(modifier=m.name); return ob
def join(objs,name=None):
    objs=[o for o in objs if o]
    activate(objs[0])
    for o in objs[1:]: o.select_set(True)
    bpy.ops.object.join(); ob=bpy.context.view_layer.objects.active
    if name: ob.name=name; ob.data.name=name
    return ob
def remesh(ob,voxel,smooth=4,smooth_f=0.5):
    apply_mod(ob,'REMESH',mode='VOXEL',voxel_size=voxel,use_smooth_shade=True)
    if smooth: apply_mod(ob,'SMOOTH',factor=smooth_f,iterations=smooth)
    return ob
def decimate(ob,ratio):
    if ratio<1: apply_mod(ob,'DECIMATE',ratio=ratio)
    return ob
def shade_smooth(ob):
    for p in ob.data.polygons: p.use_smooth=True
def tris(ob): return sum(len(p.vertices)-2 for p in ob.data.polygons)

# ---------------------------------------------------------------- primitives
def superellipse(n,rx,ryf,ryb,e=2.4,yc=0.0):
    pts=[]
    for i in range(n):
        t=2*math.pi*i/n; c,s=math.cos(t),math.sin(t)
        x=rx*math.copysign(abs(c)**(2/e),c); yy=math.copysign(abs(s)**(2/e),s)
        y=(-ryf if s<0 else ryb)*abs(yy)
        pts.append((x,y+yc))
    return pts
def loft_z(name,sections,n=40,e=2.4,cap=True):
    """sections: (z, cx, cy, hw, front, back). Closed tube along Z."""
    verts=[];faces=[]
    for (z,cx,cy,hw,fr,bk) in sections:
        for (x,y) in superellipse(n,hw,fr,bk,e): verts.append((cx+x,cy+y,z))
    R=len(sections)
    for r in range(R-1):
        for i in range(n):
            a=r*n+i;b=r*n+(i+1)%n;faces.append((a,b,b+n,a+n))
    if cap:
        faces.append(tuple(range(n))[::-1]); faces.append(tuple(range((R-1)*n,R*n)))
    return mesh_from(name,verts,faces)
def catmull(pts,samples):
    P=[V(p) for p in pts]; P=[P[0]*2-P[1]]+P+[P[-1]*2-P[-2]]
    out=[]
    for k in range(samples):
        t=k/(samples-1)*(len(P)-3); i=min(int(t),len(P)-4); u=t-i
        p0,p1,p2,p3=P[i:i+4]
        out.append(0.5*((2*p1)+(-p0+p2)*u+(2*p0-5*p1+4*p2-p3)*u*u+(-p0+3*p1-3*p2+p3)*u**3))
    return out
def tube(name,pts,radii,n=20,samples=None,flat=1.0,up=V((0,0,1)),cap=True,ends_round=True):
    """pts polyline, radii per pt (interpolated). flat: y-scale of section in the frame (width=radius, thickness=radius*flat)."""
    samples=samples or max(8,len(pts)*6)
    C=catmull(pts,samples)
    rr=np.interp(np.linspace(0,1,samples),np.linspace(0,1,len(radii)),radii)
    if isinstance(flat,(int,float)): fl=[flat]*samples
    else: fl=np.interp(np.linspace(0,1,samples),np.linspace(0,1,len(flat)),flat)
    verts=[];faces=[]
    prevN=None
    for k,c in enumerate(C):
        t=(C[min(k+1,samples-1)]-C[max(k-1,0)]).normalized()
        if prevN is None:
            nrm=up-t*up.dot(t)
            if nrm.length<1e-4: nrm=V((1,0,0))-t*t.x
        else: nrm=prevN-t*prevN.dot(t)
        nrm.normalize(); prevN=nrm; b=t.cross(nrm)
        for i in range(n):
            a=2*math.pi*i/n
            verts.append(c+nrm*math.cos(a)*rr[k]+b*math.sin(a)*rr[k]*fl[k])
    for k in range(samples-1):
        for i in range(n):
            a=k*n+i;b2=k*n+(i+1)%n;faces.append((a,b2,b2+n,a+n))
    if cap:
        faces.append(tuple(range(n))[::-1]); faces.append(tuple(range((samples-1)*n,samples*n)))
    ob=mesh_from(name,verts,faces)
    return ob
def ellipsoid(name,c,r,seg=32,rings=16,rot=None):
    bm=bmesh.new(); bmesh.ops.create_uvsphere(bm,u_segments=seg,v_segments=rings,radius=1.0)
    for v in bm.verts:
        p=V((v.co.x*r[0],v.co.y*r[1],v.co.z*r[2]))
        if rot: p=rot@p
        v.co=p+V(c)
    me=bpy.data.meshes.new(name); bm.to_mesh(me); bm.free(); return link(bpy.data.objects.new(name,me))
def rbox(name,c,size,rot=None,bevel=0.004,seg=3):
    bm=bmesh.new(); bmesh.ops.create_cube(bm,size=1.0)
    for v in bm.verts: v.co=V((v.co.x*size[0],v.co.y*size[1],v.co.z*size[2]))
    if bevel>0: bmesh.ops.bevel(bm,geom=list(bm.edges),offset=bevel,segments=seg,affect='EDGES',profile=0.5)
    for v in bm.verts:
        p=v.co.copy()
        if rot: p=rot@p
        v.co=p+V(c)
    me=bpy.data.meshes.new(name); bm.to_mesh(me); bm.free(); ob=link(bpy.data.objects.new(name,me)); shade_smooth(ob); return ob
def cyl(name,c,r,h,n=24,rot=None,bevel=0.0):
    bm=bmesh.new(); bmesh.ops.create_cone(bm,cap_ends=True,segments=n,radius1=r,radius2=r,depth=h)
    if bevel>0:
        bmesh.ops.bevel(bm,geom=[e for e in bm.edges if not e.smooth or True if abs(e.verts[0].co.z-e.verts[1].co.z)<1e-6],offset=bevel,segments=3,affect='EDGES',profile=0.5)
    for v in bm.verts:
        p=v.co.copy()
        if rot: p=rot@p
        v.co=p+V(c)
    me=bpy.data.meshes.new(name); bm.to_mesh(me); bm.free(); ob=link(bpy.data.objects.new(name,me)); return ob

# ---------------------------------------------------------------- skeleton
def make_joints(P):
    H=P.get('height',1.70)
    base=dict(ankle=.075,leg=.795,hipj=.06,torso=.44,neck=.095,head=.215)
    m=dict(ankle=1,leg=P.get('leg',1.0),hipj=1,torso=P.get('torso',1.0),neck=P.get('neck',1.0),head=P.get('head',1.0))
    S=H/sum(base[k]*m[k] for k in base)
    L={k:base[k]*m[k]*S for k in base}
    s=S; sw=P.get('shoulder',1.0)*S; hw=P.get('hipw',1.0)*S; aw=P.get('arm',1.0)*S; hs=P.get('hand',1.0)*S
    za=L['ankle']; zh=za+L['leg']; zp=zh+L['hipj']; zn=zp+L['torso']; zhd=zn+L['neck']; zt=zhd+L['head']
    tl=L['torso']
    B={}  # name: (head, tail, parent)
    zs=[zp, zp+.2045*tl, zp+.4545*tl, zp+.7045*tl, zn]
    ys=[0,0,.005*s,.01*s,.02*s]
    B['Hips']=(V((0,ys[0],zs[0])),V((0,ys[1],zs[1])),None)
    B['Spine']=(V((0,ys[1],zs[1])),V((0,ys[2],zs[2])),'Hips')
    B['Chest']=(V((0,ys[2],zs[2])),V((0,ys[3],zs[3])),'Spine')
    B['UpperChest']=(V((0,ys[3],zs[3])),V((0,ys[4],zs[4])),'Chest')
    B['Neck']=(V((0,ys[4],zs[4])),V((0,.012*s,zhd)),'UpperChest')
    B['Head']=(V((0,.012*s,zhd)),V((0,.012*s,zt)),'Neck')
    J=dict(S=S,L=L,zt=zt,zhd=zhd,zn=zn,zp=zp,zh=zh,za=za,hs=hs)
    for sd in (1,-1):
        N=side_name(sd)
        sj=V((sd*.165*sw,.015*s,zn-.018*s))
        B[N+'Shoulder']=(V((sd*.02*s,-.005*s,zn-.03*s)),sj,'UpperChest')
        d=V((sd*math.cos(math.radians(45)),0,-math.sin(math.radians(45))))
        el=sj+d*.28*aw+V((0,.02*s,0)); wr=el+d*.235*aw+V((0,-.02*s,0))
        f=(wr-el).normalized()
        B[N+'UpperArm']=(sj,el,N+'Shoulder'); B[N+'LowerArm']=(el,wr,N+'UpperArm')
        n=V((-sd*.707,0,-.707)); n=(n-f*n.dot(f)).normalized(); w=V((0,-1,0)); w=(w-f*w.dot(f)-n*w.dot(n)).normalized()
        B[N+'Hand']=(wr,wr+f*.085*hs,N+'LowerArm')
        J[N+'_handframe']=(f,n,w)
        fd={'Index':(.083,.026,.06,[.040,.024,.020]),'Middle':(.087,.008,0,[.045,.028,.022]),
            'Ring':(.083,-.010,-.06,[.042,.026,.021]),'Little':(.076,-.026,-.13,[.032,.020,.018])}
        for fn,(al,off,spr,ls) in fd.items():
            p=wr+f*al*hs+w*off*hs+n*0.002*hs; dd=(f+w*spr).normalized(); par=N+'Hand'
            for seg,l in zip(fseg(fn),ls):
                q=p+dd*l*hs; bn=f"{N}{fn}{seg}"; B[bn]=(p,q,par); par=bn; p=q
        p=wr+f*.022*hs+w*.020*hs+n*.010*hs; dd=(f*0.55+w*0.75+n*0.30).normalized(); par=N+'Hand'
        for seg,l in zip(fseg('Thumb'),[.040,.033,.028]):
            q=p+dd*l*hs; bn=f"{N}Thumb{seg}"; B[bn]=(p,q,par); par=bn; p=q; dd=(dd*0.85+f*0.15).normalized()
        ha=wr+f*.075*hs+n*.024*hs
        B[f'HandAttach_{"L" if sd>0 else "R"}']=(ha,ha+f*.04*hs,N+'Hand')
        hj=V((sd*.088*hw,0,zh)); kn=V((sd*.092*hw,-.012*s,za+L['leg']*0.497)); an=V((sd*.095*hw,.015*s,za))
        ball=V((sd*.10*hw,-.105*s*P.get('foot',1.0),.02*s)); toe=V((sd*.10*hw,-.165*s*P.get('foot',1.0),.015*s))
        B[N+'UpperLeg']=(hj,kn,'Hips'); B[N+'LowerLeg']=(kn,an,N+'UpperLeg')
        B[N+'Foot']=(an,ball,N+'LowerLeg'); B[N+'Toes']=(ball,toe,N+'Foot')
        J[N+'_heel']=V((sd*.095*hw,.05*s,0))
    for k,(h,t,p) in B.items(): J[k]=(h.copy(),t.copy())
    return B,J

NONDEFORM_PREFIX=('HandAttach',)
def build_armature(name,B,extra=None):
    arm=bpy.data.armatures.new(name); ob=link(bpy.data.objects.new(name,arm))
    activate(ob); bpy.ops.object.mode_set(mode='EDIT')
    allb=dict(B); 
    if extra: allb.update(extra)
    for k,(h,t,p) in allb.items():
        eb=arm.edit_bones.new(k); eb.head=h; eb.tail=t
        d=(t-h).normalized()
        ref=V((0,0,1)) if abs(d.y)>0.7 else V((0,-1,0))
        eb.align_roll(ref)
    for k,(h,t,p) in allb.items():
        if p: 
            eb=arm.edit_bones[k]; eb.parent=arm.edit_bones[p]
            eb.use_connect=False
        if k.startswith(NONDEFORM_PREFIX): arm.edit_bones[k].use_deform=False
    bpy.ops.object.mode_set(mode='OBJECT')
    return ob

# ---------------------------------------------------------------- materials
def img(path,noncolor=False):
    im=bpy.data.images.load(path,check_existing=True)
    if noncolor: im.colorspace_settings.name='Non-Color'
    return im
def mat(name,color,rough=0.7,metal=0.0,normal=None,nstrength=0.6,tex=None,sss=0.0,sheen=0.0,emit=None,extras=None):
    m=bpy.data.materials.new(name); m.use_nodes=True; nt=m.node_tree; b=nt.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value=hexc(color) if isinstance(color,str) else color
    b.inputs['Roughness'].default_value=rough; b.inputs['Metallic'].default_value=metal
    if sss>0:
        b.inputs['Subsurface Weight'].default_value=sss
        b.inputs['Subsurface Radius'].default_value=(1.0,0.35,0.2); b.inputs['Subsurface Scale'].default_value=0.012
    if sheen>0: b.inputs['Sheen Weight'].default_value=sheen
    if tex:
        t=nt.nodes.new('ShaderNodeTexImage'); t.image=img(tex); nt.links.new(t.outputs['Color'],b.inputs['Base Color'])
    if normal:
        t=nt.nodes.new('ShaderNodeTexImage'); t.image=img(normal,True); nm=nt.nodes.new('ShaderNodeNormalMap'); nm.inputs['Strength'].default_value=nstrength
        nt.links.new(t.outputs['Color'],nm.inputs['Color']); nt.links.new(nm.outputs['Normal'],b.inputs['Normal'])
    if emit:
        b.inputs['Emission Color'].default_value=hexc(emit); b.inputs['Emission Strength'].default_value=1.0
    # preview: multiply baked AO vertex colour like Godot's vertex_color_use_as_albedo
    src=b.inputs['Base Color'].links[0].from_socket if b.inputs['Base Color'].links else None
    ca=nt.nodes.new('ShaderNodeVertexColor'); ca.layer_name='Col'
    mx=nt.nodes.new('ShaderNodeMix'); mx.data_type='RGBA'; mx.blend_type='MULTIPLY'; mx.inputs['Factor'].default_value=1.0
    if src: nt.links.new(src,mx.inputs[6])
    else: mx.inputs[6].default_value=b.inputs['Base Color'].default_value
    nt.links.new(ca.outputs['Color'],mx.inputs[7]); nt.links.new(mx.outputs[2],b.inputs['Base Color'])
    if extras:
        for k,v in extras.items(): m[k]=v
    return m
def set_mat(ob,m):
    ob.data.materials.clear(); ob.data.materials.append(m)
    for p in ob.data.polygons: p.material_index=0
    return ob
def hair_texture(color_hex,name):
    """coloured strand albedo from the streak map"""
    path=f"{TEX}/hair_{name}.png"
    import subprocess
    subprocess.run(["python3","-c",f"""
import numpy as np
from PIL import Image
s=np.asarray(Image.open('{TEX}/hair_streak.png'),float)/255
c=np.array([int('{color_hex}'.lstrip('#')[i:i+2],16) for i in (0,2,4)],float)
lighter=np.minimum(c*1.55+18,255)
k=((s-0.7)/0.3*0.55)[...,None]
Image.fromarray(np.clip(c*(1-k)+lighter*k,0,255).astype(np.uint8)).save('{path}')
"""],check=True)
    return path
    s=None
    c=np.array([int(color_hex.lstrip('#')[i:i+2],16) for i in (0,2,4)],float)
    lighter=np.minimum(c*1.55+18,255)
    out=c*(1-(s-0.7)/0.3*0.55)[...,None]+lighter*((s-0.7)/0.3*0.55)[...,None]
    Image.fromarray(np.clip(out,0,255).astype(np.uint8)).save(path); return path

# ---------------------------------------------------------------- UV helpers
def cyl_uv(ob,axes,tile_u,tile_v,layer='UVMap'):
    """axes: list of (a, b) segment axis per part; vertex assigned to nearest axis segment.
    u = angle*circ/tile_u (wrapped), v = along/tile_v"""
    me=ob.data
    if not me.uv_layers: me.uv_layers.new(name=layer)
    uv=me.uv_layers.active.data
    co=[v.co for v in me.vertices]
    vinfo={}
    for i,p in enumerate(co):
        best=None
        for (a,b) in axes:
            a=V(a);b=V(b);ab=b-a;t=max(0,min(1,(p-a).dot(ab)/ab.length_squared));q=a+ab*t;d=(p-q).length
            if best is None or d<best[0]: best=(d,a,b,t,q)
        d,a,b,t,q=best; ax=(b-a).normalized()
        ref=V((0,-1,0)) if abs(ax.y)<0.9 else V((0,0,1)); r1=(ref-ax*ref.dot(ax)).normalized(); r2=ax.cross(r1)
        rel=p-q; ang=math.atan2(rel.dot(r2),rel.dot(r1))
        circ=2*math.pi*max(d,0.02)
        vinfo[i]=(ang,(p-a).dot(ax),circ)
    for poly in me.polygons:
        angs=[vinfo[me.loops[li].vertex_index][0] for li in poly.loop_indices]
        a0=angs[0]
        for li in poly.loop_indices:
            ang,along,circ=vinfo[me.loops[li].vertex_index]
            while ang-a0>math.pi: ang-=2*math.pi
            while ang-a0<-math.pi: ang+=2*math.pi
            uv[li].uv=(ang*circ/(2*math.pi)/tile_u, along/tile_v)
def planar_uv(ob,axis='Y',scale=1.0):
    me=ob.data
    if not me.uv_layers: me.uv_layers.new(name='UVMap')
    uv=me.uv_layers.active.data
    for poly in me.polygons:
        for li in poly.loop_indices:
            c=me.vertices[me.loops[li].vertex_index].co
            uv[li].uv=((c.x/scale, c.z/scale) if axis=='Y' else (c.y/scale,c.z/scale) if axis=='X' else (c.x/scale,c.y/scale))

# ---------------------------------------------------------------- displacement helpers
def displace(ob,fn):
    """fn(co, normal) -> offset along normal"""
    me=ob.data; me.update()
    for v in me.vertices:
        d=fn(v.co,v.normal)
        if d: v.co=v.co+v.normal*d
    me.update()
def smoothstep(a,b,x):
    t=max(0.0,min(1.0,(x-a)/(b-a))); return t*t*(3-2*t)
def gauss(x,c,w): return math.exp(-((x-c)/w)**2)

# ---------------------------------------------------------------- vertex colours / AO
def bake_ao(objs,strength=0.55,samples=24):
    sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.samples=samples; sc.cycles.device='CPU'
    for ob in objs:
        me=ob.data
        if 'Col' not in me.color_attributes: me.color_attributes.new('Col','BYTE_COLOR','CORNER')
        me.color_attributes.active_color=me.color_attributes['Col']
    for ob in objs:
        activate(ob)
        bpy.ops.object.bake(type='AO',target='VERTEX_COLORS')
    for ob in objs:
        ca=ob.data.color_attributes['Col']
        tint=ob.get('_tint')
        for i,d in enumerate(ca.data):
            a=d.color[0]; v=1-strength+strength*a
            d.color=(v,v,v,1)
def vcol_tint(ob,fn):
    """multiply corner colours by fn(vertex co)->(r,g,b)"""
    me=ob.data; ca=me.color_attributes['Col']
    for poly in me.polygons:
        for li in poly.loop_indices:
            c=fn(me.vertices[me.loops[li].vertex_index].co, poly)
            if c is None: continue
            d=ca.data[li].color; ca.data[li].color=(d[0]*c[0],d[1]*c[1],d[2]*c[2],1)

# ---------------------------------------------------------------- weights
def skin(mesh_objs,arm,heat=True):
    """bone-heat weights with helper bones temporarily non-deforming"""
    helper=[b for b in arm.data.bones if b.name.startswith(('Hair','Sweater','Cloth','HandAttach','Prop'))]
    for b in helper: b.use_deform=False
    for ob in mesh_objs:
        activate(ob); arm.select_set(True); bpy.context.view_layer.objects.active=arm
        bpy.ops.object.parent_set(type='ARMATURE_AUTO' if heat else 'ARMATURE_NAME')
    for b in helper:
        if not b.name.startswith('HandAttach'): b.use_deform=True
def set_weights(ob,arm,fn):
    """fn(co)-> dict bone:weight (replaces all weights for that vertex if not None)"""
    names=[b.name for b in arm.data.bones]
    for n in names:
        if n not in ob.vertex_groups: ob.vertex_groups.new(name=n)
    vg={g.name:g for g in ob.vertex_groups}
    for v in ob.data.vertices:
        w=fn(v.co)
        if w is None: continue
        for g in v.groups: vg[ob.vertex_groups[g.group].name].remove([v.index])
        tot=sum(w.values()) or 1
        for k,x in w.items():
            if x>1e-4: vg[k].add([v.index],x/tot,'REPLACE')
def parent_arm(ob,arm):
    ob.parent=arm; m=ob.modifiers.new('Armature','ARMATURE'); m.object=arm
def limit_weights(ob,n=4):
    activate(ob); bpy.ops.object.vertex_group_limit_total(limit=n); bpy.ops.object.vertex_group_normalize_all(lock_active=False)

# ---------------------------------------------------------------- export
def export_glb(path,objs,anim=True,mode='NLA_TRACKS'):
    for o in bpy.context.view_layer.objects: o.select_set(False)
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]
    bpy.ops.export_scene.gltf(filepath=path,export_format='GLB',use_selection=True,export_yup=True,
        export_apply=False,export_animations=anim,export_animation_mode=mode,export_force_sampling=True,
        export_extras=True,export_vertex_color='ACTIVE',export_all_vertex_colors=False,export_skins=True,
        export_def_bones=False,export_anim_single_armature=True,export_optimize_animation_size=False,
        export_reset_pose_bones=True,export_rest_position_armature=True)

# ---------------------------------------------------------------- vectorised helpers
def vco(ob):
    me=ob.data; a=np.zeros(len(me.vertices)*3); me.vertices.foreach_get('co',a); return a.reshape(-1,3)
def vnor(ob):
    me=ob.data; a=np.zeros(len(me.vertices)*3); me.vertices.foreach_get('normal',a); return a.reshape(-1,3)
def set_vco(ob,co):
    ob.data.vertices.foreach_set('co',co.reshape(-1)); ob.data.update()
def displace_np(ob,fn):
    ob.data.update(); co=vco(ob); n=vnor(ob); d=fn(co,n); set_vco(ob,co+n*d[:,None])
def sstep(a,b,x):
    t=np.clip((x-a)/(b-a),0,1); return t*t*(3-2*t)
def gaussn(x,c,w): return np.exp(-((x-c)/w)**2)
def seg_dist(co,a,b):
    a=np.array(a);b=np.array(b);ab=b-a;t=np.clip(((co-a)@ab)/(ab@ab),0,1); q=a+t[:,None]*ab
    return np.linalg.norm(co-q,axis=1),t,q
def cyl_uv_np(ob,axes,tile_u,tile_v):
    me=ob.data
    if not me.uv_layers: me.uv_layers.new(name='UVMap')
    co=vco(ob); best=np.full(len(co),1e9); U=np.zeros(len(co)); Vv=np.zeros(len(co)); R=np.zeros(len(co))
    for (a,b) in axes:
        a=np.array(a,float);b=np.array(b,float); d,t,q=seg_dist(co,a,b)
        ax=(b-a)/np.linalg.norm(b-a)
        ref=np.array([0,-1,0.]) if abs(ax[1])<0.9 else np.array([0,0,1.])
        r1=ref-ax*(ref@ax); r1/=np.linalg.norm(r1); r2=np.cross(ax,r1)
        rel=co-q; ang=np.arctan2(rel@r2,rel@r1)
        m=d<best; best[m]=d[m]; U[m]=ang[m]; Vv[m]=((co-a)@ax)[m]; R[m]=np.maximum(d[m],0.02)
    nl=len(me.loops); vi=np.zeros(nl,int); me.loops.foreach_get('vertex_index',vi)
    ang=U[vi].copy(); circ=R[vi]
    # unwrap per polygon relative to first loop
    ls=np.zeros(len(me.polygons),int); me.polygons.foreach_get('loop_start',ls)
    lt=np.zeros(len(me.polygons),int); me.polygons.foreach_get('loop_total',lt)
    first=np.repeat(ang[ls],lt)
    diff=ang-first; ang=ang-2*np.pi*np.round(diff/(2*np.pi))
    uv=np.stack([ang*circ/tile_u, Vv[vi]/tile_v],1)
    me.uv_layers.active.data.foreach_set('uv',uv.reshape(-1))
