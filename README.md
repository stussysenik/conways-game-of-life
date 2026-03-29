<p align="center">
  <br>
  <code>&nbsp;Conway's Game of Life&nbsp;</code>
  <br>
  <br>
  <strong>A fast, elegant cellular automaton simulator</strong>
  <br>
  <sub>Built with Lua + LOVE2D &mdash; runs on desktop & web</sub>
  <br>
  <br>
  <a href="#quickstart">Quickstart</a> &bull;
  <a href="#controls">Controls</a> &bull;
  <a href="#patterns">Patterns</a> &bull;
  <a href="#architecture">Architecture</a> &bull;
  <a href="#web-export">Web Export</a>
</p>

<br>

```
  ██          ██                ████████████
    ██      ██                  ██        ██
  ██████████        ──▶         ██  ████  ██
  ████  ████                    ██  ████  ██
██████████████                  ██        ██
██  ████████  ██                ████████████
██  ██    ██  ██
      ████                    B3/S23 • 100×100 • 60fps
```

---

## Table of Contents

- [Quickstart](#quickstart)
- [Controls](#controls)
- [Pattern Browser](#pattern-browser)
- [Patterns](#patterns)
- [Rules](#rules)
- [Architecture](#architecture)
- [Web Export](#web-export)
- [Configuration](#configuration)
- [Development](#development)

---

## Quickstart

**Requirements:** [LOVE2D](https://love2d.org/) 11.x

```bash
# macOS
brew install love

# Run the simulation
love .
```

The game starts **paused** with a Glider pattern loaded. Press <kbd>Space</kbd> to run, or <kbd>N</kbd>/<kbd>P</kbd> to browse through 25 built-in patterns.

---

## Controls

### Simulation

| Key | Action |
|:---|:---|
| <kbd>Space</kbd> | Pause / Resume |
| <kbd>→</kbd> | Step one generation (while paused) |
| <kbd>+</kbd> / <kbd>-</kbd> | Speed up / slow down (1–60 gen/s) |

### Grid

| Key | Action |
|:---|:---|
| <kbd>R</kbd> | Random seed (20% density) |
| <kbd>C</kbd> | Clear grid |
| <kbd>Click</kbd> | Toggle cell |
| <kbd>Click + Drag</kbd> | Paint cells |

### Patterns

| Key | Action |
|:---|:---|
| <kbd>N</kbd> | Next pattern |
| <kbd>P</kbd> | Previous pattern |
| <kbd>Tab</kbd> | Toggle pattern browser |
| <kbd>1</kbd>–<kbd>9</kbd> | Quick-load first 9 patterns |
| <kbd>Enter</kbd> | Load selected pattern |

### Import / Export

| Key | Action |
|:---|:---|
| <kbd>S</kbd> | Save to clipboard (RLE format) |
| <kbd>L</kbd> | Load from clipboard (RLE format) |

---

## Pattern Browser

Press <kbd>Tab</kbd> to open the pattern browser overlay, then use <kbd>N</kbd>/<kbd>P</kbd> to cycle through all 25 patterns. The browser shows:

- Pattern name and index
- Category (Still Life, Oscillator, Spaceship, Methuselah, Gun)
- Dimensions and cell count

Each pattern is placed centered on a cleared grid when loaded.

---

## Patterns

### Still Lifes
Stable patterns that never change.

| # | Name | Size | Cells |
|:--|:-----|:-----|:------|
| 1 | Block | 2×2 | 4 |
| 2 | Beehive | 4×3 | 6 |
| 3 | Loaf | 4×4 | 7 |
| 4 | Boat | 3×3 | 5 |
| 5 | Tub | 3×3 | 4 |
| 6 | Pond | 4×4 | 8 |

### Oscillators
Cycle through states on a fixed period.

| # | Name | Size | Period |
|:--|:-----|:-----|:-------|
| 7 | Blinker | 3×1 | 2 |
| 8 | Toad | 4×2 | 2 |
| 9 | Beacon | 4×4 | 2 |
| 10 | Pulsar | 13×13 | 3 |
| 11 | Pentadecathlon | 10×3 | 15 |
| 12 | Clock | 4×4 | 2 |
| 13 | Figure Eight | 6×6 | 8 |

### Spaceships
Translate across the grid over time.

| # | Name | Size | Speed |
|:--|:-----|:-----|:------|
| 14 | Glider | 3×3 | c/4 diagonal |
| 15 | LWSS | 5×4 | c/2 orthogonal |
| 16 | MWSS | 6×5 | c/2 orthogonal |
| 17 | HWSS | 7×5 | c/2 orthogonal |
| 18 | Glider Fleet | 20×20 | 4 gliders |

### Methuselahs
Small patterns with surprisingly long-lived evolution.

| # | Name | Size | Lifespan |
|:--|:-----|:-----|:---------|
| 19 | R-pentomino | 3×3 | 1103 gen |
| 20 | Diehard | 8×3 | 130 gen (dies) |
| 21 | Acorn | 7×3 | 5206 gen |
| 22 | B-heptomino | 4×3 | 148 gen |
| 23 | Pi-heptomino | 3×3 | 173 gen |

### Guns & Infinite Growth
Produce endless streams of spaceships.

| # | Name | Size | Output |
|:--|:-----|:-----|:-------|
| 24 | Gosper Glider Gun | 36×9 | 1 glider / 30 gen |

---

## Rules

Conway's Game of Life uses **B3/S23** notation:

```
Birth:    A dead cell with exactly 3 live neighbors becomes alive.
Survival: A live cell with 2 or 3 live neighbors survives.
Death:    All other live cells die.
```

The grid uses **toroidal wrapping** — edges connect to the opposite side, creating an infinite-feeling surface on a finite grid.

---

## Architecture

```
conways-game-of-life/
├── conf.lua        LOVE2D engine config (window, modules)
├── config.lua      Constants (colors, grid, rules, speed)
├── grid.lua        Pure simulation core (zero mutable state)
├── patterns.lua    25 patterns + RLE parser/serializer
└── main.lua        LOVE callbacks, state, rendering, input
```

### Design Principles

- **Functional core** — `grid.lua` is pure: every function takes data in and returns new data out. No globals, no mutation.
- **Double-buffered** — Two pre-allocated flat arrays ping-pong each generation. Zero allocations in the hot loop.
- **Inlined hot path** — Neighbor counting uses direct modulo arithmetic instead of function calls. ~0.5ms per 100×100 generation.
- **Responsive layout** — Grid scales to fit any window size. Recalculated on resize. Touch support for mobile.
- **Cached rendering** — Grid lines rendered to an off-screen canvas, only rebuilt on resize. Live cells use LOVE2D's autobatched rectangles.

### Performance

| Phase | Time |
|:------|:-----|
| `grid.step` (100×100) | ~0.5ms |
| Cell rendering | ~1–2ms |
| HUD + grid blit | ~0.2ms |
| **Total per frame** | **~2–3ms** (budget: 16.6ms @ 60fps) |

---

## Web Export

Deploy to the web via [love.js](https://github.com/Davidobot/love.js):

```bash
# Package and export
npx love.js . dist -t "Conway's Game of Life" -c

# Serve locally
cd dist && python3 -m http.server 8000
```

The `-c` flag creates a compatibility build (no SharedArrayBuffer requirement) that works across all browsers. Clipboard save/load gracefully degrades in the browser.

---

## Configuration

Edit `config.lua` to customize:

```lua
GRID_WIDTH  = 100       -- grid columns
GRID_HEIGHT = 100       -- grid rows
COLOR_ALIVE = {0,1,0,1} -- electric green (#00ff00)
COLOR_DEAD  = {0.04,0.04,0.04,1} -- near black
DEFAULT_SPEED = 10      -- generations per second
RANDOM_DENSITY = 0.20   -- 20% alive on random seed
```

### Custom Rules

Change the birth/survival rules to explore other cellular automata:

```lua
-- HighLife (B36/S23)
BIRTH    = { [3] = true, [6] = true }
SURVIVAL = { [2] = true, [3] = true }

-- Seeds (B2/S)
BIRTH    = { [2] = true }
SURVIVAL = {}

-- Day & Night (B3678/S34678)
BIRTH    = { [3]=true, [6]=true, [7]=true, [8]=true }
SURVIVAL = { [3]=true, [4]=true, [6]=true, [7]=true, [8]=true }
```

---

## Development

```bash
# Run
love .

# Run with console output (macOS)
/Applications/love.app/Contents/MacOS/love .

# Hot reload: just save and re-run, Lua has no compile step
```

### Adding Patterns

Add to `patterns.library` in `patterns.lua`:

```lua
{ name = "My Pattern", category = "Custom", width = 3, height = 3,
  cells = { {0,0}, {1,1}, {2,2} } },
```

Or import any RLE pattern from [LifeWiki](https://conwaylife.com/wiki/) using <kbd>L</kbd> (paste from clipboard).

---

<p align="center">
  <sub>Built with LOVE2D &bull; B3/S23 &bull; Toroidal 100&times;100</sub>
</p>
