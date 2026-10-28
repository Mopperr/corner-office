# Corner Office prop generator, batch 9: L7–L22 fixes, animations, NPCs. Run: blender -b -P build_props.py
# Blender Z-up; glTF exporter converts to Y-up. Origin = bottom center. Units = meters.
import bpy, math, os, json
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
PAL = dict(cream="#F4E9D8", wood="#C68B59", darkwood="#6B4A3A", cardboard="#D9A86C",
  sage="#8FAF7E", terracotta="#D9765F", mustard="#E6B655", blue="#7FA3B8",
  night="#3E3A4F", screen="#FFF8EC", tape="#EDCB98", light="#FFE7B0", glow="#A9C7D6")
def lin(h):
    c=[int(h[i:i+2],16)/255 for i in (1,3,5)]
    return [x/12.92 if x<=0.04045 else ((x+0.055)/1.055)**2.4 for x in c]+[1]
MATS={}
def mat(n):
    if n not in MATS:
        m=bpy.data.materials.new("M_"+n); m.use_nodes=True
        b=m.node_tree.nodes["Principled BSDF"]; b.inputs["Base Color"].default_value=lin(PAL[n])
        b.inputs["Roughness"].default_value=0.8; m.diffuse_color=lin(PAL[n]); MATS[n]=m
    return MATS[n]
def clear():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete()
PARTS=[]
def box(sx,sy,sz,x=0,y=0,z=0,m="wood",bev=0.02,rot=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(size=1,location=(x,y,z+sz/2),rotation=rot)
    o=bpy.context.object; o.scale=(sx,sy,sz); bpy.ops.object.transform_apply(scale=True)
    if bev>0:
        md=o.modifiers.new("b","BEVEL"); md.width=bev; md.segments=2; md.limit_method='ANGLE'
    o.data.materials.append(mat(m)); PARTS.append(o); return o
def cyl(r,h,x=0,y=0,z=0,m="wood",v=10,r2=None,rot=(0,0,0)):
    if r2 is None: bpy.ops.mesh.primitive_cylinder_add(vertices=v,radius=r,depth=h,location=(x,y,z+h/2),rotation=rot)
    else: bpy.ops.mesh.primitive_cone_add(vertices=v,radius1=r,radius2=r2,depth=h,location=(x,y,z+h/2),rotation=rot)
    o=bpy.context.object; o.data.materials.append(mat(m)); PARTS.append(o); return o
def ball(r,x=0,y=0,z=0,m="sage",sub=1,sz=1.0):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=r,location=(x,y,z))
    o=bpy.context.object; o.scale.z=sz; bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(mat(m)); PARTS.append(o); return o
def finish(name):
    for o in PARTS:
        bpy.context.view_layer.objects.active=o
        for md in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=md.name)
    bpy.ops.object.select_all(action='DESELECT')
    for o in PARTS: o.select_set(True)
    bpy.context.view_layer.objects.active=PARTS[0]; bpy.ops.object.join()
    o=bpy.context.object; bpy.ops.object.transform_apply(location=True,rotation=True,scale=True); o.name=name; o.data.name=name
    bpy.ops.object.shade_flat()
    # origin bottom center
    import mathutils
    vs=[o.matrix_world@v.co for v in o.data.vertices]
    mn=[min(v[i] for v in vs) for i in range(3)]; mx=[max(v[i] for v in vs) for i in range(3)]
    c=mathutils.Vector(((mn[0]+mx[0])/2,(mn[1]+mx[1])/2,mn[2]))
    o.data.transform(mathutils.Matrix.Translation(-c)); o.location=(0,0,0)
    PARTS.clear(); return o, [mx[i]-mn[i] for i in range(3)]

