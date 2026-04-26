# RuVJ Cheat Sheet

## Quick Reference

```ruby
# shapes
Bg(color:)
Circle(x: 0, y: 0, r: 1, color:, z: 0, steps: 16)
Rect(x: 0, y: 0, w: 1, h: 1, color:, z: 0)
Triangle(x: 0, y: 0, size: 1, angle: 0, color:, z: 0)
Line(x1: 0, y1: 0, x2: 1, y2: 0, color:, z: 0, bold: 0)
Text("str", x: 0, y: 0, size: 1, color:, align_x: :left, align_y: :middle, z: 0)
Ruby(x: 0, y: 0, size: 1, color:, z: 0, gap: 0.08)

# effects
Kaleidoscope(segments: 6) { ... }
Lissajous(a: 3, b: 2, delta: 0, rx: 5, ry: 5, steps: 128, bold: 0, color:, z: 0)
Ring(x: 0, y: 0, r: 1, color:, z: 0, steps: 32)
Tunnel(n: 10, offset: 0, r_max: 10, color:, z: 0)
Spectrum(n: 32, x: 0, y: -8, width: 24, height: 6, hue: 200, sat: 0.8, val: 1.0, alpha: 255, gap: 0.1, z: 0)

# stateful (@@var ||= new → per-frame)
Warp.new(max: 300)
Warp#step(r_min: 2, density: 5, speed: 0.05, accel: 1.04, bold: 0, color:, z: 0)
Particles.new(max: 300)
Particles#emit(x: 0, y: 0, speed: 0.15, life: 90, hue: 0, size: 0.2, n: 1)
Particles#update
Particles#draw(z: 0)
Trail.new(len: 60)
Trail#update { ... }
Ripple.new(max: 20, speed: 0.2, life: 60, r_start: 0.5)
Ripple#update(emit: false) { |r:, alpha:| ... }

# helpers
polar(r, theta) #=> {x:, y:}
```

See the sections below for full API details.

---

## Coordinate System

```
         y = +9
          ↑
-16 ←────┼────→ +16  (x)
          ↓
         y = -9
```

- Origin `(0, 0)` is the center of the screen
- 1 unit = 40 px
- **y is upward** (mathematical convention)

---

## color Object

```ruby
{h: hue, s: saturation, v: value}           # alpha defaults to 255 (opaque)
{h: hue, s: saturation, v: value, a: alpha}
```

| Key | Type  | Range      | Default |
|-----|-------|------------|---------|
| `h` | Float | `0..360`   | `0` (red) |
| `s` | Float | `0.0..1.0` | `1`     |
| `v` | Float | `0.0..1.0` | `1`     |
| `a` | Int   | `0..255`   | `255`   |

**Common hue values**

| h | Color |
|---|-------|
| 0 / 360 | Red |
| 30 | Orange |
| 60 | Yellow |
| 120 | Green |
| 180 | Cyan |
| 200 | Sky blue |
| 240 | Blue |
| 280 | Purple |
| 300 | Magenta |

---

## @vj — Audio & Beat Context

### Volume & Frequency Bands (0.0–1.0, peak-normalized)

| Method | Description |
|--------|-------------|
| `@vj.amp` | Overall volume |
| `@vj.low` | Low band (bass, kick) |
| `@vj.mid` | Mid band (vocals, chords) |
| `@vj.hi`  | High band (hats, cymbals) |

### Beat

| Method | Type | Description |
|--------|------|-------------|
| `@vj.beat?` | Bool | `true` on the frame the beat fires (consumed once) |
| `@vj.beat`  | Float | `0..1` — 1.0 right after beat, exponential decay; good for flashes |
| `@vj.phase` | Float | `0.0..1.0` — phase synced to BPM; one full cycle per beat |
| `@vj.bpm`   | Float | Current BPM (tap tempo or manual) |
| `@vj.count` | Int   | Cumulative beat count |

### Time & Frame

| Method | Type | Description |
|--------|------|-------------|
| `@vj.t`     | Float | Seconds elapsed since startup |
| `@vj.frame` | Int   | Frame count since startup |

### Spectrum & Waveform

| Method | Type | Description |
|--------|------|-------------|
| `@vj.spectrum(n=32)` | `Array<Float>` | Log-scaled spectrum with `n` bins (each 0.0–1.0) |
| `@vj.waveform`       | `Array<Float>` | 256-point waveform data (each approx. -1.0–1.0) |

### OSC (MIDI CC integration)

```ruby
@vj.osc('/midi/cc/1')   # 0.0–1.0; returns 0.0 if not yet received
```

---

## VjShapes — Primitives

### Bg — Background fill

