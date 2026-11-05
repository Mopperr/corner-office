"""Rigged characters (soft stylized-realistic). blender -b -P build_characters.py -- [dana] [customers]
Shared SkeletonProfileHumanoid skeleton, 14 'interact' clips (IK-authored → baked FK, in-place),
painted face atlas (5 expressions, swap via UV offset). Blender Z-up, faces -Y → glTF Y-up faces +Z."""
import bpy, bmesh, math, os, sys, json, mathutils
from mathutils import Vector as V
A=os.path.join(os.path.dirname(os.path.abspath(__file__)),".."); OUT=f"{A}/models/characters"
WANT=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else ["dana","customers"]
FPS=30
def lin(h): c=[int(h[i:i+2],16)/255 for i in (1,3,5)]; return [x/12.92 if x<=0.04045 else ((x+0.055)/1.055)**2.4 for x in c]+[1]
# ---------------- skeleton (Dana proportions, 1.65 m) ----------------
J=dict(Hips=((0,0,.94),(0,0,1.04)),Spine=((0,0,1.04),(0,0,1.16)),Chest=((0,0,1.16),(0,0,1.28)),UpperChest=((0,0,1.28),(0,0,1.42)),
 Neck=((0,0,1.42),(0,0,1.49)),Head=((0,0,1.49),(0,0,1.64)))
PAR=dict(Spine="Hips",Chest="Spine",UpperChest="Chest",Neck="UpperChest",Head="Neck")
for s,sx in (("Left",1),("Right",-1)):
    J[f"{s}Shoulder"]=((sx*.03,0,1.38),(sx*.17,0,1.39)); PAR[f"{s}Shoulder"]="UpperChest"
    J[f"{s}UpperArm"]=((sx*.18,0,1.385),(sx*.215,.005,1.12)); PAR[f"{s}UpperArm"]=f"{s}Shoulder"
    J[f"{s}LowerArm"]=((sx*.215,.005,1.12),(sx*.24,-.025,.875)); PAR[f"{s}LowerArm"]=f"{s}UpperArm"
    J[f"{s}Hand"]=((sx*.24,-.025,.875),(sx*.245,-.03,.775)); PAR[f"{s}Hand"]=f"{s}LowerArm"
    J[f"HandAttach_{s[0]}"]=((sx*.235,-.03,.81),(sx*.235,-.10,.81)); PAR[f"HandAttach_{s[0]}"]=f"{s}Hand"
    J[f"{s}UpperLeg"]=((sx*.09,0,.92),(sx*.09,0,.5)); PAR[f"{s}UpperLeg"]="Hips"
    J[f"{s}LowerLeg"]=((sx*.09,0,.5),(sx*.09,.012,.085)); PAR[f"{s}LowerLeg"]=f"{s}UpperLeg"
    J[f"{s}Foot"]=((sx*.09,.012,.085),(sx*.09,-.1,.025)); PAR[f"{s}Foot"]=f"{s}LowerLeg"
    J[f"{s}Toes"]=((sx*.09,-.1,.025),(sx*.09,-.16,.02)); PAR[f"{s}Toes"]=f"{s}Foot"
ORDER=list(J)
def make_armature(name="Skeleton"):
    ad=bpy.data.armatures.new(name); ao=bpy.data.objects.new(name,ad); bpy.context.scene.collection.objects.link(ao)
    bpy.context.view_layer.objects.active=ao; bpy.ops.object.mode_set(mode='EDIT')
    for b in ORDER:
        e=ad.edit_bones.new(b); e.head=J[b][0]; e.tail=J[b][1]
        e.roll=0; e.use_deform=not b.startswith("HandAttach")
    for b,p in PAR.items():
        e=ad.edit_bones[b]; e.parent=ad.edit_bones[p]; e.use_connect=(V(J[p][1])-V(J[b][0])).length<1e-4 and not b.startswith("HandAttach")
    for e in ad.edit_bones:   # consistent roll: local Z toward character front (-Y) where possible
        if abs(e.vector.normalized().y)<0.9: e.align_roll(V((0,-1,0)))
    bpy.ops.object.mode_set(mode='OBJECT'); return ao
