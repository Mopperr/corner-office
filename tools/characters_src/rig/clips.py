"""Clip definitions for the Corner Office humanoid (re-solved per character).
Blender coords: forward = -Y. k = height/1.70."""
import math
from mathutils import Vector as V, Matrix as M
from animlib import *

BOX=(0.40,0.35,0.40)   # w (x), h (z), d (y)

def body(rig):
    B=rig.B; k=rig.height/1.70
    sh=(B['LeftUpperArm']['h']+B['RightUpperArm']['h'])/2
    return dict(k=k,sh=sh,hipz=B['Hips']['h'].z,hj=B['LeftUpperLeg']['h'],
                leg=rig.LT+rig.LS,arm=rig.LU+rig.LF,head=B['Head']['h'])

class Prop:
    """preview-only prop: mesh kind + attachment schedule [(frame,'world'|'L'|'R'|'both')]"""
    def __init__(s,name,kind,dims,mat0,color,sched=None,anim=None):
        s.name=name; s.kind=kind; s.dims=dims; s.m0=mat0; s.color=color; s.sched=sched or [(0,'world')]; s.anim=anim
def Mt(loc,rz=0,rx=0):
    m=(Rz(rz)@Rx(rx)).to_4x4(); m.translation=V(loc); return m

def pose(c,f,d):
    for g,v in d.items(): c.k(g,f,*tup(v))
def mix(*ds):
    o={}
    for d in ds: o.update(d)
    return o

def stand(k):
    return dict(hip=(0,0,-0.012*k),hiprot=(0,0,0),spine=(1.5,0,0),chest=(0,0,0),uchest=(-1,0,0),neck=(2,0,0),head=(-2,0,0),
                footL=(0.012*k,0,0,7,0,0),footR=(-0.012*k,0,0,-7,0,0),kneeL=(0.12,),kneeR=(0.12,),clavL=(0,0),clavR=(0,0),
                fingL=(0.2,0.2,0.15),fingR=(0.2,0.2,0.15))
RELAX=(0.2,0.2,0.15); FLAT=(0.1,0.08,0.05); GRIP=(0.72,0.68,0.75); PINCH=(0.45,0.5,0.7); POINT=(0.85,0.03,0.6); SOFT=(0.32,0.3,0.3)

# ---------------------------------------------------------------- idle
def c_idle(rig):
    b=body(rig); k=b['k']; c=Clip('idle',240,loop=True,notes='breathing idle, 2 breaths + slow weight shift L->R->L')
    base=stand(k); pose(c,0,base)
    for f in range(0,241,20):
        t=f/240*2*math.pi; br=f/120*2*math.pi
        sway=math.sin(t)
        c.k('hip',f,0.016*k*sway,0.004*k*math.sin(2*t),-0.012*k-0.004*k*abs(sway))
        c.k('hiprot',f,0.6*math.sin(2*t),-2.2*sway,1.2*math.sin(t+0.5))
        c.k('spine',f,1.5+0.4*math.cos(br),1.0*sway,-0.6*math.sin(t+0.5))
        c.k('chest',f,0.3*math.cos(br),0.6*sway,0)
        c.k('uchest',f,-1.0-1.3*(0.5-0.5*math.cos(br)),0.5*sway,0)
        c.k('neck',f,2+0.6*(0.5-0.5*math.cos(br)),-0.8*sway,0)
        c.k('head',f,-2+1.5*math.sin(t*1.5+1),-0.8*sway,6*math.sin(t+1.2)*math.sin(t*0.5)**2)
        c.k('clavL',f,1.2*(0.5-0.5*math.cos(br)),0); c.k('clavR',f,1.2*(0.5-0.5*math.cos(br)),0)
        # weight on left at t=pi/2: left knee straighter, right knee relaxed (heel stays down, hip z handles it)
        c.k('fingL',f,0.2+0.04*math.sin(t*2),0.18+0.04*math.sin(t*2+1),0.15)
        c.k('fingR',f,0.2+0.04*math.sin(t*2+2),0.18+0.04*math.sin(t*2+3),0.15)
    for f in range(0,241,40):
        t=f/240*2*math.pi
        c.arm(1,f,Hang(swing=1.5*math.sin(t+1.0),abd=7+1.0*math.sin(t*2),elbow=14+3*math.sin(t+0.8),twist=0))
        c.arm(-1,f,Hang(swing=1.5*math.sin(t+2.4),abd=7+1.0*math.sin(t*2+1),elbow=14+3*math.sin(t+2.0),twist=0))
    return c

