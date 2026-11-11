#!/usr/bin/env python3
"""Reproducible fantasy art / audio for Glyph Quest v0.2.
Generated assets use only Pillow + Python stdlib. Font binary is NOT redistributed.
Run: python3 tools/make_art.py
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path
import random, math, wave, struct
random.seed(19)
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"assets"/"art"
SOUND=ROOT/"assets"/"audio"
OUT.mkdir(parents=True,exist_ok=True); SOUND.mkdir(parents=True,exist_ok=True)
W,H=720,1440
SERIF="/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
SANS="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

def rgba(color,alpha=255):
    if len(color)==4:return color
    return tuple(color)+(alpha,)

def mix(a,b,t):
    return tuple(int(a[i]*(1-t)+b[i]*t) for i in range(3))
def grad_box(im, bounds, top, bottom, horiz=False):
    d=ImageDraw.Draw(im)
    x0,y0,x1,y1=map(int,bounds)
    for i in range((x1-x0) if horiz else (y1-y0)):
        t=i/max(1,((x1-x0) if horiz else (y1-y0))-1)
        c=mix(top,bottom,t)
        if horiz:d.line((x0+i,y0,x0+i,y1),fill=c)
        else:d.line((x0,y0+i,x1,y0+i),fill=c)

def glow(im,pos,r,color,strength=100):
    glow_layer=Image.new("RGBA",(W,H));g=ImageDraw.Draw(glow_layer)
    x,y=pos;g.ellipse((x-r,y-r,x+r,y+r),fill=(*color,strength))
    glow_layer=glow_layer.filter(ImageFilter.GaussianBlur(max(10,r//2)))
    return Image.alpha_composite(im,glow_layer)

def scene():
    base=Image.new("RGB",(W,H))
    grad_box(base,(0,0,W,H),(32,35,64),(19,19,41))
    dr=ImageDraw.Draw(base)
    # stone masonry with individual dusky blocks
    for row in range(0,H,96):
        off=0 if row//96%2==0 else 70
        for col in range(-145+off,W,140):
            shade=random.randint(-9,9)
            clr=(max(5,43+shade),max(5,43+shade),max(5,69+shade))
            dr.rounded_rectangle((col+2,row+2,col+137,row+91),radius=7,fill=clr,outline=(68,60,91),width=2)
            dr.line((col+9,row+9,col+127,row+9),fill=(79,70,103),width=2)
    # distant landscape visible through tall arched stone window
    sky=Image.new("RGBA",(330,505),(0,0,0,0))
    sd=ImageDraw.Draw(sky)
    for y in range(505):
        c=mix((66,154,218),(226,214,160),y/505)
        sd.line((0,y,330,y),fill=(*c,255))
    for i in range(14):
        x=random.randint(-10,345);y=random.randint(110,245)
        sd.ellipse((x-31,y-12,x+70,y+12),fill=(227,236,248,44))
    sd.polygon([(0,355),(48,236),(91,303),(161,138),(210,242),(280,166),(330,300),(330,505),(0,505)],fill=(79,114,155,255))
    sd.polygon([(129,191),(161,138),(194,188),(168,179),(153,181)],fill=(220,237,245,255))
    sd.polygon([(252,212),(280,166),(307,217),(284,202)],fill=(215,231,241,255))
    sd.polygon([(0,380),(50,336),(140,356),(180,326),(270,351),(330,331),(330,505),(0,505)],fill=(48,100,86,255))
    sd.polygon([(0,450),(110,401),(192,432),(285,379),(330,406),(330,505),(0,505)],fill=(69,120,73,255))
    sd.line((0,430,330,430),fill=(177,173,115,180),width=4)
    # arch mask with rounded pointed top
    mask=Image.new("L",(330,505)); md=ImageDraw.Draw(mask)
    md.rectangle((0,175,329,504),fill=255)
    md.ellipse((0,0,329,350),fill=255)
    sky.putalpha(mask)
    base=base.convert("RGBA");base.alpha_composite(sky,(367,79))
    dr=ImageDraw.Draw(base,"RGBA")
    dr.arc((338,45,722,474),180,360,fill=(137,135,160,255),width=26)
    dr.line((352,257,352,604),fill=(104,93,116,255),width=23)
    dr.line((699,254,699,614),fill=(117,103,122,255),width=23)
    dr.line((516,94,516,579),fill=(78,72,97,255),width=14)
    dr.line((369,319,697,319),fill=(87,82,111,255),width=13)
    dr.arc((358,64,693,460),180,360,fill=(211,186,141,140),width=5)
    # broad wooded shelves at upper left
    dr.rounded_rectangle((0,125,310,679),radius=16,fill=(44,32,48,244),outline=(128,87,65,255),width=9)
    for shelf in [263,395,520,647]:
        dr.rectangle((0,shelf,325,shelf+16),fill=(94,58,48,255))
        dr.line((0,shelf,324,shelf),fill=(171,124,78,255),width=5)
    for row in [178,310,443,570]:
        x=10
        while x<295:
            ww=random.randint(14,29);height=random.randint(52,84)
            c=random.choice([(66,74,119),(100,48,77),(39,93,84),(111,84,66),(55,67,95)])
            dr.rounded_rectangle((x,row+88-height,x+ww,row+88),radius=3,fill=(*c,255),outline=(189,147,100,130),width=2)
            if random.random()<.5:
                dr.line((x+4,row+88-height+12,x+ww-4,row+88-height+12),fill=(222,179,106,210),width=2)
                dr.line((x+4,row+79,x+ww-4,row+79),fill=(222,179,106,210),width=2)
            x+=ww+random.randint(2,5)
    # hanging lantern
    dr.line((130,0,130,120),fill=(181,142,84,255),width=7)
    dr.polygon([(88,125),(171,125),(185,172),(178,270),(79,270),(75,172)],fill=(66,46,59,255),outline=(238,175,82,255))
    dr.polygon([(94,153),(163,153),(170,249),(88,249)],fill=(255,215,124,255))
    dr.line((130,151,130,250),fill=(148,91,59,255),width=7)
    base=glow(base,(130,200),136,(255,165,70),130)
    dr=ImageDraw.Draw(base,"RGBA")
    dr.ellipse((106,180,150,230),fill=(255,242,178,180))
    # leafy vines from top / left
    for j in range(60):
        cx=random.randint(-35,210);cy=random.randint(-20,124)
        green=random.choice([(47,99,65,255),(63,113,71,255),(89,129,83,255)])
        dr.ellipse((cx,cy,cx+random.randint(17,46),cy+random.randint(10,25)),fill=green)
    # tile floor / books / magical atlas
    for y in range(1015,H,74):
        for x in range(-30,W,130):
            off=60 if (y//74)%2 else 0
            dr.rounded_rectangle((x+off+2,y+2,x+off+124,y+68),radius=7,fill=(59,49,67,255),outline=(96,71,73,255),width=3)
    dr.polygon([(0,1370),(0,1194),(238,1203),(290,1400)],fill=(51,39,55,255))
    for j,(x,y,ww,hh,c) in enumerate([(13,1272,158,28,(124,68,52)),(26,1246,171,31,(39,72,87)),(7,1212,191,36,(101,65,85))]):
        dr.rounded_rectangle((x,y,x+ww,y+hh),radius=6,fill=(*c,255),outline=(220,165,99,230),width=3)
        dr.line((x+18,y+8,x+ww-20,y+8),fill=(210,185,130,255),width=2)
    dr.ellipse((558,1282,711,1422),outline=(213,161,76,255),width=12)
    dr.arc((567,1266,705,1436),60,310,fill=(248,202,107,255),width=9)
    dr.ellipse((575,1307,691,1404),fill=(31,76,122,255),outline=(243,180,90,255),width=6)
    dr.line((635,1275,635,1438),fill=(233,185,89,255),width=7)
    # mild depth of field and darkening to preserve readable UI
    base=base.filter(ImageFilter.GaussianBlur(1.1))
    dark=Image.new("RGBA",(W,H),(10,8,27,67))
    base=Image.alpha_composite(base,dark)
    # magical specks
    d=ImageDraw.Draw(base,"RGBA")
    for n in range(92):
        x=random.randrange(W);y=random.randrange(H);r=random.choice([1,1,2,2,3])
        d.ellipse((x-r,y-r,x+r,y+r),fill=(255,226,177,random.randint(25,115)))
    base.convert("RGB").save(OUT/"storybook.png",optimize=True)
    # gameplay backgrounds a little darker, with varied magical light
    for name,c in [('runes',(97,107,204)),('egypt',(221,157,72)),('asia',(99,185,157)),('mixed',(169,93,192))]:
        tint=Image.new("RGBA",(W,H),(*c,37))
        b=Image.alpha_composite(base,tint)
        cover=Image.new("RGBA",(W,H),(7,9,31,54))
        b=Image.alpha_composite(b,cover)
        b.convert("RGB").save(OUT/("bg_"+name+".png"),optimize=True)

def gemstones():
    palette=[
        ((164,74,246),(88,36,150)),
        ((246,106,167),(144,34,104)),
        ((250,181,46),(145,94,29)),
        ((57,171,255),(22,86,178)),
        ((39,224,207),(17,105,132)),
        ((97,216,66),(37,118,55))
    ]
    sz=104
    for idx,(hi,lo) in enumerate(palette):
        im=Image.new("RGBA",(sz,sz),(0,0,0,0))
        d=ImageDraw.Draw(im,"RGBA")
        # shadows behind a beveled octagonal jewel
        poly=[(16,5),(86,5),(100,19),(100,86),(85,100),(18,100),(4,86),(4,19)]
        d.polygon([(x+1,y+2) for x,y in poly],fill=(0,0,0,100))
        for y in range(9,97):
            if y<20:x0=20-(y-9)*1.2;x1=84+(y-9)*1.2
            elif y>85:x0=7+(y-85)*1.2;x1=97-(y-85)*1.2
            else:x0=7;x1=97
            t=(y-9)/89.0
            clr=mix(hi,lo,t)
            d.line((int(x0),y,int(x1),y),fill=(*clr,255),width=1)
        # faceted edges
        d.line([(19,8),(84,8),(97,22)],fill=(*mix(hi,(255,255,255),.50),240),width=6,joint="curve")
        d.line([(7,25),(7,84),(20,97)],fill=(*mix(lo,(255,255,255),.22),200),width=5)
        d.line([(97,22),(97,84),(84,97)],fill=(*mix(lo,(0,0,0),.3),240),width=7)
        d.line([(20,97),(84,97)],fill=(*mix(lo,(0,0,0),.3),240),width=6)
        d.polygon([(22,12),(79,12),(69,29),(31,27)],fill=(255,255,255,50))
        d.polygon([(15,35),(22,22),(28,35),(25,67)],fill=(255,255,255,18))
        d.polygon([(79,72),(94,66),(90,84),(82,91)],fill=(255,255,255,38))
        d.line((22,11,84,11),fill=(255,250,222,85),width=2)
        d.ellipse((22,20,30,28),fill=(255,255,255,80))
        im.save(OUT/f"gem_{idx}.png",optimize=True)
    # extra hammer boost and star sprites are drawn procedurally in Godot

def logo():
    width,height=690,245
    im=Image.new("RGBA",(width,height),(0,0,0,0))
    serif=ImageFont.truetype(SERIF,76)
    sans=ImageFont.truetype(SERIF,66)
    d=ImageDraw.Draw(im)
    # purple crest plate
    d.rounded_rectangle((23,15,667,211),radius=62,fill=(45,23,89,234),outline=(226,153,63,255),width=9)
    d.rounded_rectangle((31,23,659,202),radius=53,outline=(243,194,102,192),width=3)
    d.arc((263,-7,429,145),200,345,fill=(255,213,95,225),width=5)
    lines=[("Kady's",serif,33),("Glyph Quest",sans,115)]
    for s,font,y in lines:
        box=d.textbbox((0,0),s,font=font,stroke_width=1)
        x=(width-(box[2]-box[0]))//2
        d.text((x+3,y+4),s,font=font,fill=(44,16,49,255),stroke_width=5,stroke_fill=(27,11,54,255))
        d.text((x,y),s,font=font,fill=(255,212,105,255),stroke_width=3,stroke_fill=(112,55,72,255))
        # upper fine gold gleam
    d.line((282,200,410,200),fill=(244,214,132,255),width=4)
    im.save(OUT/"logo.png",optimize=True)

def ambience():
    sr=16000
    for name,secs in [("tap",.12),("match",.35),("win",1.0),("fail",.44),("ambient",6.0)]:
        n=int(secs*sr)
        pcm=bytearray()
        for i in range(n):
            t=i/sr
            if name=="tap":
                env=(1-t/secs)**3; s=math.sin(2*math.pi*(430+400*t)*t)*env
            elif name=="match":
                env=max(0,1-t/secs)**1.4
                s=(.7*math.sin(2*math.pi*740*t)+.4*math.sin(2*math.pi*1110*t))*env
            elif name=="win":
                env=min(1,t/.04)*max(0,1-t/secs)
                f=[440,554,659,880][min(3,int(t*4))]
                s=(math.sin(2*math.pi*f*t)+.3*math.sin(2*math.pi*2*f*t))*env
            elif name=="fail":
                env=max(0,1-t/secs)
                s=math.sin(2*math.pi*(360-120*t)*t)*env
            else:
                envelope=(math.sin(math.pi*t/secs))**2
                s=(.25*math.sin(2*math.pi*110*t)+.12*math.sin(2*math.pi*164.81*t)+.13*math.sin(2*math.pi*220*t))*envelope
            gain=.12 if name=="ambient" else .3
            pcm.extend(struct.pack("<h",int(max(-1,min(1,s*gain))*32760)))
        with wave.open(str(SOUND/(name+".wav")),"wb") as f:
            f.setnchannels(1);f.setsampwidth(2);f.setframerate(sr);f.writeframes(bytes(pcm))

if __name__=="__main__":
    scene();gemstones();logo();ambience()
    for p in list(OUT.glob("*"))+list(SOUND.glob("*")):
        print(p.relative_to(ROOT),p.stat().st_size)