# ---------------- mesh helpers ----------------
MATS={}
def mat(n,col,rough=0.7,metal=0.0,img=None):
    if n in MATS: return MATS[n]
    m=bpy.data.materials.new(n); m.use_nodes=True; b=m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value=lin(col); b.inputs["Roughness"].default_value=rough; b.inputs["Metallic"].default_value=metal
    if img:
        t=m.node_tree.nodes.new("ShaderNodeTexImage"); t.image=bpy.data.images.load(img); m.node_tree.links.new(t.outputs[0],b.inputs["Base Color"])
    MATS[n]=m; return m
PARTS=[]   # (obj, candidate bones)
def tube(pts,radii,mname,bones,seg=16,cap=True,ry=None,name="part"):
    """ring sweep along polyline; radii float or (rx,ry); returns obj"""
    bm=bmesh.new(); rings=[]
    for i,p in enumerate(pts):
        p=V(p); d=(V(pts[min(i+1,len(pts)-1)])-V(pts[max(i-1,0)])).normalized()
        up=V((0,-1,0)) if abs(d.y)<0.9 else V((0,0,1)); xa=d.cross(up).normalized(); ya=d.cross(xa).normalized()
        r=radii[i]; rx,ry_=(r if isinstance(r,tuple) else (r,r))
        rings.append([bm.verts.new(p+xa*rx*math.cos(a)+ya*ry_*math.sin(a)) for a in [2*math.pi*k/seg for k in range(seg)]])
    for a,b in zip(rings,rings[1:]):
        for k in range(seg): bm.faces.new((a[k],a[(k+1)%seg],b[(k+1)%seg],b[k]))
    if cap: bm.faces.new(rings[0][::-1]); bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    me=bpy.data.meshes.new(name); bm.to_mesh(me); bm.free(); o=bpy.data.objects.new(name,me); bpy.context.scene.collection.objects.link(o)
    o.data.materials.append(MATS[mname]); PARTS.append((o,bones)); return o
def ell(c,r,mname,bones,seg=24,ring=12,name="ell",keep=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=ring,radius=1,location=c); o=bpy.context.object; o.name=name
    o.scale=r; bpy.ops.object.transform_apply(scale=True,location=False)
    if keep:
        bm=bmesh.new(); bm.from_mesh(o.data); kill=[f for f in bm.faces if not keep(o.matrix_world@f.calc_center_median(),f.normal)]
        bmesh.ops.delete(bm,geom=kill,context='FACES'); bm.to_mesh(o.data); bm.free()
    o.data.materials.append(MATS[mname]); PARTS.append((o,bones)); return o
def lerp(a,b,t): return [a[i]+(b[i]-a[i])*t for i in range(3)]
def seg_dist(p,a,b):
    a,b=V(a),V(b); ab=b-a; t=max(0,min(1,(p-a).dot(ab)/ab.length_squared)); return (a+ab*t-p).length