def render(o,dims,name):
    sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.view_settings.view_transform='Standard'; sc.view_settings.look='None'; sc.cycles.device='CPU'; sc.cycles.samples=24; sc.cycles.use_denoising=False
    if 'Sun' not in bpy.data.objects:
        bpy.ops.object.light_add(type='SUN',rotation=(math.radians(40),math.radians(10),math.radians(30))); bpy.context.object.name='Sun'; bpy.context.object.data.energy=3.5; bpy.context.object.data.angle=0.3
    w=sc.world or bpy.data.worlds.new('W'); sc.world=w; w.use_nodes=True; w.node_tree.nodes['Background'].inputs[1].default_value=1.6
    sc.render.film_transparent=True; sc.render.resolution_x=sc.render.resolution_y=512
    bpy.ops.object.camera_add(); cam=bpy.context.object; cam.data.type='ORTHO'
    cam.data.ortho_scale=max(dims)*1.6
    cam.rotation_euler=(math.radians(60),0,math.radians(-45)) if False else (math.radians(60),0,math.radians(-135+180))
    import mathutils
    d=cam.rotation_euler.to_matrix()@mathutils.Vector((0,0,1))
    cam.location=mathutils.Vector((0,0,dims[2]/2))+d*20; sc.camera=cam
    sc.render.filepath=os.path.join(OUT,"previews",name+".png"); bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam)
import mathutils
PAL.update(concrete="#CFC6BE", glass="#A9C7D6", brass="#C9A24A", white="#FBF7EF")
def finish2(name, origin="bottom"):
    o,dims=finish(name)          # bottom-centre
    if origin=="back":           # wall item: front faces -Y (Blender) = +Z (Godot); origin on back face, bottom centre
        ymax=max(v.co.y for v in o.data.vertices)
        o.data.transform(mathutils.Matrix.Translation((0,-ymax,0)))
    return o,dims
def group(name):
    for o in PARTS:
        bpy.context.view_layer.objects.active=o
        for md in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=md.name)
    bpy.ops.object.select_all(action='DESELECT')
    for o in PARTS: o.select_set(True)
    bpy.context.view_layer.objects.active=PARTS[0]; bpy.ops.object.join()
    o=bpy.context.object; bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    o.name=name; o.data.name=name; bpy.ops.object.shade_flat(); PARTS.clear(); return o
def set_origin(o,p):
    p=mathutils.Vector(p); o.data.transform(mathutils.Matrix.Translation(-p)); o.location=p


PAL.update(pink="#E8B4A8", white="#FBF7EF", concrete="#CFC6BE", brass="#C9A24A",
  steel="#9FB3BF", navy="#3A4F6B", butter="#F6E7C1", flour="#F8F4EC", felt="#4F7A5A",
  chalk="#2F3B36", tile="#C9714F", glass="#A9C7D6")
import mathutils
def export_sel(objs,name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,"models",name+".glb"),export_format='GLB',use_selection=True,export_yup=True,export_apply=True)
def bounds(objs):
    vs=[o.matrix_world@v.co for o in objs if getattr(o,'type',None)=='MESH' for v in o.data.vertices]
    mn=[min(v[i] for v in vs) for i in range(3)]; mx=[max(v[i] for v in vs) for i in range(3)]; return mn,mx
def finish_mode(name,mode="bottom"):
    o,dims=finish(name)
    if mode=="back":
        ymax=max(v.co.y for v in o.data.vertices); o.data.transform(mathutils.Matrix.Translation((0,-ymax,0)))
    if mode=="top":
        o.data.transform(mathutils.Matrix.Translation((0,0,-max(v.co.z for v in o.data.vertices))))
    if mode=="slabtop":   # slab top (0.05 above bottom) at y=0; stain decals sit 0.5 mm proud
        o.data.transform(mathutils.Matrix.Translation((0,0,-0.05)))
    return o,dims

PAL.update(mint="#A8C9B8", chrome="#A8ADB4", creamwall="#F4E9D8", white="#FBF7EF",
           glass="#A9C7D6", brass="#C9A24A", pink="#E8B4A8", water="#7FA3B8")
FPS=24
def export_sel(objs,name,anim=False):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    kw=dict(filepath=os.path.join(OUT,"models",name+".glb"),export_format='GLB',use_selection=True,export_yup=True,export_apply=True)
    if anim: kw.update(export_animations=True,export_animation_mode='NLA_TRACKS',export_frame_range=False,export_force_sampling=True)
    bpy.ops.export_scene.gltf(**kw)
def bounds(objs):
    vs=[o.matrix_world@v.co for o in objs if getattr(o,'type',None)=='MESH' for v in o.data.vertices]
    mn=[min(v[i] for v in vs) for i in range(3)]; mx=[max(v[i] for v in vs) for i in range(3)]; return mn,mx
def nla_push(obj,action,track):
    ad=obj.animation_data or obj.animation_data_create()
    tr=ad.nla_tracks.new(); tr.name=track; st=tr.strips.new(track,int(action.frame_range[0]),action); st.name=track; ad.action=None
