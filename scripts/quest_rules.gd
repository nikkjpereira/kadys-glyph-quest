extends RefCounted
## Glyph Quest v0.6: dense certified puzzles, multi-stage seals, gravity, hints.
const ROWS := 8
const COLS := 8
const EMPTY := -1
const WALL := -2
const CRACK := -3

static var _catalog: Dictionary = {}
static func generate(world: int, level: int) -> Dictionary:
    if _catalog.is_empty():
        var json: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/levels_v06.json"))
        if typeof(json)==TYPE_DICTIONARY:
            _catalog=json
    var data: Variant=_catalog
    if typeof(data) != TYPE_DICTIONARY:
        push_error("Could not load certified v0.5 puzzles.")
        return {}
    var entries: Array = data.get("levels", [])
    var key := clampi(world,0,3)*12+clampi(level,1,12)-1
    if key < 0 or key >= entries.size():
        push_error("Certified level missing: %s" % key)
        return {}
    var item: Dictionary = entries[key]
    var board: Array[int] = []
    var locks: Array[int] = []
    var seal_types: Array[int] = []
    for value in item.get("board", []):
        board.append(int(value))
    for value in item.get("locks", []):
        locks.append(int(value))
    for value in item.get("seal_types", []):
        seal_types.append(int(value))
    return {
        "board":board,
        "locks":locks,
        "seal_types":seal_types,
        "solution":item.get("solution",[]),
        "gem_count":int(item.get("gem_count",0)),
        "min_certified_moves":int(item.get("min_certified_moves",0)),
        "obstacles":int(item.get("obstacles",0)),
        "opening_choices":int(item.get("opening_choices",0)),
        "board_family":str(item.get("board_family","Full Board")),
        "relic":str(item.get("relic","Ancient Relic"))
    }

static func solution_pair(level_data: Dictionary, index: int) -> Vector2i:
    var pairs: Array = level_data.get("solution", [])
    if index<0 or index>=pairs.size():
        return Vector2i(-1,-1)
    var pair: Array = pairs[index]
    return Vector2i(int(pair[0]),int(pair[1]))

static func remaining(tiles: Array[int]) -> int:
    var count := 0
    for item in tiles:
        if item>=0:count+=1
    return count

static func scan(tiles: Array[int]) -> Array[int]:
    var hits: Array[int] = []
    for r in range(ROWS):
        var start := 0
        for c in range(1,COLS+1):
            if c==COLS or tiles[r*COLS+c]!=tiles[r*COLS+start]:
                if c-start>=3 and tiles[r*COLS+start]>=0:
                    for col in range(start,c):
                        var idx:=r*COLS+col
                        if not hits.has(idx):hits.append(idx)
                start=c
    for c in range(COLS):
        var start := 0
        for r in range(1,ROWS+1):
            if r==ROWS or tiles[r*COLS+c]!=tiles[start*COLS+c]:
                if r-start>=3 and tiles[start*COLS+c]>=0:
                    for row in range(start,r):
                        var idx:=row*COLS+c
                        if not hits.has(idx):hits.append(idx)
                start=r
    return hits

static func neighbors(idx: int) -> Array[int]:
    var result: Array[int] = []
    var col:=idx%COLS
    var row:=int(idx/COLS)
    if col>0:result.append(idx-1)
    if col<COLS-1:result.append(idx+1)
    if row>0:result.append(idx-COLS)
    if row<ROWS-1:result.append(idx+COLS)
    return result

static func adjacent_obstacles(tiles: Array[int],locks: Array[int], hits: Array[int],seal_types: Array[int] = []) -> Dictionary:
    var cracked: Dictionary = {}
    var unlocked: Dictionary = {}
    for idx in hits:
        for n in neighbors(idx):
            if tiles[n]==CRACK:
                cracked[n]=true
            if not locks.is_empty() and tiles[n]>=0 and locks[n]>0:
                locks[n]-=1
                if locks[n]==0:
                    unlocked[n]=true
                    if seal_types.size()==64:seal_types[n]=0
    for idx in hits:
        if not locks.is_empty():locks[idx]=0
        if seal_types.size()==64:seal_types[idx]=0
    for idx in cracked.keys():
        tiles[idx]=EMPTY
        if seal_types.size()==64:seal_types[idx]=0
    return {"cracked":cracked.keys(),"unlocked":unlocked.keys()}

