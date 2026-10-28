"""Hair builders: wavy long clumps (Dana), plus scalp cap. Clumps carry a 'clump' int attr + group for weights."""
from charlib import *
from body import head_geom
def sdir(th,ph,sd):
    th=math.radians(th);ph=math.radians(ph)
    return V((sd*math.sin(th)*math.cos(ph),-math.cos(th)*math.cos(ph),math.sin(ph)))
def scalp_pt(G,d,off):
    return V((d.x*(G['hx']+off),G['yc']+d.y*(G['hy']+off),G['zc']+d.z*(G['hz']+off)))
def frame_tube(verts,faces,uvs,C,A,Bv,wa,wb,n=8,u0=0.0,vscale=0.25):
    base=len(verts); S=len(C)
    L=[0.0]
    for k in range(1,S): L.append(L[-1]+(C[k]-C[k-1]).length)
    for k in range(S):
        for i in range(n):
            a=2*math.pi*i/n; c,s=math.cos(a),math.sin(a)
            # lens section: sharper at the width edges
            verts.append(C[k]+A[k]*c*wa[k]+Bv[k]*s*wb[k]*(0.35+0.65*abs(s)**0.5))
    for k in range(S-1):
        for i in range(n):
            a=base+k*n+i;b=base+k*n+(i+1)%n;faces.append((a,b,b+n,a+n))
            uvs.append([(u0+i/n*0.3,L[k]/vscale),(u0+(i+1)/n*0.3,L[k]/vscale),(u0+(i+1)/n*0.3,L[k+1]/vscale),(u0+i/n*0.3,L[k+1]/vscale)])
    # tip cap + root cap
    faces.append(tuple(base+(S-1)*n+i for i in range(n))); uvs.append([(u0,L[-1]/vscale)]*n)
    faces.append(tuple(base+i for i in range(n))[::-1]); uvs.append([(u0,0)]*n)
def push_out(p,bvh,margin):
    loc,nrm,idx,d=bvh.find_nearest(p)
    if loc is None: return p
    rel=p-loc
    if rel.dot(nrm)<margin: return loc+nrm*margin
    return p
