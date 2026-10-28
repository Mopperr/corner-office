"""usage: blender -b <model.blend> -P author_clips.py -- --arm Dana --out <glb> [--clips a,b] [--preview DIR] [--json path] [--save blend]"""
import bpy, sys, os, json, math, time
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import importlib, animlib, clips; importlib.reload(animlib); importlib.reload(clips)
from animlib import *
from clips import *
argv=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
def arg(n,d=None):
    return argv[argv.index(n)+1] if n in argv else d
ARM=arg('--arm','Dana'); OUT=arg('--out'); SEL=arg('--clips'); PREV=arg('--preview'); JS=arg('--json'); SAVE=arg('--save')
VIEWS=arg('--views','q,side').split(',')
T0=time.time()
def log(*a): print(f'[{time.time()-T0:6.1f}s]',*a,flush=True)
arm=bpy.data.objects[ARM]; rig=Rig(arm); S=Solver(rig)
for pb in arm.pose.bones: pb.rotation_mode='QUATERNION'
fns=ALL if not SEL else [f for f in ALL if f.__name__[2:] in SEL.split(',')]
results=[]
for fn in fns:
    c=fn(rig); frames,infos=bake(rig,c,S)
    act=write_action(rig,c,frames)
    # metrics
    legmax=max(max(i['legL'],i['legR']) for i in infos); armmax=max(max(i['armL'],i['armR']) for i in infos)
    # foot slide: grounded heel/ball points displacement between frames (expected treadmill speed for walk)
    slide=0.0; exp=c.meta.get('speed_mps',0)/FPS
    for side in('Left','Right'):
        prev=None
        for f,(D,H) in enumerate(frames):
            pts=[H[side+'Toes'], H[side+'Foot']+D[side+'Foot']@V((0,0.035,-0.076))]
            g=[p for p in pts if p.z<0.03]
            cur=g[0].copy() if g else None
            if cur is not None and prev is not None:
                d=(cur-prev); d.y+=exp if exp else 0
                slide=max(slide,math.hypot(d.x,d.y))
            prev=cur
    # hand reach vs target
    results.append(dict(clip=c,act=act,frames=frames,leg=legmax,arm=armmax,slide=slide))
    log(f'{c.name:12s} frames={c.N:4d} loop={c.loop} legmax={legmax:.3f} armmax={armmax:.3f} slide={slide*1000:.1f}mm/f',c.meta)

# ---------------------------------------------------------------- NLA + export
ad=arm.animation_data or arm.animation_data_create()
for tr in list(ad.nla_tracks): ad.nla_tracks.remove(tr)
ad.action=None
for r in results:
    tr=ad.nla_tracks.new(); tr.name=r['clip'].name
    st=tr.strips.new(r['clip'].name,0,r['act']); st.action_frame_end=r['act'].frame_range[1]
    tr.mute=False
for pb in arm.pose.bones: pb.rotation_quaternion=(1,0,0,0); pb.location=(0,0,0)
if JS:
    B=rig.B
    js=dict(character=ARM,fps=FPS,library='interact',axis='glTF Y-up, faces +Z, right hand = -X',
        height_m=round(rig.height,3),root_motion=False,
        bones=[dict(name=b,parent=B[b]['p'],head=[round(B[b]['h'].x,4),round(B[b]['h'].z,4),round(-B[b]['h'].y,4)],
                    tail=[round(B[b]['t'].x,4),round(B[b]['t'].z,4),round(-B[b]['t'].y,4)],deform=arm.data.bones[b].use_deform) for b in rig.order],
        rest_pose='A-pose 45deg arms, palms facing body/down, slight elbow bend; feet parallel; origin between feet on the floor',
        clips=[dict(name=r['clip'].name,frames=[0,r['clip'].N],seconds=round(r['clip'].N/FPS,3),loop=r['clip'].loop,
                    notes=r['clip'].notes,**r['clip'].meta,max_leg_extension=round(r['leg'],3),max_foot_slide_mm_per_frame=round(r['slide']*1000,2)) for r in results])
    json.dump(js,open(JS,'w'),indent=1); log('json',JS)
if OUT:
    meshes=[o for o in bpy.data.objects if o.type=='MESH' and o.parent==arm]
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes+[arm]: o.select_set(True)
    bpy.context.view_layer.objects.active=arm
    bpy.ops.export_scene.gltf(filepath=OUT,export_format='GLB',use_selection=True,export_yup=True,export_apply=False,
        export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_frame_step=1,
        export_def_bones=False,export_skins=True,export_morph=False,export_colors=True,export_extras=True,
        export_optimize_animation_size=True,export_anim_single_armature=True,export_reset_pose_bones=True)
    log('exported',OUT,os.path.getsize(OUT)//1024,'KB')
if SAVE: bpy.ops.wm.save_as_mainfile(filepath=SAVE); log('saved',SAVE)

# ---------------------------------------------------------------- previews
if PREV:
    import preview; importlib.reload(preview)
    preview.render_all(arm,rig,results,PREV,VIEWS,log)
