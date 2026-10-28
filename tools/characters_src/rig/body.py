"""Body / garment / head / hand / shoe builders parameterised by joints J and params P."""
from charlib import *
FEM=[(.78,.160,.085,.110),(.84,.172,.092,.118),(.90,.168,.090,.110),(.96,.150,.082,.095),(1.02,.135,.078,.085),
     (1.07,.130,.078,.084),(1.13,.138,.082,.087),(1.19,.148,.085,.090),(1.25,.155,.080,.092),(1.31,.162,.080,.090),
     (1.35,.165,.072,.082),(1.385,.120,.058,.066),(1.41,.058,.048,.050)]
MAL=[(.78,.155,.085,.100),(.84,.162,.090,.105),(.90,.160,.090,.100),(.96,.152,.088,.095),(1.02,.148,.088,.092),
     (1.07,.148,.090,.092),(1.13,.152,.092,.092),(1.19,.160,.095,.095),(1.25,.168,.098,.098),(1.31,.175,.095,.098),
     (1.35,.178,.085,.090),(1.385,.130,.062,.070),(1.41,.062,.052,.054)]
LAND_B=[0,.075,.87,.93,1.37,1.465,1.68]
def zmap(J,zb):
    L=[0,J['za'],J['zh'],J['zp'],J['zn'],J['zhd'],J['zt']]
    return float(np.interp(zb,LAND_B,L))
def torso_dims(J,P,zb):
    T=MAL if P.get('male') else FEM
    zs=[t[0] for t in T]
    hw,fr,bk=[float(np.interp(zb,zs,[t[k] for t in T])) for k in (1,2,3)]
    S=J['S']; g=P.get('girth',1.0)
    bust=P.get('bust',0.0); belly=P.get('belly',0.0); hipf=P.get('hips',1.0); shf=P.get('shoulder',1.0)
    fr+=bust*0.032*gauss(zb,1.235,0.05)
    fr+=belly*0.045*gauss(zb,1.07,0.09); hw+=belly*0.02*gauss(zb,1.05,0.10)
    if zb<1.0: hw*=1+(hipf-1)*smoothstep(1.0,0.86,zb)
    if zb>1.22: hw*=1+(shf-1)*smoothstep(1.22,1.33,zb)
    if zb>1.37: hw=hw  # neck region
    return hw*S*g,fr*S*g,bk*S*g
def torso_shell(J,P,zb0,zb1,thick,name,n=44,extra=None,step=0.02):
    zs=list(np.arange(zb0,zb1,step))+[zb1]
    secs=[]
    for zb in zs:
        hw,fr,bk=torso_dims(J,P,zb)
        e=extra(zb) if extra else 0.0
        t=thick+e
        if zb>1.38: t=thick*0.6+e
        secs.append((zmap(J,zb),0,0,hw+t,fr+t,bk+t))
    return loft_z(name,secs,n=n,e=2.3)
def arm_r(J,P): return .047*J['S']*P.get('armg',P.get('girth',1.0))*(1.1 if P.get('male') else 1.0)
def sleeve(J,P,sd,length,thick,name,cuff=0.0,flare=0.0):
    """length: 'long' (to wrist), 'three_q', 'elbow', 'short' (mid upper arm), 'cap'"""
    N=side_name(sd); sj,el=J[N+'UpperArm']; _,wr=J[N+'LowerArm']
    r=arm_r(J,P); S=J['S']
    inner=sj+V((-sd*.035*S,0,.005*S))
    if length=='long': end=wr+(wr-el).normalized()*.008*S; pts=[inner,sj,sj.lerp(el,.5),el,el.lerp(wr,.5),end]; rr=[r*1.05,r*1.12,r*.98,r*.86,r*.82+flare*.3,r*.74+flare]
    elif length=='three_q': end=el.lerp(wr,.6); pts=[inner,sj,sj.lerp(el,.5),el,end]; rr=[r*1.05,r*1.12,r*.98,r*.88,r*.86+flare]
    elif length=='elbow': end=el.lerp(wr,.08); pts=[inner,sj,sj.lerp(el,.5),end]; rr=[r*1.05,r*1.12,r*1.0,r*.95+flare]
    else: end=sj.lerp(el,.5 if length=='short' else .25); pts=[inner,sj,end]; rr=[r*1.05,r*1.14,r*1.08+flare]
    rr=[x+thick for x in rr]
    if cuff>0: rr[-1]+=cuff
    ob=tube(name,pts,rr,n=24,samples=28)
    ball=ellipsoid(name+'_d',sj+V((sd*.004*S,0,.002*S)),(r*1.15+thick,r*1.1+thick,r*1.08+thick),24,12)
    return [ob,ball],(pts[0],end)