def wavy_long(J,P,body_objs,name='Hair',seed=7):
    """returns hair object; vertex attribute 'hgrp' (0 head/scalp,1 front,2 back) via custom data"""
    rnd=random.Random(seed); G=head_geom(J,P); S=J['S']; sh=G['sh']
    dg=bpy.context.evaluated_depsgraph_get()
    bms=[]
    for o in body_objs:
        bm=bmesh.new(); bm.from_object(o,dg); bm.transform(o.matrix_world); bms.append(bm)
    bm=bmesh.new()
    for b in bms:
        tmp=bpy.data.meshes.new('t'); b.to_mesh(tmp); bm.from_mesh(tmp); bpy.data.meshes.remove(tmp)
    bvh=BVHTree.FromBMesh(bm)
    verts=[];faces=[];uvs=[];grp=[];clumpid=[]
    zend_back=zmap_local=P.get('hair_end',1.19)
    zn=J['zn']
    def zb(z): return z  # already world
    clumps=[]
    for sd in(1,-1):
        for layer,(N,off0,wmul) in enumerate([(13,.012,1.35),(20,.007,1.0)]):
            for k in range(N):
                p=(k+rnd.uniform(-.3,.3))/(N-1); p=min(max(p,0),1)
                clumps.append((sd,layer,p,off0,wmul))
    for ci,(sd,layer,p,off0,wmul) in enumerate(clumps):
        beta=32+p*135
        root=V((sd*0.004,-math.cos(math.radians(beta)),math.sin(math.radians(beta)))).normalized()
        front=p<0.22 and layer==1 and rnd.random()<0.85
        th_e=62+p*118+rnd.uniform(-4,4); ph_e=-4-28*p**1.3+rnd.uniform(-3,3)
        if front: th_e=58+p*60; ph_e=-12
        ex=sdir(th_e,ph_e,sd)
        # scalp arc
        C=[]
        for t in np.linspace(0,1,9):
            d=root.slerp(ex,t) if hasattr(root,'slerp') else (root*(1-t)+ex*t).normalized()
            d=(root*(1-t)+ex*t).normalized()
            C.append(scalp_pt(G,d,.003*sh+off0*sh*smoothstep(0,0.6,t)))
        pe=C[-1]
        zE=pe.z
        if front:
            zf=zn-.06*S-rnd.uniform(0,.08)*S
            fx=sd*(.115+.03*rnd.random())*S
            ctrl=[pe+V((sd*.014*S,.0*S,-.04*S)),V((fx*0.95,-.035*S,J['zhd']-.02*S)),V((fx*1.05,-.045*S,zn)),V((fx*1.08,-.07*S,zf))]
        else:
            q=min(1,(th_e-60)/120)
            xf=sd*math.sin(math.radians(min(th_e,178)))*(.165*S)*(1.0 if layer==0 else 0.9)+sd*.01*S
            yb=(.105+.012*(1-abs(xf)/(.17*S)))*S+(.012*S if layer==0 else 0)
            zf=zend_back+(.06*S)*(abs(xf)/(.17*S))**1.5+rnd.uniform(-.025,.025)*S
            ctrl=[pe+V((sd*.006*S,.01*S,-.03*S)),V((xf*0.75,(.06+.04*q)*S,J['zhd']-.01*S)),V((xf*0.92,yb*0.92,zn+.0*S)),V((xf,yb,(zn+zf)/2)),V((xf*1.02,yb*0.98,zf))]
        path=C[:-1]+catmull([pe]+ctrl,36)
        # resample + collide
        pts=[V(x) for x in path]
        for it in range(8):
            pts=[push_out(x,bvh,.007*S if i<9 else .013*S) for i,x in enumerate(pts)]
            pts=[pts[0]]+[(pts[i-1]+pts[i]*2+pts[i+1])/4 for i in range(1,len(pts)-1)]+[pts[-1]]
        pts=[push_out(x,bvh,.006*S if i<9 else .011*S) for i,x in enumerate(pts)]
        # waves on the hanging part
        L=[0.0]
        for i in range(1,len(pts)): L.append(L[-1]+(pts[i]-pts[i-1]).length)
        sE=L[8]; Ltot=L[-1]; ph=th_e*0.045+rnd.uniform(-.5,.5); lam=.085*S
        C2=[];Aa=[];Bb=[];wa=[];wb=[]; rw=rnd.uniform(.88,1.08)
        prevlat=None
        HC=V((0,G['yc'],G['zc']))
        for i,x in enumerate(pts):
            t=(pts[min(i+1,len(pts)-1)]-pts[max(i-1,0)]).normalized()
            o1=x-HC; o2=V((x.x,x.y-.01*S,0))
            bl=smoothstep(G['zc'],G['zc']-.08*S,x.z)
            out=o1*(1-bl)+o2.normalized()*o1.length*bl
            out=(out-t*out.dot(t))
            if out.length<1e-6: out=V((0,1,0))
            out.normalize(); lat=t.cross(out).normalized()
            if prevlat is not None and lat.dot(prevlat)<0: lat=-lat
            prevlat=lat
            s=L[i]-sE
            amp=(.016*S*smoothstep(0,.14,s) if s>0 else 0)*P.get('wave',1.0)
            xx=x+lat*math.sin(2*math.pi*s/lam+ph)*amp*0.75+out*math.cos(2*math.pi*s/lam+ph)*amp*0.45 if s>0 else x
            if s>0: xx=push_out(xx,bvh,.008*S)
            C2.append(xx); Aa.append(lat); Bb.append(out)
            u=L[i]/Ltot
            width=(.017+.016*smoothstep(0,.35,u))*S*wmul*(1-0.85*smoothstep(.78,1,u))*rw
            thick=(.0065+.004*smoothstep(0,.3,u))*S*(1-0.7*smoothstep(.8,1,u))
            wa.append(width); wb.append(thick)
        C2=[C2[0]]+[(C2[i-1]+C2[i]*2+C2[i+1])/4 for i in range(1,len(C2)-1)]+[C2[-1]]
        nb=len(verts)
        frame_tube(verts,faces,uvs,C2,Aa,Bb,wa,wb,n=6,u0=rnd.random())
        g=1 if front else 2
        for _ in range(len(verts)-nb): grp.append(g); clumpid.append(ci)
    ob=mesh_from(name,verts,faces)
    me=ob.data; uvl=me.uv_layers.new(name='UVMap')
    li=0
    for poly,uvp in zip(me.polygons,uvs):
        for j,l in enumerate(poly.loop_indices): uvl.data[l].uv=uvp[j%len(uvp)]
    a=me.attributes.new('hgrp','INT','POINT'); a.data.foreach_set('value',grp)
    a=me.attributes.new('clump','INT','POINT'); a.data.foreach_set('value',clumpid)
    shade_smooth(ob)
    for b in bms: b.free()
    bm.free()
    cap=scalp_cap(J,P,G)
    return ob,cap
