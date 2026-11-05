"""Painterly 2D Dana (v3). Supersampled Pillow+numpy painting: catmull-rom shapes,
soft blurred shading ramps, strand strokes, rim light. Variations a/b/c."""
import numpy as np, math, sys, random
from PIL import Image, ImageDraw, ImageFilter
SS=4
def hx(h):
    h=h.lstrip('#'); return np.array([int(h[i:i+2],16) for i in (0,2,4)],float)/255
def cr(pts,closed=True,n=16):
    P=[np.array(p,float) for p in pts]; out=[]; m=len(P)
    rng=range(m) if closed else range(m-1)
    for i in rng:
        p0=P[(i-1)%m] if closed or i>0 else P[i]; p1=P[i]; p2=P[(i+1)%m]; p3=P[(i+2)%m] if closed or i+2<m else P[(i+1)%m]
        for t in np.linspace(0,1,n,endpoint=False):
            t2,t3=t*t,t*t*t
            out.append(0.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t2+(-p0+3*p1-3*p2+p3)*t3))
    if not closed: out.append(P[-1])
    return out
class Canvas:
    def __init__(s,w,h):
        s.w,s.h=w*SS,h*SS; s.rgb=np.zeros((s.h,s.w,3)); s.a=np.zeros((s.h,s.w))
    def mask(s,fn,blur=0):
        im=Image.new('L',(s.w,s.h),0); d=ImageDraw.Draw(im); fn(d)
        if blur: im=im.filter(ImageFilter.GaussianBlur(blur*SS))
        return np.asarray(im,float)/255
    def poly(s,pts,blur=0): return s.mask(lambda d:d.polygon([(x*SS,y*SS) for x,y in pts],fill=255),blur)
    def ell(s,cx,cy,rx,ry,blur=0): return s.mask(lambda d:d.ellipse([(cx-rx)*SS,(cy-ry)*SS,(cx+rx)*SS,(cy+ry)*SS],fill=255),blur)
    def line(s,pts,w,blur=0): return s.mask(lambda d:d.line([(x*SS,y*SS) for x,y in pts],fill=255,width=max(1,int(w*SS)),joint='curve'),blur)
    def paint(s,m,col,alpha=1.0):
        a=np.clip(m*alpha,0,1)[...,None]; c=col if isinstance(col,np.ndarray) and col.ndim==3 else np.array(col)
        s.rgb=s.rgb*(1-a)+c*a; s.a=s.a+(1-s.a)*a[...,0]
    def vgrad(s,y0,y1,c0,c1):
        t=np.clip((np.arange(s.h)/SS-y0)/(y1-y0),0,1)[:,None,None]; return np.broadcast_to(c0*(1-t)+c1*t,(s.h,s.w,3))
    def rgrad(s,cx,cy,r,c0,c1):
        yy,xx=np.mgrid[0:s.h,0:s.w]/SS; t=np.clip(np.hypot(xx-cx,yy-cy)/r,0,1)[...,None]; return c0*(1-t)+c1*t
    def shift(s,m,dx,dy): return np.roll(np.roll(m,int(dy*SS),0),int(dx*SS),1)
    def blur(s,m,r): return np.asarray(Image.fromarray((m*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r*SS)),float)/255
    def out(s,w,h):
        im=np.dstack([np.clip(s.rgb,0,1),np.clip(s.a,0,1)[...,None]])
        # un-premultiply not needed (straight colour); downsample with alpha weighting
        img=Image.fromarray((im*255).astype(np.uint8),'RGBA')
        return img.resize((w,h),Image.LANCZOS)