# ---------------- character builder ----------------
def build_body(P):
    """P: dict of colours/proportions. Returns list of parts (built into PARTS)."""
    g=P.get("girth",1.0); hw=P.get("hip",1.0); bust=P.get("bust",1.0)
    skin=P["skin"]; mat("M_skin",skin,0.55); mat("M_hair",P["hair_col"],0.5); mat("M_top",P["top"],0.92); mat("M_bottom",P["bottom"],0.85)
    mat("M_shoe",P.get("shoe","#4A3226"),0.45); mat("M_collar",P.get("collar","#F4E9D8"),0.9)
    mat("M_face",skin,0.6,img=P["face_img"])
    TB=["Hips","Spine","Chest","UpperChest","Neck","LeftShoulder","RightShoulder","LeftUpperArm","RightUpperArm"]
    # torso (top)
    zs=[.86,.94,1.04,1.14,1.24,1.32,1.38,1.42,1.445]; rx=[.165*hw,.16*hw,.145*g,.15*g,.16*g*bust,.172*g,.175*g,.14,.075]; ryy=[.11*hw,.105,.10*g,.10*g,.11*g*bust,.11*g,.10*g,.085,.06]
    top_from=P.get("top_from",.86)
    zz=[z for z in zs if z>=top_from-1e-6]; i0=zs.index(zz[0])
    tube([(0,0.0,z) for z in zz],[(rx[i0+i],ryy[i0+i]) for i in range(len(zz))],"M_top",TB,seg=24,name="Top")
    # pelvis/bottom
    LB=["Hips","Spine","LeftUpperLeg","RightUpperLeg"]
    if P.get("skirt"):
        tube([(0,0,1.0),(0,0,.92),(0,0,.8),(0,0,P.get("skirt_hem",.5))],[(.15*hw,.105*hw),(.165*hw,.115*hw),(.19*hw,.14*hw),(.23*hw,.18*hw)],"M_bottom",LB,seg=28,name="Skirt")
    else:
        tube([(0,0,1.0),(0,0,.9),(0,0,.83)],[(.155*hw,.108*hw),(.168*hw,.115*hw),(.16*hw,.11*hw)],"M_bottom",LB,seg=24,name="Pelvis")
    for s,sx in (("Left",1),("Right",-1)):
        L=[f"{s}UpperLeg",f"{s}LowerLeg","Hips"]
        if P.get("skirt"):
            tube([(sx*.09,0,P.get("skirt_hem",.5)+.02),(sx*.09,0.006,.3),(sx*.09,.012,.1)],[.05,.042,.037],"M_skin",L,seg=14,name=f"Leg_{s}")
        else:
            wl=P.get("wide",1.0)
            tube([(sx*.088,0,.86),(sx*.09,0,.7),(sx*.09,0,.5),(sx*.09,.006,.3),(sx*.09,.012,.075)],[.085*hw,.075*g,.066*wl,.07*wl,.078*wl],"M_bottom",L,seg=18,name=f"Leg_{s}")
        F=[f"{s}Foot",f"{s}Toes",f"{s}LowerLeg"]
        tube([(sx*.09,.05,.035),(sx*.09,0.0,.04),(sx*.09,-.09,.03),(sx*.09,-.16,.022)],[(.04,.035),(.045,.045),(.045,.032),(.03,.02)],"M_shoe",F,seg=16,name=f"Shoe_{s}")
        # arm (sleeve + hand with simple fingers)
        sh,el,wr=V(J[f"{s}UpperArm"][0]),V(J[f"{s}LowerArm"][0]),V(J[f"{s}Hand"][0])
        AB=[f"{s}Shoulder",f"{s}UpperArm",f"{s}LowerArm",f"{s}Hand"]
        sl_end=P.get("sleeve",1.0)
        pts=[sh+V((sx*-.01,0,.01)),sh.lerp(el,.5),el,el.lerp(wr,.5),el.lerp(wr,sl_end*0.97)]
        tube([tuple(p) for p in pts],[.06*g,.052*g,.046*g,.043,.044],"M_top",AB,seg=16,name=f"Sleeve_{s}")
        if sl_end<0.95: tube([tuple(el.lerp(wr,sl_end*.95)),tuple(wr)],[.034,.03],"M_skin",AB,seg=12,name=f"Forearm_{s}")
        hb=V(J[f"{s}Hand"][0]); ht=V(J[f"{s}Hand"][1])
        tube([tuple(hb),tuple(hb.lerp(ht,.6))],[(.03,.018),(.035,.016)],"M_skin",[f"{s}Hand",f"{s}LowerArm"],seg=12,name=f"Palm_{s}")
        for k,dx in enumerate((-.022,-.008,.006,.019)):
            b0=hb.lerp(ht,.55)+V((sx*0.0,0,0))+V((0,dx*0 ,0)); off=V((sx*.003, -.0+dx*0.0, 0))
            p0=hb.lerp(ht,.55)+V((0,dx,0)); p1=p0+V((sx*.004,0,-.045+abs(dx)*0.6)); p2=p1+V((-sx*.006,-.006,-.02))
            tube([tuple(p0),tuple(p1),tuple(p2)],[.0085,.008,.007],"M_skin",[f"{s}Hand"],seg=8,name=f"Finger{k}_{s}")
        t0=hb.lerp(ht,.2)+V((-sx*.022,-.018,0)); tube([tuple(t0),tuple(t0+V((-sx*.012,-.02,-.035)))],[.0095,.008],"M_skin",[f"{s}Hand"],seg=8,name=f"Thumb_{s}")
    # neck + head
    tube([(0,.005,1.40),(0,.005,1.47),(0,.008,1.5)],[.042,.04,.045],"M_skin",["Neck","Head","UpperChest"],seg=16,name="Neck")
    HC=V((0,0.0,1.535)); HR=(.083,.094,.1)
    in_face=lambda p,n: n.y<-0.25 and abs(p.x)<.066 and 1.447<p.z<1.628
    ell(HC,HR,"M_skin",["Head"],seg=40,ring=20,name="Head")
    fo=ell(HC,(HR[0]+.0015,HR[1]+.0015,HR[2]+.0015),"M_face",["Head"],seg=40,ring=20,name="Face",keep=in_face)
    me=fo.data; uv=me.uv_layers[0]
    for p in me.polygons:
        for li in p.loop_indices:
            v=me.vertices[me.loops[li].vertex_index].co
            u=(v.x+.066)/.132; w=(v.z-1.447)/(1.628-1.447)
            uv.data[li].uv=(u/5.0,w)            # cell 0 (neutral); Godot shifts uv1_offset.x by idx/5
    for s,sx in ((1,1),(-1,-1)): ell(HC+V((sx*.084,.005,-.005)),(.012,.02,.026),"M_skin",["Head"],seg=12,ring=6,name="Ear")
    # collar
    if P.get("collar_on",True):
        for sx in (1,-1):
            c=ell(V((sx*.045,-.045,1.42)),(.055,.032,.012),"M_collar",["UpperChest","Neck"],seg=16,ring=6,name="Collar")
            c.rotation_euler=(math.radians(-20),math.radians(sx*-14),0); bpy.context.view_layer.objects.active=c; bpy.ops.object.transform_apply(rotation=True)
    P["hair_fn"](HC,HR)
    for f in P.get("extras",[]): f(HC,HR)
