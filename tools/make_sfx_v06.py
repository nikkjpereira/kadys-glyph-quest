#!/usr/bin/env python3
"""Generate original, royalty-free Glyph Quest effect sounds using pure synthesis."""
from pathlib import Path
import math,wave,random,array
OUT=Path(__file__).resolve().parents[1]/"assets"/"audio"/"v06"
OUT.mkdir(parents=True,exist_ok=True)
rate=22050
tasks={"stone":(.33,83,5),"seal":(.62,475,2),"combo":(.95,640,3),"relic":(1.20,370,4),"land":(.19,120,1),"ice":(.40,760,6)}
for name,(duration,base,kind) in tasks.items():
    rng=random.Random(7511+kind)
    output=array.array("h")
    for k in range(int(duration*rate)):
        t=k/rate
        tau=t/duration
        if kind==5:
            v=(.40*math.sin(2*math.pi*(base*(1+2*(1-tau)))*t)+.55*rng.uniform(-1,1)) * math.exp(-8*t)
        elif kind==2:
            v=(math.sin(2*math.pi*(base+270*t)*t)+.45*math.sin(2*math.pi*(base*1.67+500*t)*t)) * (1-tau)**1.8
        elif kind==3:
            v=sum(math.sin(2*math.pi*(base*(1.0+.25*i)+190*t)*t+.15*i) for i in range(4))*.22*math.sin(min(1.0,t*18)*math.pi/2)*(1-tau)
        elif kind==4:
            v=(math.sin(2*math.pi*(base+110*t)*t)+.4*math.sin(2*math.pi*(base*1.5+120*t)*t)) * math.sin(math.pi*min(1,t/.15)/2)*(1-tau)**1.0
        elif kind==1:
            v=math.sin(2*math.pi*base*math.exp(-9*t)*t)*math.exp(-16*t)
        else:
            v=(math.sin(2*math.pi*(base-250*t)*t)+.6*rng.uniform(-1,1))*math.exp(-8*t)
        output.append(int(max(-1,min(1,v*.55))*30000))
    file=OUT/(name+".wav")
    with wave.open(str(file),"wb") as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(output.tobytes())
    print(name,round(duration,2),file.stat().st_size)
