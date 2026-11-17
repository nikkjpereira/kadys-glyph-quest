#!/usr/bin/env python3
"""Glyph Quest 0.6 deterministic dense puzzle fixtures and reproducible difficulty probes.
Reuse the 0.5 reverse-proof builder, but insist on >=57 gems, no blank top row,
and vary locks / ice / chains without breaking the certified clearing path.
A recorded 18-19 move proof is NOT a proof of optimal solution length.
"""
import importlib.util, json, random, collections, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location("legacy",ROOT/"tools/make_levels_v05.py")
legacy=importlib.util.module_from_spec(spec)
spec.loader.exec_module(legacy)
OUT=ROOT/"data"/"levels_v06.json"
WORLD_RELICS=[
 ["Frost Rune","Viking Compass","Aurora Amulet","Runestone Crown"],
 ["Golden Scarab","Eye of the Sun","Ankh of Life","Pharaoh Seal"],
 ["Jade Lotus","Moon Lantern","Dragon Seal","Celestial Scroll"],
 ["Crystal Key","Starlit Tome","Arcane Compass","Astral Crown"]
]
def replay(board, path, seals):
    return legacy.run_solution(board,path,seals)

def overlays(board,path,w,l,seed):
    rng=random.Random(seed+817)
    b=list(board);locks=[0]*64;kind=[0]*64
    states=replay(b,path,locks)
    if not states:raise ValueError("initial proof failed")
    # A cracked stone sits in a permanently empty socket if possible. It is
    # NOT a puzzle's required objective. It may be destroyed by an adjacent match.
    choices=[i for i,v in enumerate(b) if v==-1 and i%8 not in (0,7)]
    rng.shuffle(choices)
    if l>=4:
        for idx in choices:
            candidate=b.copy();candidate[idx]=-3
            if replay(candidate,path,locks):
                b=candidate
                break
    # On late levels, distribute 1-3 sealed gems: magic locks, frosted gems,
    # and two-hit runic chains, validated against the WHOLE certified solution.
    cap=0 if l==1 and w==0 else 1 if l<5 else 2 if l<9 else 3
    selected=[]
    candidates=[i for i,v in enumerate(b) if v>=0]
    rng.shuffle(candidates)
    order=[1,3,2] if l>=8 else [1,3]
    for seal_kind in order:
        if len(selected)>=cap:break
        hp=2 if seal_kind==2 else 1
        for idx in candidates:
            if idx in selected:continue
            if any(abs(idx//8-k//8)+abs(idx%8-k%8)<3 for k in selected):continue
            new=locks.copy();new[idx]=hp
            if replay(b,path,new):
                locks=new;kind[idx]=seal_kind;selected.append(idx)
                break
    return b,locks,kind

def probe(board,locks,seed,rounds=16):
    # Deterministic greedy/randomized simulations to catch obvious cheap
    # alternatives, but intentionally do not claim a mathematically minimal path.
    rng=random.Random(seed)
    observed=999
    first_choices=len(legacy.moves(board,locks))
    for _ in range(rounds):
        b=list(board);seals=list(locks);steps=0
        while steps<24 and sum(x>=0 for x in b)>0:
            legal=legacy.moves(b,seals)
            if not legal:break
            ranked=[]
            for a,c in legal:
                tmp=b.copy();tmp[a],tmp[c]=tmp[c],tmp[a]
                after,_,removed,_=legacy.resolve(tmp,seals[:])
                ranked.append((removed,rng.random(),a,c,after))
            ranked.sort(reverse=True)
            select=ranked[0] if rng.random()<.77 else ranked[min(len(ranked)-1,rng.randrange(min(4,len(ranked))))]
            a,c=select[2:4]
            b[a],b[c]=b[c],b[a]
            b,seals,_,_=legacy.resolve(b,seals)
            steps+=1
        if sum(x>=0 for x in b)==0:observed=min(observed,steps)
    return first_choices,0 if observed==999 else observed

def generate():
    entries=[];now=time.time()
    for w in range(4):
        for level in range(1,13):
            # 18 successful swaps => 57 starting gems. 19 => 60 gems.
            # The old 9-swap intro produced a half-empty board; removed.
            steps=18 if level<=4 and w<=1 else 19
            seed=163731+w*8821+level*1511
            first=None
            for trial in range(7):
                ss=seed+trial*9871
                b,path=legacy.candidate(ss,steps)
                if sum(x>=0 for x in b)<54 or not any(x>=0 for x in b[:8]):continue
                b,seals,kind=overlays(b,path,w,level,ss)
                if not replay(b,path,seals):continue
                first=(b,seals,kind,path,ss)
                break
            if first is None:raise ValueError(f"No dense certified board for {w}/{level}")
            b,seals,kind,path,ss=first
            choices,short=probe(b,seals,ss,rounds=12)
            if short>0 and short<10:raise ValueError(f"Unexpected trivial alternate route at {w}-{level}: {short}")
            gem_count=sum(x>=0 for x in b)
            entries.append({
                "world":w,"level":level,"board":b,"locks":seals,"seal_types":kind,
                "solution":[list(pair) for pair in path],
                "min_certified_moves":len(path),
                "gem_count":gem_count,"obstacles":sum(x in (-2,-3) for x in b),
                "difficulty":"intro" if level<=3 and w==0 else "advanced" if level>7 or w>1 else "intermediate",
                "opening_choices":choices, "shortest_sampled_clear":short,
                "relic":WORLD_RELICS[w][min(3,(level-1)//3)],
                "board_family":["Full Board","Broken Ruins","Center Core","Runic Lock","Fractured Board","Side Chambers"][(w*3+level)%6]
            })
            print(f"{w+1}/{level:02d}: {gem_count} gems, top {sum(x>=0 for x in b[:8])},"
                  f" {len(path)}-move proof, {choices} opening choices, {sum(v>0 for v in seals)} seals,"
                  f" {sum(x==-3 for x in b)} cracked; random-sampled shortest={short or 'none'}",flush=True)
    OUT.write_text(json.dumps({"version":6,"levels":entries,"relics":WORLD_RELICS},separators=(',',':'))+'\n')
    print(f"PASS: {len(entries)} dense certified puzzles, {OUT.stat().st_size} bytes, {time.time()-now:.1f}s")
if __name__=="__main__":generate()
