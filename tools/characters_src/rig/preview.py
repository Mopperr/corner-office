import bpy, os, math, subprocess, bmesh
from mathutils import Vector as V, Matrix as M
from animlib import *
def hexc(h): h=h.lstrip('#'); c=[int(h[i:i+2],16)/255 for i in (0,2,4)]; return tuple(((x+0.055)/1.055)**2.4 if x>0.04045 else x/12.92 for x in c)+(1,)
def pmat(name,col):
    m=bpy.data.materials.get('P_'+name) or bpy.data.materials.new('P_'+name); m.diffuse_color=hexc(col); m.use_nodes=True
    m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=hexc(col); m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.7
    return m
def cube(name,dims,loc,col,parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1); o=bpy.context.object; o.name=name; o.scale=dims; o.location=loc
    bpy.ops.object.transform_apply(location=False,scale=True)
    o.data.materials.append(pmat(name,col))
    if parent: o.parent=parent
    return o
def cylo(name,r,h,loc,col,parent=None,rot=(0,0,0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=r,depth=h,vertices=24,location=loc,rotation=rot); o=bpy.context.object; o.name=name
    o.data.materials.append(pmat(name,col)); 
    if parent: o.parent=parent
    return o
def empty(name):
    e=bpy.data.objects.new(name,None); bpy.context.scene.collection.objects.link(e); return e
def build_prop(p):
    root=empty('PR_'+p.name); w,d,h=p.dims[0],p.dims[1],p.dims[2]
    if p.kind=='box': cube(p.name,(p.dims[0],p.dims[2],p.dims[1]),(0,0,0),p.color,root)
    elif p.kind=='openbox':
        W,Hh,Dd=p.dims; cube(p.name+'_b',(W,Dd,Hh),(0,0,0),p.color,root); root['flaps']=[]
        for i,(axis,off,sz) in enumerate([('x',(0,Dd/2,Hh/2),(W,Dd/2,0.004)),('x',(0,-Dd/2,Hh/2),(W,Dd/2,0.004)),('y',(W/2,0,Hh/2),(W/2,Dd,0.004)),('y',(-W/2,0,Hh/2),(W/2,Dd,0.004))]):
            hinge=empty(f'{p.name}_h{i}'); hinge.parent=root; hinge.location=off
            sx,sy,sz_=sz; c=(0,-sy/2 if off[1]>0 else sy/2,0) if axis=='x' else (-sx/2 if off[0]>0 else sx/2,0,0)
            cube(f'{p.name}_f{i}',sz,c,'#BF9A62',hinge)
    elif p.kind=='desk':
        cube(p.name+'_top',(w,d,0.04),(0,0,h-0.02),p.color,root)
        for sx in(-1,1):
            for sy in(-1,1): cube(p.name+'_leg',(0.04,0.04,h-0.04),(sx*(w/2-0.05),sy*(d/2-0.05),(h-0.04)/2),'#6B4A3A',root)
    elif p.kind=='table':
        cylo(p.name+'_top',w/2,0.03,(0,0,h-0.015),p.color,root); cylo(p.name+'_leg',0.03,h,(0,0,h/2),'#6B4A3A',root)
    elif p.kind=='chair':
        cube(p.name+'_seat',(w,d,0.05),(0,0,h-0.025),p.color,root); cube(p.name+'_back',(w,0.04,0.45),(0,d/2,h+0.25),p.color,root)
        for sx in(-1,1):
            for sy in(-1,1): cube(p.name+'_leg',(0.035,0.035,h-0.05),(sx*(w/2-0.03),sy*(d/2-0.03),(h-0.05)/2),'#4E3A2A',root)
    elif p.kind=='kbd': cube(p.name,(w,d,h),(0,0,h/2),p.color,root)
    elif p.kind=='plant':
        cylo(p.name+'_pot',0.08,0.12,(0,0,0.06),'#D9765F',root)
        bpy.ops.mesh.primitive_ico_sphere_add(radius=0.11,location=(0,0,0.22)); o=bpy.context.object; o.parent=root; o.data.materials.append(pmat('leaf','#6F8A5A'))
    elif p.kind=='can':
        cylo(p.name+'_body',0.07,0.16,(0.06,0,0.08),p.color,root)
        cylo(p.name+'_spout',0.012,0.22,(0.17,-0.0,0.14),p.color,root,rot=(0,math.radians(55),0))
        bpy.ops.mesh.primitive_torus_add(major_radius=0.05,minor_radius=0.01,location=(0.0,0,0.15),rotation=(math.radians(90),0,0)); o=bpy.context.object; o.parent=root; o.data.materials.append(pmat(p.name,p.color))
    elif p.kind=='mug':
        cylo(p.name,0.042,0.10,(0,0,0.05),p.color,root)
    elif p.kind=='lamp':
        cylo(p.name+'_base',0.07,0.02,(0,0,0.01),'#3E3A4F',root); cylo(p.name+'_pole',0.01,0.32,(0.04,0.04,0.17),'#3E3A4F',root)
        cylo(p.name+'_shade',0.09,0.12,(0.04,0.04,0.36),p.color,root); cylo(p.name+'_btn',0.012,0.012,(0,0,0.026),'#D9765F',root)
    elif p.kind=='shelf':
        for zz in (0.4,0.8,1.2,1.42,1.9): cube(p.name+'_s',(w,d,0.025),(0,0,zz*h/1.9),p.color,root)
        for sx in(-1,1): cube(p.name+'_side',(0.025,d,h),(sx*w/2,0,h/2),p.color,root)
        for i in range(8): cube(p.name+f'_bk{i}',(0.035,0.2,0.22),(-0.42+i*0.04+(0.3 if i>3 else 0),0,1.42*h/1.9+0.13),['#7FA3B8','#E6B655','#8C9F72','#C9714F'][i%4],root)
    elif p.kind=='book': cube(p.name,(w,d,h),(0,0,0),p.color,root)
    return root

def hand_mat(H,D,rig,s):
    b='HandAttach_'+s; m=(D[b]@rig.B[b]['R']).to_4x4(); m.translation=H[b]; return m
def both_mat(H,D):
    a=H['HandAttach_L']; b=H['HandAttach_R']; x=(a-b).normalized(); z=V((0,0,1)); z=(z-x*x.dot(z)).normalized(); y=z.cross(x)
    m=M.Identity(4)
    for i in range(3): m[i][0]=x[i]; m[i][1]=y[i]; m[i][2]=z[i]
    m.translation=(a+b)/2; return m
def prop_track(p,frames,rig):
    out=[]; cur=p.m0.copy(); mode='world'; off=None
    sched=dict(p.sched)
    for f,(D,H) in enumerate(frames):
        if f in sched and sched[f]!=mode:
            new=sched[f]
            if new=='world': cur=out[-1] if out else cur
            else:
                hm=hand_mat(H,D,rig,new) if new in 'LR' else both_mat(H,D)
                off=hm.inverted()@(out[-1] if out else cur)
            mode=new
        if mode=='world': mw=cur if not (p.anim and p.kind not in ('openbox','lamp')) else p.anim(f)
        else:
            hm=hand_mat(H,D,rig,mode) if mode in 'LR' else both_mat(H,D); mw=hm@off
        out.append(mw.copy())
    return out

def setup_wb(res):
    sc=bpy.context.scene; sc.render.engine='BLENDER_WORKBENCH'; sc.render.resolution_x,sc.render.resolution_y=res; sc.render.resolution_percentage=100
    sh=sc.display.shading; sh.light='STUDIO'; sh.color_type='MATERIAL'; sh.show_cavity=True; sh.cavity_type='BOTH'; sh.show_shadows=True; sh.shadow_intensity=0.4
    sc.display.shadow_shift=0.1; sh.show_object_outline=False
    sc.view_settings.view_transform='Standard'; sc.render.film_transparent=False
    sc.world=sc.world or bpy.data.worlds.new('W')
    for m in bpy.data.materials:
        if m.use_nodes and 'Principled BSDF' in m.node_tree.nodes and not m.name.startswith('P_'):
            b=m.node_tree.nodes['Principled BSDF']; col=b.inputs['Base Color'].default_value
            if m.name=='M_Face': col=hexc('#ECBEA0')
            if m.name=='M_Hair': col=hexc('#4E3224')
            m.diffuse_color=col
    if 'Floor' not in bpy.data.objects:
        bpy.ops.mesh.primitive_plane_add(size=12); f=bpy.context.object; f.name='Floor'; f.data.materials.append(pmat('floor','#E9E1D3'))
        # grid lines for slide reading
        for i in range(-10,11):
            cube('grid',(0.004,6,0.001),(i*0.1,0,0.0005),'#CFC4B2')
def cam(name,az,el=8,target=(0,-0.1,0.88),scale=2.1):
    c=bpy.data.objects.get(name)
    if not c:
        cd=bpy.data.cameras.new(name); c=bpy.data.objects.new(name,cd); bpy.context.scene.collection.objects.link(c)
    c.data.type='ORTHO'; c.data.ortho_scale=scale; c.data.clip_end=50
    a=math.radians(az); e=math.radians(el)
    c.location=V(target)+V((math.sin(a)*math.cos(e),-math.cos(a)*math.cos(e),math.sin(e)))*8
    c.rotation_euler=(V(target)-c.location).to_track_quat('-Z','Y').to_euler(); return c
VIEWDEF={'q':(-35,8),'side':(-90,3),'front':(0,5),'back':(180,5),'qL':(35,8)}
def render_all(arm,rig,results,outdir,views,log,res=(420,560),strip_n=8):
    os.makedirs(outdir,exist_ok=True); setup_wb(res); sc=bpy.context.scene
    ad=arm.animation_data
    for tr in ad.nla_tracks: tr.mute=True
    tmp='/tmp/prev_frames'; os.makedirs(tmp,exist_ok=True)
    for r in results:
        c=r['clip']; ad.action=r['act']
        roots=[]; tracks=[]
        for p in c.props:
            root=build_prop(p); roots.append(root); tracks.append((root,p,prop_track(p,r['frames'],rig)))
        n=len(r['frames']); sc.frame_start=0; sc.frame_end=n-1
        files={}
        for v in views:
            cm=cam('PC_'+v,*VIEWDEF[v]); sc.camera=cm
            for f in range(n):
                sc.frame_set(f)
                for root,p,tr in tracks:
                    root.matrix_world=tr[f]
                    if p.kind=='openbox':
                        a,b2=p.anim(f)
                        for i,ang in enumerate([a,a,b2,b2]):
                            h=bpy.data.objects[f'{p.name}_h{i}']
                            sgn=[-1,1,1,-1][i]; h.rotation_euler=((sgn*math.radians(200*ang),0,0) if i<2 else (0,sgn*math.radians(200*ang),0))
                sc.render.filepath=f'{tmp}/{c.name}_{v}_{f:04d}.png'; bpy.ops.render.render(write_still=True)
        # mp4 (views side by side) + strip
        ins=[]; 
        for v in views: ins+=['-framerate','30','-i',f'{tmp}/{c.name}_{v}_%04d.png']
        fc=f'hstack=inputs={len(views)}' if len(views)>1 else 'null'
        subprocess.run(['ffmpeg','-y','-loglevel','error']+ins+['-filter_complex',fc+',format=yuv420p','-c:v','libx264','-crf','20',f'{outdir}/{c.name}.mp4'])
        idx=[round(i*(n-1)/(strip_n-1)) for i in range(strip_n)]
        subprocess.run(['python3','-c',f'''
from PIL import Image, ImageDraw
v={views!r}[0]; idx={idx}
ims=[Image.open(f"{tmp}/{c.name}_"+v+f"_{{i:04d}}.png") for i in idx]
W,H=ims[0].size; o=Image.new("RGB",(W*len(ims),H+28),(250,247,240)); d=ImageDraw.Draw(o)
for j,(i,im) in enumerate(zip(idx,ims)): o.paste(im,(j*W,28)); d.text((j*W+8,8),"{c.name}  f"+str(i),fill=(60,50,40))
o.save("{outdir}/{c.name}_strip.png")'''])
        for root in roots:
            for ch in list(root.children_recursive)+[root]: bpy.data.objects.remove(ch,do_unlink=True)
        log('preview',c.name)
    ad.action=None
    for tr in ad.nla_tracks: tr.mute=False
