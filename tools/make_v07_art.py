#!/usr/bin/env python3
"""Create original high-resolution gemstone materials, magical FX, and restoring-world overlays.
Offline, deterministic, no third-party copyrighted assets. Generated PNGs are game assets.
"""
from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path
import math, random
R=Path(__file__).resolve().parents[1]/"assets"/"v07"
R.mkdir(parents=True,exist_ok=True)
random.seed(700700)
PALETTES=[
    (147,48,239), (229,56,154), (239,174,29),
    (39,137,245), (21,191,207), (50,205,79)
]
def sat(a):return max(0,min(255,int(a)))
def col(rgb,delta=0,a=255):return tuple(sat(x+delta) for x in rgb)+(a,)
def mix(a,b,t):return tuple(sat((1-t)*a[k]+t*b[k]) for k in range(3))
def poly_cut(box,cut):
    l,t,r,b=box
    return [(l+cut,t),(r-cut,t),(r,t+cut),(r,b-cut),(r-cut,b),(l+cut,b),(l,b-cut),(l,t+cut)]
def blur_circle(im,cx,cy,r,color,sigma):
    glow=Image.new("RGBA",im.size,(0,0,0,0))
    d=ImageDraw.Draw(glow)
    d.ellipse((cx-r,cy-r,cx+r,cy+r),fill=color)
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(sigma)))

# 256x256 jewels rendered at 512 then supersampled, with coherent reflection.
for idx,rgb in enumerate(PALETTES):
    n=512
    a=Image.new("RGBA",(n,n))
    # Drop shadow contained within sprite.
    sh=Image.new("RGBA",(n,n))
    sd=ImageDraw.Draw(sh)
    sd.polygon(poly_cut((29,31,491,492),77), fill=(0,0,0,155))
    a.alpha_composite(sh.filter(ImageFilter.GaussianBlur(15)))
    mask=Image.new("L",(n,n),0);md=ImageDraw.Draw(mask)
    md.polygon(poly_cut((25,18,485,480),76),fill=255)
    inner=Image.new("RGBA",(n,n))
    ip=inner.load()
    for y in range(n):
        for x in range(n):
            # Curving diffuse illumination from upper left and darker violet lower edge.
            light=.47+.25*(1-y/n)+.13*(1-x/n)
            light+=.22*math.exp(-((x-165)**2+(y-90)**2)/75000)
            dark=(1-y/n)*.0
            t=max(0,min(1,light))
            base=mix((7,11,50),rgb,t)
            # High frequency glass caustic ripples, intentionally restrained.
            wave=(math.sin(x*.034+y*.015+idx)*math.sin(y*.018-x*.01+idx))*.038
            fade=.90+.07*math.sin(math.pi*x/n)*math.sin(math.pi*y/n)
            ip[x,y]=tuple(sat(c*(fade+wave)) for c in base)+(255,)
    a.paste(inner,(0,0),mask)
    d=ImageDraw.Draw(a)
    points=poly_cut((23,18,484,479),77)
    d.line(points+[points[0]],fill=col(rgb,-100,255),width=25,joint="curve")
    d.line(poly_cut((27,22,479,473),72)+[poly_cut((27,22,479,473),72)[0]],fill=col(rgb,75),width=16,joint="curve")
    d.line(poly_cut((40,39,467,459),61)+[poly_cut((40,39,467,459),61)[0]],fill=col(rgb,-45),width=8,joint="curve")
    # Faceted beveled edges, with side-specific material response.
    d.line([(101,40),(399,40),(441,89)],fill=(255,255,245,205),width=13,joint="curve")
    d.line([(60,99),(60,359),(113,425)],fill=col(rgb,110,180),width=11,joint="curve")
    d.line([(406,444),(464,387),(464,114)],fill=col(rgb,-95,230),width=14,joint="curve")
    translucent=Image.new("RGBA",(n,n))
    td=ImageDraw.Draw(translucent)
    td.polygon([(71,95),(110,64),(392,64),(438,106),(407,142),(117,145)],fill=(255,255,255,32))
    td.polygon([(83,154),(132,135),(397,138),(436,163),(398,190),(110,185)],fill=(255,255,255,22))
    td.polygon([(85,378),(106,406),(397,406),(442,372),(405,350),(125,354)],fill=col(rgb,-70,80))
    a.alpha_composite(translucent)
    # Specular soft spot upper left, gold-reflected lower right.
    hl=Image.new("RGBA",(n,n))
    hd=ImageDraw.Draw(hl)
    hd.ellipse((102,52,330,218),fill=(255,255,255,125))
    a.alpha_composite(hl.filter(ImageFilter.GaussianBlur(67)))
    d=ImageDraw.Draw(a)
    d.ellipse((125,67,160,91),fill=(255,255,255,195))
    d.line([(134,70),(143,70)],fill=(255,255,255,240),width=6)
    d.ellipse((408,388,431,410),fill=(255,227,146,130))
    # Tiny internal curved refraction lines.
    arcs=Image.new("RGBA",(n,n));ad=ImageDraw.Draw(arcs)
    ad.arc((122,102,417,374),198,307,fill=(245,252,255,58),width=7)
    ad.arc((87,113,425,421),10,85,fill=(255,232,155,45),width=5)
    a.alpha_composite(arcs)
    # Metallic/cut-glass bottom highlight.
    d.line([(122,452),(382,452)],fill=col(rgb,92,155),width=11)
    a.resize((256,256),Image.Resampling.LANCZOS).save(R/f"gem_{idx}.png",optimize=True)

