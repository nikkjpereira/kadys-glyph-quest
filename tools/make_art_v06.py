#!/usr/bin/env python3
"""Original procedural v0.6 relic medallions and under-board fantasy murals."""
from PIL import Image,ImageDraw,ImageFont,ImageFilter
from pathlib import Path
import math,random
OUT=Path(__file__).resolve().parents[1]/"assets"/"v06"
OUT.mkdir(exist_ok=True,parents=True)
F="/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
themes=[((90,150,231),(153,216,249),"ᚱ"),((202,146,56),(252,221,120),"☥"),((86,173,151),(193,245,221),"✿"),((166,95,210),(236,190,255),"✦")]
for w,(base,light,symbol) in enumerate(themes):
    for j in range(4):
        n=384;im=Image.new("RGBA",(n,n))
        glow=Image.new("RGBA",(n,n));dg=ImageDraw.Draw(glow)
        dg.ellipse((42,42,342,342),fill=(*light,110))
        im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(27)))
        d=ImageDraw.Draw(im)
        d.ellipse((39,39,345,345),fill=(29,19,65,255),outline=(240,199,115),width=12)
        d.ellipse((54,54,330,330),fill=(*base,230),outline=(255,225,151),width=7)
        d.ellipse((70,70,314,314),fill=(21,28,76,205),outline=(255,243,197),width=4)
        for i in range(12):
            a=i*math.tau/12
            x=192+151*math.cos(a);y=192+151*math.sin(a)
            d.ellipse((x-7,y-7,x+7,y+7),fill=(255,230,156,255))
        symbol_set=[["ᚠ","ᚱ","ᛟ","ᚹ"],["☥","◈","☼","✴"],["✿","◆","♢","☯"],["✦","◇","✷","✺"]]
        # Font can lack glyphs; fallback still renders original ornament ring.
        sym=symbol_set[w][j]
        font=ImageFont.truetype(F,145 if len(sym)==1 else 112)
        try:d.text((192,191),sym,font=font,anchor="mm",fill=(255,231,157),stroke_width=4,stroke_fill=(95,47,92))
        except Exception:pass
        for k in range(5):
            a=(k*1.62+j*.39)
            x=192+105*math.cos(a);y=192+105*math.sin(a)
            d.line((x-10,y,x+10,y),fill=(255,243,202,175),width=3)
        path=OUT/f"relic_{w}_{j}.png"
        im.save(path,optimize=True)
    # Engraved relic mural revealed under cleared sockets.
    n=800
    mural=Image.new("RGBA",(n,n),(11,25,60,255))
    d=ImageDraw.Draw(mural)
    center=(400,400)
    for rad in [333,290,230,165,104]:
        d.ellipse((400-rad,400-rad,400+rad,400+rad),outline=(*base,100 if rad>180 else 75),width=7)
    for k in range(24):
        a=k*math.tau/24
        x=400+295*math.cos(a);y=400+295*math.sin(a)
        nx=400+270*math.cos(a);ny=400+270*math.sin(a)
        d.line((x,y,nx,ny),fill=(*light,115),width=5)
    font=ImageFont.truetype(F,240)
    try:d.text(center,symbol,font=font,anchor="mm",fill=(*light,125),stroke_width=5,stroke_fill=(*base,100))
    except Exception:d.ellipse((335,335,465,465),fill=(*light,70))
    mural.save(OUT/f"mural_{w}.png",optimize=True)
print("Generated",len(list(OUT.glob("*.png"))),"v0.6 artwork files")
