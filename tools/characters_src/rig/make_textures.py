"""Tileable fabric/hair maps + Dana face atlas.  python3 make_textures.py"""
import numpy as np, os
from PIL import Image, ImageDraw, ImageFilter
A=os.path.abspath(os.path.join(os.path.dirname(__file__),"../.."))
T=f"{A}/textures/characters"; os.makedirs(T,exist_ok=True)
def nmap(h,strength):
    gy,gx=np.gradient(h); n=np.dstack([-gx*strength,gy*strength,np.ones_like(h)]); n/=np.linalg.norm(n,axis=2,keepdims=True)
    return Image.fromarray(((n*0.5+0.5)*255).astype(np.uint8))
N=512; u,v=np.meshgrid(np.arange(N)/N,np.arange(N)/N)
rng=np.random.default_rng(3)
def tnoise(scale,seed):
    r=np.random.default_rng(seed).random((scale,scale)); im=Image.fromarray((r*255).astype(np.uint8)).resize((N,N),Image.BICUBIC)
    return np.asarray(im)/255.0
# knit: 6 ribs per tile (tile = 3.6 cm -> 6 mm ribs), stockinette V stitches 10 rows
rib=u*6%1; row=v*12%1
vst=np.abs((rib-0.5)*2)  # 0 centre ..1 edge
chev=np.clip(1-np.abs(row-0.5-0.35*(vst-0.5))*2.2,0,1)
h=0.55*np.sin(np.pi*rib)**0.6+0.35*chev*np.sin(np.pi*rib)+0.08*tnoise(64,1)
nmap(h*6,1.0).save(f"{T}/knit_rib_n.png")
# fine knit (cardigan/hoodie jersey): small stitches
h=0.5*np.sin(np.pi*(u*14%1))**0.7*(0.6+0.4*np.sin(np.pi*(v*24%1)))+0.1*tnoise(96,2); nmap(h*4,1.0).save(f"{T}/jersey_n.png")
# twill (trousers): diagonal fine wale, tile 1.6 cm
d=(u*20+v*20)%1; h=0.6*np.sin(np.pi*d)**1.5+0.15*tnoise(128,3); nmap(h*3,1.0).save(f"{T}/twill_n.png")
# corduroy: vertical wales
h=np.sin(np.pi*(u*8%1))**0.5+0.05*tnoise(64,4); nmap(h*5,1.0).save(f"{T}/cord_n.png")
# leather / shoe micro
h=tnoise(48,5)*0.6+tnoise(160,6)*0.4; nmap(h*3,1.0).save(f"{T}/leather_n.png")
# skin pores
h=tnoise(200,7)*0.5+tnoise(90,8)*0.5; nmap(h*1.5,1.0).save(f"{T}/skin_n.png")
# hair: strands along V. u across clump, v along length (tiles every 0.25 m)
W,Hh=256,1024; uu,vv=np.meshgrid(np.arange(W)/W,np.arange(Hh)/Hh)
s=np.zeros_like(uu)
for k in range(70):
    c=rng.random(); w=0.004+rng.random()*0.012; a=0.3+rng.random()*0.7
    off=0.01*np.sin(2*np.pi*(vv*rng.integers(1,3)+rng.random()))
    s+=a*np.exp(-((((uu-c-off)+0.5)%1-0.5)/w)**2)
s=s/s.max(); nmap(s*10,1.0).resize((W,Hh)).save(f"{T}/hair_n.png")
alb=(0.70+0.30*s)  # light streaks
np.save("/tmp/hair_streak.npy",alb)
Image.fromarray((np.clip(alb,0,1)*255).astype(np.uint8)).save(f"{T}/hair_streak.png")
print("fabric maps ok")