def hair_wavy_long(HC,HR,length=1.30,col_bones=["Head","Neck"]):
    cap=lambda p,n: not (n.y<-0.2 and p.z<1.605 and abs(p.x)<.075)
    ell(HC+V((0,.006,.006)),(HR[0]+.014,HR[1]+.016,HR[2]+.012),"M_hair",["Head"],seg=32,ring=16,name="HairCap",keep=cap)
    # side part sweep across forehead
    ell(HC+V((.012,-.07,.07)),(.07,.03,.022),"M_hair",["Head"],seg=16,ring=8,name="HairFringe")
    for k in range(15):
        a=math.radians(-110+k*(220/14))       # around sides/back
        x0,y0=math.sin(a)*(HR[0]+.008),math.cos(a)*(HR[1]+.006)
        if y0<-.04: continue
        pts=[];
        n=7
        for i in range(n):
            t=i/(n-1); z=1.6-t*(1.6-length+(0.03 if abs(math.sin(a))<.5 else 0))
            spread=1+0.55*t
            w=.012*math.sin(t*math.pi*2.5+k)
            pts.append((x0*spread+w*math.cos(a),y0*spread*0.95+.02*t+w*math.sin(a),z))
        tube(pts,[(.026,.012)]*(n-1)+[(.016,.008)],"M_hair",col_bones+["UpperChest"],seg=10,name=f"Strand{k}")
def hair_short(HC,HR):
    cap=lambda p,n: not (n.y<-0.2 and p.z<1.6 and abs(p.x)<.08) and p.z>1.47
    ell(HC+V((0,.004,.008)),(HR[0]+.012,HR[1]+.012,HR[2]+.01),"M_hair",["Head"],seg=28,ring=14,name="HairCap",keep=cap)
def hair_bun(HC,HR):
    hair_short(HC,HR); ell(HC+V((0,.06,.08)),(.045,.045,.04),"M_hair",["Head"],seg=16,ring=8,name="Bun")
