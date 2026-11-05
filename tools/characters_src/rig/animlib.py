"""Corner Office character animation solver (pure python FK/IK, Blender mathutils).
Blender space: Z up, character faces -Y, her left = +X."""
import bpy, math
from mathutils import Vector as V, Matrix as M, Quaternion as Q
FPS=30
def rad(d): return math.radians(d)
def Rx(d): return M.Rotation(rad(d),3,'X')
def Ry(d): return M.Rotation(rad(d),3,'Y')
def Rz(d): return M.Rotation(rad(d),3,'Z')
def eul(p): return Rz(p[2])@Ry(p[1])@Rx(p[0])   # (pitch fwd+, side(+ = lean to her left), yaw(+ = turn to her left))
def frame(a,b):
    a=a.normalized(); b=(b-a*a.dot(b)).normalized(); c=a.cross(b)
    m=M.Identity(3); m.col[0]=a; m.col[1]=b; m.col[2]=c; return m
def rot_between(a,b):
    a=a.normalized(); b=b.normalized(); return a.rotation_difference(b).to_matrix()
def side_name(sd): return 'Left' if sd>0 else 'Right'
def lerp(a,b,t): return a+(b-a)*t
def sstep(a,b,x):
    if a==b: return 1.0 if x>=b else 0.0
    t=min(max((x-a)/(b-a),0),1); return t*t*(3-2*t)
def tup(v): return tuple(v) if hasattr(v,'__len__') else (v,)

# ------------------------------------------------------------------ tracks
class Track:
    """auto-clamped Hermite over keys [(frame, tuple)]"""
    def __init__(s,keys,length=None,cyclic=False):
        s.cyc=cyclic; s.N=length; d={}
        for t,v in keys: d[(t%length) if cyclic else t]=v
        s.k=sorted(d.items(),key=lambda x:x[0])
    def ev(s,f):
        k=s.k
        if len(k)==1: return k[0][1]
        if s.cyc:
            f=f%s.N
            ext=[(t-s.N,v) for t,v in k[-2:]]+k+[(t+s.N,v) for t,v in k[:2]]
        else: ext=k
        if f<=ext[0][0]: return ext[0][1]
        if f>=ext[-1][0]: return ext[-1][1]
        i=max(j for j in range(len(ext)-1) if ext[j][0]<=f)
        t0,v0=ext[i]; t1,v1=ext[i+1]; h=t1-t0; u=(f-t0)/h
        def tan(j):
            if j<=0 or j>=len(ext)-1: return [0.0]*len(v0)
            tp,vp=ext[j-1]; tn,vn=ext[j+1]; tc,vc=ext[j]; out=[]
            for c in range(len(vc)):
                d0=(vc[c]-vp[c])/(tc-tp); d1=(vn[c]-vc[c])/(tn-tc)
                if d0*d1<=0: out.append(0.0); continue
                m=(vn[c]-vp[c])/(tn-tp)
                m=math.copysign(min(abs(m),3*abs(d0),3*abs(d1)),m); out.append(m)
            return out
        m0=tan(i); m1=tan(i+1)
        h00=2*u**3-3*u**2+1; h10=u**3-2*u**2+u; h01=-2*u**3+3*u**2; h11=u**3-u**2
        return tuple(h00*v0[c]+h10*h*m0[c]+h01*v1[c]+h11*h*m1[c] for c in range(len(v0)))