def key_action(obj,name,keys):
    ad=obj.animation_data or obj.animation_data_create()
    act=bpy.data.actions.new(obj.name+"_"+name); ad.action=act
    base_l=tuple(obj.location); base_r=tuple(obj.rotation_euler); base_s=tuple(obj.scale)
    for f,k in keys:
        f=f-1
        obj.location=k.get("loc",base_l); obj.rotation_euler=k.get("rot",base_r); obj.scale=k.get("scale",base_s)
        obj.keyframe_insert("location",frame=f); obj.keyframe_insert("rotation_euler",frame=f); obj.keyframe_insert("scale",frame=f)
    obj.location=base_l; obj.rotation_euler=base_r; obj.scale=base_s
    for fc in act.fcurves:
        for kp in fc.keyframe_points: kp.interpolation='BEZIER'
    nla_push(obj,act,name); return act

_mat_orig=mat
def mat(n):
    m=_mat_orig(n)
    if n=="glass" and not m.get("_glass_done"):
        b=m.node_tree.nodes["Principled BSDF"]; b.inputs["Alpha"].default_value=0.3; b.inputs["Roughness"].default_value=0.1
        m.blend_method='BLEND'; m["_glass_done"]=1
    return m
PAL.update(kraft="#D9B98A", pages="#F8F4EC", brick="#C9714F", chrome="#A8ADB4", white="#FBF7EF",
  glass="#A9C7D6", steel="#9FB3BF", teal="#1F4A52", sky="#BFDDEA", sand="#EADBB8", velvet="#A84E3A",
  redwood="#8B4A32", sunset="#F2B35E", neon_green="#6DBF73", mint="#A8C9B8", skin="#E8B4A8")
FPS=24
def export_sel(objs,name,anim=False):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    kw=dict(filepath=os.path.join(OUT,"models",name+".glb"),export_format='GLB',use_selection=True,export_yup=True,export_apply=True)
    if anim: kw.update(export_animations=True,export_animation_mode='NLA_TRACKS',export_frame_range=False,export_force_sampling=True)
    bpy.ops.export_scene.gltf(**kw)
def bounds(objs):
    vs=[o.matrix_world@v.co for o in objs if getattr(o,'type',None)=='MESH' for v in o.data.vertices]
    mn=[min(v[i] for v in vs) for i in range(3)]; mx=[max(v[i] for v in vs) for i in range(3)]; return mn,mx
def nla_push(obj,action,track):
    ad=obj.animation_data or obj.animation_data_create()
    tr=ad.nla_tracks.new(); tr.name=track; st=tr.strips.new(track,int(action.frame_range[0]),action); st.name=track; ad.action=None
REST={}
def key_action(obj,name,keys,interp='BEZIER'):
    if obj.name not in REST: REST[obj.name]=(tuple(obj.location),tuple(obj.rotation_euler),tuple(obj.scale))
    ad=obj.animation_data or obj.animation_data_create()
    act=bpy.data.actions.new(obj.name+"_"+name); ad.action=act
    bl=tuple(obj.location); br=tuple(obj.rotation_euler); bs=tuple(obj.scale)
    for f,k in keys:
        obj.location=k.get("loc",bl); obj.rotation_euler=k.get("rot",br); obj.scale=k.get("scale",bs)
        for p in ("location","rotation_euler","scale"): obj.keyframe_insert(p,frame=f)
    obj.location=bl; obj.rotation_euler=br; obj.scale=bs
    for fc in act.fcurves:
        for kp in fc.keyframe_points: kp.interpolation=interp
    nla_push(obj,act,name); return act
# emissive material (named for Godot): M_<name>_emissive
def emat(name,hexc,strength=4.0):
    key="E_"+name
    if key in MATS: return MATS[key]
    m=bpy.data.materials.new("M_"+name+"_emissive"); m.use_nodes=True
    b=m.node_tree.nodes["Principled BSDF"]; c=lin(hexc)
    b.inputs["Base Color"].default_value=c; b.inputs["Emission Color"].default_value=c; b.inputs["Emission Strength"].default_value=strength
    MATS[key]=m; return m
def ebox(sx,sy,sz,x=0,y=0,z=0,name="neon",hexc="#6DBF73",bev=0.01,rot=(0,0,0)):
    o=box(sx,sy,sz,x,y,z,m="white",bev=bev,rot=rot); o.data.materials.clear(); o.data.materials.append(emat(name,hexc)); return o