# ---------------------------------------------------------------- walk (procedural)
WALK=dict(N=32,step=0.62,duty=0.62)
def walk_legs(rig,c,F0=0.30,armswing=True):
    b=body(rig); k=b['k']; N=c.N
    step=WALK['step']*k; v_frame=2*step/N; duty=WALK['duty']; Ls=v_frame*N*duty
    c.meta['speed_mps']=round(v_frame*FPS,3); c.meta['step_m']=round(step,3)
    F0=F0*k
    def foot(ph,sd):
        if ph<duty:
            s=ph/duty; fw=F0-Ls*s
            pitch=-15*(1-sstep(0,0.16,s))+34*sstep(0.62,1.0,s)**1.4
            z=0; toe=0
        else:
            s=(ph-duty)/(1-duty); e=s*s*(3-2*s)
            fw=lerp(F0-Ls,F0,e)
            z=0.055*k*math.sin(math.pi*s)**1.3+0.012*k*math.sin(math.pi*min(s*2,1))
            pitch=lerp(34,-15,sstep(0,0.85,s)) ; toe=-12*math.sin(math.pi*min(s/0.4,1))
        return (sd*0.006*k,-fw,z,sd*5,pitch,toe)
    def fn(f,P):
        w=2*math.pi*f/N
        P['footL']=foot((f/N)%1,1); P['footR']=foot((f/N+0.5)%1,-1)
        P['hip']=(0.02*k*math.sin(w-0.3),-0.0,-0.035*k-0.016*k*math.cos(2*w-0.25))
        P['hiprot']=(4,-3.0*math.sin(w-0.3),-5*math.cos(w))
        P['spine']=(2,1.0*math.sin(w-0.3),2*math.cos(w-0.2))
        P['chest']=(1,0.5*math.sin(w),2.5*math.cos(w-0.3))
        P['uchest']=(0+0.8*math.cos(2*w),0.3*math.sin(w),4.5*math.cos(w-0.4))
        P['neck']=(-1,-0.8*math.sin(w),-2.0*math.cos(w-0.5))
        P['head']=(-1.5-1.2*math.cos(2*w-0.6),-0.6*math.sin(w),-1.8*math.cos(w-0.6))
        P['kneeL']=(0.08,); P['kneeR']=(0.08,)
    c.proc(fn)
    if armswing:
        for f in range(0,N+1,4):
            w=2*math.pi*(f-3)/N; sL=-17*math.cos(w); sR=17*math.cos(w)
            c.arm(1,f,Hang(swing=sL,abd=8,elbow=16+12*max(0,sL)/17,twist=-4))
            c.arm(-1,f,Hang(swing=sR,abd=8,elbow=16+12*max(0,sR)/17,twist=-4))
            c.k('fingL',f,0.25,0.22,0.2); c.k('fingR',f,0.25,0.22,0.2)
def c_walk(rig):
    c=Clip('walk',WALK['N'],loop=True,notes='in-place walk; move the character at speed_mps'); walk_legs(rig,c); return c

# ---------------------------------------------------------------- box helpers
def box_frames(rig):
    b=body(rig); k=b['k']; sh=b['sh']
    carry=V((0,sh.y-0.35,sh.z-0.30)); floor=V((0,-0.38*max(k,0.85),BOX[1]/2))
    return carry,floor
def box_palms(center,sd,fdir=(0,-0.45,-0.89)):
    f=V(fdir); f.x=0; n=V((-sd,0,0))
    return Tgt(center+V((sd*(BOX[0]/2+0.012),0,0)),f,n)
def carry_pose(rig,c,f,breath=0.0):
    carry,_=box_frames(rig); cc=carry+V((0,0,0.004*breath))
    c.arm(1,f,box_palms(cc,1,(0.05,-0.8,-0.6))); c.arm(-1,f,box_palms(cc,-1,(-0.05,-0.8,-0.6)))

def c_carry(rig):
    b=body(rig); k=b['k']; c=Clip('carry',90,loop=True,notes='holding medium box at carry height, breathing')
    base=stand(k); base.update(spine=(-1,0,0),uchest=(-2.5,0,0),head=(1,0,0),fingL=FLAT,fingR=FLAT)
    for f in range(0,91,15):
        t=f/90*2*math.pi
        d=dict(base); d['hip']=(0.008*k*math.sin(t),0.006*k,-0.016*k-0.003*k*math.cos(2*t))
        d['uchest']=(-2.5-1.0*(0.5-0.5*math.cos(2*t)),0,0); d['hiprot']=(-1,-1.0*math.sin(t),0)
        d['head']=(1+0.8*math.sin(2*t+1),0,2*math.sin(t))
        pose(c,f,d)
    for f in range(0,91,15):
        t=f/90*2*math.pi; carry,_=box_frames(rig); cc=carry+V((0.004*math.sin(t),0,0.006*math.cos(2*t)))
        c.arm(1,f,box_palms(cc,1,(0.05,-0.8,-0.6))); c.arm(-1,f,box_palms(cc,-1,(-0.05,-0.8,-0.6)))
    carry,_=box_frames(rig)
    c.props.append(Prop('Box','box',BOX,Mt(carry),'#C9A46C',[(0,'both')]))
    return c

def c_carry_walk(rig):
    b=body(rig); k=b['k']; c=Clip('carry_walk',WALK['N'],loop=True,notes='extra: walking while carrying the box')
    walk_legs(rig,c,armswing=False)
    def up(f,P):
        P['uchest']=(P['uchest'][0]-3,P['uchest'][1],P['uchest'][2]*0.5); P['hiprot']=(1.5,P['hiprot'][1],P['hiprot'][2]*0.7)
        P['fingL']=FLAT; P['fingR']=FLAT
    c.proc(up)
    carry,_=box_frames(rig)
    for f in range(0,33,8):
        w=2*math.pi*f/32; cc=carry+V((0,0,-0.006*math.cos(2*w)))
        c.arm(1,f,box_palms(cc,1,(0.05,-0.8,-0.6))); c.arm(-1,f,box_palms(cc,-1,(-0.05,-0.8,-0.6)))
    c.props.append(Prop('Box','box',BOX,Mt(carry),'#C9A46C',[(0,'both')]))
    return c

def squat(k,depth=1.0,yb=0.14):
    return dict(hip=(0,yb*k*depth,(-0.52*depth)*k),hiprot=(48*depth,0,0),spine=(4*depth,0,0),chest=(2*depth,0,0),uchest=(0,0,0),
                neck=(-6*depth,0,0),head=(-14*depth,0,0),kneeL=(0.55,),kneeR=(0.55,))

