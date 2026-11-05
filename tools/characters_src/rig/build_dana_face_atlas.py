"""Dana face atlas from painted portraits: 5 cells (neutral, happy, surprised, tired, proud) 340×512 each → textures/characters/dana_face_atlas.png"""
from PIL import Image, ImageDraw, ImageFilter
import os
A=os.path.join(os.path.dirname(os.path.abspath(__file__)),"..")
E_=("neutral","happy","surprised","tired","proud"); CW,CH=340,512; skin=(237,192,161)
atlas=Image.new("RGB",(CW*5,CH),skin)
m=Image.new("L",(CW,CH),0); d=ImageDraw.Draw(m); d.ellipse((26,14,CW-26,CH-30),fill=255); m=m.filter(ImageFilter.GaussianBlur(16))
for i,e in enumerate(E_):
    im=Image.open(f"{A}/ui/characters/dana/dana_portrait_{e}.png").convert("RGBA")
    c=im.crop((236,175,404,447)).resize((CW,CH),Image.LANCZOS)
    bg=Image.new("RGBA",(CW,CH),skin+(255,)); bg.alpha_composite(c)
    atlas.paste(Image.composite(bg.convert("RGB"),Image.new("RGB",(CW,CH),skin),m),(i*CW,0))
atlas.save(f"{A}/textures/characters/dana_face_atlas.png")