def glass_mat():
    if "G" in MATS: return MATS["G"]
    m=bpy.data.materials.new("M_glass"); m.use_nodes=True; b=m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value=lin("#A9C7D6"); b.inputs["Alpha"].default_value=0.35; b.inputs["Roughness"].default_value=0.05
    m.blend_method='BLEND'; MATS["G"]=m; return m
def gbox(*a,**k):
    o=box(*a,m="white",**k); o.data.materials.clear(); o.data.materials.append(glass_mat()); return o
stats={}
def record(name,objs,lvl,extra=None,origin="bottom"):
    meshes=[o for o in objs if o.type=='MESH']; mn,mx=bounds(meshes)
    for o in meshes: o.data.calc_loop_triangles()
    st=dict(tris=sum(len(o.data.loop_triangles) for o in meshes),size_m=[round(mx[i]-mn[i],3) for i in range(3)],level=lvl,origin=origin)
    if extra: st.update(extra)
    stats[name]=st
    for ob in bpy.data.objects:
        if ob.animation_data: ob.animation_data_clear()
        if ob.name in REST:
            l,r,sc=REST[ob.name]; ob.location=l; ob.rotation_euler=r; ob.scale=sc
    bpy.context.scene.frame_set(0); bpy.context.view_layer.update()
    render(meshes[0],[mx[i]-mn[i] for i in range(3)],name)
def rooted(name,parts):
    root=bpy.data.objects.new(name,None); bpy.context.scene.collection.objects.link(root)
    for o in parts: o.parent=root
    return root

# ---------- 1. fixes ----------
def neon_sign():
    box(0.9,0.06,0.4,0,0.03,0,m="night",bev=0.015)                 # backplate (behind tubes)
    for x in (-0.4,0.4): box(0.02,0.04,0.02,x,0.0,0.38,m="chrome",bev=0)
    # "RECORDS" bar + a vinyl circle + underline, chunky tubes on the front face (-Y)
    ebox(0.72,0.05,0.07,0,-0.03,0.25,"neon_green","#6DBF73")
    ebox(0.5,0.05,0.05,0,-0.03,0.07,"neon_terracotta","#D9765F")
    for i in range(12):
        t=i*2*math.pi/12; ebox(0.04,0.05,0.04,-0.33+0.06*math.cos(t),-0.03,0.17+0.06*math.sin(t)-0.02,"neon_mustard","#E6B655",bev=0.008)
clear(); REST.clear() if "REST" in globals() else None; PARTS.clear(); neon_sign(); o,_=finish_mode("neon_sign","back"); export_sel([o],"neon_sign")
record("neon_sign",[o],"L12",dict(emissive_materials=["M_neon_green_emissive","M_neon_terracotta_emissive","M_neon_mustard_emissive"]),"back")

def city_backdrop():
    box(4.0,0.06,2.5,0,0.0,0,m="teal",bev=0)                        # sky panel
    box(4.0,0.05,0.6,0,-0.005,1.9,m="blue",bev=0)                   # upper sky band (soft gradient)
    hs=[1.1,1.5,0.9,1.8,1.2,1.6,1.0,1.4]
    for i,h in enumerate(hs):
        x=-1.75+i*0.5; box(0.42,0.08,h,x,-0.04,0,m=["steel","chrome","night","blue"][i%4],bev=0.01)
        for r in range(int(h/0.2)-1):
            for c in range(2):
                if (r+c+i)%3: ebox(0.08,0.02,0.08,x-0.08+c*0.16,-0.085,0.15+r*0.2,"window_lit","#F2B35E",bev=0)
clear(); REST.clear() if "REST" in globals() else None; PARTS.clear(); city_backdrop(); o,_=finish_mode("city_backdrop","back"); export_sel([o],"city_backdrop")
record("city_backdrop",[o],"L16",dict(emissive_materials=["M_window_lit_emissive"]),"back")

