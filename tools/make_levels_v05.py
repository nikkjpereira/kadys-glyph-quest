#!/usr/bin/env python3
"""Constructive, independently validated finite board puzzles for v0.5.
Reverse-inserts a three-stone match above a stable finite board and swaps a
stone beneath it to hide the match. Reversing the recorded operations is a
proof that the complete board can be cleared. No runtime solver or booster.
"""
from __future__ import annotations
from pathlib import Path
import json, random, math
N=8; EMPTY=-1; WALL=-2; CRACK=-3
ROOT=Path(__file__).resolve().parents[1]
TARGET=ROOT/"data"/"levels_v05.json"

def neighbors(i):
    r,c=divmod(i,N)
    return [rr*N+cc for rr,cc in ((r-1,c),(r+1,c),(r,c-1),(r,c+1)) if 0<=rr<N and 0<=cc<N]
def scan(board):
    hit=set()
    for r in range(N):
        for c in range(N-2):
            j=r*N+c
            if board[j]>=0 and board[j]==board[j+1]==board[j+2]:hit.update((j,j+1,j+2))
    for c in range(N):
        for r in range(N-2):
            j=r*N+c
            if board[j]>=0 and board[j]==board[j+N]==board[j+2*N]:hit.update((j,j+N,j+2*N))
    return hit
def settle(board,locks=None):
    board=list(board)
    locks=list(locks) if locks else [0]*64
    for col in range(N):
        bottom=N-1
        while bottom>=0:
            if board[bottom*N+col] in (WALL,CRACK):
                bottom-=1
                continue
            top=bottom
            while top>=0 and board[top*N+col] not in (WALL,CRACK):top-=1
            gems=[(board[r*N+col],locks[r*N+col]) for r in range(top+1,bottom+1) if board[r*N+col]>=0]
            for r in range(top+1,bottom+1):
                board[r*N+col]=EMPTY;locks[r*N+col]=0
            for k,(v,l) in enumerate(gems):
                pos=(bottom-len(gems)+1+k)*N+col
                board[pos]=v;locks[pos]=l
            bottom=top-1
    return board,locks
def resolve(board,locks=None):
    board=list(board)
    locks=list(locks) if locks else [0]*64
    total=0;combos=0
    for i in range(28):
        hits=scan(board)
        if not hits:break
        combos+=1;total+=len(hits)
        cracked=set()
        for idx in hits:
            for n in neighbors(idx):
                if board[n]==CRACK:cracked.add(n)
                elif board[n]>=0 and locks[n]>0:locks[n]-=1
        for idx in hits:
            board[idx]=EMPTY;locks[idx]=0
        for idx in cracked:board[idx]=EMPTY
        board,locks=settle(board,locks)
    return board,locks,total,combos
def moves(board,locks=None):
    locks=locks or [0]*64
    arr=[]
    for idx in range(64):
        if board[idx]<0 or locks[idx]:continue
        for other in [idx+1 if idx%8<7 else -1,idx+8 if idx<56 else -1]:
            if other<0 or board[other]<0 or locks[other] or board[other]==board[idx]:continue
            a=board.copy();a[idx],a[other]=a[other],a[idx]
            if scan(a):arr.append((idx,other))
    return arr
def base(rng):
    colors=rng.sample(range(6),2)
    b=[EMPTY]*64;b[56]=WALL;b[63]=WALL
    for c,v in enumerate([colors[0],colors[0],colors[1],colors[0],colors[1],colors[1]],1):
        b[56+c]=v
    return b,(59,60)
def options(board,rng):
    out=[]
    # Add three matching gems at the tops of three evenly tall neighboring
    # columns, then hide the match with a vertical swap.
    for r in range(8):
        for c in range(6):
            ids=[r*8+c+k for k in range(3)]
            if not all(board[i]==EMPTY and (r==7 or board[i+8]!=EMPTY) for i in ids):
                continue
            for k in range(3):
                idx=ids[k];below=idx+8
                if r==7 or board[below]<0:continue
                for color in range(6):
                    if color==board[below]:continue
                    candidate=board.copy()
                    for i in ids:candidate[i]=color
                    candidate[idx],candidate[below]=candidate[below],candidate[idx]
                    if scan(candidate):continue
                    verify=candidate.copy()
                    verify[idx],verify[below]=verify[below],verify[idx]
                    solved,_,count,_=resolve(verify)
                    if count==3 and solved==board:
                        out.append((candidate,(idx,below),"H"))
    # Vertically add three; swapping the lowest with an older gem hides it.
    for c in range(8):
        for r in range(6):
            ids=[(r+k)*8+c for k in range(3)]
            if not all(board[i]==EMPTY for i in ids):continue
            below=(r+3)*8+c
            if board[below]<0:continue
            for color in range(6):
                if color==board[below]:continue
                candidate=board.copy()
                for i in ids:candidate[i]=color
                idx=ids[-1]
                candidate[idx],candidate[below]=candidate[below],candidate[idx]
                if scan(candidate):continue
                verify=candidate.copy()
                verify[idx],verify[below]=verify[below],verify[idx]
                solved,_,count,_=resolve(verify)
                if count==3 and solved==board:out.append((candidate,(idx,below),"V"))
    rng.shuffle(out)
    return out
