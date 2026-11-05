# L7 Dentist / L8 Market / L9 Architect placeholder models (level_layouts/README.md "Placeholders Art still needs").
# Blender coords: X width, Y depth (front = -Y = Godot +Z), Z up. Origin bottom-centre unless noted. Box -colonly per item.
# Run: blender -b -P build_L07_L09.py [-- names...]  then upgrade_pass.py -- L7_L9 <names>
import sys, os
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),"lvl_kit.py")).read())
ONLY=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
def want(n): return not ONLY or n in ONLY
WH,WT=3.0,0.24
def hcyl(r,h,x=0,y=0,z=0,**k):   # rotated cylinder centred at (x,y,z)
    o=cyl(r,h,x,y,z,**k); o.location=(x,y,z); return o
# ---------------- door_double_2m: 2.0 x 3.0 x 0.24 wall piece, 1.4 x 2.2 m clear opening, two glazed leaves ----------------
def door_double_2m():
    clear(); PARTS.clear(); OW,OH=1.4,2.2
    for x0,x1 in ((-1,-OW/2),(OW/2,1)):
        box(x1-x0,WT,WH,(x0+x1)/2,0,0,m="cream",bev=0); box(x1-x0,WT+0.004,0.12,(x0+x1)/2,0,0,m="darkwood",bev=0)
        box(x1-x0,WT+0.004,0.06,(x0+x1)/2,0,WH-0.06,m="wood",bev=0)
    box(OW,WT,WH-OH,0,0,OH,m="cream",bev=0); box(OW,WT+0.004,0.06,0,0,WH-0.06,m="wood",bev=0)
    for x in (-OW/2-0.035,OW/2+0.035): box(0.07,WT+0.02,OH+0.07,x,0,0,m="wood",bev=0.008)     # casing (outside the clear width)
    box(OW+0.14,WT+0.02,0.07,0,0,OH,m="wood",bev=0.008)
    wall=group("Wall")
    leaves=[]
    for s,nm in ((-1,"DoorLeaf_L"),(1,"DoorLeaf_R")):
        PARTS.clear(); lw=OW/2-0.01; cx=s*(OW/2-lw/2)
        for xx in (cx-lw/2+0.05,cx+lw/2-0.05): box(0.1,0.05,OH-0.02,xx,0,0.005,m="mintdk",bev=0.01)   # stiles
        box(lw,0.05,0.12,cx,0,OH-0.13,m="mintdk",bev=0.01); box(lw,0.05,0.75,cx,0,0.005,m="mintdk",bev=0.01)   # top rail, kick panel
        box(lw,0.05,0.08,cx,0,0.86,m="mintdk",bev=0.01)
        box(lw-0.2,0.06,0.22,cx,0,0.24,m="wood",bev=0.008)                          # raised panel (wood)
        gl(box(lw-0.18,0.012,OH-0.13-0.94,cx,0,0.94,m="white",bev=0))                 # single glass pane (front+back faces, single-sided)
        box(lw-0.2,0.07,0.02,cx,0,1.52,m="mintdk",bev=0)                              # muntin
        cyl(0.016,0.36,s*0.06,-0.05,1.0,m="chrome",v=10); cyl(0.016,0.36,s*0.06,0.05,1.0,m="chrome",v=10)   # pull handles both sides
        l=group(nm); set_origin(l,(s*OW/2,0,0)); leaves.append(l)
    cols=[colbox(1-OW/2,WT,WH,-(1+OW/2)/2,0,0),colbox(1-OW/2,WT,WH,(1+OW/2)/2,0,0),colbox(OW,WT,WH-OH,0,0,OH)]
    finish_item("door_double_2m","L7/L9",[wall]+leaves,cols,extras=dict(clear_opening_m=[1.4,2.2],door="double_swing",
        leaves=["DoorLeaf_L","DoorLeaf_R"],hinge_axis="y",leaf_open_deg=[-95,95],role="door"))