# ------------------------------------------------------------------ rig
class Rig:
    def __init__(s,arm_ob):
        s.ob=arm_ob; s.B={}
        for b in arm_ob.data.bones:
            s.B[b.name]=dict(R=b.matrix_local.to_3x3().normalized(),h=b.head_local.copy(),t=b.tail_local.copy(),
                             p=b.parent.name if b.parent else None,L=b.length,ML=b.matrix_local.copy())
        s.order=[b.name for b in arm_ob.data.bones]  # parents precede children
        B=s.B
        s.LU=B['LeftUpperArm']['L']; s.LF=B['LeftLowerArm']['L']
        s.LT=B['LeftUpperLeg']['L']; s.LS=B['LeftLowerLeg']['L']
        s.hand_rest={}; s.leg_rest={}; s.arm_rest={}
        for sd in(1,-1):
            N=side_name(sd)
            f=(B[N+'Hand']['t']-B[N+'Hand']['h']).normalized()
            n=V((-sd*.707,0,-.707)); n=(n-f*f.dot(n)).normalized()
            Fr=frame(f,n); off=Fr.transposed()@(B['HandAttach_'+N[0]]['h']-B[N+'Hand']['h'])
            s.hand_rest[sd]=dict(f=f,n=n,F=Fr,off=off,axis=f.cross(n).normalized())
            # thumb axis
            tb=B[N+'ThumbMetacarpal']; td=(B[N+'ThumbDistal']['t']-tb['h']).normalized()
            s.hand_rest[sd]['taxis']=td.cross(n).normalized(); s.hand_rest[sd]['tdir']=td
            hj=B[N+'UpperLeg']['h']; kn=B[N+'LowerLeg']['h']; an=B[N+'Foot']['h']
            s.leg_rest[sd]=s._ikframes(hj,kn,an)
            sj=B[N+'UpperArm']['h']; el=B[N+'LowerArm']['h']; wr=B[N+'Hand']['h']
            s.arm_rest[sd]=s._ikframes(sj,el,wr)
            mid=(sj+wr)/2; s.arm_rest[sd]['pole']=(el-mid).normalized()
            s.arm_rest[sd]['twist0']=s._twistang(s.arm_rest[sd]['Fl'],n)
            G0=V((an.x,an.y,0)); s.leg_rest[sd].update(G0=G0,A=an-G0,ball=B[N+'Toes']['h']-G0,
                 heel=V((an.x-G0.x,.05*1.0-G0.y+0.0,0)))
            s.leg_rest[sd]['heel']=V((0,0.035,0)); s.leg_rest[sd]['ballp']=V((B[N+'Toes']['h'].x-G0.x,B[N+'Toes']['h'].y-G0.y,0))
        s.height=B['Head']['t'].z
    def _ikframes(s,a,b,c):
        x=(c-a).normalized(); y=(b-(a+x*x.dot(b-a)))
        if y.length<1e-6: y=V((0,-1,0))
        nrm=x.cross(y.normalized()).normalized()
        return dict(Fu=frame(b-a,nrm),Fl=frame(c-b,nrm))
    def _twistang(s,Fl,n):
        d=Fl.col[0]; r=Fl.col[1]; nn=(n-d*d.dot(n)).normalized()
        return math.atan2(d.cross(r).dot(nn),r.dot(nn))
    @staticmethod
    def ik2(A,T,L1,L2,pole):
        d=T-A; dist=d.length; mx=(L1+L2)*0.9995; mn=abs(L1-L2)+1e-3
        over=dist/(L1+L2)
        dist=min(max(dist,mn),mx); x=d.normalized()
        y=pole-x*x.dot(pole)
        if y.length<1e-6: y=V((0,0,1))-x*x.z
        y.normalize()
        a=(L1*L1+dist*dist-L2*L2)/(2*dist); h=math.sqrt(max(L1*L1-a*a,0))
        knee=A+x*a+y*h; end=A+x*dist
        return knee,end,x.cross(y).normalized(),over

# ------------------------------------------------------------------ arm keys
class Hang:
    def __init__(s,swing=0,abd=7,elbow=14,twist=0,wrist=8): s.a=(swing,abd,elbow,twist,wrist)
class Tgt:
    """palm-centre target. space: 'world' or 'chest' (UpperChest frame) or 'hips'. f=finger dir, n=palm normal (world-ish)"""
    def __init__(s,pos,f,n,space='world',pole=None): s.pos=V(pos); s.f=V(f); s.n=V(n); s.space=space; s.pole=V(pole) if pole else None
class Follow:
    """target given by a function frame-> (pos,f,n) (props)"""
    def __init__(s,fn,pole=None): s.fn=fn; s.pole=V(pole) if pole else None

DEFAULT=dict(hip=(0,0,-0.012),hiprot=(0,0,0),spine=(1.5,0,0),chest=(0,0,0),uchest=(-1.0,0,0),neck=(2,0,0),head=(-2,0,0),
    clavL=(0,0),clavR=(0,0),footL=(0.012,0,0,7,0,0),footR=(-0.012,0,0,-7,0,0),kneeL=(0.12,),kneeR=(0.12,),
    fingL=(0.2,0.2,0.15),fingR=(0.2,0.2,0.15))