C=dict(skin=hx('#E9C3A6'),skin_hi=hx('#F2D6C2'),skin_sh=hx('#C9907A'),skin_deep=hx('#A86A5C'),blush=hx('#E8A6A0'),
 hair=hx('#5A3A2A'),hair_mid=hx('#8A5A3C'),hair_hi=hx('#C08A5A'),hair_dk=hx('#3A241A'),
 brow=hx('#4A3226'),lash=hx('#2A1A14'),sclera=hx('#F7F1EA'),iris_dk=hx('#5A3418'),iris=hx('#7A4E2D'),iris_lt=hx('#A8743F'),iris_gn=hx('#8C7A3E'),
 lip=hx('#C97A7E'),lip_dk=hx('#A85A60'),lip_hi=hx('#E3A3A3'),sweater=hx('#7FA3B8'),sweater_sh=hx('#5E7F96'),sweater_hi=hx('#A3C2D3'),
 cream=hx('#F4E9D8'),cream_sh=hx('#D9C9B0'),gold=hx('#C9A24A'),gold_hi=hx('#F0D58A'),rim=hx('#FFD9A8'),
 trouser=hx('#D8C3A5'),trouser_sh=hx('#B8A080'),shoe=hx('#6B4A3A'),box=hx('#D9A86C'),box_sh=hx('#B8834C'),tape=hx('#E8D5A8'),
 ny=hx('#E6B655'),ns=hx('#8FAF7E'),npk=hx('#E8B4A8'),frame=hx('#4A3226'),pencil=hx('#E6B655'))

def strands(cv,mask,curves,cols,widths,alpha):
    for pts,col,w in zip(curves,cols,widths):
        cv.paint(cv.line(cr(pts,False,10),w,blur=0.4)*mask,col,alpha)

def T(cx,cy,k,pts): return [(cx+x*k,cy+y*k) for x,y in pts]

