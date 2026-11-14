#!/usr/bin/env python3
"""Draw transparent render-inspired HUD components (not a flattened screenshot)."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path
import math
ROOT=Path(__file__).resolve().parents[1]/"assets"/"v05"
ROOT.mkdir(parents=True,exist_ok=True)
FONT="/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
def font(sz):return ImageFont.truetype(FONT,sz)
def stroke_text(d,xy,s,f,fill,stroke,sw):
    d.text(xy,s,font=f,fill=fill,stroke_width=sw,stroke_fill=stroke,anchor="mm")
def logo():
    w,h=850,330
    im=Image.new("RGBA",(w,h))
    glow=Image.new("RGBA",(w,h))
    gd=ImageDraw.Draw(glow)
    gd.rounded_rectangle((62,45,790,253),radius=110,fill=(167,82,222,130))
    im=Image.alpha_composite(im,glow.filter(ImageFilter.GaussianBlur(25)))
    d=ImageDraw.Draw(im)
    d.rounded_rectangle((78,58,773,265),radius=92,fill=(65,18,119,247),outline=(54,17,87,255),width=12)
    d.arc((65,20,790,288),185,358,fill=(255,205,94,250),width=8)
    d.arc((80,46,770,270),5,179,fill=(242,175,57,230),width=7)
    d.rounded_rectangle((92,66,761,251),radius=78,outline=(246,190,69,240),width=5)
    stroke_text(d,(425,109),"Kady's",font(92),(255,215,103,255),(94,37,85,255),7)
    stroke_text(d,(425,203),"Glyph Quest",font(85),(255,199,78,255),(90,37,83,255),7)
    # golden swoop and illustrated open book
    d.arc((256,203,593,318),10,168,fill=(244,191,67,250),width=7)
    d.polygon([(365,263),(418,254),(426,307),(368,300)],fill=(255,227,157,255),outline=(137,76,39,255))
    d.polygon([(427,307),(430,254),(488,263),(483,300)],fill=(253,218,139,255),outline=(137,76,39,255))
    d.line([(427,262),(428,306)],fill=(108,62,44,255),width=4)
    for x in range(379,415,10):
        d.line([(x,272),(x+13,280)],fill=(168,113,63,190),width=2)
    for x in range(446,473,10):
        d.line([(x,280),(x+13,272)],fill=(168,113,63,190),width=2)
    for x,y,r in [(123,86,8),(719,80,7),(743,221,7),(125,218,6),(430,20,8)]:
        d.line((x-r,y,x+r,y),fill=(255,238,164,240),width=2)
        d.line((x,y-r,x,y+r),fill=(255,238,164,240),width=2)
        d.ellipse((x-3,y-3,x+3,y+3),fill=(255,255,228,255))
    im.save(ROOT/"logo.png",optimize=True)
def board_frame():
    w,h=850,880
    im=Image.new("RGBA",(w,h))
    d=ImageDraw.Draw(im)
    d.rounded_rectangle((9,9,w-10,h-10),radius=36,fill=(17,27,57,229),outline=(20,38,74,255),width=18)
    d.rounded_rectangle((18,18,w-19,h-19),radius=31,outline=(85,129,177,255),width=8)
    d.rounded_rectangle((32,30,w-33,h-33),radius=18,outline=(23,35,73,255),width=9)
    d.rounded_rectangle((38,40,w-39,h-41),radius=16,fill=(8,15,36,238))
    d.rounded_rectangle((28,26,w-29,h-27),radius=26,outline=(160,190,218,144),width=2)
    for x,y in [(29,29),(w-30,29),(29,h-30),(w-30,h-30)]:
        d.ellipse((x-17,y-17,x+17,y+17),fill=(59,92,136,255),outline=(241,190,86,225),width=5)
        d.ellipse((x-5,y-5,x+5,y+5),fill=(124,213,247,255))
    im.save(ROOT/"board_frame.png",optimize=True)
def locked():
    w=h=100
    im=Image.new("RGBA",(w,h))
    d=ImageDraw.Draw(im)
    # chains are translucent so glyph remains identifiable
    for shift in [-13,12]:
        for j in range(4):
            x=6+23*j+shift
            y=5+23*j
            d.ellipse((x,y,x+26,y+16),outline=(248,220,155,215),width=5)
    d.arc((32,31,68,71),185,355,fill=(255,225,131,255),width=7)
    d.rounded_rectangle((34,52,68,78),radius=6,fill=(89,46,120,240),outline=(255,222,131,255),width=4)
    d.ellipse((49,60,55,66),fill=(251,228,164,255))
    im.save(ROOT/"lock.png",optimize=True)
def cracked():
    im=Image.new("RGBA",(104,104))
    d=ImageDraw.Draw(im)
    d.rounded_rectangle((5,5,99,99),radius=15,fill=(72,79,106,255),outline=(161,172,189,255),width=5)
    d.rounded_rectangle((13,12,90,91),radius=9,outline=(52,56,87,255),width=3)
    p=[(14,37),(31,44),(48,29),(56,52),(76,41),(63,63),(89,78)]
    d.line(p,fill=(19,24,47,255),width=7)
    d.line(p,fill=(202,177,128,210),width=2)
    d.line([(48,29),(41,14),(30,12)],fill=(17,22,39,255),width=4)
    d.line([(63,63),(57,83),(43,96)],fill=(18,22,38,255),width=4)
    im.save(ROOT/"cracked.png",optimize=True)
def booster_plate():
    w,h=160,156
    im=Image.new("RGBA",(w,h))
    d=ImageDraw.Draw(im)
    d.rounded_rectangle((10,5,151,150),radius=29,fill=(22,29,75,245),outline=(247,190,90,255),width=7)
    d.rounded_rectangle((17,12,144,142),radius=25,outline=(131,210,255,235),width=4)
    d.rounded_rectangle((26,20,135,132),radius=20,fill=(20,80,139,205),outline=(49,142,223,240),width=3)
    d.arc((24,16,137,119),180,352,fill=(230,248,255,190),width=5)
    d.ellipse((34,26,48,35),fill=(236,248,255,130))
    im.save(ROOT/"booster_plate.png",optimize=True)
if __name__=="__main__":
    logo();board_frame();locked();cracked();booster_plate()
    for f in ROOT.glob("*.png"):
        print(f.name,f.stat().st_size)

def magic_glow():
    # White-hot core, violet rim, transparent feathered falloff for match bursts.
    im=Image.new("RGBA",(256,256))
    px=im.load()
    for y in range(256):
        for x in range(256):
            r=((x-127.5)**2+(y-127.5)**2)**.5/128.0
            if r>=1.0:continue
            if r<.19:
                color=(255,244,255);alpha=int(205*(1-r/.19)+88)
            elif r<.47:
                k=(r-.19)/.28
                color=(224,128,255);alpha=int(125*(1-k)+55)
            else:
                k=(r-.47)/.53
                color=(156,53,247);alpha=int(66*(1-k)**2)
            px[x,y]=(*color,min(255,alpha))
    im.save(ROOT/"magic_glow.png",optimize=True)

magic_glow()