def scalp_cap(J,P,G,name='HairCap',hairline=None):
    sh=G['sh']
    bm=bmesh.new(); bmesh.ops.create_uvsphere(bm,u_segments=64,v_segments=32,radius=1.0)
    kill=[]
    for v in bm.verts:
        d=v.co.normalized(); th=math.degrees(math.atan2(abs(d.x),-d.y)); ph=math.degrees(math.asin(max(-1,min(1,d.z))))
        lim=np.interp(th,[0,40,70,95,120,180],[34,28,14,8,-18,-32]) if hairline is None else hairline(th)
        if ph<lim: kill.append(v)
    bmesh.ops.delete(bm,geom=kill,context='VERTS')
    uvl=bm.loops.layers.uv.new('UVMap')
    for f in bm.faces:
        for l in f.loops:
            d=l.vert.co.normalized()
            l[uvl].uv=(math.atan2(-d.y,abs(d.z)+1e-3)*0.6, math.atan2(d.x,d.z)*0.5)
    for v in bm.verts:
        d=v.co.normalized(); v.co=scalp_pt(G,d,.0045*sh)
    me=bpy.data.meshes.new(name); bm.to_mesh(me); bm.free(); ob=link(bpy.data.objects.new(name,me))
    apply_mod(ob,'SOLIDIFY',thickness=.004*sh,offset=-1)
    shade_smooth(ob); return ob
def hair_bones(J,P,style='long'):
    G=head_geom(J,P); S=J['S']; zn=J['zn']; ze=P.get('hair_end',1.19)
    E={}
    for sd in(1,-1):
        c='L' if sd>0 else 'R'
        p0=V((sd*.05*S,.075*S,G['zc']-.05*sh_(G))); p1=V((sd*.085*S,.11*S,zn+.01*S)); p2=V((sd*.09*S,.12*S,(zn+ze)/2+.02*S)); p3=V((sd*.09*S,.12*S,ze))
        E[f'HairBack{c}1']=(p0,p1,'Head'); E[f'HairBack{c}2']=(p1,p2,f'HairBack{c}1'); E[f'HairBack{c}3']=(p2,p3,f'HairBack{c}2')
        f0=V((sd*.08*S,-.02*S,G['zc']-.04*sh_(G))); f1=V((sd*.115*S,-.065*S,zn)); f2=V((sd*.12*S,-.09*S,zn-.12*S))
        E[f'HairFront{c}1']=(f0,f1,'Head'); E[f'HairFront{c}2']=(f1,f2,f'HairFront{c}1')
    return E
def sh_(G): return G['sh']
def hair_weights(ob,J,P,E):
    me=ob.data; g=me.attributes['hgrp'].data if 'hgrp' in me.attributes else None
    G=head_geom(J,P)
    def chainw(co,names):
        # weights by z along chain
        segs=[(E[n][0],E[n][1],n) for n in names]
        z=co.z; w={}
        top=segs[0][0].z
        if z>=top: return {'Head':1.0}
        hb=smoothstep(top-.05,top,z)
        rest=1-hb
        if hb>0: w['Head']=hb
        # find segment position
        zs=[segs[0][0].z]+[s[1].z for s in segs]
        t=np.interp(-z,[-x for x in zs],list(range(len(zs))))
        i=min(int(t),len(segs)-1); fr=t-i
        if fr>0.5 and i+1<len(segs): w[segs[i][2]]=rest*(1.5-fr); w[segs[i+1][2]]=rest*(fr-0.5)
        elif fr<0.5 and i>0: w[segs[i][2]]=rest*(0.5+fr); w[segs[i-1][2]]=rest*(0.5-fr)
        else: w[segs[i][2]]=rest
        return w
    def fn_factory():
        vals=[d.value for d in g] if g else None
        idx=[0]
        def fn(co):
            i=idx[0]; idx[0]+=1
            gr=vals[i] if vals else 0
            if gr==1:
                return chainw(co,['HairFrontL1','HairFrontL2'] if co.x>0 else ['HairFrontR1','HairFrontR2'])
            if gr==2:
                wl=smoothstep(-.03,.03,co.x)
                a=chainw(co,['HairBackL1','HairBackL2','HairBackL3']); b=chainw(co,['HairBackR1','HairBackR2','HairBackR3'])
                out={}
                for k,v in a.items(): out[k]=out.get(k,0)+v*wl
                for k,v in b.items(): out[k]=out.get(k,0)+v*(1-wl)
                return out
            return {'Head':1.0}
        return fn
    return fn_factory()
