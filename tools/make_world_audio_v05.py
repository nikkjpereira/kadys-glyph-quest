#!/usr/bin/env python3
"""Generate five original, distinct loopable fantasy instrumental themes.
No samples, copyrighted melodies or synthesis dependencies; only stdlib + ffmpeg.
"""
from pathlib import Path
from array import array
import math, subprocess, wave
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"assets"/"audio"/"worlds"
OUT.mkdir(parents=True,exist_ok=True)
RATE=16000
TWO_PI=2*math.pi
CONFIG={
    "menu":   {"bpm":96,"scale":[0,2,4,7,9],"root":62,"progress":[0,3,4,1],"timbre":"bell","beat":.44},
    "runes":  {"bpm":88,"scale":[0,2,3,5,7,10],"root":45,"progress":[0,4,3,1],"timbre":"drone","beat":.52},
    "egypt":  {"bpm":104,"scale":[0,1,4,5,7,8,11],"root":50,"progress":[0,4,3,1],"timbre":"reed","beat":.60},
    "asia":   {"bpm":80,"scale":[0,2,4,7,9],"root":57,"progress":[0,3,2,4],"timbre":"pluck","beat":.36},
    "mixed":  {"bpm":110,"scale":[0,2,3,5,7,9,10],"root":53,"progress":[0,4,2,3],"timbre":"hybrid","beat":.60}
}
def hz(midi):
    return 440.0*2**((midi-69)/12)
def main():
    for name,p in CONFIG.items():
        bpm=p["bpm"]
        beat=60.0/bpm
        bars=16
        length=bars*4*beat
        n=int(length*RATE)
        samples=array("f",[0.0])*n
        scale=p["scale"]
        degree=len(scale)
        root=p["root"]
        def note_to_midi(deg,octaves=0):
            return root+scale[deg%degree]+12*(deg//degree+octaves)
        def instrument(midi,start,duration,kind,vol):
            frequency=hz(midi)
            begin=int(start*RATE)
            end=min(n,begin+int(duration*RATE))
            for i in range(max(0,begin),end):
                t=(i-begin)/RATE
                if kind=="pluck":
                    env=math.exp(-3.6*t/max(.1,duration))*(1-math.exp(-t*70))
                    value=(math.sin(TWO_PI*frequency*t)+.32*math.sin(TWO_PI*2*frequency*t)+.11*math.sin(TWO_PI*3*frequency*t))
                elif kind=="bell":
                    env=math.exp(-3.3*t/max(.1,duration))*(1-math.exp(-t*100))
                    value=(math.sin(TWO_PI*frequency*t)+.38*math.sin(TWO_PI*frequency*2.013*t)+.18*math.sin(TWO_PI*frequency*3.7*t))
                elif kind=="reed":
                    env=min(1,t/.09)*min(1,(duration-t)/.13)
                    vibrato=1+0.004*math.sin(2*math.pi*5*t)
                    value=(math.sin(TWO_PI*frequency*t*vibrato)+.18*math.sin(TWO_PI*3*frequency*t))
                elif kind=="drone":
                    env=min(1,t/.35)*min(1,(duration-t)/.45)
                    value=(math.sin(TWO_PI*frequency*t)+.27*math.sin(TWO_PI*frequency*.502*t)+.08*math.sin(TWO_PI*frequency*2*t))
                else:
                    env=math.exp(-2.0*t/max(.1,duration))*(1-math.exp(-t*70))
                    value=(math.sin(TWO_PI*frequency*t)+.3*math.sin(TWO_PI*2*frequency*t))
                samples[i]+=value*env*vol
        def drum(start,low=True,vol=.09):
            begin=int(start*RATE)
            duration=.26 if low else .14
            end=min(n,begin+int(duration*RATE))
            for i in range(begin,end):
                t=(i-begin)/RATE
                freq=(74 if low else 420)*math.exp(-t*(7 if low else 3))
                env=math.exp(-t*(16 if low else 34))
                samples[i]+=math.sin(TWO_PI*freq*t)*env*vol
        # Four chords repeated across 16 bars, with original pentatonic or
        # modal melodies and independent world-specific timbres.
        for bar in range(bars):
            chord=p["progress"][bar%4]
            start=bar*4*beat
            bass=note_to_midi(chord,-1)
            instrument(bass,start,4*beat,"drone" if name in ("runes","mixed") else "pluck",.10)
            instrument(note_to_midi(chord),start,3.8*beat,"drone",.04)
            instrument(note_to_midi(chord+2),start+.03,3.7*beat,"drone",.028)
            if name=="runes":
                for b in [0,2,3]:
                    drum(start+b*beat,low=(b!=3),vol=.11)
                for j,deg in enumerate([chord+4,chord+3,chord+2,chord+4]):
                    instrument(note_to_midi(deg,1),start+j*beat,beat*.72,"bell",.085)
            elif name=="egypt":
                for j in range(8):
                    drum(start+j*.5*beat,low=(j%4==0),vol=.11 if j%4==0 else .055)
                for j,deg in enumerate([chord+3,chord+4,chord+1,chord+5]):
                    instrument(note_to_midi(deg,1),start+j*beat,beat*.80,"reed",.12)
            elif name=="asia":
                for j,deg in enumerate([chord+4,chord+2,chord+1,chord+3,chord+4]):
                    instrument(note_to_midi(deg,1),start+j*.7*beat,beat*.92,"pluck",.12)
                if bar%2==0:instrument(note_to_midi(chord+5,1),start+1.75*beat,1.65*beat,"reed",.065)
                drum(start,True,.035)
            elif name=="mixed":
                for j in range(8):
                    drum(start+j*.5*beat,j%4==0,.08 if j%4 else .12)
                for j,deg in enumerate([chord+4,chord+2,chord+5,chord+3,chord+4,chord+2]):
                    instrument(note_to_midi(deg,1),start+j*(4*beat/6),beat*.52,["bell","pluck","reed"][j%3],.085)
            else:
                for j,deg in enumerate([chord+2,chord+4,chord+5,chord+3,chord+1]):
                    instrument(note_to_midi(deg,1),start+j*.75*beat,beat*.75,"bell",.10)
                drum(start,True,.035)
        # Gentle fade exactly at loop boundaries to avoid hard discontinuities.
        fade=int(.11*RATE)
        peak=max(0.1,max(abs(x) for x in samples))
        scale=.72/peak
        pcm=array("h")
        for i,v in enumerate(samples):
            env=min(1.0, i/max(1,fade), (n-1-i)/max(1,fade))
            pcm.append(int(max(-1,min(1,v*scale*max(0.0,env)))*32760))
        wav=OUT/(name+".wav")
        with wave.open(str(wav),"wb") as f:
            f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(pcm.tobytes())
        ogg=OUT/(name+".ogg")
        subprocess.run(["ffmpeg","-nostdin","-loglevel","error","-y","-i",str(wav),"-c:a","libvorbis","-q:a","4",str(ogg)],check=True)
        wav.unlink()
        print(name,"seconds",round(length,1),"ogg bytes",ogg.stat().st_size,flush=True)
if __name__=="__main__":
    main()
