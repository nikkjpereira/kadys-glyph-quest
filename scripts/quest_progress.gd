extends RefCounted
## Runefall: fair progression rules shared by gameplay and tests.
## Use integer comparisons to avoid rounding gems into a higher star tier.
const PASS_PERCENT := 75
const TWO_STAR_PERCENT := 85

static func clear_count(start_gems: int, remaining_gems: int) -> int:
    return clampi(start_gems - remaining_gems, 0, maxi(0,start_gems))

static func clear_rate(start_gems: int, remaining_gems: int) -> float:
    return 100.0 * float(clear_count(start_gems,remaining_gems)) / float(maxi(1,start_gems))

static func stars(start_gems: int, remaining_gems: int) -> int:
    if start_gems <= 0:return 0
    var removed: int=clear_count(start_gems,remaining_gems)
    if remaining_gems <= 0:return 3
    if removed * 100 >= 85 * start_gems:return 2
    if removed * 100 >= 75 * start_gems:return 1
    return 0

static func qualifies(start_gems: int,remaining_gems: int) -> bool:
    return stars(start_gems,remaining_gems)>0