def window_wall_2m():
    box(2.0,0.12,0.12,0,-0.06,0,m="chrome",bev=0.01); box(2.0,0.12,0.12,0,-0.06,2.88,m="chrome",bev=0.01)
    for x in (-0.97,0,0.97): box(0.06,0.12,3.0,x,-0.06,0,m="chrome",bev=0.008)
    box(2.0,0.1,0.05,0,-0.06,1.0,m="chrome",bev=0.006)
    for x in (-0.49,0.49): gbox(0.9,0.02,2.75,x,-0.06,0.12,bev=0)
    for x,z in ((-0.7,1.6),(0.3,0.5),(0.6,1.9)):                    # reflection streaks
        box(0.06,0.005,0.6,x,-0.075,z,m="white",bev=0,rot=(0,math.radians(30),0))
clear(); REST.clear() if "REST" in globals() else None; PARTS.clear(); window_wall_2m(); o,_=finish_mode("window_wall_2m","back"); export_sel([o],"window_wall_2m")
record("window_wall_2m",[o],"L21",None,"back")

# ---------- 2. animated props ----------
# L11 freight elevator: Platform 'lift' (3.0 m, 3 s), Gate 'gate_open' (1 s)
clear(); REST.clear() if "REST" in globals() else None; PARTS.clear()
for x in (-0.85,0.85):
    for y in (-0.85,0.85): box(0.1,0.1,6.0,x,y,0,m="steel",bev=0.01)
box(1.8,1.8,0.08,0,0,5.92,m="steel",bev=0.01); frame=group("Shaft")
PARTS.clear(); box(1.6,1.6,0.1,m="steel",bev=0.02); box(1.6,0.05,1.0,0,0.78,0.1,m="steel",bev=0.01); plat=group("Platform")
PARTS.clear()
for i in range(8): box(0.04,0.04,2.0,-0.75+i*0.215,-0.88,0.1,m="mustard",bev=0.005)
box(1.6,0.04,0.06,0,-0.88,2.05,m="mustard",bev=0.005); gate=group("Gate")
gate.parent=plat
root=rooted("freight_elevator",[frame,plat])
key_action(plat,"lift",[(0,{"loc":(0,0,0)}),(72,{"loc":(0,0,3.0)})])
key_action(gate,"gate_open",[(0,{"loc":(0,0,0),"scale":(1,1,1)}),(24,{"loc":(0.7,0,0),"scale":(0.15,1,1)})])
export_sel([root,frame,plat,gate],"freight_elevator",anim=True)
record("freight_elevator",[frame,plat,gate],"L11",dict(nodes=["Shaft","Platform","Gate"],animations={"lift":{"seconds":3.0,"loop":False,"travel_y_m":3.0},"gate_open":{"seconds":1.0,"loop":False}}))

# L12 turntable: Platter 'spin' (1.8 s ≈ 33 rpm loop), 'beat_pulse' (0.5 s loop, 120 bpm)
clear(); REST.clear() if "REST" in globals() else None; PARTS.clear(); box(0.42,0.36,0.07,m="night",bev=0.015); box(0.02,0.18,0.02,0.13,0.05,0.08,m="chrome",bev=0.004,rot=(0,0,math.radians(-20))); base=group("Base")
PARTS.clear(); cyl(0.15,0.012,m="darkwood",v=20); cyl(0.05,0.004,z=0.012,m="terracotta",v=12); box(0.12,0.01,0.003,0.06,0,0.012,m="cream",bev=0); plat=group("Platter")
set_origin(plat,(0,0,0)); plat.location=(-0.03,-0.01,0.07)
root=rooted("turntable",[base,plat])
key_action(plat,"spin",[(0,{"rot":(0,0,0)}),(43,{"rot":(0,0,-2*math.pi)})],interp='LINEAR')
key_action(base,"beat_pulse",[(0,{"scale":(1,1,1)}),(3,{"scale":(1.03,1.03,1.06)}),(12,{"scale":(1,1,1)})])
export_sel([root,base,plat],"turntable",anim=True)
record("turntable",[base,plat],"L12",dict(nodes=["Base","Platter"],animations={"spin":{"seconds":1.8,"loop":True},"beat_pulse":{"seconds":0.5,"loop":True}}))

# L14 droopy plant: Leaves 'droop' 1 s, 'perk' 1 s, 'idle' 3 s
clear(); REST.clear() if "REST" in globals() else None; PARTS.clear(); cyl(0.13,0.2,m="terracotta",v=10,r2=0.15); cyl(0.13,0.02,z=0.19,m="darkwood",v=10); pot=group("Pot")
PARTS.clear(); cyl(0.015,0.2,z=0.2,m="sage",v=5)
for i in range(6):
    t=i*2*math.pi/6; box(0.06,0.16,0.015,0.08*math.cos(t),0.08*math.sin(t),0.36,m="sage",bev=0.008,rot=(math.radians(40),0,t+math.pi/2))