def c_pick_up(rig):
    b=body(rig); k=b['k']; c=Clip('pick_up',84,notes='squat with straight back, palms on box sides, lift to carry')
    carry,floor=box_frames(rig)
    st=stand(k)
    pose(c,0,st)
    pose(c,8,dict(head=(16,0,0),neck=(6,0,0),hip=(0,0.0,-0.02*k),uchest=(-0.5,0,0)))              # look down (anticipation)
    pose(c,16,dict(hip=(0,0.03*k,-0.07*k),hiprot=(8,0,0),spine=(2,0,0)))
    pose(c,32,mix(squat(k,1.0),dict(head=(-16,0,0))))
    pose(c,38,mix(squat(k,1.04),dict(head=(-18,0,0))))    # settle/weight
    pose(c,44,squat(k,1.0))
    pose(c,58,mix(squat(k,0.45),dict(spine=(0,0,0),head=(-4,0,0))))
    pose(c,70,dict(hip=(0,0.01*k,-0.022*k),hiprot=(-2,0,0),spine=(-2,0,0),chest=(-1,0,0),uchest=(-3,0,0),neck=(0,0,0),head=(2,0,0),kneeL=(0.15,),kneeR=(0.15,)))
    pose(c,76,dict(hip=(0,0.008*k,-0.012*k),hiprot=(-1.5,0,0),spine=(-1,0,0),uchest=(-2.5,0,0),head=(1,0,0)))
    pose(c,84,dict(hip=(0,0.006*k,-0.016*k),hiprot=(-1,0,0),spine=(-1,0,0),chest=(0,0,0),uchest=(-2.5,0,0),neck=(2,0,0),head=(1,0,0),kneeL=(0.12,),kneeR=(0.12,)))
    for sd in(1,-1):
        G='fing'+('L' if sd>0 else 'R')
        c.k(G,0,*RELAX); c.k(G,26,*SOFT); c.k(G,34,*FLAT); c.k(G,40,0.16,0.14,0.08); c.k(G,84,*FLAT)
        c.arm(sd,0,Hang()); c.arm(sd,10,Hang(swing=4,abd=9,elbow=18))
        hover=box_palms(floor+V((0,0,0.03)),sd,(0,-0.2,-0.98)); hover.pos+=V((sd*0.05,0,0))
        c.arm(sd,24,hover)
        c.arm(sd,34,box_palms(floor,sd,(0,-0.2,-0.98)))
        c.arm(sd,40,box_palms(floor+V((0,0,-0.004)),sd,(0,-0.2,-0.98)))
        c.arm(sd,58,box_palms(lerp(floor,carry,0.45)+V((0,0.03,0)),sd,(0.02*sd,-0.5,-0.85)))
        c.arm(sd,70,box_palms(carry+V((0,0,0.012)),sd,(0.05*sd,-0.8,-0.6)))
        c.arm(sd,77,box_palms(carry+V((0,0,-0.008)),sd,(0.05*sd,-0.8,-0.6)))
        c.arm(sd,84,box_palms(carry,sd,(0.05*sd,-0.8,-0.6)))
    c.props.append(Prop('Box','box',BOX,Mt(floor),'#C9A46C',[(0,'world'),(40,'both')]))
    c.meta['box_start_local_godot']=[0,round(floor.z,3),round(-floor.y,3)]
    return c

def c_set_down(rig):
    b=body(rig); k=b['k']; c=Clip('set_down',78,notes='from carry: squat, place box, release, stand')
    carry,floor=box_frames(rig)
    cp=dict(hip=(0,0.006*k,-0.016*k),hiprot=(-1,0,0),spine=(-1,0,0),chest=(0,0,0),uchest=(-2.5,0,0),neck=(2,0,0),head=(1,0,0),kneeL=(0.12,),kneeR=(0.12,),
            footL=(0.012*k,0,0,7,0,0),footR=(-0.012*k,0,0,-7,0,0),clavL=(0,0),clavR=(0,0))
    pose(c,0,cp)
    pose(c,6,dict(head=(14,0,0),neck=(6,0,0),hip=(0,0.006*k,-0.008*k)))   # look down, tiny rise (anticipation)
    pose(c,26,squat(k,0.95)); pose(c,34,squat(k,1.02)); pose(c,40,squat(k,1.0))
    pose(c,48,mix(squat(k,0.9),dict(head=(-8,0,0))))
    pose(c,64,dict(hip=(0,0,-0.03*k),hiprot=(6,0,0),spine=(2,0,0),chest=(0,0,0),uchest=(-1,0,0),neck=(3,0,0),head=(-1,0,0),kneeL=(0.15,),kneeR=(0.15,)))
    pose(c,78,stand(k))
    for sd in(1,-1):
        G='fing'+('L' if sd>0 else 'R')
        c.k(G,0,*FLAT); c.k(G,36,0.16,0.14,0.08); c.k(G,42,*FLAT); c.k(G,52,*SOFT); c.k(G,78,*RELAX)
        c.arm(sd,0,box_palms(carry,sd,(0.05*sd,-0.8,-0.6)))
        c.arm(sd,8,box_palms(carry+V((0,0,0.01)),sd,(0.05*sd,-0.8,-0.6)))
        c.arm(sd,24,box_palms(lerp(floor,carry,0.4)+V((0,0.02,0)),sd,(0.02*sd,-0.4,-0.9)))
        c.arm(sd,34,box_palms(floor+V((0,0,0.003)),sd,(0,-0.2,-0.98)))
        c.arm(sd,40,box_palms(floor,sd,(0,-0.2,-0.98)))
        rel=box_palms(floor+V((0,0,0.05)),sd,(0,-0.2,-0.98)); rel.pos+=V((sd*0.06,0,0)); c.arm(sd,50,rel)
        c.arm(sd,66,Hang(swing=6,abd=10,elbow=20)); c.arm(sd,78,Hang())
    c.props.append(Prop('Box','box',BOX,Mt(carry),'#C9A46C',[(0,'both'),(40,'world')]))
    return c