static func settle(tiles: Array[int],locks: Array[int] = [],seal_types: Array[int] = []) -> void:
    for col in range(COLS):
        var bottom:=ROWS-1
        while bottom>=0:
            if tiles[bottom*COLS+col] in [WALL,CRACK]:
                bottom-=1
                continue
            var top:=bottom
            while top>=0 and tiles[top*COLS+col] not in [WALL,CRACK]:
                top-=1
            var values: Array[int] = []
            var seals: Array[int] = []
            var kinds: Array[int] = []
            for row in range(top+1,bottom+1):
                var idx:=row*COLS+col
                if tiles[idx]>=0:
                    values.append(tiles[idx])
                    if not locks.is_empty():seals.append(locks[idx])
                    if seal_types.size()==64:kinds.append(seal_types[idx])
            for row in range(top+1,bottom+1):
                var idx:=row*COLS+col
                tiles[idx]=EMPTY
                if not locks.is_empty():locks[idx]=0
                if seal_types.size()==64:seal_types[idx]=0
            for k in range(values.size()):
                var idx: int=(bottom-values.size()+1+k)*COLS+col
                tiles[idx]=values[k]
                if not locks.is_empty():locks[idx]=seals[k]
                if seal_types.size()==64:seal_types[idx]=kinds[k]
            bottom=top-1

static func resolve(tiles: Array[int],locks: Array[int] = [],seal_types: Array[int] = []) -> int:
    var total:=0
    for step in range(28):
        var hits:=scan(tiles)
        if hits.is_empty():break
        total+=hits.size()
        adjacent_obstacles(tiles,locks,hits,seal_types)
        for idx in hits:
            tiles[idx]=EMPTY
        settle(tiles,locks,seal_types)
    return total

static func legal_moves(tiles: Array[int],locks: Array[int] = []) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for i in range(ROWS*COLS):
        if tiles[i]<0 or (not locks.is_empty() and locks[i]>0):
            continue
        for j in [i+1 if i%COLS<COLS-1 else -1,i+COLS if i<(ROWS-1)*COLS else -1]:
            if j<0 or tiles[j]<0 or tiles[i]==tiles[j] or (not locks.is_empty() and locks[j]>0):
                continue
            var candidate: Array[int]=tiles.duplicate()
            var temp:=candidate[i]
            candidate[i]=candidate[j]
            candidate[j]=temp
            if not scan(candidate).is_empty():
                result.append(Vector2i(i,j))
    return result

static func can_match(tiles: Array[int],a: int,b: int,locks: Array[int] = []) -> bool:
    if a<0 or b<0 or a>=64 or b>=64:return false
    if tiles[a]<0 or tiles[b]<0 or tiles[a]==tiles[b]:return false
    if not locks.is_empty() and (locks[a]>0 or locks[b]>0):return false
    if abs(a%COLS-b%COLS)+abs(int(a/COLS)-int(b/COLS))!=1:return false
    var clone: Array[int]=tiles.duplicate()
    var tmp:=clone[a]
    clone[a]=clone[b]
    clone[b]=tmp
    return not scan(clone).is_empty()

static func certified_solution(world: int,level: int) -> bool:
    var data:=generate(world,level)
    if data.is_empty():return false
    var board: Array[int]=data["board"]
    var locks: Array[int]=data["locks"]
    var types: Array[int]=data["seal_types"]
    if board.size()!=64 or locks.size()!=64 or types.size()!=64 or not scan(board).is_empty():
        return false
    var actions: Array=data["solution"]
    if actions.size()<18 or remaining(board)<54:return false
    for pair_data in actions:
        var pair: Array=pair_data
        var a:=int(pair[0])
        var b:=int(pair[1])
        if not can_match(board,a,b,locks):return false
        var v:=board[a]
        board[a]=board[b]
        board[b]=v
        if resolve(board,locks,types)<3:return false
    return remaining(board)==0