# Overlay particles drawn with GPU-friendly transparent sprites.
for kind in ["spark_star","crystal_shard","magic_ring","light_ray","gem_glint"]:
    n=192
    im=Image.new("RGBA",(n,n))
    d=ImageDraw.Draw(im)
    if kind=="spark_star":
        for radius,al in [(92,30),(65,60),(42,110)]:
            blur_circle(im,96,96,radius,(255,248,191,al),13)
        d=ImageDraw.Draw(im)
        d.polygon([(96,3),(110,80),(189,96),(110,111),(96,190),(81,110),(2,96),(82,82)],fill=(255,244,197,200))
        d.ellipse((83,83,109,109),fill=(255,255,255,255))
    elif kind=="crystal_shard":
        d.polygon([(72,11),(151,43),(166,119),(104,179),(53,152),(27,79)],fill=(217,239,255,150),outline=(255,255,255,210),width=4)
        d.polygon([(72,11),(104,179),(27,79)],fill=(255,255,255,85))
        d.line([(72,11),(104,179),(166,119)],fill=(255,255,255,126),width=5)
    elif kind=="magic_ring":
        d.ellipse((21,21,171,171),outline=(255,244,218,180),width=13)
        d.ellipse((38,38,154,154),outline=(255,255,255,95),width=3)
        for k in range(16):
            a=k*math.tau/16
            x=96+72*math.cos(a);y=96+72*math.sin(a)
            d.ellipse((x-3,y-3,x+3,y+3),fill=(255,244,163,210))
        # Semi-transparent central viewport
    elif kind=="light_ray":
        for x in range(192):
            for y in range(192):
                v=max(0,1-abs(x-96)/70)*max(0,1-y/192)
                if v>.01:
                    im.putpixel((x,y),(229,242,255,int(140*v*v)))
    elif kind=="gem_glint":
        for x in range(192):
            for y in range(192):
                xx=(x-96)/96;yy=(y-96)/96
                v=max(0,math.exp(-((xx+yy*.70)**2)/.005)*math.exp(-((yy-xx*.5)**2)/.35))
                if v>.01:
                    im.putpixel((x,y),(255,255,255,int(min(255,v*165))))
    im.save(R/f"{kind}.png",optimize=True)