# ---------------- L7 dentist ----------------
def instrument_jar_tray():
    clear(); PARTS.clear()
    box(0.40,0.25,0.012,0,0,0,m="mintdk",bev=0.004)
    for sx in (-1,1): box(0.012,0.25,0.03,sx*0.194,0,0.012,m="mintdk",bev=0.003)
    for sy in (-1,1): box(0.40,0.012,0.03,0,sy*0.119,0.012,m="mintdk",bev=0.003)
    for i,x in enumerate((-0.12,0,0.12)):
        g=cyl(0.048,0.115,x,0,0.012,m="white",v=20); gl(g)
        cyl(0.052,0.02,x,0,0.13,m="chrome",v=20)                          # lid -> top 0.15
        if i==0:
            for k in range(7): ball(0.018,x+0.022*math.cos(k*2.2),0.02*math.sin(k*2.2),0.035+0.02*(k%3),m="cotton",sub=1)   # cotton balls
        elif i==1:
            for k in range(6): box(0.016,0.003,0.1,x-0.02+k*0.008,0.01*math.sin(k),0.016,m="card",bev=0,rot=(0,math.radians(-8+k*3),0))  # tongue depressors
        else:
            for k in range(8):
                a=k*0.8; cyl(0.0025,0.1,x+0.02*math.cos(a),0.02*math.sin(a),0.016,m="cotton",v=5); ball(0.006,x+0.02*math.cos(a),0.02*math.sin(a),0.112,m="cotton",sub=1)
    t=group("JarTray"); finish_item("instrument_jar_tray","L7",[t],extras=dict(role="fragile",contents=["cotton","tongue_depressors","swabs"]))
def reception_desk():
    clear(); PARTS.clear()
    box(1.8,0.06,0.98,0,-0.27,0.07,m="mintdk",bev=0.012)                     # front panel (Godot +Z)
    for x in (-0.87,0.87): box(0.06,0.6,0.98,x,0,0.07,m="mintdk",bev=0.012)
    box(1.8,0.6,0.07,0,0,0,m="darkwood",bev=0.006)                           # kick plinth
    box(1.84,0.26,0.04,0,-0.19,1.01,m="cream",bev=0.01)                       # transaction ledge (top 1.05)
    box(1.72,0.5,0.035,0,0.03,0.72,m="cream",bev=0.008)                       # work surface behind
    for z in (0.32,0.62): box(1.74,0.006,0.025,0,-0.302,z,m="cream",bev=0)    # cream reveal lines on the front
    box(0.3,0.012,0.3,0,-0.305,0.36,m="card",bev=0.01); box(0.14,0.016,0.16,0,-0.31,0.44,m="mintdk",bev=0.02)   # tooth sign
    for x in (-0.03,0.03): box(0.04,0.016,0.07,x,-0.31,0.39,m="mintdk",bev=0.01)
    cyl(0.045,0.035,0.55,0.05,0.755,m="chrome",v=14,r2=0.01); cyl(0.05,0.008,0.55,0.05,0.755,m="darkwood",v=14)   # service bell
    box(0.22,0.16,0.012,-0.4,0.05,0.755,m="card",bev=0.002)                   # appointment book
    d=group("Desk"); finish_item("reception_desk","L7",[d],extras=dict(role="heavy"))
def waiting_bench():
    clear(); PARTS.clear()
    for x in (-0.72,0.72):
        for y in (-0.2,0.2): cyl(0.018,0.42,x,y,0,m="chrome",v=10)
        box(0.04,0.46,0.03,x,0,0.40,m="chrome",bev=0.005)
    for y in (-0.15,0.12): box(1.56,0.04,0.03,0,y,0.40,m="chrome",bev=0.005)
    for i,x in enumerate((-0.52,0,0.52)):
        box(0.48,0.46,0.07,x,-0.03,0.43,m="mintdk",bev=0.03)                  # seat pad
        box(0.48,0.08,0.36,x,0.22,0.48,m="mintdk",bev=0.03,rot=(math.radians(-10),0,0))   # back pad
    for x in (-0.78,-0.26,0.26,0.78): box(0.04,0.4,0.04,x,0,0.62,m="chrome",bev=0.008); cyl(0.012,0.12,x,-0.15,0.5,m="chrome",v=8)
    b=group("Bench"); finish_item("waiting_bench","L7",[b],extras=dict(role="heavy",seats=3))