def skin_arm(J,P,sd,start_f,name):
    """bare arm from fraction along upper arm (0=shoulder) to wrist"""
    N=side_name(sd); sj,el=J[N+'UpperArm']; _,wr=J[N+'LowerArm']; r=arm_r(J,P)
    st=sj.lerp(el,start_f) if start_f<1 else el.lerp(wr,start_f-1)
    pts=[st,el,el.lerp(wr,.4),wr]; rr=[r*(1.0 if start_f<1 else .85),r*.8,r*.78,r*.58]
    if start_f<1: pts=[sj.lerp(el,start_f),sj.lerp(el,(start_f+1)/2)]+pts[1:]; rr=[r*1.0,r*.92]+rr[1:]
    return tube(name,pts,rr,n=20,samples=24)
LEG_R=[.092,.084,.074,.064,.055,.046,.038,.034]  # thigh..ankle (bare leg radii, base)
def leg_axis(J,sd):
    N=side_name(sd); hj,kn=J[N+'UpperLeg']; _,an=J[N+'LowerLeg']; return hj,kn,an
def pants(J,P,sd,style,thick,name,hem_zb=0.035):
    hj,kn,an=leg_axis(J,sd); S=J['S']; g=P.get('legg',P.get('girth',1.0))
    top=hj+V((0,0,.03*S))
    hem=V((an.x+sd*.003*S, an.y-.005*S, zmap(J,hem_zb)))
    if style=='wide':   pts=[top,hj.lerp(kn,.5),kn,kn.lerp(hem,.5),hem]; rr=[.094,.082,.074,.078,.090]
    elif style=='slim': pts=[top,hj.lerp(kn,.5),kn,kn.lerp(hem,.5),hem]; rr=[.092,.078,.062,.054,.050]
    elif style=='straight': pts=[top,hj.lerp(kn,.5),kn,kn.lerp(hem,.5),hem]; rr=[.094,.082,.068,.064,.062]
    elif style=='jogger': hem=V((an.x,an.y,an.z+.02*S)); pts=[top,hj.lerp(kn,.5),kn,kn.lerp(hem,.6),hem]; rr=[.096,.084,.070,.060,.046]
    elif style=='shorts': end=hj.lerp(kn,.72); pts=[top,hj.lerp(kn,.4),end]; rr=[.096,.090,.086]
    elif style=='scrub': pts=[top,hj.lerp(kn,.5),kn,kn.lerp(hem,.5),hem]; rr=[.096,.086,.074,.068,.064]
    rr=[x*S*g+thick for x in rr]
    return tube(name,pts,rr,n=24,samples=30)
def skin_leg(J,P,sd,from_f,to_ankle=True,name='leg'):
    hj,kn,an=leg_axis(J,sd); S=J['S']; g=P.get('legg',P.get('girth',1.0))
    st=hj.lerp(kn,from_f) if from_f<1 else kn.lerp(an,from_f-1)
    pts=[st]
    if from_f<1: pts+= [kn]
    pts+=[kn.lerp(an,.35),kn.lerp(an,.7),an+V((0,0,-.01*S))]
    rr=[np.interp(from_f,[0,.5,1,1.5,2],[.092,.080,.058,.050,.034])]+([.058] if from_f<1 else [])+[.054,.045,.034]
    rr=[x*S*g for x in rr]
    return tube(name,pts,rr,n=20,samples=24)
def skirt(J,P,zb_top,zb_hem,flare,thick,name,front_open=False):
    S=J['S']; secs=[]
    for k,zb in enumerate(np.linspace(zb_top,zb_hem,10)):
        hw,fr,bk=torso_dims(J,P,max(zb,.80))
        f=1+flare*smoothstep(zb_top,zb_hem,zb)**0.8 if zb<.84 else 1
        fl=(zb<.84)*flare*((.84-zb)/(.84-zb_hem))
        secs.append((zmap(J,zb),0,0.004*S,hw*(1+fl*0.9)+thick,fr*(1+fl*1.1)+thick,bk*(1+fl*1.1)+thick))
    return loft_z(name,secs[::-1],n=48,e=2.2)
