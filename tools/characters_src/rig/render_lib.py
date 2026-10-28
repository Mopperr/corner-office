import bpy, math
from mathutils import Vector as V
def setup_scene(res=(900,1200),engine='BLENDER_EEVEE_NEXT',bg=(0.93,0.89,0.82)):
    sc=bpy.context.scene; sc.render.engine=engine
    sc.render.resolution_x,sc.render.resolution_y=res; sc.render.resolution_percentage=100
    sc.render.film_transparent=False
    w=bpy.data.worlds.new('W') if not bpy.data.worlds else bpy.data.worlds[0]; sc.world=w; w.use_nodes=True
    w.node_tree.nodes['Background'].inputs[0].default_value=(*bg,1); w.node_tree.nodes['Background'].inputs[1].default_value=0.9
    if engine=='BLENDER_EEVEE_NEXT':
        e=sc.eevee; e.taa_render_samples=32
        try: e.use_shadows=True; e.use_raytracing=True
        except: pass
    sc.view_settings.view_transform='Standard'; sc.view_settings.exposure=-0.9
    for n,(loc,en,sz) in {'Key':((2.5,-3.5,3.8),600,2.5),'Fill':((-3.5,-2.5,2.2),220,4),'Rim':((0.5,4,3),380,2)}.items():
        if n in bpy.data.objects: continue
        l=bpy.data.lights.new(n,'AREA'); l.energy=en; l.size=sz
        o=bpy.data.objects.new(n,l); bpy.context.scene.collection.objects.link(o); o.location=loc
        d=V((0,0,1.0))-V(loc); o.rotation_euler=d.to_track_quat('-Z','Y').to_euler()
    if 'Floor' not in bpy.data.objects:
        bpy.ops.mesh.primitive_plane_add(size=30); f=bpy.context.object; f.name='Floor'
        m=bpy.data.materials.new('floor'); m.use_nodes=True; m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(*bg,1)
        m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=0.9; f.data.materials.append(m)
def camera(name,target,dist,az,el,lens=50,ortho=None):
    c=bpy.data.objects.get(name)
    if not c:
        cd=bpy.data.cameras.new(name); c=bpy.data.objects.new(name,cd); bpy.context.scene.collection.objects.link(c)
    c.data.lens=lens
    if ortho: c.data.type='ORTHO'; c.data.ortho_scale=ortho
    a=math.radians(az); e=math.radians(el)
    c.location=V(target)+V((math.sin(a)*math.cos(e),-math.cos(a)*math.cos(e),math.sin(e)))*dist
    c.rotation_euler=(V(target)-c.location).to_track_quat('-Z','Y').to_euler()
    bpy.context.scene.camera=c; return c
