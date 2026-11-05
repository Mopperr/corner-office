import sys,random,os,math
import numpy as np
sys.path.insert(0,os.path.dirname(__file__))
import painter as P
from painter import C,cr,hx
var=sys.argv[1]; out=sys.argv[2]; P.SS=int(os.environ.get('SS','4'))
cv=P.Canvas(900,1400); rng=random.Random(7)
k=0.68; cx,cy=450,235
def shade(m,col=C['sweater_sh'],dx=-14,dy=-4,r=14,a=0.75):
    cv.paint(m*(1-cv.blur(cv.shift(m,dx,dy),r)),col,a)
def rim(m,a=0.45,w=4): cv.paint(m*(1-cv.blur(cv.shift(m,w,1),2.5)),C['rim'],a)
def limb(pts,widths,n=14):
    path=cr(pts,False,n); W=np.interp(np.linspace(0,1,len(path)),np.linspace(0,1,len(widths)),widths)
    L=[];Rr=[]
    for i,p in enumerate(path):
        q=path[min(i+1,len(path)-1)]-path[max(i-1,0)]; nrm=np.array([-q[1],q[0]])/ (np.linalg.norm(q)+1e-9)
        L.append(tuple(p+nrm*W[i]/2)); Rr.append(tuple(p-nrm*W[i]/2))
    return cv.poly(L+Rr[::-1],blur=0.4)
def hand(x,y,ang,sc=1.0,fingers=True):
    m=cv.ell(x,y,13*sc,16*sc,blur=0.4)
    if fingers:
        for i in range(4):
            a=math.radians(ang+(i-1.5)*13); fx=x+math.sin(a)*14*sc; fy=y+math.cos(a)*14*sc
            m=np.maximum(m,limb([(fx,fy),(fx+math.sin(a)*13*sc,fy+math.cos(a)*13*sc)],[7.5*sc,6*sc],4))
    cv.paint(m,C['skin']); shade(m,C['skin_sh'],-6,-4,5,0.6); rim(m,0.4,2)
    return m
# back hair
P.draw_head(cv,cx,cy,k,var,random.Random(7),'back')
# trousers: high-waisted wide-leg, weight on her left (viewer right) leg
hipx=462
tl=[(hipx-82,650),(hipx-92,760),(hipx-102,960),(hipx-110,1250),(hipx-26,1254),(hipx-12,960),(hipx+2,780)]
tr=[(hipx+82,650),(hipx+90,760),(hipx+96,960),(hipx+102,1250),(hipx+18,1254),(hipx+10,960),(hipx-2,780)]
waist=[(hipx-74,630),(hipx+74,630),(hipx+86,700),(hipx+40,800),(hipx-40,800),(hipx-86,700)]
tm=np.maximum(np.maximum(cv.poly(cr(tl),blur=0.4),cv.poly(cr(tr),blur=0.4)),cv.poly(cr(waist),blur=0.4))
# loafers
for x0,x1 in ((hipx-112,hipx-24),(hipx+18,hipx+108)):
    sm=cv.poly(cr([(x0-4,1248),(x1+4,1248),(x1+10,1280),(x1,1298),(x0,1298),(x0-10,1280)]),blur=0.4)
    cv.paint(sm,C['shoe']); cv.paint(sm*cv.ell((x0+x1)/2-10,1265,24,6,blur=4),hx('#9A7058'),0.7)
cv.paint(tm,C['trouser']); shade(tm,C['trouser_sh'],-18,-2,16,0.85); rim(tm,0.4)
for pts in ([(hipx-60,790),(hipx-70,1000),(hipx-66,1230)],[(hipx+50,800),(hipx+58,1040),(hipx+62,1230)],[(hipx-20,700),(hipx-6,760)]):
    cv.paint(cv.line(cr(pts,False),3,blur=3)*tm,C['trouser_sh'],0.55)
cv.paint(cv.line([(hipx,640),(hipx,780)],1.5,blur=0.6)*tm,C['trouser_sh'],0.6)
# torso: fitted, cropped sweater with defined waist and sloped shoulders
tor=[(cx-30,345),(cx-70,358),(cx-102,384),(cx-100,450),(cx-84,540),(cx-66,610),(cx-76,668),(cx+82,668),(cx+72,610),(cx+86,540),(cx+102,450),(cx+104,384),(cx+72,358),(cx+30,345)]
sw=cv.poly(cr(tor),blur=0.4)
cv.paint(sw,C['sweater']); shade(sw,C['sweater_sh'],-18,-4,18,0.8)
cv.paint(sw*cv.ell(cx-40,430,50,40,blur=24),C['sweater_hi'],0.5); rim(sw)
for i in range(-10,11):
    x=cx+i*9; cv.paint(cv.line([(x,370),(x+i*0.6,668)],1.3,blur=0.6)*sw,C['sweater_sh'],0.22)
hem=cv.poly(cr([(cx-76,650),(cx+82,650),(cx+84,672),(cx-78,672)]),blur=0.4)*sw
cv.paint(hem,C['sweater_sh'],0.35)
for pts in ([(cx-62,600),(cx-20,615),(cx+30,612)],[(cx+70,590),(cx+40,620)],[(cx-50,470),(cx-30,520)]):
    cv.paint(cv.line(cr(pts,False),3,blur=3)*sw,C['sweater_sh'],0.55)