def shoe(J,P,sd,style,name):
    N=side_name(sd); an,ball=J[N+'Foot']; _,toe=J[N+'Toes']; S=J['S']*P.get('foot',1.0); x0=an.x
    y_an=an.y
    if style in('sneaker','chunky'):
        prof=[(.065,.030,.075),(.035,.037,.085),(0,.042,.085),(-.05,.047,.066),(-.10,.050,.052),(-.14,.046,.044),(-.172,.034,.036),(-.185,.014,.026)]
    elif style=='boot':
        prof=[(.06,.032,.15),(.03,.038,.16),(0,.042,.16),(-.05,.046,.075),(-.10,.048,.05),(-.14,.044,.04),(-.172,.032,.032),(-.18,.012,.022)]
    elif style=='sandal':
        prof=[(.06,.030,.03),(.03,.036,.035),(0,.04,.04),(-.05,.044,.04),(-.10,.046,.034),(-.14,.042,.028),(-.17,.030,.024),(-.178,.012,.02)]
    else: # loafer
        prof=[(.06,.030,.062),(.03,.036,.068),(0,.040,.07),(-.05,.044,.058),(-.10,.047,.044),(-.14,.042,.036),(-.168,.030,.026),(-.18,.012,.018)]
    if style=='chunky': prof=[(y,w*1.12,h*1.08) for y,w,h in prof]
    verts=[];faces=[];n=24
    for (y,w,h) in prof:
        for i in range(n):
            a=2*math.pi*i/n; c,s=math.cos(a),math.sin(a)
            x=w*math.copysign(abs(c)**(2/3.2),c)
            z=h*0.5+h*0.5*math.copysign(abs(s)**(2/2.6),s)
            verts.append((x0+x*S,y_an+y*S,z*S))
    R=len(prof)
    for r in range(R-1):
        for i in range(n): a=r*n+i;b=r*n+(i+1)%n;faces.append((a,b,b+n,a+n))
    faces.append(tuple(range(n))[::-1]); faces.append(tuple(range((R-1)*n,R*n)))
    ob=mesh_from(name,verts,faces)
    return ob
def sole(J,P,sd,style,name):
    N=side_name(sd); an,_=J[N+'Foot']; S=J['S']*P.get('foot',1.0)
    h={'chunky':.028,'sneaker':.02,'boot':.018,'sandal':.016}.get(style,.012)
    ob=rbox(name,(an.x,an.y-.058*S,h*S/2),(.098*S,.25*S,h*S),bevel=.005*S)
    return ob

# ---------------------------------------------------------------- head
def head_geom(J,P):
    S=J['S']; Lh=J['L']['head']; sh=Lh/.215
    chin=J['zhd']-.008*sh; crown=J['zt']-.006*sh
    hz=(crown-chin)/2; zc=(crown+chin)/2
    hx=.074*sh*P.get('headw',1.0); hy=.095*sh
    return dict(zc=zc,hx=hx,hy=hy,hz=hz,yc=-.008*sh,sh=sh,eye=zc-.002*sh)
def head_neck(J,P,name='HeadSkin'):
    G=head_geom(J,P); S=J['S']; sh=G['sh']
    hd=ellipsoid('hd',(0,G['yc'],G['zc']),(G['hx'],G['hy'],G['hz']),64,32)
    for v in hd.data.vertices:
        x,y,z=v.co.x,v.co.y-G['yc'],v.co.z-G['zc']
        t=max(0,-z/G['hz'])
        jaw=P.get('jaw',1.0)
        x*=1-0.30*(t**1.6)*(2-jaw)
        if y>0: y*=1-0.50*t**1.4; y*=1.03
        else:
            y+=-0.004*sh*t*t
            if z>0: y*=1-0.07*(z/G['hz'])
        v.co=V((x,y+G['yc'],z+G['zc']))
    nr=.044*S*P.get('neckg',1.0)
    nk=tube('nk',[V((0,.014*S,J['zn']-.05*S)),V((0,.012*S,J['zn'])),V((0,.006*S,J['zhd']+.03*sh))],[nr*1.08,nr,nr*.96],n=24,samples=12)
    ears=[]
    for sd in(1,-1):
        e=ellipsoid('ear',(sd*G['hx']*0.94,G['yc']+.012*sh,G['eye']-.012*sh),(.011*sh,.019*sh,.029*sh),20,12,
                    rot=Euler((0,0,sd*math.radians(-18))).to_matrix())
        ears.append(e)
    nose=ellipsoid('nose',(0,G['yc']-G['hy']*0.93,G['eye']-.032*sh),(.0095*sh,.013*sh,.019*sh),20,12,rot=Euler((math.radians(-12),0,0)).to_matrix())
    ob=join([hd,nk,nose]+ears,name)
    remesh(ob,.0032*sh,smooth=6,smooth_f=0.5)
    return ob,G