def candidate(seed,steps):
    rng=random.Random(seed)
    best=None
    for attempt in range(25):
        board,pair=base(random.Random(seed+attempt*133))
        history=[pair]
        for step in range(steps-1):
            variants=options(board,rng)
            if not variants:break
            def score(item):
                arr,move,axis=item
                heights=[sum(arr[r*8+c]>=0 for r in range(8)) for c in range(8)]
                spread=max(heights)-min(heights)
                used=sum(x>0 for x in heights)
                return used*11-spread*2.7-sum(x*x for x in heights)*.08+(axis=="H")*2+rng.random()*13
            board,pair,_=max(variants,key=score)
            history.append(pair)
        if best is None or len(history)>len(best[1]):best=(board,history)
        if len(history)>=steps:break
    if len(best[1])!=steps:raise ValueError(f"cannot generate {steps} certified operations, got {len(best[1])}")
    return best[0],list(reversed(best[1]))

def run_solution(board,path,locks=None):
    b=list(board);l=list(locks) if locks else [0]*64
    state=[b.copy()]
    cascade_counts=[]
    for a,c in path:
        if abs(a%8-c%8)+abs(a//8-c//8)!=1:return None
        if b[a]<0 or b[c]<0 or l[a] or l[c]:return None
        b[a],b[c]=b[c],b[a]
        if not scan(b):return None
        b,l,n,combo=resolve(b,l)
        if n==0:return None
        cascade_counts.append(combo)
        state.append(b.copy())
    if sum(x>=0 for x in b)>0:return None
    return state,cascade_counts

def choose_overlay(board,path,level,world,seed):
    # Only place obstacles if the *entire* original certificate still runs.
    rng=random.Random(seed+791)
    b=board.copy()
    locks=[0]*64
    base_run=run_solution(b,path)
    if not base_run:raise ValueError("original solution failed")
    states=base_run[0]
    # Truly sparse: two existing corner stones, 0..2 extra distributed blockers.
    always_empty=[i for i in range(64)
                  if all(state[i]==EMPTY for state in states)
                  and i not in (56,63) and 1<=i//8<=6]
    rng.shuffle(always_empty)
    max_block=0 if level<4 else (1 if level<9 else 2)
    chosen=[]
    for idx in always_empty:
        if len(chosen)>=max_block:break
        if any(abs(idx//8-j//8)+abs(idx%8-j%8)<3 for j in chosen+( [56,63] )):
            continue
        for kind in ([CRACK,WALL] if level>=6 else [WALL]):
            try_board=b.copy();try_board[idx]=kind
            if run_solution(try_board,path):
                b=try_board;chosen.append(idx);break
    # Locks are immobilized gem overlays that release on neighboring clears.
    if level>=5:
        matches=set(path[0])
        near_first=[]
        first_state=states[0]
        for idx in range(64):
            if b[idx]<0 or idx in matches:continue
            if any(n in neighbors(idx) for n in matches):
                near_first.append(idx)
        rng.shuffle(near_first)
        for idx in near_first:
            if sum(locks)>= (1 if level<9 else 2):break
            test=locks.copy();test[idx]=1
            if run_solution(b,path,test):
                locks=test
    return b,locks
def generate():
    results=[]
    for world in range(4):
        for level in range(1,13):
            # Level 1 in each world is a lighter introduction, but never the
            # old six-swap layout. Later worlds start further up the curve.
            length=min(19, 9+(level-1)//2+world*2)
            seed=163731+world*8821+level*1511
            board,path=candidate(seed,length)
            mirrored=(world+level)%2==0
            if mirrored:
                def flip(i):return (i//8)*8+7-i%8
                board=[board[flip(i)] for i in range(64)]
                path=[(flip(a),flip(c)) for a,c in path]
            board,locks=choose_overlay(board,path,level,world,seed)
            result=run_solution(board,path,locks)
            if not result:raise ValueError(f"invalid level {world+1}-{level}")
            if len(path)<9:raise ValueError("too short")
            if scan(board):raise ValueError("starting matches")
            if not moves(board,locks):raise ValueError("unplayable start")
            results.append({"world":world,"level":level,"board":board,"locks":locks,
                            "solution":[list(p) for p in path],
                            "min_certified_moves":len(path),
                            "gem_count":sum(v>=0 for v in board),
                            "obstacles":sum(v in (WALL,CRACK) for v in board),
                            "difficulty":"intro" if length<=10 else "intermediate" if length<=14 else "advanced"})
            print(f"world {world+1} level {level:02} proof {len(path):2} moves, {sum(v>=0 for v in board):2} gems, "
                  f"{sum(v in (WALL,CRACK) for v in board)} obstacles, {sum(locks)} locks")
    TARGET.parent.mkdir(parents=True,exist_ok=True)
    TARGET.write_text(json.dumps({"version":5,"levels":results},separators=(",",":"))+"\n")
    print(f"PASS: {len(results)} certified levels, {TARGET.stat().st_size} bytes")
if __name__=="__main__":
    generate()
