extends RefCounted
## v0.7: Presentation-only animation math. Gameplay and saved state never depend on it.
const FULL_FX_FRAMES_PER_SECOND := 45
const LOW_FX_FRAMES_PER_SECOND := 18
const REDUCED_FRAMES_PER_SECOND := 10

static func frame_rate(reduced_motion: bool, low_effects: bool) -> int:
    if reduced_motion:return REDUCED_FRAMES_PER_SECOND
    if low_effects:return LOW_FX_FRAMES_PER_SECOND
    return FULL_FX_FRAMES_PER_SECOND

static func gem_specular(time: float,cell: int,low_effects: bool,reduced_motion: bool) -> float:
    if reduced_motion or low_effects:return 0.0
    var theta:=time*0.94+float(cell)*2.391
    return pow(maxf(0.0,sin(theta)),11.0)

static func atmosphere_alpha(stage: int,reduced_motion: bool) -> float:
    if reduced_motion:return 0.68
    return clampf(.64 + .08*float(stage),.64,.96)

static func gravity_ease(time_fraction: float,reduced_motion: bool) -> float:
    var t:=clampf(time_fraction,0.0,1.0)
    if reduced_motion:return t
    var ease:=1.0-pow(1.0-t,3.0)
    # A slight spring overshoot near landing, with exact endpoints.
    return clampf(ease + sin(t*PI*2.75)*pow(1.0-t,2.0)*.10,0.0,1.045)

static func shockwave_radius(life: float) -> float:
    return 25.0 + (1.0-clampf(life/.72,0.0,1.0))*74.0

static func debris_count(low_effects: bool,reduced_motion: bool,active_bursts: int) -> int:
    if reduced_motion:return 0
    if low_effects:return 1
    return 2 if active_bursts>12 else 5

static func parallax(time: float,world: int,reduced_motion: bool) -> Vector2:
    if reduced_motion:return Vector2.ZERO
    return Vector2(sin(time*.15+world*.9)*3.5,cos(time*.13+world*.5)*2.5)