def assign_face(ob,G,mface_idx=1,cell_w=1/7):
    """faces on the front of the face get material idx 1 and atlas UVs"""
    me=ob.data
    if not me.uv_layers: me.uv_layers.new(name='UVMap')
    uv=me.uv_layers.active.data
    sh=G['sh']
    for p in me.polygons:
        c=p.center; rel=V((c.x/sh,0,(c.z-G['eye'])/sh))
        inside=(rel.x/.068)**2+((rel.z+.006)/.112)**2<1 and p.normal.y<-0.15 and c.y<G['yc']
        if inside: p.material_index=mface_idx
        for li in p.loop_indices:
            co=me.vertices[me.loops[li].vertex_index].co
            u=0.5+(co.x/sh)/0.15; v=((co.z-G['eye'])/sh+0.115)/0.22
            uv[li].uv=((min(max(u,0.002),0.998))*cell_w, min(max(v,0.002),0.998))

# ---------------------------------------------------------------- hands
def hand(J,P,sd,name):
    N=side_name(sd); wr,mcp=J[N+'Hand']; f,n,w=J[N+'_handframe']; hs=J['hs']; g=P.get('handg',1.0)
    R=M((w,f,n)).transposed()  # columns
    palm=ellipsoid('palm',wr+f*.048*hs+n*(-.001*hs),(.040*hs*g,.050*hs,.015*hs*g),32,16,rot=R)
    # squarer palm: union with rounded box
    pb=rbox('pb',wr+f*.050*hs,(.074*hs*g,.07*hs,.024*hs*g),rot=R,bevel=.010*hs)
    wrist=tube('wr',[wr-f*.06*hs,wr+f*.015*hs],[.027*hs*g,.026*hs*g],n=20,samples=6,flat=.72,up=w)
    parts=[palm,pb,wrist]
    rad={'Index':[.0088,.0080,.0072],'Middle':[.0090,.0082,.0074],'Ring':[.0084,.0077,.0069],'Little':[.0074,.0068,.0062],'Thumb':[.0125,.0105,.0092]}
    for fn in FINGERS:
        segs=fseg(fn); pts=[J[f"{N}{fn}{segs[0]}"][0]]+[J[f"{N}{fn}{sg}"][1] for sg in segs]
        r=[x*hs*g for x in rad[fn]]
        rr=[r[0],r[0],r[1],r[2]*0.92]
        if fn=='Thumb': rr=[r[0]*1.25,r[0],r[1],r[2]*0.9]
        # pull tip back by a radius so it rounds off at bone tip
        tip=pts[-1]-(pts[-1]-pts[-2]).normalized()*r[2]*0.6
        pts=pts[:-1]+[tip]
        parts.append(tube('f'+fn,pts,rr,n=14,samples=16,flat=0.88,up=n))
        for p,rad_ in zip(pts,rr): parts.append(ellipsoid('k',p,(rad_,rad_,rad_),12,8))
    ob=join(parts,name)
    remesh(ob,.0016*hs,smooth=3,smooth_f=0.5)
    return ob

# ---------------------------------------------------------------- simple solids
def torus(name,c,R,r,rot=None,seg=24,rs=8):
    bm=bmesh.new()
    verts=[]
    for i in range(seg):
        a=2*math.pi*i/seg
        for j in range(rs):
            b=2*math.pi*j/rs
            p=V(((R+r*math.cos(b))*math.cos(a),(R+r*math.cos(b))*math.sin(a),r*math.sin(b)))
            if rot: p=rot@p
            verts.append(bm.verts.new(p+V(c)))
    for i in range(seg):
        for j in range(rs):
            a=verts[i*rs+j];b=verts[((i+1)%seg)*rs+j];c2=verts[((i+1)%seg)*rs+(j+1)%rs];d=verts[i*rs+(j+1)%rs]
            bm.faces.new((a,b,c2,d))
    me=bpy.data.meshes.new(name); bm.to_mesh(me); bm.free(); ob=link(bpy.data.objects.new(name,me)); shade_smooth(ob); return ob
def surface_patch(name,target,grid_fn,nu,nv,offset,thick,from_dir=V((0,0,1))):
    """grid_fn(u,v)->(x,y,z guess); raycast guess onto target along -from_dir, offset along normal; solidify"""
    bvh=BVHTree.FromObject(target,bpy.context.evaluated_depsgraph_get())
    verts=[];faces=[]
    for i in range(nu):
        for j in range(nv):
            p=V(grid_fn(i/(nu-1),j/(nv-1)))
            hit=bvh.ray_cast(p+from_dir*0.15,-from_dir,0.4)
            if hit[0] is None: hit=bvh.find_nearest(p)
            loc,nrm=hit[0],hit[1]
            verts.append(loc+nrm*offset)
    for i in range(nu-1):
        for j in range(nv-1): a=i*nv+j; faces.append((a,a+nv,a+nv+1,a+1))
    ob=mesh_from(name,verts,faces)
    apply_mod(ob,'SOLIDIFY',thickness=thick,offset=1.0)
    apply_mod(ob,'SUBSURF',levels=1)
    shade_smooth(ob); return ob