def hair_bob(HC,HR):
    cap=lambda p,n: not (n.y<-0.2 and p.z<1.6 and abs(p.x)<.075)
    ell(HC+V((0,.008,-.005)),(HR[0]+.02,HR[1]+.02,HR[2]+.014),"M_hair",["Head"],seg=32,ring=16,name="HairBob",keep=lambda p,n: cap(p,n) and p.z>1.45)
    ell(HC+V((0,-.065,.075)),(.075,.025,.03),"M_hair",["Head"],seg=16,ring=8,name="Bangs")
def hair_afro(HC,HR):
    ell(HC+V((0,.02,.03)),(.13,.13,.12),"M_hair",["Head"],seg=28,ring=14,name="Afro",keep=lambda p,n: not (n.y<-0.1 and p.z<1.62))
def hair_bald(HC,HR):
    ell(HC+V((0,.01,-.01)),(HR[0]+.008,HR[1]+.008,HR[2]*0.7),"M_hair",["Head"],seg=28,ring=14,name="SideHair",keep=lambda p,n: n.y>-0.1 and 1.47<p.z<1.56)
def hair_ponytail(HC,HR):
    hair_short(HC,HR); tube([(0,.1,1.6),(0,.13,1.52),(0,.14,1.42),(0,.13,1.35)],[.03,.032,.026,.012],"M_hair",["Head","Neck","UpperChest"],seg=12,name="Ponytail")
def glasses(HC,HR):
    mat("M_glasses","#3B2A22",0.4)
    for sx in (1,-1):
        bpy.ops.mesh.primitive_torus_add(major_radius=.022,minor_radius=.0025,location=(sx*.032,-.098,1.56),rotation=(math.pi/2,0,0)); o=bpy.context.object; o.data.materials.append(MATS["M_glasses"]); PARTS.append((o,["Head"]))
def cap_hat(HC,HR):
    mat("M_hat","#4F7488",0.85); ell(HC+V((0,0,.05)),(.095,.105,.07),"M_hat",["Head"],seg=24,ring=10,name="Cap",keep=lambda p,n: p.z>1.585)
    ell(HC+V((0,-.1,.045)),(.07,.06,.006),"M_hat",["Head"],seg=16,ring=6,name="Brim")
def beard(HC,HR):
    ell(HC+V((0,-.04,-.07)),(.07,.06,.045),"M_hair",["Head"],seg=20,ring=10,name="Beard",keep=lambda p,n: n.y<0.2 and p.z<1.5)
def skin_weights(arm,obj,bones):
    vg={b:obj.vertex_groups.new(name=b) for b in set(bones)}
    for v in obj.data.vertices:
        p=obj.matrix_world@v.co; ds=sorted(((seg_dist(p,*J[b]),b) for b in bones))[:3]
        ws=[(1/(d**4+1e-7),b) for d,b in ds]; t=sum(w for w,_ in ws)
        for w,b in ws:
            if w/t>0.02: vg[b].add([v.index],w/t,'REPLACE')
def assemble(name,arm):
    objs=[]
    for o,b in PARTS:
        skin_weights(arm,o,b); objs.append(o)
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]; bpy.ops.object.join(); body=bpy.context.object; body.name=f"{name}_Body"; body.data.name=body.name
    bpy.ops.object.shade_smooth()
    wn=body.modifiers.new("wn","WEIGHTED_NORMAL"); wn.keep_sharp=True; bpy.ops.object.modifier_apply(modifier="wn")
    body.parent=arm; md=body.modifiers.new("Armature","ARMATURE"); md.object=arm
    PARTS.clear(); return body