```ruby
Bg(color:)
```

### Circle — Filled circle

```ruby
Circle(x: 0, y: 0, r: 1, color:, z: 0, steps: 16)
```

| Arg | Range | Description |
|-----|-------|-------------|
| `r`     | `> 0`   | Radius in VJ units |
| `steps` | 8–32 recommended | Polygon resolution; higher = smoother |

### Rect — Rectangle

```ruby
Rect(x: 0, y: 0, w: 1, h: 1, color:, z: 0)
```

### Triangle — Equilateral triangle

```ruby
Triangle(x: 0, y: 0, size: 1, angle: 0, color:, z: 0)
```

| Arg | Unit | Description |
|-----|------|-------------|
| `angle` | Radians | Rotation angle |

### Line — Line segment

```ruby
Line(x1: 0, y1: 0, x2: 1, y2: 0, color:, z: 0, bold: 0)
```

| Arg | Range | Description |
|-----|-------|-------------|
| `bold` | `0..` | 0 = hairline; positive = line width (1/100 VJ units; `bold: 100` = width 1) |

### Text — Text label

```ruby
Text("hello", x: 0, y: 0, size: 1, color:, align_x: :left, align_y: :middle, z: 0)
```

| Arg | Options | Description |
|-----|---------|-------------|
| `align_x` | `:left` `:center` `:right` | Horizontal alignment |
| `align_y` | `:top` `:middle` `:bottom`  | Vertical alignment |

Newlines (`\n`) are supported for multi-line text.

### Ruby — Ruby logo gem shape

```ruby
Ruby(x: 0, y: 0, size: 1, color:, z: 0, gap: 0.08)
```

Renders the Ruby logo silhouette as 8 filled triangles (3 pavilion + 5 crown facets).
Draw with `{h: 0, s: 1, v: 1}` for the classic red gem.

| Arg | Default | Description |
|-----|---------|-------------|
| `size` | `1`    | Overall scale (width ≈ `2 * size` VJ units, height ≈ `1.2 * size`) |
| `gap`  | `0.08` | Inward shrink ratio per facet triangle; larger = more visible facet gaps |

---

## VjShapes — Composite Effects

### Kaleidoscope — Rotational symmetry

```ruby
Kaleidoscope(segments: 6) do
  Circle(x: 3, y: 0, r: @vj.mid * 2, color: {h: 120, s: 1, v: 1})
end
```

Rotates and mirrors the block's drawing `segments` times evenly.
`@vj` and shape methods are available directly inside the block.

### Lissajous — Lissajous curve

```ruby
Lissajous(a: 3, b: 2, delta: 0, rx: 5, ry: 5, steps: 128, bold: 0, color:, z: 0)
```

| Arg | Description |
|-----|-------------|
| `a`, `b` | X/Y frequency ratio; integer ratios produce closed curves (e.g. 3:2, 5:4) |
| `delta` | Phase offset in radians; use `@vj.t * 0.5` to animate |
| `rx`, `ry` | X/Y radius in VJ units |
| `bold` | Line thickness (same unit as `Line#bold`) |

### Ring — Hollow circle

```ruby
Ring(x: 0, y: 0, r: 3, color:, z: 0, steps: 32)
```

Outline-only version of `Circle`, drawn as a polyline.

| Arg | Default | Description |
|-----|---------|-------------|
| `r`     | `1`  | Radius in VJ units |
| `steps` | `32` | Polygon resolution |

### Tunnel — Concentric ring tunnel

```ruby
Tunnel(n: 10, offset: 0, r_max: 10, color:, z: 0)
```

| Arg | Default | Description |
|-----|---------|-------------|
| `n`      | `10` | Number of rings |
| `offset` | `0`  | Phase offset (0.0–1.0); use `@vj.t * 0.3` to scroll |
| `r_max`  | `10` | Outermost ring radius in VJ units |

Alpha automatically gradients from 0 (center) to 255 (edge); no need to set `a:` in `color`.

---

## Warp — Radial warp stream

```ruby
@@warp ||= Warp.new(max: 300)

def draw_scene
  @@warp.step(r_min: 2, density: 5, color: {h: 200, s: 1, v: 1})
end
```

| Arg | Default | Description |
|-----|---------|-------------|
| `r_min`   | `2`    | Dead-zone radius; no particles inside this distance |
| `density` | `5`    | Particles emitted per frame |
| `speed`   | `0.05` | Initial speed in VJ units/frame |
| `accel`   | `1.04` | Speed multiplier per frame; `1.0` = constant, `1.04–1.08` = warp feel |
| `bold`    | `0`    | Streak line thickness (same unit as `Line#bold`) |
| `max`     | `300`  | Set at `new`; maximum live particle count |