class Clip:
    def __init__(s,name,length,loop=False,notes=''):
        s.name=name; s.N=length; s.loop=loop; s.keys={}; s.arms={1:[],-1:[]}; s.procs=[]; s.props=[]; s.notes=notes; s.meta={}
    def k(s,group,f,*v):
        s.keys.setdefault(group,[]).append((f,tuple(v) if len(v)>1 else tup(v[0]))); return s
    def arm(s,sd,f,key): s.arms[sd].append((f,key)); return s
    def proc(s,fn): s.procs.append(fn); return s
    def tracks(s):
        s.T={g:Track(v,s.N,s.loop) for g,v in s.keys.items()}
    def params(s,f):
        P={g:(s.T[g].ev(f) if g in s.T else DEFAULT[g]) for g in DEFAULT}
        for fn in s.procs: fn(f,P)
        return P

# ------------------------------------------------------------------ solve
class Solver:
    def __init__(s,rig): s.r=rig
    def torso(s,P):
        r=s.r; B=r.B; D={}; H={}
        D['Hips']=eul(P['hiprot']); H['Hips']=B['Hips']['h']+V(P['hip'])
        for b,g in [('Spine','spine'),('Chest','chest'),('UpperChest','uchest'),('Neck','neck'),('Head','head')]:
            p=B[b]['p']; H[b]=H[p]+D[p]@(B[b]['h']-B[p]['h']); D[b]=D[p]@eul(P[g])
        return D,H
    def solve(s,P,f=0,clip=None):
        r=s.r; B=r.B; D,H=s.torso(P); s.info={}
        # legs
        for sd in(1,-1):
            N=side_name(sd); lr=r.leg_rest[sd]; x,y,z,yaw,pitch,toe=P['foot'+N[0]]
            G=lr['G0']+V((x,y,z)); Rzy=Rz(yaw)
            piv=lr['ballp'] if pitch>0 else lr['heel']
            Rp=Rx(pitch)
            def xf(pt): return G+Rzy@(piv+Rp@(pt-piv))
            ank=xf(lr['A']); ballw=xf(lr['ballp']+V((0,0,.02)))
            hj=H['Hips']+D['Hips']@(B[N+'UpperLeg']['h']-B['Hips']['h'])
            hy=Rz(math.degrees(math.atan2(D['Hips'].col[1].x*-1,D['Hips'].col[1].y)) if False else 0)
            pole=Rz((yaw+P['hiprot'][2])*0.5)@V((sd*P['knee'+N[0]][0],-1,0.0))
            kn,end,nrm,over=Rig.ik2(hj,ank,r.LT,r.LS,pole.normalized())
            s.info['leg'+N[0]]=over
            D[N+'UpperLeg']=frame(kn-hj,nrm)@lr['Fu'].transposed(); H[N+'UpperLeg']=hj
            D[N+'LowerLeg']=frame(end-kn,nrm)@lr['Fl'].transposed(); H[N+'LowerLeg']=kn
            D[N+'Foot']=Rzy@Rp; H[N+'Foot']=end
            D[N+'Toes']=Rzy@Rx(min(pitch,0)+toe); H[N+'Toes']=end+D[N+'Foot']@(B[N+'Toes']['h']-B[N+'Foot']['h'])
        # arms
        for sd in(1,-1):
            N=side_name(sd); C=N+'Shoulder'
            l0,f0=P['clav'+N[0]]; D[C]=D['UpperChest']@Ry(-sd*l0)@Rz(-sd*f0)
            H[C]=H['UpperChest']+D['UpperChest']@(B[C]['h']-B['UpperChest']['h'])
            pos,fv,nv,pole=s.arm_target(sd,P,D,H,f,clip)
            for it in range(2):
                lift,fwd=P['clav'+N[0]]
                if it==1:
                    u=(pos-H[C]-D[C]@(B[N+'UpperArm']['h']-B[C]['h'])).normalized()
                    lift+=max(0,min(16,(u.z+0.45)*22)); fwd+=max(-4,min(10,-u.y*10))
                D[C]=D['UpperChest']@Ry(-sd*lift)@Rz(-sd*fwd)
                H[C]=H['UpperChest']+D['UpperChest']@(B[C]['h']-B['UpperChest']['h'])
                sj=H[C]+D[C]@(B[N+'UpperArm']['h']-B[C]['h'])
                hr=r.hand_rest[sd]; Fh=frame(fv,nv); Dh=Fh@hr['F'].transposed()
                wr=pos-Fh@hr['off']
                el,end,nrm,over=Rig.ik2(sj,wr,r.LU,r.LF,pole)
                if it==0: u0=el
            s.info['arm'+N[0]]=over
            ar=r.arm_rest[sd]
            D[N+'UpperArm']=frame(el-sj,nrm)@ar['Fu'].transposed(); H[N+'UpperArm']=sj
            Fl=frame(end-el,nrm)
            tw=r._twistang(Fl,Fh.col[1])-ar['twist0']; tw=(tw+math.pi)%(2*math.pi)-math.pi
            Fl=M.Rotation(tw*0.5,3,(end-el).normalized())@Fl
            D[N+'LowerArm']=Fl@ar['Fl'].transposed(); H[N+'LowerArm']=el
            D[N+'Hand']=Dh; H[N+'Hand']=end
            H['HandAttach_'+N[0]]=end+Dh@(B['HandAttach_'+N[0]]['h']-B[N+'Hand']['h']); D['HandAttach_'+N[0]]=Dh
            # fingers
            curl,idx,th=P['fing'+N[0]]
            ax=hr['axis']
            for fn in ('Index','Middle','Ring','Little'):
                c=idx if fn=='Index' else curl
                c=c*(1+{'Index':-0.05,'Middle':0,'Ring':0.06,'Little':0.12}[fn])
                ang=0; par=N+'Hand'
                for seg,mx in (('Proximal',80),('Intermediate',95),('Distal',60)):
                    b=N+fn+seg; ang+=c*mx
                    H[b]=H[par]+D[par]@(B[b]['h']-B[par]['h']); D[b]=Dh@M.Rotation(rad(ang),3,ax); par=b
            ta=hr['taxis']; par=N+'Hand'; ang=0
            for seg,mx in (('Metacarpal',15),('Proximal',30),('Distal',40)):
                b=N+'Thumb'+seg; ang+=th*mx
                Rop=M.Rotation(rad(th*30*-sd*-1),3,hr['f']) if seg=='Metacarpal' else M.Identity(3)
                if seg=='Metacarpal': s._top=Rop
                H[b]=H[par]+D[par]@(B[b]['h']-B[par]['h']); D[b]=Dh@s._top@M.Rotation(rad(ang),3,ta); par=b
        # passive bones follow parent rigidly (springs added later)
        for b in r.order:
            if b not in D:
                p=B[b]['p']; H[b]=H[p]+D[p]@(B[b]['h']-B[p]['h']); D[b]=D[p]
        return D,H
    def chest_frame(s,D,H):
        return D['UpperChest'],H['UpperChest']
    def resolve(s,key,sd,P,D,H,f):
        r=s.r; Dc,Hc=D['UpperChest'],H['UpperChest']
        defpole=(Dc@V((sd*0.55,0.55,-0.62))).normalized()
        if isinstance(key,Hang):
            sw,abd,elb,tw,wr=key.a
            yawM=Rz(math.degrees(math.atan2(-Dc.col[0].y,Dc.col[0].x)))
            Bm=yawM
            u=Bm@(Rx(-sw)@Ry(-sd*abd)@V((0,0,-1)))
            fwd=Bm@V((0,-1,0)); ax=u.cross(fwd).normalized()
            fa=M.Rotation(rad(elb),3,ax)@u
            fdir=M.Rotation(rad(elb+wr),3,ax)@u
            C=side_name(sd)+'Shoulder'
            sj=H[C]+D[C]@(r.B[side_name(sd)+'UpperArm']['h']-r.B[C]['h'])
            el=sj+u*r.LU; wrp=el+fa*r.LF
            n=Bm@V((-sd,0.15,0)); n=(n-fdir*fdir.dot(n)).normalized(); n=M.Rotation(rad(sd*tw),3,fdir)@n
            hr=r.hand_rest[sd]; Fh=frame(fdir,n); pos=wrp+Fh@hr['off']
            mid=(sj+wrp)/2; pole=(el-mid); pole=pole.normalized() if pole.length>1e-4 else defpole
            return pos,fdir,n,(pole+defpole*0.15).normalized()
        if isinstance(key,Follow):
            pos,fv,nv=key.fn(f); return V(pos),V(fv),V(nv),(key.pole or defpole)
        if key.space=='chest':
            return Hc+Dc@key.pos,Dc@key.f,Dc@key.n,(Dc@key.pole if key.pole else defpole)
        return key.pos.copy(),key.f.copy(),key.n.copy(),(key.pole if key.pole else defpole)
    def arm_target(s,sd,P,D,H,f,clip):
        ks=clip.arms[sd] if clip else []
        if not ks: ks=[(0,Hang())]
        if clip and clip.loop:
            d={}
            for t,k_ in ks: d[t%clip.N]=k_
            ks=list(d.items())
        ks=sorted(ks,key=lambda x:x[0])
        if len(ks)==1: return s.resolve(ks[0][1],sd,P,D,H,f)
        N=clip.N
        if clip.loop:
            ff=f%N; ext=[(t-N,k) for t,k in ks[-2:]]+ks+[(t+N,k) for t,k in ks[:2]]
        else: ff=f; ext=ks
        if ff<=ext[0][0]: return s.resolve(ext[0][1],sd,P,D,H,f)
        if ff>=ext[-1][0]: return s.resolve(ext[-1][1],sd,P,D,H,f)
        i=max(j for j in range(len(ext)-1) if ext[j][0]<=ff)
        idx=[max(i-1,0),i,i+1,min(i+2,len(ext)-1)]
        R=[s.resolve(ext[j][1],sd,P,D,H,f) for j in idx]; T=[ext[j][0] for j in idx]
        u=(ff-T[1])/(T[2]-T[1])
        def herm(c):
            v0=R[1][c]; v1=R[2][c]
            def tan(a,b,c_,ta,tb,tc):
                if idx[0]==idx[1] and a is R[0][c] and ta==tb: return v0*0
                out=V((0,0,0))
                for q in range(3):
                    d0=(b[q]-a[q])/max(tb-ta,1e-6); d1=(c_[q]-b[q])/max(tc-tb,1e-6)
                    if d0*d1<=0 or ta==tb or tb==tc: continue
                    m=(c_[q]-a[q])/(tc-ta); out[q]=math.copysign(min(abs(m),3*abs(d0),3*abs(d1)),m)
                return out
            m0=tan(R[0][c],R[1][c],R[2][c],T[0],T[1],T[2]); m1=tan(R[1][c],R[2][c],R[3][c],T[1],T[2],T[3])
            h=T[2]-T[1]
            return v0*(2*u**3-3*u**2+1)+m0*h*(u**3-2*u**2+u)+v1*(-2*u**3+3*u**2)+m1*h*(u**3-u**2)
        pos=herm(0); fv=herm(1); nv=herm(2); pole=R[1][3].lerp(R[2][3],u*u*(3-2*u))
        return pos,fv.normalized(),nv.normalized(),pole.normalized()