ball(0.07,0,0,0.42,m="sage"); ball(0.03,0,0,0.5,m="pink",sub=1)
leaves=group("Leaves"); set_origin(leaves,(0,0,0.2)); leaves.location=(0,0,0.2)
root=rooted("plant_droopy",[pot,leaves])
key_action(leaves,"droop",[(0,{"rot":(0,0,0),"scale":(1,1,1)}),(24,{"rot":(0.5,0,0),"scale":(1.05,1.05,0.8)})])
key_action(leaves,"perk",[(0,{"rot":(0.5,0,0),"scale":(1.05,1.05,0.8)}),(24,{"rot":(0,0,0),"scale":(1,1,1)})])
key_action(leaves,"idle",[(0,{"rot":(0,0,0)}),(36,{"rot":(0.06,0.04,0)}),(72,{"rot":(0,0,0)})])
export_sel([root,pot,leaves],"plant_droopy",anim=True)
record("plant_droopy",[pot,leaves],"L14",dict(nodes=["Pot","Leaves"],animations={"droop":{"seconds":1.0,"loop":False},"perk":{"seconds":1.0,"loop":False},"idle":{"seconds":3.0,"loop":True}}))

# L17 stage curtain: CurtainL/CurtainR 'open' 2 s, 'close' 2 s
clear(); REST.clear() if "REST" in globals() else None; PARTS.clear(); box(3.4,0.2,0.3,0,0,3.0,m="velvet",bev=0.03); box(0.12,0.12,3.3,-1.7,0,0,m="redwood",bev=0.02); box(0.12,0.12,3.3,1.7,0,0,m="redwood",bev=0.02); frame=group("Proscenium")
panels=[]
for side,nm in ((-1,"CurtainL"),(1,"CurtainR")):
    PARTS.clear()
    for i in range(5): box(0.32,0.1,2.95,side*(0.16+i*0.3),0,0.05,m="velvet",bev=0.04)
    p=group(nm); set_origin(p,(side*1.6,0,0)); p.location=(side*1.6,0,0); panels.append(p)
root=rooted("stage_curtain",[frame]+panels)
for p,side in zip(panels,(-1,1)):
    key_action(p,"open",[(0,{"scale":(1,1,1)}),(48,{"scale":(0.18,1,1)})])
    key_action(p,"close",[(0,{"scale":(0.18,1,1)}),(48,{"scale":(1,1,1)})])
export_sel([root,frame]+panels,"stage_curtain",anim=True)
record("stage_curtain",[frame]+panels,"L17",dict(nodes=["Proscenium","CurtainL","CurtainR"],animations={"open":{"seconds":2.0,"loop":False},"close":{"seconds":2.0,"loop":False}}))

# L17 rubber chicken bounce 'bounce' 0.6 s
clear(); REST.clear() if "REST" in globals() else None; PARTS.clear(); ball(0.06,0,0,0.12,m="mustard",sub=1); ball(0.04,0.08,0,0.16,m="mustard",sub=1); box(0.03,0.02,0.04,0.12,0,0.16,m="terracotta",bev=0.005)
ck=group("Chicken"); set_origin(ck,(0,0,0.06)); ck.location=(0,0,0.06)
root=rooted("rubber_chicken",[ck])
key_action(ck,"bounce",[(0,{"loc":(0,0,0.06),"scale":(1.1,1.1,0.8)}),(7,{"loc":(0,0,0.3),"scale":(0.9,0.9,1.15)}),(14,{"loc":(0,0,0.06),"scale":(1.1,1.1,0.8)})])
export_sel([root,ck],"rubber_chicken",anim=True)
record("rubber_chicken",[ck],"L17",dict(nodes=["Chicken"],animations={"bounce":{"seconds":0.583,"loop":True}}))

