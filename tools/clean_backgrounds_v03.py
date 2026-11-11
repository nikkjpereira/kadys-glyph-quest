#!/usr/bin/env python3
"""Darken baked labels and old mockup tiles that appeared in the concept-image side margins."""
from PIL import Image, ImageFilter
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'assets'/'v03'

def scrub(name, top, bottom, margin, dark=0.78):
    path=root/name
    base=Image.open(path).convert('RGBA')
    blur=base.filter(ImageFilter.GaussianBlur(18))
    pix=base.load();src=blur.load()
    for y in range(top,min(bottom,base.height)):
        yf=min(1.0,(y-top)/48.0,(bottom-y)/48.0)
        for x in range(base.width):
            edge=max(0.0, (margin-x)/margin, (x-(base.width-margin))/margin)
            t=max(0,min(1,edge*yf))*dark
            if t <= 0:continue
            r,g,b,a=pix[x,y]
            rr,gg,bb,_=src[x,y]
            # Recreate stone/library depth without leaving legible baked mockup labels.
            pix[x,y]=(int((1-t)*r+t*(rr*.48+22*.52)),int((1-t)*g+t*(gg*.48+17*.52)),int((1-t)*b+t*(bb*.48+42*.52)),a)
    base.save(path,optimize=True)
    print('cleaned',name,path.stat().st_size)

if __name__ == '__main__':
    scrub('menu_scene.png',765,1350,135,.80)
    for n in ['runes_scene.png','egypt_scene.png','asia_scene.png','mixed_scene.png']:
        scrub(n,455,1200,100,.86)