# ------------------------------------------------------------------ springs
SPRINGS={'HairBack':dict(freq=2.2,zeta=.32,maxang=24,grav=.55),'HairFront':dict(freq=2.6,zeta=.35,maxang=22,grav=.45),
         'Sweater':dict(freq=4.0,zeta=.55,maxang=12,grav=.25)}
def spring_pass(rig,frames,loop):
    """frames: list of (D,H). modifies spring bones in place."""
    B=rig.B; dt=1/FPS; n=len(frames)
    sb=[b for b in rig.order if any(b.startswith(k) for k in SPRINGS)]
    st={}
    passes=3 if loop else 1
    seq=[]
    # pre-roll: hold first frame for 20 frames to settle
    order=([0]*20 if not loop else [])+list(range(n))*passes
    for step,fi in enumerate(order):
        D,H=frames[fi]
        for b in sb:
            cfg=next(v for k,v in SPRINGS.items() if b.startswith(k))
            p=B[b]['p']; H[b]=H[p]+D[p]@(B[b]['h']-B[p]['h'])
            Drig=D[p] if p in D else M.Identity(3)
            drig=(Drig@(B[b]['t']-B[b]['h'])).normalized(); L=B[b]['L']
            down=V((0,0,-1)); restd=(B[b]['t']-B[b]['h']).normalized()
            # gravity: keep the rest relation to world-down partially
            g=rot_between(Drig@restd,restd).slerp(M.Identity(3),1.0) if False else None
            q=(Drig@restd).rotation_difference(restd)
            dtar=(Q().slerp(q,cfg['grav'])@(Drig@restd)).normalized()
            tgt=H[b]+dtar*L
            if b not in st: st[b]=[tgt.copy(),V((0,0,0))]
            pp,vv=st[b]; w=2*math.pi*cfg['freq']
            for sub in range(4):
                h=dt/4; acc=(tgt-pp)*w*w-vv*2*cfg['zeta']*w; vv=vv+acc*h; pp=pp+vv*h
            dsim=(pp-H[b]).normalized()
            ang=dtar.angle(dsim) if dsim.length>0 else 0
            mx=rad(cfg['maxang'])
            if ang>mx: dsim=dtar.slerp(dsim,mx/ang) if hasattr(dtar,'slerp') else dsim
            pp=H[b]+dsim*L; st[b]=[pp,vv]
            D[b]=rot_between(Drig@restd,dsim)@Drig
            # children follow
        if step>=len(order)-n:
            pass