# ---------- 3. simple NPC rig (shared): Body, Head, ArmL, ArmR, LegL, LegR; clips idle 2 s, walk 1 s ----------
def npc(name,shirt,pants,extra=None,lvl="L16",accent=None):
    clear(); REST.clear(); parts=[]
    PARTS.clear(); box(0.32,0.2,0.42,0,0,0.8,m=shirt,bev=0.06); body=group("Body"); set_origin(body,(0,0,0.8)); body.location=(0,0,0.8)
    PARTS.clear(); ball(0.12,0,0,1.38,m="skin",sub=2); box(0.22,0.2,0.06,0,0,1.47,m="darkwood",bev=0.03); head=group("Head"); set_origin(head,(0,0,1.25)); head.location=(0,0,1.25)
    arms=[]
    for s,nm in ((-1,"ArmL"),(1,"ArmR")):
        PARTS.clear(); box(0.08,0.08,0.38,s*0.21,0,0.82,m=shirt,bev=0.03); ball(0.045,s*0.21,0,0.8,m="skin",sub=1)
        a=group(nm); set_origin(a,(s*0.21,0,1.18)); a.location=(s*0.21,0,1.18); arms.append(a)
    legs=[]
    for s,nm in ((-1,"LegL"),(1,"LegR")):
        PARTS.clear(); box(0.11,0.12,0.8,s*0.08,0,0,m=pants,bev=0.03); box(0.12,0.18,0.06,s*0.08,-0.03,0,m="night",bev=0.02)
        l=group(nm); set_origin(l,(s*0.08,0,0.8)); l.location=(s*0.08,0,0.8); legs.append(l)
    props=[]
    if extra: PARTS.clear(); extra(); pr=group("Prop"); set_origin(pr,(0.21,0,0.85)); pr.location=(0.21,0,0.85); pr.parent=arms[1]; pr.location=(0,0,0.85-1.18+0.7); props.append(pr)
    allp=[body,head]+arms+legs
    root=rooted(name,allp)
    key_action(body,"idle",[(0,{"scale":(1,1,1)}),(24,{"scale":(1.02,1.02,1.03)}),(48,{"scale":(1,1,1)})])
    key_action(head,"idle",[(0,{"rot":(0,0,0)}),(24,{"rot":(0,0.08,0.1)}),(48,{"rot":(0,0,0)})])
    for a,sg in zip(arms,(1,-1)):
        key_action(a,"walk",[(0,{"rot":(0.5*sg,0,0)}),(12,{"rot":(-0.5*sg,0,0)}),(24,{"rot":(0.5*sg,0,0)})])
    for l,sg in zip(legs,(-1,1)):
        key_action(l,"walk",[(0,{"rot":(0.45*sg,0,0)}),(12,{"rot":(-0.45*sg,0,0)}),(24,{"rot":(0.45*sg,0,0)})])
    key_action(body,"walk",[(0,{"loc":(0,0,0.8)}),(6,{"loc":(0,0,0.83)}),(12,{"loc":(0,0,0.8)}),(18,{"loc":(0,0,0.83)}),(24,{"loc":(0,0,0.8)})])
    export_sel([root]+allp+props,name,anim=True)
    record(name,allp+props,lvl,dict(nodes=["Body","Head","ArmL","ArmR","LegL","LegR"]+(["Prop"] if props else []),
        animations={"idle":{"seconds":2.0,"loop":True},"walk":{"seconds":1.0,"loop":True}},height_m=1.5))
def clipboard(): box(0.03,0.2,0.26,0,-0.12,0,m="wood",bev=0.008); box(0.035,0.17,0.2,0,-0.12,0.02,m="white",bev=0)
def rolled_plan(): cyl(0.035,0.5,0,-0.1,0,m="kraft",v=8,rot=(math.pi/2,0,0)).location=(0,-0.1,0.0)
def box_carry(): box(0.3,0.25,0.25,0,-0.18,-0.1,m="cardboard",bev=0.015)
def flag_sign(): box(0.03,0.03,0.6,0,-0.1,-0.2,m="darkwood",bev=0.005); box(0.22,0.02,0.22,0,-0.1,0.35,m="mustard",bev=0.01)
npc("npc_helper","sage","darkwood",box_carry,"L16")
npc("npc_rival","night","night",clipboard,"L19")
npc("npc_architect","kraft","blue",rolled_plan,"L9")
npc("npc_flagger","mustard","blue",flag_sign,"L9")
npc("npc_vendor","terracotta","darkwood",None,"L8")
npc("npc_band","velvet","cream",None,"L18")

json.dump(stats,open(os.path.join(OUT,"models","stats_9.json"),"w"),indent=1)
print("built",len(stats))