def exam_lamp():
    clear(); PARTS.clear()
    cyl(0.24,0.035,0,0,0,m="chrome",v=24); cyl(0.2,0.02,0,0,0.035,m="mintdk",v=24)
    for a in range(5): ball(0.025,0.2*math.cos(a*1.257),0.2*math.sin(a*1.257),0.02,m="night",sub=1)
    cyl(0.022,1.5,0,0,0.05,m="chrome",v=12); cyl(0.035,0.08,0,0,1.0,m="mintdk",v=12)   # pole + height knob
    ball(0.04,0,0,1.56,m="chrome",sub=2)
    arm=cyl(0.02,0.26,0,0,0,m="chrome",v=10); arm.rotation_euler=(0,math.radians(55),0); arm.location=(0.0,-0.0,1.56)
    # lamp head: oval dish, cream/mint shell, emissive face toward floor/front
    hd=ball(0.11,0.16,-0.04,1.72,m="mintdk",sub=2,sz=0.45); hd.scale.x=1.25; bpy.context.view_layer.objects.active=hd
    rim=cyl(0.118,0.02,0.16,-0.04,1.66,m="cream",v=24); rim.scale.x=1.25
    f=cyl(0.1,0.006,0.16,-0.04,1.655,m="white",v=24); f.scale.x=1.25; emit(f,"lamp_face","#FFF4E2",1.2)
    for s in (-1,1): hcyl(0.012,0.1,0.16+s*0.16,-0.04,1.68,m="chrome",v=8,rot=(0,math.radians(90),0))   # handles
    cyl(0.03,0.11,0,0,1.79,m="mintdk",v=12)                                    # top cap -> 1.9
    l=group("ExamLamp"); finish_item("exam_lamp","L7",[l],extras=dict(role="upright",emission="lamp_face x1.2 (no light node)"))
def aquarium_stand():
    clear(); PARTS.clear()
    box(0.8,0.4,0.06,0,0,0,m="darkwood",bev=0.006)
    box(0.78,0.38,0.64,0,0,0.06,m="mintdk",bev=0.012)
    box(0.82,0.42,0.05,0,0,0.70,m="cream",bev=0.01)
    for s in (-1,1):
        box(0.36,0.012,0.56,s*0.19,-0.195,0.1,m="mintdk",bev=0.01)            # doors
        box(0.3,0.006,0.48,s*0.19,-0.203,0.14,m="cream",bev=0)               # inset cream panel
        hcyl(0.012,0.02,s*0.04,-0.215,0.5,m="chrome",v=10,rot=(math.pi/2,0,0))
    s_=group("Stand"); finish_item("aquarium_stand","L7",[s_],extras=dict(role="heavy",supports="aquarium.glb (0.70 x 0.35)"))
def xray_lightbox():
    clear(); PARTS.clear()
    box(0.6,0.06,0.45,0,0,0,m="card",bev=0.012)                                # body/frame #F8F4EC
    f=box(0.54,0.004,0.37,0,-0.031,0.04,m="white",bev=0); emit(f,"xray","#EAF4FF",2.75)   # backlit panel
    for x in (-0.13,0.13):                                                     # two films, dark with light teeth
        fl=box(0.22,0.002,0.29,x,-0.034,0.07,m="white",bev=0); emit(fl,"xray_film","#55657A",2.75)
        for k in range(4):
            for row,zz,sg in ((0,0.24,1),(1,0.14,-1)):
                t=box(0.032,0.002,0.05,x-0.06+k*0.04,-0.036,zz,m="white",bev=0); emit(t,"xray_teeth","#EAF4FF",2.75)
        hcyl(0.008,0.012,x,-0.036,0.39,m="chrome",v=8,rot=(math.pi/2,0,0))     # clip
    box(0.08,0.012,0.02,0.22,-0.035,0.015,m="night",bev=0.003)                 # switch
    b=group("Lightbox"); finish_item("xray_lightbox","L7",[b],origin="back",
        extras=dict(role="fragile",mount="wall",emission="#EAF4FF x2.75 panel, no light node"))
