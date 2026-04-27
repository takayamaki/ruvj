# RuVJ

A Gosu-based live coding visualizer for DJ/VJ performances at Rubyist events.

## Overview

A VJ tool that switches visual effects through live coding.
Just edit `visual.rb` in your editor — hot reload picks up changes instantly.

## Tech Stack

- **Ruby** 4.0.2
- **Gosu** 1.4.6 (2D game library)
- **parec** (microphone input via PulseAudio)
- **osc-ruby** (OSC input, optional)
- **Linux** (including WSL2 + WSLg); macOS support TBD

## Architecture

```
main.rb       # Gosu window, hot reload watcher, key handling
beat.rb       # BPM counter, beat signal management
audio.rb      # Mic input, FFT, beat detection, fallback chain
visual.rb     # Live coding target — edit this during performance
palette.rb    # Color palette definitions and switching
draw_ext.rb   # Drawing helpers (circle, polygon, HSV conversion)
particle.rb   # Particle base class
perlin.rb     # Perlin noise implementation
```

## Key Controls

| Key | Action |
|-----|--------|
| Space | Tap tempo |
| R | Force reload |
| ↑↓ | Manual BPM adjustment |
| 1–9 | Switch effects |
| P / Shift+P | Cycle color palette |

## Setup

```bash
bundle install
ruby main.rb
```

## License

MIT