# ---------------------------------------------------------------- push
def c_push(rig):
    b=body(rig); k=b['k']; sh=b['sh']; c=Clip('push',54,notes='two-hand push of a waist-high object ~0.15 m forward')
    st=stand(k); st['footR']=(-0.012*k,0.10*k,0,-10,0,0); st['footL']=(0.012*k,-0.06*k,0,6,0,0)  # staggered stance (set in frame 0 = from idle blend)
    face_y=-0.40*k; z=sh.z-0.40*k
    pose(c,0,st)
    pose(c,10,dict(hip=(0,0.035*k,-0.03*k),hiprot=(-2,0,0),spine=(-2,0,0),uchest=(-3,0,0),head=(4,0,0)))      # anticipation: rock back
    pose(c,16,dict(hip=(0,0.0,-0.04*k),hiprot=(6,0,0),spine=(4,0,0),uchest=(2,0,0),head=(0,0,0)))
    pose(c,30,dict(hip=(0,-0.10*k,-0.055*k),hiprot=(12,0,0),spine=(6,0,0),chest=(3,0,0),uchest=(3,0,0),head=(-4,0,0)))
    pose(c,36,dict(hip=(0,-0.11*k,-0.05*k),hiprot=(10,0,0),spine=(4,0,0),uchest=(1,0,0)))                          # follow-through
    pose(c,44,dict(hip=(0,-0.04*k,-0.02*k),hiprot=(3,0,0),spine=(2,0,0),uchest=(-1,0,0),head=(-2,0,0)))
    pose(c,54,dict(hip=(0,-0.02*k,-0.012*k),hiprot=(0,0,0),spine=(1.5,0,0),uchest=(-1,0,0),head=(-2,0,0)))
    def palm(sd,dy,dz=0):
        return Tgt((sd*0.17*k,face_y+dy,z+dz),(sd*0.12,-0.15,0.98),(0,-1,0))
    for sd in(1,-1):
        G='fing'+('L' if sd>0 else 'R')
        c.k(G,0,*RELAX); c.k(G,14,*FLAT); c.k(G,40,*FLAT); c.k(G,54,*RELAX)
        c.arm(sd,0,Hang()); c.arm(sd,8,Hang(swing=18,abd=9,elbow=55))
        c.arm(sd,15,palm(sd,0.0)); c.arm(sd,30,palm(sd,-0.15*k)); c.arm(sd,36,palm(sd,-0.155*k))
        c.arm(sd,44,Hang(swing=10,abd=9,elbow=30)); c.arm(sd,54,Hang())
    def push_fn(f):
        t=sstep(15,30,f)*0.15*k+ (sstep(30,36,f)*0.005*k)
        return Mt((0,face_y-0.25-t,z))
    c.props.append(Prop('Crate','box',(0.50,0.50,0.50),Mt((0,face_y-0.25,z)),'#8A6A4A',anim=push_fn))
    return c

# ---------------------------------------------------------------- open_box
def c_open_box(rig):
    b=body(rig); k=b['k']; sh=b['sh']; c=Clip('open_box',90,notes='open the top flaps of a box on a desk')
    top=0.75*k+BOX[1]; cy=-0.48*k; ctr=V((0,cy,top))
    pose(c,0,stand(k))
    pose(c,10,dict(head=(14,0,0),neck=(6,0,0),hiprot=(4,0,0)))
    pose(c,22,dict(hip=(0,0.03*k,-0.04*k),hiprot=(16,0,0),spine=(6,0,0),chest=(3,0,0),uchest=(2,0,0),head=(10,0,0)))
    pose(c,46,dict(hip=(0,0.02*k,-0.035*k),hiprot=(14,0,0),spine=(5,0,0)))
    pose(c,58,dict(hiprot=(18,0,0),head=(16,0,0)))
    pose(c,72,dict(hip=(0,0.01*k,-0.02*k),hiprot=(6,0,0),spine=(1,0,0),chest=(-1,0,0),uchest=(-3,0,0),head=(4,0,0)))   # little lean back (pleased)
    pose(c,90,stand(k))
    for sd in(1,-1):
        G='fing'+('L' if sd>0 else 'R')
        c.k(G,0,*RELAX); c.k(G,20,*SOFT); c.k(G,26,*PINCH); c.k(G,36,*PINCH); c.k(G,40,*SOFT); c.k(G,48,*PINCH); c.k(G,56,*PINCH); c.k(G,62,*SOFT); c.k(G,90,*RELAX)
        c.arm(sd,0,Hang()); c.arm(sd,12,Hang(swing=14,abd=10,elbow=40))
        # front flap edges (near side), then side flaps
        c.arm(sd,24,Tgt(ctr+V((sd*0.08,0.20,0.02)),(sd*0.1,-0.6,-0.8),(0,0.3,-1)))
        c.arm(sd,36,Tgt(ctr+V((sd*0.10,0.32,0.16)),(sd*0.1,-0.2,-0.98),(0,0.8,-0.5)))
        c.arm(sd,46,Tgt(ctr+V((sd*0.20,-0.02,0.03)),(sd*0.2,-0.5,-0.8),(-sd,0,-0.4)))
        c.arm(sd,58,Tgt(ctr+V((sd*0.34,-0.02,0.12)),(sd*0.6,-0.3,-0.7),(-sd*0.5,0,-1)))
        c.arm(sd,72,Hang(swing=10,abd=12,elbow=30)); c.arm(sd,90,Hang())
    c.props.append(Prop('Desk','desk',(1.2,0.6,0.75*k),Mt((0,cy-0.05,0)),'#B08A62'))
    def flaps(f): return (sstep(26,36,f),sstep(48,58,f))
    c.props.append(Prop('OpenBox','openbox',BOX,Mt((0,cy,0.75*k+BOX[1]/2)),'#C9A46C',anim=flaps))
    return c