# ---------------- clips (IK targets → baked FK) ----------------
BOX=dict(w=.40,d=.35,h=.40)   # medium box: palms on side faces at mid-height, centre 0.35 m front, 0.3 m below shoulders
SHZ=1.385; CARRY_Z=SHZ-0.30; CARRY_Y=-0.35
HAND_REST={"L":(.235,-.04,.83),"R":(-.235,-.04,.83)}; FOOT_REST={"L":(.09,.012,.085),"R":(-.09,.012,.085)}
CLIPS={}   # name -> dict(frames, loop, contact, keys)
def clip(name,frames,loop,contact,**k): CLIPS[name]=dict(frames=frames,loop=loop,contact=contact,**k)
def hands(L,R): return {"L":L,"R":R}
def H(x,y,z): return (x,y,z)
# key format: list of (frame, dict(hand_L, hand_R, foot_L, foot_R, hips_z, hips_y, spine, chest, head, hips_rot))
idleH=hands(HAND_REST["L"],HAND_REST["R"])
def K(f,**kw): return (f,kw)
clip("idle",36,True,[],keys=[K(0,spine=0,chest=0),K(18,spine=1.5,chest=2,hips_z=-.004,hL=(.237,-.045,.825),hR=(-.237,-.045,.825)),K(36,spine=0,chest=0)])
def walk_keys(n=30,stride=.19,lift=.07,swing=.11,carry=False,lean=3,amp_hands=True):
    ks=[]
    for f in range(0,n+1,5):
        ph=2*math.pi*f/n; s=math.cos(ph)
        fl=(.09,.012-stride*s,.085+max(0,-math.sin(ph))*lift*(1 if True else 0)); fr=(-.09,.012+stride*s,.085+max(0,math.sin(ph))*lift)
        kw=dict(fL=fl,fR=fr,hips_z=-.035+.02*abs(math.cos(ph))*1.0 -0.0,spine=lean,hips_rot=4*math.sin(ph))
        if carry: kw.update(hL=(.20,CARRY_Y,CARRY_Z+.01*math.cos(2*ph)),hR=(-.20,CARRY_Y,CARRY_Z+.01*math.cos(2*ph)))
        elif amp_hands: kw.update(hL=(.235,-.04+swing*s,.84),hR=(-.235,-.04-swing*s,.84))
        ks.append(K(f,**kw))
    return ks
clip("walk",30,True,[0,15],keys=walk_keys())
CARRYH=dict(hL=(.20,CARRY_Y,CARRY_Z),hR=(-.20,CARRY_Y,CARRY_Z))
FLOORH=dict(hL=(.20,-.38,.20),hR=(-.20,-.38,.20))
clip("carry",36,True,[],keys=[K(0,spine=-3,**CARRYH),K(18,spine=-2,chest=1.5,hips_z=-.005,hL=(.20,CARRY_Y,CARRY_Z-.008),hR=(-.20,CARRY_Y,CARRY_Z-.008)),K(36,spine=-3,**CARRYH)])
squat=dict(hips_z=-.33,hips_y=.12,spine=38,chest=8,head=-12)
clip("pick_up",30,False,[13],keys=[K(0,**{**dict(hL=HAND_REST["L"],hR=HAND_REST["R"])}),K(11,**squat,hL=(.24,-.36,.24),hR=(-.24,-.36,.24)),K(13,**squat,**FLOORH),K(16,**squat,**FLOORH),
    K(26,spine=-2,hips_z=-.01,hL=(.20,CARRY_Y,CARRY_Z-.04),hR=(-.20,CARRY_Y,CARRY_Z-.04)),K(30,spine=-3,**CARRYH)])
clip("set_down",30,False,[17],keys=[K(0,spine=-3,**CARRYH),K(12,**squat,hL=(.20,-.38,.22),hR=(-.20,-.38,.22)),K(17,**squat,**FLOORH),K(20,**squat,hL=(.25,-.36,.24),hR=(-.25,-.36,.24)),K(30,hL=HAND_REST["L"],hR=HAND_REST["R"])])
def push_keys(n=30):
    ks=[]
    for f in range(0,n+1,5):
        ph=2*math.pi*f/n; s=math.cos(ph)
        ks.append(K(f,spine=16,chest=6,hips_y=.06,hips_z=-.05+.01*abs(s),fL=(.09,.06-.12*s,.085+max(0,-math.sin(ph))*.04),fR=(-.09,.06+.12*s,.085+max(0,math.sin(ph))*.04),
                    hL=(.20,-.42,1.02+.006*s),hR=(-.20,-.42,1.02-.006*s)))
    return ks
