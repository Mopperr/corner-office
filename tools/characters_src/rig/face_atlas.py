"""Dana face atlas: 7 cells (352x512) from painted portraits. python3 face_atlas.py"""
import numpy as np, os
from PIL import Image, ImageDraw, ImageFilter
A=os.path.abspath(os.path.join(os.path.dirname(__file__),"../.."))
SRC=f"{A}/ui/characters/dana"; T=f"{A}/textures/characters"; OUT=f"{T}/dana_face"; os.makedirs(OUT,exist_ok=True)
PXM=1403.0; CX,EY=319,300      # px/m, face centre x, eye line y
ZE=0.106                        # eye height above chin-ish origin used by UV (see charlib face uv)
# crop window in metres relative to (centre, eye line): x +-0.075, z -0.115..+0.105
X0,X1=CX-0.075*PXM, CX+0.075*PXM; Y0,Y1=EY-0.105*PXM, EY+0.115*PXM
CW,CH=352,512
SKIN=np.array([236,191,160],float)
def load(n): return np.asarray(Image.open(f"{SRC}/dana_portrait_{n}.png").convert("RGB"),float)
def crop(img):
    im=Image.fromarray(img.astype(np.uint8)).crop((int(X0),int(Y0),int(X1),int(Y1))).resize((CW,CH),Image.LANCZOS)
    return np.asarray(im,float)
yy,xx=np.mgrid[0:CH,0:CW]
# mask in metres
mx=(xx/CW-0.5)*0.15; mz=0.105-(yy/CH)*0.22
def ell(ax,az0,az1,feather):
    zc=(az0+az1)/2; hz=(az1-az0)/2
    d=np.sqrt((mx/ax)**2+((mz-zc)/hz)**2)
    return np.clip((1-d)/feather,0,1)
mask=ell(0.056,-0.105,0.075,0.12)
mask=np.maximum(mask, ell(0.050,-0.02,0.10,0.15)*0.0)
def process(img):
    c=crop(img)
    lum0=c.mean(2)
    w=np.clip(1-np.abs(lum0-np.median(lum0[CH//3:2*CH//3,CW//4:3*CW//4]))/22,0,1)
    from scipy.ndimage import gaussian_filter
    def gbf(a,r): return gaussian_filter(a,(r,r,0) if a.ndim==3 else r)
    blur=gbf(c*w[...,None],16)/np.maximum(gbf(w,16),1e-3)[...,None]
    ratio=SKIN/np.maximum(blur,1)
    flat=np.clip(c*ratio,0,255)
    # kill dark hair strands outside feature zones: pixels much darker+more saturated than local blur, far from eyes/brows/mouth
    feat=np.zeros((CH,CW))
    for (fx,fz,ax,az) in [(-0.031,0.0,0.026,0.022),(0.031,0.0,0.026,0.022),(-0.031,0.039,0.028,0.014),(0.031,0.039,0.028,0.014),(0,-0.071,0.032,0.024),(0,-0.035,0.016,0.022)]:
        feat=np.maximum(feat,np.clip(1.6-np.sqrt(((mx-fx)/ax)**2+((mz-fz)/az)**2),0,1))
    lum=flat.mean(2); dark=np.clip((SKIN.mean()-25-lum)/40,0,1)*(1-feat)
    flat=flat*(1-dark[...,None])+SKIN*dark[...,None]
    out=flat*mask[...,None]+SKIN*(1-mask[...,None])
    return out,c
cells=[]
names=["base","neutral","happy","surprised","tired","proud"]
for n in names:
    o,_=process(load(n)); cells.append(o)
# blink: from neutral, paint over eyes
b=cells[1].copy()
im=Image.fromarray(b.astype(np.uint8)); dr=ImageDraw.Draw(im)
def px(x,z): return ((x/0.15+0.5)*CW,(0.105-z)/0.22*CH)
for s in(-1,1):
    cx,cz=s*0.031,0.0
    # fill eye area with skin (slightly darker lid)
    x0,y0=px(cx-0.027,cz+0.016); x1,y1=px(cx+0.027,cz-0.014)
    lid=Image.new("L",im.size,0); ImageDraw.Draw(lid).ellipse([x0,y0,x1,y1],fill=255); lid=lid.filter(ImageFilter.GaussianBlur(3))
    im=Image.composite(Image.new("RGB",im.size,(228,182,152)),im,lid); dr=ImageDraw.Draw(im)
    pts=[px(cx+s*t*0.019, cz-0.004-0.004*(1-t*t)) for t in np.linspace(-1,1,20)]
    dr.line(pts,fill=(52,32,26),width=5,joint="curve")
    for t in np.linspace(-0.6,0.9,6):
        x,y=px(cx+s*t*0.019, cz-0.004-0.004*(1-t*t)); dr.line([(x,y),(x+s*2*(t+0.3),y+7)],fill=(52,32,26),width=2)
cells.append(np.asarray(im,float)); names.append("blink")
atlas=np.concatenate(cells,1)
Image.fromarray(np.clip(atlas,0,255).astype(np.uint8)).save(f"{T}/dana_face_atlas7.png")
for n,c in zip(names,cells): Image.fromarray(np.clip(c,0,255).astype(np.uint8)).save(f"{OUT}/dana_face_{n}.png")
print("atlas",atlas.shape,names)