# ---------------------------------------------------------------- seated
SEAT=0.46
def seated(k,lean=0.0):
    return dict(hip=(0,0.25*k,(SEAT+0.155)*k-0.938*k if False else None),hiprot=(-6+lean,0,0))
def sit_base(rig):
    b=body(rig); k=b['k']; hz=rig.B['Hips']['h'].z
    d=stand(k); d.update(hip=(0,0.25*k,(SEAT*k+0.15*k)-hz),hiprot=(-4,0,0),spine=(4,0,0),chest=(2,0,0),uchest=(0,0,0),neck=(2,0,0),head=(-3,0,0),
        footL=(0.03*k,-0.12*k,0,8,0,0),footR=(-0.03*k,-0.12*k,0,-8,0,0),kneeL=(0.15,),kneeR=(0.15,))
    return d
def thigh_palm(rig,sd,d):
    k=rig.height/1.70; hz=rig.B['Hips']['h'].z
    return Tgt((sd*0.105*k,0.25*k-0.25*k,SEAT*k+0.15*k-0.02*k),(-sd*0.12,-1,-0.1),(0,0,-1))
def chair_props(rig,k):
    return [Prop('Chair','chair',(0.46,0.44,SEAT*k),Mt((0,0.30*k,0)),'#7A5A3E')]

def c_sit(rig):
    b=body(rig); k=b['k']; c=Clip('sit',120,loop=True,notes='seated idle (chair seat 0.46 m, seat centre 0.30 m behind origin)')
    base=sit_base(rig)
    for f in range(0,121,20):
        t=f/120*2*math.pi
        d=dict(base); d['uchest']=(-1.2*(0.5-0.5*math.cos(t)),0.5*math.sin(t),0); d['spine']=(4+0.4*math.cos(t),0,0)
        d['head']=(-3+1.2*math.sin(t+1),0.6*math.sin(t),4*math.sin(t+0.6)); d['clavL']=(1.0*(0.5-0.5*math.cos(t)),0); d['clavR']=d['clavL']
        d['hiprot']=(-4,0.8*math.sin(t),0)
        d['fingL']=(0.3+0.03*math.sin(t*2),0.28,0.2); d['fingR']=(0.3+0.03*math.sin(t*2+1),0.28,0.2)
        pose(c,f,d)
    for sd in(1,-1):
        for f in range(0,121,40):
            t=f/120*2*math.pi; tp=thigh_palm(rig,sd,0); tp.pos+=V((0,-0.01*math.sin(t+sd),0.003*math.cos(t)))
            c.arm(sd,f,tp)
    c.props+=chair_props(rig,k); return c

def c_stand_up(rig):
    b=body(rig); k=b['k']; c=Clip('stand_up',90,notes='chair -> standing idle, hands push off thighs')
    base=sit_base(rig); st=stand(k); st['footL']=base['footL']; st['footR']=base['footR']
    pose(c,0,base)
    pose(c,10,dict(hip=(0,0.21*k,base['hip'][2]+0.005*k),hiprot=(8,0,0),spine=(6,0,0),head=(4,0,0)))           # scoot / start lean
    pose(c,26,dict(hip=(0,0.16*k,base['hip'][2]+0.01*k),hiprot=(38,0,0),spine=(6,0,0),chest=(3,0,0),uchest=(0,0,0),neck=(-6,0,0),head=(-10,0,0)))  # weight over feet
    pose(c,32,dict(hip=(0,0.13*k,base['hip'][2]+0.02*k),hiprot=(42,0,0)))
    pose(c,52,dict(hip=(0,0.0,-0.07*k),hiprot=(12,0,0),spine=(3,0,0),chest=(1,0,0),neck=(0,0,0),head=(-3,0,0)))
    pose(c,62,dict(hip=(0,-0.035*k,-0.005*k),hiprot=(-2,0,0),spine=(0,0,0),chest=(-1,0,0),uchest=(-2,0,0),head=(-1,0,0)))  # overshoot
    pose(c,72,dict(hip=(0,-0.02*k,-0.016*k),hiprot=(0,0,0),spine=(1.5,0,0),chest=(0,0,0),uchest=(-1,0,0),head=(-2,0,0)))
    # feet: step right foot back under the body, then left foot (lift and replace, no sliding)
    fL=base['footL']; fR=base['footR']
    c.k('footR',0,*fR); c.k('footR',62,*fR); c.k('footR',68,-0.03*k,-0.07*k,0.04*k,-7,8,0); c.k('footR',74,-0.012*k,0,0,-7,0,0); c.k('footR',90,-0.012*k,0,0,-7,0,0)
    c.k('footL',0,*fL); c.k('footL',72,*fL); c.k('footL',78,0.03*k,-0.07*k,0.04*k,7,8,0); c.k('footL',84,0.012*k,0,0,7,0,0); c.k('footL',90,0.012*k,0,0,7,0,0)
    c.k('hip',78,0.012*k,-0.01*k,-0.014*k); c.k('hip',90,0,0,-0.012*k)
    c.k('kneeL',0,0.15); c.k('kneeL',26,0.35); c.k('kneeL',60,0.12); c.k('kneeR',0,0.15); c.k('kneeR',26,0.35); c.k('kneeR',60,0.12)
    for sd in(1,-1):
        G='fing'+('L' if sd>0 else 'R')
        c.k(G,0,0.3,0.28,0.2); c.k(G,24,*FLAT); c.k(G,44,*FLAT); c.k(G,90,*RELAX)
        c.arm(sd,0,thigh_palm(rig,sd,0))
        tp=thigh_palm(rig,sd,0); tp.pos+=V((0,-0.10*k,0.0)); c.arm(sd,24,tp)
        tp2=thigh_palm(rig,sd,0); tp2.pos+=V((0,-0.10*k,0.01)); c.arm(sd,34,tp2)
        c.arm(sd,52,Hang(swing=-6,abd=10,elbow=22)); c.arm(sd,64,Hang(swing=4,abd=8,elbow=14)); c.arm(sd,90,Hang())
    c.props+=chair_props(rig,k); return c