static func certified_next_move(world: int, level: int, tiles: Array[int],locks: Array[int],seal_types: Array[int]) -> Vector2i:
    # If the player is still following the level's certified solution,
    # offer the next *proven* move, not a greedy short-term match.
    var entry:=generate(world,level)
    if entry.is_empty():return Vector2i(-1,-1)
    var state: Array[int]=entry["board"].duplicate()
    var seals: Array[int]=entry["locks"].duplicate()
    var kinds: Array[int]=entry["seal_types"].duplicate()
    for pair_data in entry["solution"]:
        var pair: Array=pair_data
        var a:=int(pair[0])
        var b:=int(pair[1])
        if state==tiles and seals==locks and kinds==seal_types:
            return Vector2i(a,b)
        if not can_match(state,a,b,seals):
            break
        var old:=state[a]
        state[a]=state[b]
        state[b]=old
        resolve(state,seals,kinds)
    return Vector2i(-1,-1)

static func _move_result(tiles: Array[int],locks: Array[int],seal_types: Array[int],pair: Vector2i) -> Dictionary:
    var result_board: Array[int]=tiles.duplicate()
    var result_locks: Array[int]=locks.duplicate()
    var result_types: Array[int]=seal_types.duplicate()
    var old:=result_board[pair.x]
    result_board[pair.x]=result_board[pair.y]
    result_board[pair.y]=old
    var n:=resolve(result_board,result_locks,result_types)
    return {"board":result_board,"locks":result_locks,"seal_types":result_types,"removed":n}

static func recommend_move(world: int,level: int,tiles: Array[int],locks: Array[int],seal_types: Array[int],quest_mode: bool=true) -> Vector2i:
    var options:=legal_moves(tiles,locks)
    if options.is_empty():return Vector2i(-1,-1)
    if not quest_mode:return options[0]
    var proof:=certified_next_move(world,level,tiles,locks,seal_types)
    if proof.x>=0 and options.has(proof):
        return proof
    # For off-certificate states, look ahead one additional move and penalize
    # deadlocks. This is a bounded heuristic, not a guarantee of solvability.
    var best: Vector2i=options[0]
    var best_score: float=-INF
    for pair in options:
        var first:=_move_result(tiles,locks,seal_types,pair)
        var first_board: Array[int]=first["board"]
        var first_locks: Array[int]=first["locks"]
        var first_types: Array[int]=first["seal_types"]
        var first_removed:=int(first["removed"])
        var next_options:=legal_moves(first_board,first_locks)
        var best_second:=0
        for next_index in range(mini(16,next_options.size())):
            var follow: Vector2i=next_options[next_index]
            var sim:=_move_result(first_board,first_locks,first_types,follow)
            best_second=maxi(best_second,int(sim["removed"]))
        var score:=float(first_removed)*100.0+float(best_second)*80.0
        score+=float(next_options.size())*.8
        if remaining(first_board)==0:score+=200000.0
        elif next_options.is_empty():score-=10000.0
        if score>best_score:
            best_score=score
            best=pair
    return best

static func recovery_shuffle(tiles: Array[int],locks: Array[int]) -> Array[int]:
    # Rescue never spawns fresh gems, consumes a charge, or claims that
    # an arbitrary remaining layout must be solvable.
    var movable: Array[int]=[]
    var values: Array[int]=[]
    for i in range(tiles.size()):
        if tiles[i]>=0 and (locks.is_empty() or locks[i]==0):
            movable.append(i)
            values.append(tiles[i])
    if values.size()<3:return []
    for attempt in range(350):
        values.shuffle()
        var candidate: Array[int]=tiles.duplicate()
        for j in range(movable.size()):
            candidate[movable[j]]=values[j]
        if scan(candidate).is_empty() and not legal_moves(candidate,locks).is_empty():
            return candidate
    return []