def instrument_cart():
    clear(); PARTS.clear()
    for x in (-0.27,0.27):
        for y in (-0.19,0.19): cyl(0.014,0.76,x,y,0.06,m="chrome",v=8); ball(0.03,x,y,0.03,m="night",sub=1)
    for z in (0.3,0.74):
        box(0.6,0.42,0.02,0,0,z,m="mintdk",bev=0.004)
        for sy in (-1,1): box(0.6,0.012,0.035,0,sy*0.204,z+0.02,m="mintdk",bev=0.003)
        for sx in (-1,1): box(0.012,0.42,0.035,sx*0.294,0,z+0.02,m="mintdk",bev=0.003)
    hcyl(0.012,0.4,0.31,0,0.83,m="chrome",v=8,rot=(math.pi/2,0,0))             # push handle (side)
    dish=ball(0.07,-0.12,0,0.775,m="chrome",sub=2,sz=0.25); dish.scale.y=0.55
    for k in range(4): hcyl(0.004,0.13,0.05+k*0.025,-0.02,0.772,m="chrome",v=6,rot=(math.pi/2,0,math.radians(8*k)))
    box(0.14,0.09,0.06,0.16,0.08,0.76,m="card",bev=0.006); box(0.05,0.002,0.02,0.16,0.034,0.8,m="mintdk",bev=0)   # glove box
    box(0.2,0.16,0.12,-0.1,0,0.32,m="cotton",bev=0.01)                       # towels on lower shelf
    c=group("Cart"); finish_item("instrument_cart","L7",[c],extras=dict(role="upright"))
def npc_delbert():
    def cap(part):
        if part=="head": cyl(0.13,0.05,0,0,1.47,m="olive",v=16); box(0.2,0.08,0.015,0,-0.12,1.47,m="olive",bev=0.005)   # flat cap
        if part=="body":
            for z in (0.95,1.05,1.15): ball(0.012,0,-0.105,z,m="brass",sub=1)   # cardigan buttons
    def watch(): hcyl(0.035,0.012,0,-0.06,0,m="brass",v=16,rot=(math.pi/2,0,0))
    npc2("npc_delbert","olive","darkwood",1.7,"L7",hair="hair_white",acc=cap,extra=watch,
         extras=dict(role="npc",character="Delbert Finch (retired clockmaker, L7 cameo)",optional=True))
# ---------------- L8 reward decor ----------------
def fruit_basket():
    clear(); PARTS.clear()
    b=cyl(0.2,0.13,0,0,0,m="wicker",v=24,r2=0.16); b.scale.y=0.72
    for z in (0.03,0.065,0.1): r=cyl(0.2-0.03*z/0.13*1.3+0.004,0.012,0,0,z,m="cardboard",v=24); r.scale.y=0.72
    rim=cyl(0.205,0.02,0,0,0.12,m="cardboard",v=24); rim.scale.y=0.72
    bpy.ops.mesh.primitive_torus_add(major_radius=0.17,minor_radius=0.012,major_segments=24,minor_segments=6,location=(0,0,0.13),rotation=(math.pi/2,0,0))
    h=bpy.context.object; h.scale.z=0.85; h.data.materials.append(mat("wicker")); PARTS.append(h)
    for (x,y,c,r) in ((-0.08,-0.03,"apple",0.045),(0.0,-0.05,"peach",0.045),(0.08,-0.02,"applegreen",0.042),(-0.04,0.05,"peach",0.043),(0.06,0.05,"apple",0.044),(0.02,0.0,"applegreen",0.043)):
        ball(r,x,y,0.15,m=c,sub=2); cyl(0.004,0.02,x,y,0.15+r-0.004,m="darkwood",v=5)
    for k in range(3):
        bn=hcyl(0.018,0.17,-0.02+k*0.025,0.0,0.2,m="banana",v=8,rot=(0,math.radians(80),math.radians(20)))
    fb=group("Basket"); finish_item("fruit_basket","L8",[fb],extras=dict(role="decor",note="L8 reward decor"))