def c_type(rig):
    b=body(rig); k=b['k']; c=Clip('type',60,loop=True,notes='seated typing at desk (desk 0.72 m)')
    base=sit_base(rig); base.update(hiprot=(2,0,0),spine=(4,0,0),chest=(2,0,0),uchest=(1,0,0),head=(-2,0,0),neck=(4,0,0),
                                    footL=(0.04*k,-0.14*k,0,10,0,0),footR=(-0.04*k,-0.14*k,0,-10,0,0))
    kz=0.72*k+0.03; ky=-0.06*k
    for f in range(0,61,6):
        t=f/60*2*math.pi
        d=dict(base); d['head']=(-2+1.0*math.sin(t),0,3*math.sin(t*0.5+0.3) if False else 2*math.sin(t))
        d['uchest']=(1-0.8*(0.5-0.5*math.cos(t)),0,0)
        # alternating finger taps
        d['fingL']=(0.35+0.12*max(0,math.sin(t*5)),0.25+0.3*max(0,math.sin(t*5+1.3)),0.3)
        d['fingR']=(0.35+0.12*max(0,math.sin(t*5+2.1)),0.25+0.3*max(0,math.sin(t*5+3.5)),0.3)
        pose(c,f,d)
    for sd in(1,-1):
        for f in range(0,61,6):
            t=f/60*2*math.pi; ph=t*3+(0 if sd>0 else 1.7)
            c.arm(sd,f,Tgt((sd*0.12*k+0.012*math.sin(ph),ky+0.01*math.cos(ph),kz+0.006*max(0,math.sin(ph*1.3))),(-sd*0.25,-1,-0.15),(sd*0.12,0,-1)))
    c.props+=chair_props(rig,k)
    c.props.append(Prop('Desk','desk',(1.2,0.6,0.72*k),Mt((0,ky-0.22*k,0)),'#B08A62'))
    c.props.append(Prop('Keyboard','kbd',(0.36,0.13,0.025),Mt((0,ky-0.03,0.72*k)),'#E8E2D8'))
    return c