# Detailed illustrated atmosphere. Individual world/stage assets, cumulative story restoration.
WORLD_C=[(111,191,248),(255,202,105),(143,238,190),(203,136,251)]
def world_overlay(world,stage):
    W,H=720,1440
    im=Image.new("RGBA",(W,H))
    d=ImageDraw.Draw(im)
    rgb=WORLD_C[world]
    # Ancient architectural columns in the upper corners (never board-center).
    for side in (0,1):
        sideflip=lambda x: x if side==0 else W-x
        line=[(sideflip(8),350),(sideflip(38),300),(sideflip(56),122),(sideflip(74),58)]
        d.line(line,fill=col(rgb,10,60+stage*18),width=8,joint="curve")
        for off in [0,57,114,171]:
            y=80+off
            d.line([(sideflip(36),y),(sideflip(81),y-8)],fill=col(rgb,44,33+stage*22),width=5)
    if stage>=1:
        # Illuminated torches/lanterns; all live in margins away from the 8x8 board.
        for x,y in [(51,247),(669,252),(56,1209),(663,1214)]:
            blur_circle(im,x,y,25+stage*8,col(rgb,70,60+stage*16),22)
            d=ImageDraw.Draw(im)
            d.ellipse((x-12,y-12,x+12,y+12),outline=col(rgb,84,190),width=4)
            d.line((x,y+11,x,y+30),fill=(191,147,92,160),width=6)
    if stage>=2:
        # Floating glyph/spiral engravings illuminate upper edges.
        for edge in (0,1):
            for k in range(5):
                x=(75+k*42) if edge==0 else (645-k*42)
                y=55+(k%3)*17
                r=9+(k%2)*5
                d.arc((x-r,y-r,x+r,y+r),35,322,fill=col(rgb,85,105+stage*10),width=3)
                if world==0:
                    d.line([(x-5,y+r),(x,y-r),(x+6,y+r)],fill=col(rgb,75,155),width=4)
                elif world==1:
                    d.ellipse((x-6,y-6,x+6,y+6),outline=(255,222,135,140),width=3)
                elif world==2:
                    d.arc((x-12,y-12,x+12,y+12),210,20,fill=(235,255,207,140),width=4)
                else:
                    d.polygon([(x,y-11),(x+8,y),(x,y+11),(x-8,y)],outline=col(rgb,100,135))
    if stage>=3:
        # Restored illuminated gateway behind the title, not behind the UI buttons.
        glow=Image.new("RGBA",(W,H))
        gd=ImageDraw.Draw(glow)
        for rr in range(6):
            a=65-rr*8
            gd.arc((175-rr*5,33-rr*4,545+rr*5,365+rr*5),192,349,fill=col(rgb,84,a),width=8+rr*2)
        im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(11)))
        d=ImageDraw.Draw(im)
        d.arc((174,24,546,353),195,347,fill=col(rgb,105,105),width=7)
        d.line((22,1142,145,1172),fill=col(rgb,60,120),width=6)
        d.line((576,1172,694,1142),fill=col(rgb,60,120),width=6)
    if stage>=4:
        # Sanctuary restored: beams and magical glyph-emitting floor lights.
        beams=Image.new("RGBA",(W,H)); bd=ImageDraw.Draw(beams)
        for i in range(4):
            x=90+i*180
            bd.polygon([(x-33,0),(x+5,0),(x+135,H),(x-50,H)],fill=col(rgb,35,17))
        im.alpha_composite(beams.filter(ImageFilter.GaussianBlur(12)))
        d=ImageDraw.Draw(im)
        for x,y in [(78,1220),(642,1220),(142,91),(578,91)]:
            d.ellipse((x-16,y-16,x+16,y+16),outline=col(rgb,110,180),width=4)
            d.ellipse((x-5,y-5,x+5,y+5),fill=(255,255,255,200))
    # Differentiating visual motifs at the bottom, including gameplay periphery.
    if world==0:
        if stage>=1:
            for x,y in [(20,1100),(691,1073),(40,1334),(670,1368)]:
                d.polygon([(x,y+27),(x+8,y-28),(x+20,y+12),(x+13,y+43)],fill=(69,133,212,90+stage*15))
    elif world==1:
        if stage>=1:
            d.arc((-75,1120,185,1380),190,290,fill=(253,210,121,80+stage*10),width=10)
            d.arc((545,1105,790,1385),252,349,fill=(252,209,114,80+stage*10),width=11)
    elif world==2:
        if stage>=1:
            for i in range(18):
                x=(i*173+71)%720
                y=(i*121+65)%1440
                if 245<y<1140 and 75<x<645:continue
                d.ellipse((x-5,y-2,x+5,y+7),fill=(255,190,217,70+stage*20))
        if stage>=3:
            for x in [70,644]:
                d.line((x,90,x,280),fill=(255,193,134,110),width=5)
                d.ellipse((x-16,255,x+16,309),fill=(255,177,128,115),outline=(255,237,186,155),width=4)
    else:
        if stage>=1:
            for k in range(19):
                x=(k*97+43)%720;y=(k*197+47)%1440
                if 405<y<1100 and 20<x<700:continue
                r=3+(k%3)
                d.ellipse((x-r,y-r,x+r,y+r),fill=(222,174,255,65+stage*17))
        if stage>=3:
            d.arc((33,1148,331,1437),165,348,fill=(204,159,247,90),width=7)
            d.arc((383,1148,687,1437),192,371,fill=(204,159,247,90),width=7)
    return im

for w in range(4):
    for stage in range(5):
        im=world_overlay(w,stage)
        im.save(R/f"world_{w}_stage_{stage}.png",optimize=True)

print("v0.7 generated assets:",len(list(R.glob("*.png"))))
print("Total MB:",round(sum(x.stat().st_size for x in R.glob("*.png"))/1e6,2))