clip("push",30,True,[0,15],keys=push_keys())
bend=dict(spine=30,chest=10,hips_z=-.06,hips_y=.06,head=-15)
clip("open_box",30,False,[10],keys=[K(0,hL=HAND_REST["L"],hR=HAND_REST["R"]),K(10,**bend,hL=(.08,-.42,.47),hR=(-.08,-.42,.47)),K(16,**bend,hL=(.10,-.44,.50),hR=(-.10,-.44,.50)),
    K(24,**bend,hL=(.30,-.40,.56),hR=(-.30,-.40,.56)),K(30,spine=4,hL=HAND_REST["L"],hR=HAND_REST["R"])])
SIT=dict(hips_z=-.44,hips_y=.06,fL=(.10,-.40,.085),fR=(-.10,-.40,.085),spine=-4)
clip("sit",36,True,[0],keys=[K(0,**SIT,hL=(.15,-.30,.60),hR=(-.15,-.30,.60)),K(18,**{**SIT,"chest":2},hL=(.15,-.30,.605),hR=(-.15,-.30,.605)),K(36,**SIT,hL=(.15,-.30,.60),hR=(-.15,-.30,.60))])
def type_keys(n=24):
    ks=[]
    for f in range(0,n+1,3):
        a=.012*math.sin(2*math.pi*f/n*2); b=.012*math.sin(2*math.pi*f/n*2+math.pi)
        ks.append(K(f,**{**SIT,"spine":6},head=-8,hL=(.13,-.40,.765+max(0,a)),hR=(-.13,-.40,.765+max(0,b))))
    return ks
clip("type",24,True,[3,9,15,21],keys=type_keys())
clip("water",36,False,[14],keys=[K(0,hL=HAND_REST["L"],hR=(-.22,-.12,.92)),K(10,spine=10,head=-10,hR=(-.18,-.42,.92)),K(14,spine=14,head=-14,hR=(-.14,-.48,.85)),K(26,spine=14,head=-14,hR=(-.14,-.48,.84)),K(36,hR=(-.22,-.12,.92))])
clip("lamp_switch",18,False,[8],keys=[K(0),K(7,spine=6,hR=(-.12,-.42,1.04)),K(8,spine=6,hR=(-.12,-.43,1.03)),K(10,spine=6,hR=(-.12,-.40,1.04)),K(18)])
clip("drink",36,False,[16],keys=[K(0,hR=(-.20,-.22,1.0)),K(12,head=4,hR=(-.05,-.15,1.42)),K(16,head=10,hR=(-.03,-.13,1.47)),K(24,head=10,hR=(-.03,-.13,1.47)),K(36,hR=(-.20,-.22,1.0))])
clip("shelve",30,False,[15],keys=[K(0,hR=(-.20,-.25,1.05)),K(12,spine=-3,head=10,hR=(-.12,-.42,1.52)),K(15,spine=-3,head=10,hR=(-.10,-.46,1.56)),K(19,spine=-3,head=8,hR=(-.12,-.40,1.50)),K(30,hR=HAND_REST["R"])])
clip("stand_up",30,False,[10],keys=[K(0,hL=HAND_REST["L"],hR=HAND_REST["R"]),K(10,**bend,hL=(.15,-.42,.30),hR=(-.15,-.42,.30)),K(20,spine=14,hips_z=-.03,hL=(.15,-.45,.62),hR=(-.15,-.45,.62)),K(30,hL=HAND_REST["L"],hR=HAND_REST["R"])])
TYPE_NAMES=["pick_up","carry","set_down","push","open_box","sit","type","water","lamp_switch","drink","shelve","stand_up","idle","walk"]
assert sorted(TYPE_NAMES)==sorted(CLIPS)
def make_controls(arm):
    C={}
    for k in ("hL","hR","fL","fR","pL","pR","kL","kR"):
        e=bpy.data.objects.new("CTL_"+k,None); bpy.context.scene.collection.objects.link(e); C[k]=e
    C["pL"].location=(.45,.35,1.0); C["pR"].location=(-.45,.35,1.0); C["kL"].location=(.12,-.8,.5); C["kR"].location=(-.12,-.8,.5)
    pb=arm.pose.bones
    for s,S in (("L","Left"),("R","Right")):
        c=pb[f"{S}LowerArm"].constraints.new("IK"); c.target=C["h"+s]; c.pole_target=C["p"+s]; c.chain_count=2; c.pole_angle=math.radians(-90)
        c=pb[f"{S}LowerLeg"].constraints.new("IK"); c.target=C["f"+s]; c.pole_target=C["k"+s]; c.chain_count=2; c.pole_angle=math.radians(-90)
    return C
