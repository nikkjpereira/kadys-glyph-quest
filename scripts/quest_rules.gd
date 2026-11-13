extends RefCounted
## Finite, no-refill puzzle rules for Quest Mode.
## -1 means empty socket, -2 means an immovable stone wall.
## The row-gadget construction is intentionally solvable, not random luck:
## each full row is a scrambled (AAA BBB) pair. Exchanging its middle two
## cells clears exactly six gems. Clearing complete rows bottom-up always wins.
const ROWS := 8
const COLS := 8
const EMPTY := -1
const WALL := -2
const TILE_COUNT := 6
const ROW_GADGET := [0, 0, 1, 0, 1, 1]

static func generate(world: int, level: int) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(190273 + (world + 1) * 7817 + level * 13499)
    var colors: Array[int] = [0, 1, 2, 3, 4, 5]
    for i in range(colors.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var value := colors[i]
        colors[i] = colors[j]
        colors[j] = value
    var shift := posmod(world + level, 3)
    var active_rows := mini(8, 6 + int((level - 1) / 4))
    var tiles: Array[int] = []
    tiles.resize(64)
    tiles.fill(EMPTY)
    for row in range(ROWS):
        for col in range(COLS):
            if col < shift or col >= shift + TILE_COUNT:
                tiles[row * COLS + col] = WALL
    for row in range(ROWS - active_rows, ROWS):
        var pair_id := row % 3
        var a := colors[pair_id * 2]
        var b := colors[pair_id * 2 + 1]
        var inverted := (row + level + world) % 2 == 0
        for x in range(TILE_COUNT):
            var code := ROW_GADGET[x]
            if inverted:
                code = 1 - code
            tiles[row * COLS + shift + x] = a if code == 0 else b
    return {"board": tiles, "shift": shift, "rows": active_rows, "gem_count": active_rows * TILE_COUNT, "seed": rng.seed}

static func remaining(tiles: Array[int]) -> int:
    var result := 0
    for v in tiles:
        if v >= 0:
            result += 1
    return result

static func scan(tiles: Array[int]) -> Array[int]:
    var result: Array[int] = []
    for row in range(ROWS):
        var start := 0
        for col in range(1, COLS + 1):
            if col == COLS or tiles[row * COLS + col] != tiles[row * COLS + start]:
                if col - start >= 3 and tiles[row * COLS + start] >= 0:
                    for c in range(start, col):
                        result.append(row * COLS + c)
                start = col
    for col in range(COLS):
        var start := 0
        for row in range(1, ROWS + 1):
            if row == ROWS or tiles[row * COLS + col] != tiles[start * COLS + col]:
                if row - start >= 3 and tiles[start * COLS + col] >= 0:
                    for r in range(start, row):
                        var idx := r * COLS + col
                        if not result.has(idx):
                            result.append(idx)
                start = row
    return result

static func settle(tiles: Array[int]) -> void:
    # Gravity affects only the segment between immovable stone walls.
    for col in range(COLS):
        var bottom := ROWS - 1
        while bottom >= 0:
            if tiles[bottom * COLS + col] == WALL:
                bottom -= 1
                continue
            var top := bottom
            while top >= 0 and tiles[top * COLS + col] != WALL:
                top -= 1
            var values: Array[int] = []
            for row in range(top + 1, bottom + 1):
                var v := tiles[row * COLS + col]
                if v >= 0:
                    values.append(v)
            for row in range(top + 1, bottom + 1):
                tiles[row * COLS + col] = EMPTY
            for i in range(values.size()):
                tiles[(bottom - values.size() + 1 + i) * COLS + col] = values[i]
            bottom = top - 1

static func resolve(tiles: Array[int]) -> int:
    var total := 0
    for combo in range(24):
        var hits := scan(tiles)
        if hits.is_empty():
            break
        total += hits.size()
        for idx in hits:
            tiles[idx] = EMPTY
        settle(tiles)
    return total

static func legal_moves(tiles: Array[int]) -> Array[Vector2i]:
    var found: Array[Vector2i] = []
    for idx in range(64):
        if tiles[idx] < 0:
            continue
        var checks: Array[int] = []
        if idx % COLS < COLS - 1:
            checks.append(idx + 1)
        if idx < (ROWS - 1) * COLS:
            checks.append(idx + COLS)
        for other in checks:
            if tiles[other] < 0 or tiles[other] == tiles[idx]:
                continue
            var candidate: Array[int] = tiles.duplicate()
            var t := candidate[idx]
            candidate[idx] = candidate[other]
            candidate[other] = t
            if not scan(candidate).is_empty():
                found.append(Vector2i(idx, other))
    return found

static func certified_solution(world: int, level: int) -> bool:
    # A constructive proof, exercised for every world/level in CI.
    var level_data := generate(world, level)
    var tiles: Array[int] = level_data["board"]
    if not scan(tiles).is_empty():
        return false
    var shift := int(level_data["shift"])
    var rows := int(level_data["rows"])
    for row in range(rows):
        var a := (ROWS - 1) * COLS + shift + 2
        var b := a + 1
        if tiles[a] < 0 or tiles[b] < 0:
            return false
        var t := tiles[a]
        tiles[a] = tiles[b]
        tiles[b] = t
        if scan(tiles).is_empty():
            return false
        if resolve(tiles) < 6:
            return false
    return remaining(tiles) == 0

static func can_match(tiles: Array[int], a: int, b: int) -> bool:
    if a < 0 or b < 0 or a >= 64 or b >= 64:
        return false
    if tiles[a] < 0 or tiles[b] < 0 or tiles[a] == tiles[b]:
        return false
    if abs(a % COLS - b % COLS) + abs(int(a / COLS) - int(b / COLS)) != 1:
        return false
    var sim: Array[int] = tiles.duplicate()
    var v := sim[a]
    sim[a] = sim[b]
    sim[b] = v
    return not scan(sim).is_empty()