# her left arm (viewer right): relaxed, hand by thigh, watch
ra=limb([(cx+72,380),(cx+98,470),(cx+106,560),(cx+102,680)],[48,38,32,26])
cv.paint(ra,C['sweater']); shade(ra,C['sweater_sh'],-10,0,10,0.75); rim(ra,0.5)
cv.paint(cv.line(cr([(cx+90,540),(cx+114,556)],False),3,blur=2.5)*ra,C['sweater_sh'],0.6)
cuff=limb([(cx+102,668),(cx+102,690)],[28,28]); cv.paint(cuff,C['sweater']); shade(cuff,C['sweater_sh'],0,-4,3,0.6)
wr=limb([(cx+102,688),(cx+102,705)],[17,15]); cv.paint(wr,C['skin'])
cv.paint(limb([(cx+102,694),(cx+102,700)],[19,19]),C['gold'])
hand(cx+102,722,0,1.0)
# head + collar
P.draw_head(cv,cx,cy,k,var,rng,'front')
P.draw_collar(cv,cx,cy+8,k*0.85)
# box at her right hip (viewer left), held by her right arm
bx0,by0,bw,bh,bd=262,640,160,130,50
front=cv.poly([(bx0,by0+bd*0.5),(bx0+bw,by0+bd*0.5+12),(bx0+bw,by0+bd*0.5+12+bh),(bx0,by0+bd*0.5+bh)],blur=0.3)
top=cv.poly([(bx0,by0+bd*0.5),(bx0+bd*0.9,by0-bd*0.2),(bx0+bw+bd*0.9,by0-bd*0.2+12),(bx0+bw,by0+bd*0.5+12)],blur=0.3)
side=cv.poly([(bx0+bw,by0+bd*0.5+12),(bx0+bw+bd*0.9,by0-bd*0.2+12),(bx0+bw+bd*0.9,by0-bd*0.2+12+bh),(bx0+bw,by0+bd*0.5+12+bh)],blur=0.3)
cv.paint(side,C['box_sh']); cv.paint(top,hx('#E6BC86')); cv.paint(front,C['box'])
cv.paint(front*cv.vgrad(by0,by0+bh+40,np.zeros(3),np.ones(3))[...,0],C['box_sh'],0.35)
cv.paint(cv.poly([(bx0+bw*0.5-14,by0+bd*0.5+6),(bx0+bw*0.5+14,by0+bd*0.5+6),(bx0+bw*0.5+14,by0+bd*0.5+40),(bx0+bw*0.5-14,by0+bd*0.5+40)])*front,C['tape'],0.9)
for (x,y,s_,col,ang) in ((bx0+30,by0+70,30,C['ns'],-6),(bx0+110,by0+100,28,C['ny'],5),(bx0+60,by0+125,24,C['npk'],8)):
    pts=[(x+math.cos(math.radians(ang))*dx-math.sin(math.radians(ang))*dy,y+math.sin(math.radians(ang))*dx+math.cos(math.radians(ang))*dy) for dx,dy in ((0,0),(s_,0),(s_,s_),(0,s_))]
    nm=cv.poly(pts,blur=0.3); cv.paint(cv.blur(cv.shift(nm,2,3),2)*front,C['box_sh'],0.5); cv.paint(nm,col)
# plant + mug on top
pot=cv.poly(cr([(bx0+110,by0-6),(bx0+140,by0-6),(bx0+136,by0+22),(bx0+114,by0+22)]),blur=0.3); cv.paint(pot,hx('#D9765F'))
for dx,dy,r in ((0,-20,16),(-14,-12,12),(14,-14,12),(4,-34,11)):
    lm=cv.ell(bx0+125+dx,by0+dy,r,r*0.8,blur=0.4); cv.paint(lm,C['ns']); cv.paint(lm*cv.ell(bx0+120+dx,by0+dy-4,r*0.5,r*0.4,blur=3),hx('#B5CFA5'),0.7)
mug=cv.poly(cr([(bx0+46,by0-4),(bx0+80,by0-4),(bx0+80,by0+26),(bx0+46,by0+26)]),blur=0.3); cv.paint(mug,C['cream']); shade(mug,C['cream_sh'],-5,0,4,0.6)
cv.paint(cv.ell(bx0+63,by0-4,17,4),hx('#6B4A3A'))
# her right arm wrapping the box
la=limb([(cx-72,380),(cx-100,480),(cx-118,575),(bx0+110,by0+20),(bx0+70,by0+60)],[44,38,32,28,24],12)
cv.paint(la,C['sweater']); shade(la,C['sweater_sh'],-8,-6,10,0.75); rim(la,0.4)
cv.paint(cv.line(cr([(cx-122,555),(cx-104,585)],False),3,blur=2.5)*la,C['sweater_sh'],0.6)
hand(bx0+58,by0+78,20,1.05)
cv.rgb=np.roll(cv.rgb,int(30*P.SS),0); cv.a=np.roll(cv.a,int(30*P.SS),0)
cv.out(900,1400).save(out)