def to_basis(rig,D,H):
    """armature-space pose -> local basis (quaternion per bone, location for Hips)"""
    B=rig.B; out={}
    W={}
    for b in rig.order:
        Rb=B[b]['R']; m=(D[b]@Rb).to_4x4(); m.translation=H[b]; W[b]=m
        p=B[b]['p']
        if p is None: basis=B[b]['ML'].inverted()@m
        else: basis=(B[p]['ML'].inverted()@B[b]['ML']).inverted()@W[p].inverted()@m
        loc,rq,sc=basis.decompose(); out[b]=(loc,rq)
    return out

def bake(rig,clip,solver):
    clip.tracks(); frames=[]; infos=[]
    nf=clip.N if clip.loop else clip.N+1
    for f in range(nf):
        P=clip.params(f); D,H=solver.solve(P,f,clip); frames.append((D,H)); infos.append(dict(solver.info))
    spring_pass(rig,frames,clip.loop)
    return frames,infos

def write_action(rig,clip,frames):
    act=bpy.data.actions.new(clip.name); act.use_fake_user=True
    data={}
    for f,(D,H) in enumerate(frames):
        bs=to_basis(rig,D,H)
        for b,(loc,q) in bs.items(): data.setdefault(b,[]).append((loc,q))
    if clip.loop:
        for b in data: data[b].append(data[b][0])   # close loop: key at frame N == frame 0
    for b,seq in data.items():
        if b.startswith('HandAttach'): continue
        pth=f'pose.bones["{b}"]'
        prev=None; qs=[]
        for loc,q in seq:
            if prev is not None and prev.dot(q)<0: q=-q
            qs.append(q); prev=q
        for c in range(4):
            fc=act.fcurves.new(pth+'.rotation_quaternion',index=c,action_group=b)
            fc.keyframe_points.add(len(qs)); co=[]
            for i,q in enumerate(qs): co+= [i,q[c]]
            fc.keyframe_points.foreach_set('co',co)
            for kp in fc.keyframe_points: kp.interpolation='LINEAR'
        if b=='Hips':
            for c in range(3):
                fc=act.fcurves.new(pth+'.location',index=c,action_group=b)
                fc.keyframe_points.add(len(seq)); co=[]
                for i,(loc,q) in enumerate(seq): co+=[i,loc[c]]
                fc.keyframe_points.foreach_set('co',co)
                for kp in fc.keyframe_points: kp.interpolation='LINEAR'
    act.frame_range=(0,len(frames)-1 if not clip.loop else clip.N)
    return act