- Draws radial streaks as `Line` from `r_prev → r`
- Alpha is auto-calculated proportional to distance; `color[:a]` is overridden

---

## VjEffects::Spectrum — Spectrum bars

```ruby
require_relative 'lib/vj_effects/spectrum'
include VjEffects::Spectrum

def draw_scene
  Spectrum(n: 32, x: 0, y: -8, width: 24, height: 6, hue: 0..360)
end
```

| Arg | Default | Description |
|-----|---------|-------------|
| `n`      | `32`     | Bar count (passed to `@vj.spectrum(n)`) |
| `x`, `y` | `0, -8`  | Left edge X, bottom edge Y of the bar group |
| `width`  | `24`     | Total width in VJ units |
| `height` | `6`      | Maximum bar height in VJ units |
| `hue`    | `0..360` | Hue value or Range; a Range splits `begin..end` across `n` bars (`0..360` = rainbow) |
| `sat`    | `0.8`    | Saturation |
| `val`    | `1.0`    | Value (brightness) |
| `alpha`  | `255`    | Opacity |
| `gap`    | `0.1`    | Gap between bars in VJ units |

---

## Particles — Gravity particles

```ruby
@@ps ||= Particles.new(max: 500)

def draw_scene
  @@ps.emit(x: 0, y: 0, speed: 0.2, life: 120, hue: @vj.t * 30 % 360, n: @vj.beat? ? 20 : 2)
  @@ps.update
  @@ps.draw(z: 1)
end
```

### emit arguments

| Arg | Default | Description |
|-----|---------|-------------|
| `x`, `y` | `0, 0` | Spawn position in VJ units |
| `speed`  | `0.15` | Max initial speed (actual speed is random from 0 to `speed`) |
| `life`   | `90`   | Lifetime in frames |
| `hue`    | `0`    | Hue (0–360) |
| `size`   | `0.2`  | Radius in VJ units |
| `n`      | `1`    | Number of particles per emit call |

- Gravity: `vy -= 0.003` per frame (downward)
- Alpha decays proportional to `life / max_life`
- Use `@@` class variables so state survives hot reload

---

## Trail — Motion trail

```ruby
@@trail ||= Trail.new(len: 60)

def draw_scene
  Bg(color: {h: 0, s: 0, v: 0})
  @@trail.update do
    Circle(x: Math.sin(@vj.t * 2) * 10, y: 0, r: 0.5, color: {h: 180, s: 1, v: 1})
  end
end
```

Records the block's drawing each frame and replays the last `len` frames with alpha fade.
`@vj` and shape methods inside the block resolve against the calling context (`RuVJ`).

| Arg | Default | Description |
|-----|---------|-------------|
| `len` | `60` | Frames to retain; larger = longer trail |

- Gosu clears the screen every frame, so the semi-transparent `Bg` trick doesn't work here — use `Trail` instead.
- `translate`/`scale`/`rotate` inside the block are baked into coordinates at record time.

---

## Ripple — Ripple effect

```ruby
@@ripple ||= Ripple.new(max: 20, speed: 0.2, life: 60)

def draw_scene
  Bg(color: {h: 0, s: 0, v: 0.02})
  @@ripple.update(emit: @vj.beat?) do |r:, alpha:|
    Ring(x: 0, y: 0, r: r, color: {h: 180, s: 1, v: 1, a: alpha})
  end
end
```

Spawns a new drop when `emit: true`, expands its radius by `speed` each frame, and removes it after `life` frames.
Every frame the block is called for each live drop with `r` and `alpha` as keyword arguments.

### Ripple.new arguments

| Arg | Default | Description |
|-----|---------|-------------|
| `max`     | `20`  | Max concurrent drops; new emits are suppressed when full |
| `speed`   | `0.2` | Radius increase per frame in VJ units |
| `life`    | `60`  | Drop lifetime in frames |
| `r_start` | `0.5` | Initial radius at spawn in VJ units |

### update arguments

| Arg | Default | Description |
|-----|---------|-------------|
| `emit` | `false` | Spawn a new drop on `true` frames |

### Block keyword arguments

| Key | Type | Description |
|-----|------|-------------|
| `r`     | Float | Current radius in VJ units |
| `alpha` | Int   | `0..255`, decays with remaining lifetime |

---

## polar — Polar coordinate helper

```ruby
polar(r, theta)  # => {x:, y:}

# Spread example with Circle
Circle(**polar(3, @vj.t), r: 1, color: {h: 0, s: 1, v: 1})
```

| Arg | Unit |
|-----|------|
| `r`     | VJ units |
| `theta` | Radians |