# ---------------------------------------------------------------- one-hand interactions (right hand)
def c_water(rig):
    b=body(rig); k=b['k']; sh=b['sh']; c=Clip('water',112,notes='lift watering can from side table, water plant, put back')
    can=V((-0.24*k,-0.30*k,0.70*k)); plant=V((0.02*k,-0.52*k,0.70*k))
    st=stand(k); pose(c,0,st)
    pose(c,8,dict(head=(10,0,-14),neck=(4,0,-6),hiprot=(0,0,-3)))
    pose(c,22,dict(hip=(-0.02*k,0.01*k,-0.05*k),hiprot=(10,-3,-10),spine=(6,-3,-4),chest=(2,0,-2),head=(10,0,-8)))
    pose(c,30,dict(hip=(-0.02*k,0.01*k,-0.055*k)))
    pose(c,44,dict(hip=(0.0,0.0,-0.02*k),hiprot=(3,0,0),spine=(3,0,0),chest=(0,0,0),uchest=(-1,0,0),head=(14,0,6),neck=(6,0,2)))
    pose(c,52,dict(hiprot=(6,0,2),spine=(4,0,2),head=(18,0,4)))
    pose(c,72,dict(hiprot=(7,0,3),spine=(5,0,2),head=(18,0,6)))
    pose(c,82,dict(hip=(-0.02*k,0.01*k,-0.05*k),hiprot=(10,-3,-10),spine=(6,-3,-4),chest=(2,0,-2),head=(10,0,-8)))
    pose(c,92,dict(hip=(-0.02*k,0.01*k,-0.055*k)))
    pose(c,112,st)
    hz=0.13  # handle height above can base
    up=lambda p,dz: p+V((0,0,dz))
    # grip on handle: palm faces +X (toward can body), fingers forward-down
    def g(p,tilt=0):
        f=Rx(-tilt)@V((0,-0.35,-0.94)) ; n=Rx(-tilt)@V((1,0,0.0))
        return Tgt(p+V((-0.0,0.0,hz)),f,n)
    c.k('fingR',0,*RELAX); c.k('fingR',22,*SOFT); c.k('fingR',30,*GRIP); c.k('fingR',86,*GRIP); c.k('fingR',94,*SOFT); c.k('fingR',112,*RELAX)
    c.arm(-1,0,Hang()); c.arm(-1,12,Hang(swing=12,abd=16,elbow=30))
    c.arm(-1,24,g(up(can,0.04))); c.arm(-1,30,g(can)); c.arm(-1,34,g(can+V((0,0,-0.004))))
    c.arm(-1,44,g(up(lerp(can,plant,0.6),0.18)))
    c.arm(-1,54,g(up(plant+V((-0.20,0.06,0)),0.16),tilt=-38)); c.arm(-1,64,g(up(plant+V((-0.18,0.05,0)),0.15),tilt=-44)); c.arm(-1,72,g(up(plant+V((-0.20,0.06,0)),0.16),tilt=-40))
    c.arm(-1,80,g(up(lerp(can,plant,0.3),0.10))); c.arm(-1,88,g(can)); c.arm(-1,94,g(up(can,0.05)))
    c.arm(-1,104,Hang(swing=6,abd=10,elbow=20)); c.arm(-1,112,Hang())
    c.arm(1,0,Hang()); c.arm(1,44,Hang(swing=3,abd=8,elbow=22)); c.arm(1,60,Hang(swing=8,abd=7,elbow=50)); c.arm(1,80,Hang(swing=3,abd=8,elbow=22)); c.arm(1,112,Hang())
    c.props.append(Prop('SideTable','table',(0.45,0.45,0.70*k),Mt((-0.12*k,-0.42*k,0)),'#B08A62'))
    c.props.append(Prop('Plant','plant',(0.16,0.16,0.30),Mt(plant),'#6F8A5A'))
    c.props.append(Prop('Can','can',(0.16,0.12,0.20),Mt(can),'#7FA3B8',[(0,'world'),(32,'R'),(90,'world')]))
    return c

def c_lamp_switch(rig):
    b=body(rig); k=b['k']; c=Clip('lamp_switch',48,notes='press a desk-lamp push switch with the right index finger')
    sw=V((-0.16*k,-0.44*k,0.80*k))
    st=stand(k); pose(c,0,st)
    pose(c,6,dict(head=(14,0,-10),neck=(5,0,-4)))
    pose(c,16,dict(hip=(-0.01*k,0,-0.02*k),hiprot=(8,-2,-6),spine=(5,-2,-3),head=(14,0,-6)))
    pose(c,22,dict(hiprot=(9,-2,-6)))
    pose(c,32,dict(hip=(0,0,-0.014*k),hiprot=(2,0,-1),spine=(2,0,0),head=(4,0,-2)))
    pose(c,48,st)
    def p(dz,press=0): return Tgt(sw+V((0.0,0.03,0.075+dz-press)),(0.05,-0.55,-0.83),(0.2,-0.5,0.25),pole=(-0.6,0.5,-0.4))
    c.k('fingR',0,*RELAX); c.k('fingR',12,*POINT); c.k('fingR',30,*POINT); c.k('fingR',40,*RELAX); c.k('fingR',48,*RELAX)
    c.arm(-1,0,Hang()); c.arm(-1,8,Hang(swing=14,abd=12,elbow=40))
    c.arm(-1,16,p(0.03)); c.arm(-1,20,p(0,0.0)); c.arm(-1,23,p(0,0.012)); c.arm(-1,27,p(0.02))
    c.arm(-1,36,Hang(swing=8,abd=10,elbow=28)); c.arm(-1,48,Hang())
    c.props.append(Prop('Desk','desk',(1.2,0.6,0.74*k),Mt((0,-0.62*k,0)),'#B08A62'))
    c.props.append(Prop('Lamp','lamp',(0.12,0.12,0.40),Mt((sw.x,sw.y,0.74*k)),'#E6B655',anim=lambda f:(1.0 if f>=23 else 0.0)))
    c.meta['switch_local_godot']=[round(-sw.x,3) if False else round(sw.x,3),round(sw.z,3),round(-sw.y,3)]
    return c