def draw_head(cv,cx,cy,k,var,rng,stage='all'):
    t=lambda pts:T(cx,cy,k,pts)
    if stage!='front':
        # ---------- BACK HAIR ----------
        if var=='a':
            back=[(-114,-30),(-112,-120),(-70,-178),(0,-196),(70,-178),(112,-120),(116,-30),(98,40),(-98,40)]
        elif var=='b':
            R_=[(124,-20),(136,40),(128,90),(150,140),(140,190),(162,240),(150,290),(168,330),(120,340)]
            back=[(-118,-30),(-116,-125),(-70,-182),(0,-198),(70,-182),(116,-125)]+R_+[(60,250),(-60,250)]+[(-x,y) for x,y in reversed(R_)]
        else:
            back=[(-118,-30),(-114,-125),(-70,-182),(0,-198),(70,-182),(114,-125),(126,-10),(132,70),(128,108),(104,120),(80,112),(-80,112),(-104,120),(-128,108),(-132,70),(-126,-10)]
        bm=cv.poly(t(cr(back)),blur=0.6*k)
        cv.paint(bm,C['hair_dk'])
        cv.paint(bm*cv.blur(cv.shift(bm,-14*k,6*k),8*k),C['hair'],0.85)
        if var=='a':  # messy bun + pencil
            bun=cv.ell(cx+8*k,cy-212*k,54*k,44*k,blur=0.6*k)
            for dx,dy,r in ((-38,-6,26),(40,-12,24),(-10,-38,24),(22,-36,20)):
                bun=np.maximum(bun,cv.ell(cx+(8+dx)*k,cy+(-212+dy)*k,r*k,r*0.85*k,blur=0.6*k))
            cv.paint(bun,C['hair'])
            cv.paint(bun*cv.blur(cv.shift(bun,-10*k,10*k),8*k),C['hair_mid'],0.6)
            loops=[[(-30,-200),(-10,-235),(30,-240),(50,-215),(30,-190)],[(-40,-215),(-20,-245),(15,-250)],[(0,-185),(25,-205),(55,-195)],[(-45,-195),(-25,-225),(5,-228)]]
            strands(cv,bun,[T(cx+8*k,cy,k,[(x,y+0) for x,y in l]) for l in loops],[C['hair_dk'],C['hair_hi'],C['hair_dk'],C['hair_mid']],[2.2*k,1.6*k,2*k,1.6*k],0.7)
            # flyaways
            for pts in ([(-30,-250),(-48,-266),(-62,-262)],[(46,-244),(66,-262),(80,-258)]):
                cv.paint(cv.line(t(cr(pts,False)),1.2*k,blur=0.3),C['hair_mid'],0.8)
            # pencil
            p0=np.array([cx-50*k,cy-188*k]); p1=np.array([cx+70*k,cy-262*k])
            cv.paint(cv.line([tuple(p0),tuple(p1)],9*k,blur=0.3),C['pencil'])
            cv.paint(cv.line([tuple(p0+(p1-p0)*0.02),tuple(p1-(p1-p0)*0.02)],2.5*k,blur=0.6),C['gold_hi'],0.6)
            tip=p1+(p1-p0)/np.linalg.norm(p1-p0)*14*k
            cv.paint(cv.line([tuple(p1),tuple(tip)],7*k,blur=0.3),hx('#E8C9A0'))
            cv.paint(cv.line([tuple(p1+(tip-p1)*0.6),tuple(tip)],3*k,blur=0.3),hx('#3A2E28'))
            # re-cover pencil middle with bun strands (tucked)
            cv.paint(cv.ell(cx-2*k,cy-222*k,26*k,20*k,blur=1.5*k),C['hair'],0.95)
            strands(cv,cv.ell(cx-2*k,cy-222*k,26*k,20*k),[t([(-24,-230),(-2,-240),(20,-226)])],[C['hair_hi']],[1.6*k],0.6)
        if var=='b':  # wavy strand lines on back hair
            for i in range(30):
                sd=rng.choice([-1,1]); x0=sd*rng.uniform(110,140); pts=[(x0,-10)]
                for j in range(1,6): pts.append((x0+sd*j*6+10*math.sin(j*1.7+i),-10+j*55))
                cv.paint(cv.line(t(cr(pts,False)),rng.uniform(1,2)*k,blur=0.4)*bm,rng.choice([C['hair_mid'],C['hair_hi'],C['hair_dk']]),0.5)
    if stage=='back': return
    # ---------- NECK ----------
    neck=cv.poly(t(cr([(-42,60),(42,60),(44,140),(54,190),(-54,190),(-44,140)])),blur=0.5*k)
    cv.paint(neck,C['skin'])
    cv.paint(neck*cv.vgrad(0,1,1,1)[...,0]*cv.blur(cv.ell(cx,cy+95*k,80*k,40*k),14*k),C['skin_sh'],0.85)
    # ---------- FACE ----------
    face_pts=[(-98,-110),(-106,-20),(-100,40),(-80,92),(-44,128),(4,146),(48,126),(82,90),(100,38),(104,-20),(96,-110),(0,-150)]
    fm=cv.poly(t(cr(face_pts)),blur=0.5*k)
    cv.paint(fm,C['skin'])
    # form shading: shadow on (viewer) right side & under cheekbones; highlights
    inner=cv.blur(cv.shift(fm,-16*k,-6*k),18*k)
    cv.paint(fm*(1-inner),C['skin_sh'],0.75)
    cv.paint(fm*cv.ell(cx+70*k,cy+60*k,34*k,46*k,blur=18*k),C['skin_sh'],0.35)
    cv.paint(fm*(1-cv.blur(cv.shift(fm,5*k,0),3*k)),C['rim'],0.6)
    for (x,y,rx,ry,a) in ((-40,-70,60,34,0.45),(-55,10,26,18,0.35),(4,-6,7,40,0.55),(4,92,22,10,0.25)):
        cv.paint(fm*cv.ell(cx+x*k,cy+y*k,rx*k,ry*k,blur=10*k),C['skin_hi'],a)
    # blush
    for x in (-60,62):
        cv.paint(fm*cv.ell(cx+x*k,cy+42*k,32*k,20*k,blur=11*k),C['blush'],0.7)
    cv.paint(fm*cv.ell(cx+6*k,cy+40*k,10*k,7*k,blur=5*k),C['blush'],0.4)
    # freckles
    for _ in range(14):
        fx=rng.uniform(-70,70); fy=rng.uniform(25,48)
        if abs(fx)<14: continue
        cv.paint(fm*cv.ell(cx+fx*k,cy+fy*k,1.3*k,1.3*k,blur=0.6*k),C['skin_sh'],0.35)
    # ears (only partly visible under hair)
    # ---------- EYES ----------
    k0=k
    for side in (-1,1):
        k=k0*1.17; ex=cx+side*47*k0+4*k0; ey=cy+6*k0
        al=[(-side*30,2),(-side*16,-14),(side*6,-17),(side*30,-8),(side*16,9),(-side*8,11)]
        al=[(x,y) for x,y in al]
        alm=cv.poly(T(ex,ey,k,cr(al)),blur=0.3*k)
        cv.paint(alm,C['sclera'])
        cv.paint(alm*cv.blur(cv.shift(alm,0,8*k),5*k)*0+alm*(1-cv.blur(cv.shift(alm,0,6*k),4*k)),C['skin_sh'],0.55)
        ix=ex+2*k; iy=ey-2*k; R=15.5*k
        irm=cv.ell(ix,iy,R,R)*alm
        cv.paint(irm,cv.rgrad(ix,iy+4*k,R,C['iris_lt'],C['iris_dk']))
        cv.paint(irm*cv.ell(ix,iy+6*k,R*0.7,R*0.5,blur=3*k),C['iris_gn'],0.35)
        ring=cv.ell(ix,iy,R,R)-cv.ell(ix,iy,R-2.5*k,R-2.5*k,blur=1*k)
        cv.paint(np.clip(ring,0,1)*alm,C['iris_dk'],0.9)
        cv.paint(cv.ell(ix,iy,6.2*k,6.2*k,blur=0.4*k)*alm,hx('#1A100C'))
        cv.paint(alm*(1-cv.blur(cv.shift(alm,0,10*k),3*k)),C['iris_dk'],0.45)  # lid shadow on iris
        cv.paint(cv.ell(ix+6*k,iy-6*k,4.6*k,4.2*k,blur=0.3*k)*alm,hx('#FFFFFF'))
        cv.paint(cv.ell(ix-5*k,iy+6*k,2.2*k,2.2*k,blur=0.3*k)*alm,hx('#FFFFFF'),0.9)
        # upper lash line with wing (tapered)
        top=[(-side*31,3),(-side*16,-14),(side*6,-17.5),(side*30,-8.5),(side*40,-15)]
        up=cv.line(T(ex,ey,k,cr(top,False,12)),3.6*k,blur=0.3*k)
        cv.paint(up,C['lash'])
        cv.paint(cv.line(T(ex,ey,k,cr([(side*14,-16),(side*32,-9),(side*43,-17)],False)),2.2*k,blur=0.3*k),C['lash'])
        for j in range(4):  # a few lashes at outer corner
            bx=side*(18+j*5); by=-15+j*2
            cv.paint(cv.line(T(ex,ey,k,[(bx,by),(bx+side*5,by-6)]),1.2*k,blur=0.2*k),C['lash'],0.85)
        low=[(-side*26,5),(-side*6,11.5),(side*14,9.5),(side*28,-4)]
        cv.paint(cv.line(T(ex,ey,k,cr(low,False)),1.2*k,blur=0.5*k),C['skin_deep'],0.55)
        # crease
        cv.paint(cv.line(T(ex,ey,k,cr([(-side*20,-20),(side*4,-27),(side*26,-20)],False)),1.6*k,blur=1*k)*fm,C['skin_sh'],0.6)
        # brows: groomed, gently arched, tapered
        bpts=[(-side*30,-42),(-side*8,-52),(side*16,-53),(side*36,-44)]
        for wdt,a in ((5,0.75),(3.5,0.45)):
            cv.paint(cv.line(T(ex,ey,k,cr(bpts,False)),wdt*k*(1 if wdt>5 else 1),blur=0.8*k),C['brow'],a)
        cv.paint(cv.line(T(ex,ey,k,cr([(side*20,-52),(side*36,-44),(side*44,-37)],False)),2.4*k,blur=0.8*k),C['brow'],0.6)
    k=k0
    # ---------- NOSE ----------
    cv.paint(cv.line(t(cr([(18,-20),(16,20),(12,48)],False)),3*k,blur=3*k)*fm,C['skin_sh'],0.5)
    cv.paint(cv.ell(cx+4*k,cy+50*k,11*k,8*k,blur=4*k)*fm,C['skin_hi'],0.6)
    cv.paint(cv.line(t(cr([(-10,58),(-4,62),(4,62),(14,58)],False)),2.6*k,blur=1.4*k),C['skin_deep'],0.75)
    cv.paint(cv.ell(cx+4*k,cy+67*k,16*k,4*k,blur=3*k)*fm,C['skin_sh'],0.35)
    # ---------- LIPS ----------
    mx,my=cx+5*k,cy+92*k
    upl=[(-33,-11),(-15,-10),(-4,-8),(0,-6),(4,-8),(15,-10),(33,-12),(15,-1),(0,1),(-15,-1)]
    lol=[(-30,-9),(-13,9),(4,13),(19,8),(31,-10),(15,0),(0,2),(-15,0)]
    um=cv.poly(T(mx,my,k,cr(upl)),blur=0.4*k); lm=cv.poly(T(mx,my,k,cr(lol)),blur=0.4*k)
    cv.paint(um,C['lip_dk']); cv.paint(lm,C['lip'])
    cv.paint(lm*cv.ell(mx+2*k,my+7*k,10*k,3.5*k,blur=2.5*k),C['lip_hi'],0.8)
    cv.paint(cv.line(T(mx,my,k,cr([(-34,-12),(-17,-1),(0,1.5),(17,-1),(34,-13)],False)),1.8*k,blur=0.5*k),hx('#8A4A4E'),0.9)
    for sd in (-1,1):
        cv.paint(cv.ell(mx+sd*37*k,my-12*k,4*k,3*k,blur=2*k)*fm,C['skin_sh'],0.5)  # smile dimples
    cv.paint(cv.ell(mx,my+24*k,14*k,5*k,blur=4*k)*fm,C['skin_sh'],0.3)
    # ---------- FRONT HAIR ----------
    cap=[(-112,-20),(-108,-120),(-60,-176),(0,-190),(60,-176),(108,-120),(114,-20),(102,-40),(84,-96),(40,-128),(4,-136),(-36,-128),(-82,-96),(-102,-40)]
    if var=='c':
        cap=[(-118,88),(-122,20),(-114,-60),(-104,-136),(-60,-182),(0,-194),(60,-182),(104,-136),(116,-60),(124,20),(122,90),(106,108),(92,96),(96,10),(80,-80),(20,-118),(-40,-110),(-80,-90),(-104,-20),(-96,96),(-106,108)]
    hm=cv.poly(t(cr(cap)),blur=0.5*k)
    bangs=[]
    if var in ('a','b'):
        for sd in (-1,1):  # curtain bangs
            bangs.append([(sd*2,-140),(sd*36,-124),(sd*74,-86),(sd*96,-30),(sd*100,20),(sd*94,-20),(sd*76,-66),(sd*44,-100),(sd*12,-122)])
            lo=40 if var=='a' else 160
            bangs.append([(sd*100,-60),(sd*110,0),(sd*104,lo*0.5),(sd*108,lo),(sd*100,lo*0.6),(sd*94,0)])
    else:
        bangs.append([(-10,-140),(30,-126),(70,-96),(98,-50),(104,-10),(86,-50),(50,-88),(10,-110),(-30,-112),(-70,-96),(-96,-60),(-74,-104),(-40,-128)])
    for b in bangs: hm=np.maximum(hm,cv.poly(t(cr(b)),blur=0.5*k))
    # cast shadow of hair on face (soft)
    cv.paint(fm*cv.blur(cv.shift(hm,4*k,9*k),6*k)*(1-hm),C['skin_sh'],0.5)
    cv.paint(hm,C['hair'])
    cv.paint(hm*cv.blur(cv.shift(hm,10*k,12*k),12*k)*cv.vgrad(cy-200*k/k*0+ (cy-200*k)/1 ,cy,np.ones(3),np.zeros(3))[...,0]*0,C['hair_mid'],0)
    # sheen band + mid tones
    cv.paint(hm*cv.ell(cx-30*k,cy-150*k,70*k,22*k,blur=12*k),C['hair_mid'],0.75)
    cv.paint(hm*cv.ell(cx-36*k,cy-152*k,40*k,8*k,blur=6*k),C['hair_hi'],0.7)
    cv.paint(hm*(1-cv.blur(cv.shift(hm,-8*k,0),6*k)),C['hair_dk'],0.5)
    # rim light (warm) on viewer-right edge
    cv.paint(hm*(1-cv.blur(cv.shift(hm,7*k,2*k),3*k)),C['rim'],0.55)
    # strand lines following flow from part
    curves=[];cols=[];wid=[]
    for i in range(46):
        sd=rng.choice([-1,1]); off=rng.uniform(0,1)
        if var=='c' and rng.random()<0.6: sd=1
        x0=sd*rng.uniform(0,10); y0=-150+rng.uniform(-30,10)
        x1=sd*(30+off*70); y1=-120+off*40
        x2=sd*(70+off*40); y2=-60+off*80 + (rng.uniform(0,90) if var!='a' else rng.uniform(0,30))
        curves.append(t([(x0,y0),(x1,y1),(x2,y2)])); cols.append(rng.choice([C['hair_dk'],C['hair_mid'],C['hair_hi']])); wid.append(rng.uniform(0.8,1.6)*k)
    strands(cv,hm,curves,cols,wid,0.5)
    # wisps
    if var=='a':
        for sd in (-1,1):
            cv.paint(cv.line(t(cr([(sd*96,-10),(sd*104,40),(sd*98,75)],False)),3.2*k,blur=1.2*k),C['hair_mid'],0.75)
    # hoops
    if var in ('a','b'):
        for sd in (-1,1):
            hxp,hyp=cx+sd*104*k,cy+48*k
            ring=cv.ell(hxp,hyp,9*k,11*k)-cv.ell(hxp,hyp,6.5*k,8.5*k)
            cv.paint(np.clip(ring,0,1),C['gold']); cv.paint(np.clip(ring,0,1)*cv.ell(hxp-4*k,hyp-4*k,4*k,4*k,blur=2*k),C['gold_hi'],0.9)
    # glasses
    if var=='c':
        for sd in (-1,1):
            ex=cx+sd*48*k+4*k; ey=cy+6*k
            outer=cv.mask(lambda d:d.rounded_rectangle([(ex-38*k)*SS,(ey-26*k)*SS,(ex+38*k)*SS,(ey+26*k)*SS],radius=int(22*k*SS),fill=255))
            inner=cv.mask(lambda d:d.rounded_rectangle([(ex-34.5*k)*SS,(ey-22.5*k)*SS,(ex+34.5*k)*SS,(ey+22.5*k)*SS],radius=int(19*k*SS),fill=255))
            cv.paint(inner*cv.ell(ex-16*k,ey-14*k,14*k,5*k,blur=4*k),hx('#FFFFFF'),0.25)
            cv.paint(np.clip(outer-inner,0,1),C['frame'])
            cv.paint(np.clip(outer-inner,0,1)*cv.ell(ex-20*k,ey-22*k,16*k,6*k,blur=4*k),C['gold_hi'],0.5)
        cv.paint(cv.line(t(cr([(-6,0),(4,-6),(14,0)],False)),3.5*k,blur=0.3),C['frame'])

