#!/usr/bin/env python3
"""Produce small game UI textures with transparent alpha; no new dependencies beyond Pillow."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path
import random, math
random.seed(18)
root=Path(__file__).resolve().parents[1]
out=root/"assets"/"v04"
out.mkdir(parents=True,exist_ok=True)
SZ=256
im=Image.new("RGBA",(SZ,SZ),(0,0,0,0))
d=ImageDraw.Draw(im,"RGBA")
d.rounded_rectangle((9,11,247,248),radius=44,fill=(18,23,46,220),outline=(222,176,93,240),width=9)
d.polygon([(43,18),(209,18),(239,48),(238,204),(205,240),(47,238),(15,208),(16,49)],fill=(60,62,88,255))
for i in range(10):
    gray=60+i*4
    d.line((25+i*2,34+i,215-i*2,32+i),fill=(gray+35,gray+26,gray+47,180),width=2)
d.polygon([(45,38),(201,35),(216,68),(217,188),(201,216),(51,219),(34,190),(37,74)],fill=(66,73,96,255),outline=(134,147,162,255))
d.line([(47,47),(198,47),(205,75)],fill=(192,169,128,215),width=4)
d.line([(48,209),(206,207)],fill=(38,36,58,210),width=6)
d.line([(55,68),(96,108),(75,165),(140,184),(183,137),(209,166)],fill=(33,37,68,220),width=9,joint="curve")
d.line([(54,67),(96,108),(75,165)],fill=(172,175,207,115),width=3)
d.ellipse((99,101,152,155),fill=(30,39,70,255),outline=(235,193,104,230),width=5)
d.line((113,132,145,116),fill=(204,175,116,230),width=5)
im.save(out/"stone.png",optimize=True)
W,H=320,260
im=Image.new("RGBA",(W,H),(0,0,0,0));d=ImageDraw.Draw(im,"RGBA")
d.ellipse((39,16,281,252),fill=(56,23,109,252),outline=(242,191,91,255),width=12)
d.ellipse((53,30,268,235),outline=(163,111,238,245),width=6)
d.arc((92,65,235,207),40,312,fill=(122,226,255,255),width=21)
d.polygon([(90,79),(131,82),(102,127)],fill=(195,244,255,255))
d.arc((100,73,228,201),45,310,fill=(222,248,255,195),width=6)
d.ellipse((110,100,209,202),outline=(252,202,94,180),width=4)
im.save(out/"undo.png",optimize=True)
print("Created",[(p.name,p.stat().st_size) for p in out.glob("*.png")])
