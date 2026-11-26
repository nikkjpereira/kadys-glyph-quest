#!/usr/bin/env python3
"""Remove baked-in obsolete UI from historical menu scenery.
Keeps original environmental artwork, replaces old UI ghosts with dark atmospheric fog.
The output is scenery only; labels/buttons are exclusively drawn by Godot.
"""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter
root=Path(__file__).resolve().parents[1]
source=Image.open(root/"assets/v03/menu_scene.png").convert("RGB")
w,h=source.size
mist=Image.new("RGB",(w,h),(35,24,54))
mask=Image.new("L",(w,h),0)
d=ImageDraw.Draw(mask)
# Baked navigation labels and obsolete decorative buttons in source art.
for ellipse in [
    (58,182,249,375),   # old decorative left title / icon
    (476,190,701,384),  # old right title / icon
    (11,430,167,652),   # old world navigation
    (556,430,718,646),
    (0,766,180,1048),   # old world-card captions
    (540,759,719,1056),
    (3,1141,224,1420), # obsolete Settings decoration
    (498,1141,718,1420) # obsolete Collection decoration
]:
    d.ellipse(ellipse,fill=255)
# Subtle edge fog blends old controls away while preserving architecture near top.
mask=mask.filter(ImageFilter.GaussianBlur(28))
fog=Image.new("RGB",(w,h))
src=source.load();dst=fog.load()
for y in range(h):
    for x in range(w):
        # A cool ambient vignette, not opaque patches.
        a=(max(0.,1-abs(x-w*.5)/(w*.5))*.0)
        seed=src[x,y]
        base=(35+int(y/h*8),25+int(y/h*9),54+int(y/h*10))
        dst[x,y]=tuple(int(seed[k]*.02+base[k]*.98) for k in range(3))
composite=Image.composite(fog,source,mask)
# A unified light-purple mist binds the scenery without added UI elements.
out=root/"assets/v075/menu_scene_clean.png"
out.parent.mkdir(parents=True,exist_ok=True)
composite.save(out,optimize=True)
print(out, out.stat().st_size, source.size)