def draw_shoulders(cv,cx,cy,k,top_y,part='body'):
    t=lambda pts:T(cx,cy,k,pts)
    if part=='collar': return draw_collar(cv,cx,cy,k)
    sw=[(-60,180),(-130,210),(-205,253),(-238,318),(-250,460),(250,460),(238,318),(205,253),(130,210),(60,180)]
    sm=cv.poly(t(cr(sw)),blur=0.5*k)
    cv.paint(sm,C['sweater'])
    cv.paint(sm*(1-cv.blur(cv.shift(sm,-20*k,-6*k),22*k)),C['sweater_sh'],0.8)
    cv.paint(sm*cv.ell(cx-90*k,cy+270*k,90*k,30*k,blur=24*k),C['sweater_hi'],0.6)
    # knit ribs
    for i in range(-24,25):
        x=i*10
        cv.paint(cv.line(t([(x,240+abs(x)*0.15),(x*1.04,460)]),1.6*k,blur=0.8*k)*sm,C['sweater_sh'],0.25)
    cv.paint(sm*(1-cv.blur(cv.shift(sm,6*k,2*k),3*k)),C['rim'],0.4)
    # fold lines
    for pts in ([(-150,330),(-120,380),(-128,450)],[(140,320),(118,390)],[(-60,300),(-30,360)]):
        cv.paint(cv.line(t(cr(pts,False)),4*k,blur=3*k)*sm,C['sweater_sh'],0.5)
def draw_collar(cv,cx,cy,k):
    t=lambda pts:T(cx,cy,k,pts); sm=1
    for sd in (-1,1):
        col=[(0,186),(sd*30,176),(sd*62,182),(sd*86,204),(sd*70,230),(sd*36,236),(sd*6,216)]
        cm=cv.poly(t(cr(col)),blur=0.5*k)
        cv.paint(cv.blur(cv.shift(cm,0,5*k),4*k)*sm,C['sweater_sh'],0.5)
        cv.paint(cm,C['cream']); cv.paint(cm*(1-cv.blur(cv.shift(cm,-4*k,-4*k),4*k)),C['cream_sh'],0.7)