# ---------------- L9 architect ----------------
def plan_tube():
    clear(); PARTS.clear()
    cyl(0.048,0.82,0,0,0.04,m="planblue",v=18)
    cyl(0.051,0.05,0,0,0.0,m="night",v=18); cyl(0.051,0.06,0,0,0.84,m="night",v=18)   # end caps (top cap 0.84..0.90)
    cyl(0.049,0.05,0,0,0.42,m="cream",v=18)                                     # label band
    cyl(0.0495,0.012,0,0,0.6,m="night",v=18)                                    # strap ring
    t=group("Tube"); finish_item("plan_tube","L9",[t],extras=dict(role="tube"))
def blueprint_roll():
    clear(); PARTS.clear()
    hcyl(0.04,0.6,0,0,0,m="card",v=18,rot=(0,math.pi/2,0)).location=(-0.3,0,0.04)
    PARTS[-1].location=(0,0,0.04)
    for s in (-1,1):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.022,minor_radius=0.006,location=(s*0.301,0,0.04),rotation=(0,math.pi/2,0))
        t=bpy.context.object; t.data.materials.append(mat("planblue")); PARTS.append(t)       # blue edge spiral at the ends
        hcyl(0.012,0.004,s*0.3005,0,0.04,m="planblue",v=10,rot=(0,math.pi/2,0)).location=(s*0.3005,0,0.04)
    hcyl(0.0415,0.018,0,0,0.04,m="terracotta",v=18,rot=(0,math.pi/2,0)).location=(0.12,0,0.04)  # rubber band
    PARTS[-1].location=(0.12,0,0.04)
    b=group("Roll"); finish_item("blueprint_roll","L9",[b],extras=dict(role="light"))
def drafting_stool():
    clear(); PARTS.clear()
    for a in range(5):
        an=a*2*math.pi/5; x,y=0.17*math.cos(an),0.17*math.sin(an)
        arm=box(0.17,0.03,0.025,x/2,y/2,0.04,m="chrome",bev=0.005,rot=(0,0,an)); ball(0.022,x,y,0.022,m="night",sub=1)
    cyl(0.04,0.05,0,0,0.035,m="chrome",v=12); cyl(0.022,0.48,0,0,0.08,m="chrome",v=12)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.16,minor_radius=0.01,major_segments=24,minor_segments=6,location=(0,0,0.32))
    r=bpy.context.object; r.data.materials.append(mat("chrome")); PARTS.append(r)
    for a in range(3): box(0.15,0.015,0.01,0.08*math.cos(a*2.094),0.08*math.sin(a*2.094),0.315,m="chrome",bev=0,rot=(0,0,a*2.094))
    cyl(0.12,0.03,0,0,0.56,m="chrome",v=16); cyl(0.19,0.06,0,0,0.59,m="slate",v=24)    # seat (top 0.65)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.185,minor_radius=0.012,major_segments=24,minor_segments=6,location=(0,0,0.62))
    s=bpy.context.object; s.data.materials.append(mat("slate")); PARTS.append(s)
    st=group("Stool"); finish_item("drafting_stool","L9",[st],extras=dict(role="light"))
ALL=[door_double_2m,instrument_jar_tray,reception_desk,waiting_bench,exam_lamp,aquarium_stand,xray_lightbox,instrument_cart,npc_delbert,
     fruit_basket,plan_tube,blueprint_roll,drafting_stool]
for fn in ALL:
    if want(fn.__name__): fn()
dump("L07_L09"); print("L7L9_DONE",len(SPEC))