def author_and_bake(arm,C):
    sc=bpy.context.scene; sc.render.fps=FPS; pb=arm.pose.bones; baked={}
    for b in pb: b.rotation_mode='XYZ'
    for name in TYPE_NAMES:
        cl=CLIPS[name]; n=cl["frames"]
        for o in [arm]+list(C.values()): o.animation_data_clear()
        for b in pb: b.location=(0,0,0); b.rotation_euler=(0,0,0)
        for fr,kw in cl["keys"]:
            sc.frame_set(fr)
            for s in "LR":
                C["h"+s].location=kw.get("h"+s,HAND_REST[s]); C["h"+s].keyframe_insert("location",frame=fr)
                C["f"+s].location=kw.get("f"+s,FOOT_REST[s]); C["f"+s].keyframe_insert("location",frame=fr)
            h=pb["Hips"]; h.location=(0,kw.get("hips_z",0),-kw.get("hips_y",0)) # bone-local: Y=up(world Z), Z=-world Y... (see below)
            h.rotation_euler=(0,math.radians(kw.get("hips_rot",0)),0)
            h.keyframe_insert("location",frame=fr); h.keyframe_insert("rotation_euler",frame=fr)
            for bn,key,w in (("Spine","spine",.5),("Chest","spine",.5),("Chest","chest",1),("UpperChest","chest",.5)):
                pass
            sp=math.radians(kw.get("spine",0)); ch=math.radians(kw.get("chest",0))
            pb["Spine"].rotation_euler=(sp*.5,0,0); pb["Chest"].rotation_euler=(sp*.5+ch*.6,0,0); pb["UpperChest"].rotation_euler=(ch*.4,0,0)
            pb["Head"].rotation_euler=(math.radians(-kw.get("head",0))*-1*-1,0,0); pb["Neck"].rotation_euler=(0,0,0)
            for bn in ("Spine","Chest","UpperChest","Head","Neck"): pb[bn].keyframe_insert("rotation_euler",frame=fr)
        sc.frame_start=0; sc.frame_end=n
        bpy.context.view_layer.objects.active=arm; arm.select_set(True); bpy.ops.object.mode_set(mode='POSE'); bpy.ops.pose.select_all(action='SELECT')
        bpy.ops.nla.bake(frame_start=0,frame_end=n,only_selected=False,visual_keying=True,clear_constraints=False,use_current_action=False,bake_types={'POSE'})
        bpy.ops.object.mode_set(mode='OBJECT')
        act=arm.animation_data.action; act.name=name; act.use_fake_user=True; act.use_frame_range=True; act.frame_start=0; act.frame_end=n
        act.use_cyclic=cl["loop"]; baked[name]=act
    for o in C.values(): bpy.data.objects.remove(o)
    for b in pb:
        for c in list(b.constraints): b.constraints.remove(c)
    arm.animation_data.action=baked["idle"]
    for act in baked.values():   # NLA strip per clip so the exporter writes every clip by name
        tr=arm.animation_data.nla_tracks.new(); tr.name=act.name; st=tr.strips.new(act.name,0,act); tr.mute=True
    arm.animation_data.action=None
    return baked
def export(arm,body,path):
    bpy.ops.object.select_all(action='DESELECT'); arm.select_set(True); body.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path,export_format='GLB',use_selection=True,export_yup=True,export_skins=True,export_animations=True,
        export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_frame_range=False,export_anim_slide_to_zero=True,export_def_bones=False,export_apply=False)