def c_drink(rig):
    b=body(rig); k=b['k']; hd=b['head']; c=Clip('drink',96,notes='lift mug from desk, sip, put it back')
    mug=V((-0.15*k,-0.38*k,0.74*k)); mouth=V((-0.0,hd.y-0.16*k,hd.z+0.06*k))
    st=stand(k); pose(c,0,st)
    pose(c,8,dict(head=(12,0,-8),neck=(4,0,-3)))
    pose(c,20,dict(hip=(-0.01*k,0.01*k,-0.03*k),hiprot=(9,-2,-6),spine=(5,-2,-3),head=(14,0,-6)))
    pose(c,26,dict(hiprot=(10,-2,-6)))
    pose(c,40,dict(hip=(0,0,-0.012*k),hiprot=(0,0,0),spine=(1,0,0),chest=(0,0,0),uchest=(-2,0,0),neck=(0,0,0),head=(0,0,0)))
    pose(c,48,dict(uchest=(-3,0,0),neck=(-3,0,0),head=(-10,0,0)))
    pose(c,58,dict(uchest=(-3.5,0,0),neck=(-4,0,0),head=(-13,0,0)))
    pose(c,66,dict(uchest=(-2,0,0),neck=(1,0,0),head=(0,0,0)))
    pose(c,76,dict(hip=(-0.01*k,0.01*k,-0.03*k),hiprot=(9,-2,-6),spine=(5,-2,-3),head=(12,0,-6),neck=(3,0,-2)))
    pose(c,82,dict(hiprot=(9.5,-2,-6)))
    pose(c,96,st)
    # wrap grip around mug body: palm toward mug (+X for right hand), fingers forward
    def g(p,tilt=0):
        f=Rx(tilt)@V((0.25,-0.97,0)); n=Rx(tilt)@V((0.97,0.25,0))
        return Tgt(p+V((-0.045,0,0.05)),f,n,pole=(-0.6,0.3,-0.7))
    c.k('fingR',0,*RELAX); c.k('fingR',20,*SOFT); c.k('fingR',26,*GRIP); c.k('fingR',80,*GRIP); c.k('fingR',86,*SOFT); c.k('fingR',96,*RELAX)
    c.arm(-1,0,Hang()); c.arm(-1,10,Hang(swing=14,abd=12,elbow=40))
    c.arm(-1,20,g(mug+V((0,0,0.03)))); c.arm(-1,26,g(mug)); c.arm(-1,30,g(mug+V((0,0,-0.003))))
    c.arm(-1,40,g(mouth+V((-0.01,-0.06,-0.10)))); c.arm(-1,48,g(mouth+V((0,-0.005,-0.05)),tilt=-30)); c.arm(-1,58,g(mouth+V((0,0.0,-0.045)),tilt=-42))
    c.arm(-1,66,g(mouth+V((-0.01,-0.07,-0.12)),tilt=-5)); c.arm(-1,78,g(mug+V((0,0,0.02)))); c.arm(-1,82,g(mug))
    c.arm(-1,88,Hang(swing=10,abd=10,elbow=28)); c.arm(-1,96,Hang())
    c.arm(1,0,Hang()); c.arm(1,40,Hang(swing=2,abd=7,elbow=18)); c.arm(1,96,Hang())
    c.props.append(Prop('Desk','desk',(1.2,0.6,0.74*k),Mt((0,-0.60*k,0)),'#B08A62'))
    c.props.append(Prop('Mug','mug',(0.085,0.085,0.10),Mt(mug),'#F2E6D3',[(0,'world'),(28,'R'),(82,'world')]))
    return c

def c_shelve(rig):
    b=body(rig); k=b['k']; sh=b['sh']; c=Clip('shelve',80,notes='slide a held book onto a shelf at head height (rises onto toes)')
    slot=V((-0.08*k,-0.46*k,1.52*k))
    st=stand(k); pose(c,0,st)
    pose(c,8,dict(head=(-10,0,-4),neck=(-3,0,0),hip=(0,0,-0.025*k)))           # look up, slight dip (anticipation)
    pose(c,24,dict(hip=(-0.01*k,-0.03*k,0.02*k),hiprot=(-2,-2,-4),spine=(-2,-2,-3),uchest=(-4,0,0),head=(-16,0,-4),footL=(0.012*k,0,0,7,10,0),footR=(-0.012*k,0,0,-7,10,0)))
    pose(c,34,dict(hip=(-0.01*k,-0.04*k,0.025*k),footL=(0.012*k,0,0,7,12,0),footR=(-0.012*k,0,0,-7,12,0)))
    pose(c,44,dict(hip=(0,-0.01*k,-0.016*k),hiprot=(0,0,0),spine=(1,0,0),uchest=(-1,0,0),head=(-6,0,-2),footL=(0.012*k,0,0,7,0,0),footR=(-0.012*k,0,0,-7,0,0)))
    pose(c,50,dict(hip=(0,0,-0.02*k)))
    pose(c,80,st)
    def g(p): return Tgt(p+V((0.01,0.10,-0.0)),(0.1,-0.5,0.86),(0.95,0,0.2),pole=(-0.7,0.4,-0.5))
    held=V((-0.20*k,-0.22*k,1.0*k))
    c.k('fingR',0,*PINCH); c.k('fingR',34,*PINCH); c.k('fingR',40,*SOFT); c.k('fingR',80,*RELAX)
    c.arm(-1,0,g(held)); c.arm(-1,8,g(held+V((0,0,-0.02))))
    c.arm(-1,22,g(slot+V((0,0.12,-0.02)))); c.arm(-1,30,g(slot+V((0,0.02,0)))); c.arm(-1,34,g(slot))
    c.arm(-1,42,Tgt(slot+V((0.0,0.16,-0.08)),(0.1,-0.6,0.6),(0.9,0,0.2),pole=(-0.7,0.4,-0.5)))
    c.arm(-1,56,Hang(swing=8,abd=10,elbow=26)); c.arm(-1,80,Hang())
    c.arm(1,0,Hang()); c.arm(1,24,Hang(swing=-4,abd=12,elbow=16)); c.arm(1,44,Hang(swing=2,abd=7,elbow=14)); c.arm(1,80,Hang())
    c.props.append(Prop('Shelf','shelf',(0.9,0.30,1.9*k),Mt((0,slot.y-0.27,0)),'#B08A62'))
    c.props.append(Prop('Book','book',(0.03,0.16,0.22),Mt(held+V((0.02,0,0.01))),'#C9714F',[(0,'R'),(36,'world')]))
    return c

ALL=[c_pick_up,c_carry,c_set_down,c_push,c_open_box,c_sit,c_type,c_water,c_lamp_switch,c_drink,c_shelve,c_stand_up,c_idle,c_walk,c_carry_walk]
