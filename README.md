<p align="center">
  <br>
  <img src="screenshots/special_random_evolved.png" width="600" alt="Conway's Game of Life — Random Soup evolved for 50 generations">
  <br>
  <br>
  <strong>Conway's Game of Life</strong>
  <br>
  <sub>A fast, visually rich cellular automaton simulator built with Lua + LOVE2D</sub>
  <br>
  <br>
  <a href="#why-this-exists">Why</a> &bull;
  <a href="#how-it-works">How</a> &bull;
  <a href="#quickstart">Quickstart</a> &bull;
  <a href="#controls">Controls</a> &bull;
  <a href="#pattern-gallery">Gallery</a> &bull;
  <a href="#architecture">Architecture</a>
</p>

---

## Table of Contents

- [Why This Exists](#why-this-exists)
- [How It Works](#how-it-works)
  - [The Rules](#the-rules)
  - [Visual System](#visual-system)
  - [Toroidal Grid](#toroidal-grid)
- [Quickstart](#quickstart)
- [Controls](#controls)
- [Pattern Browser](#pattern-browser)
- [Pattern Gallery](#pattern-gallery)
  - [Still Lifes](#still-lifes)
  - [Oscillators](#oscillators)
  - [Spaceships](#spaceships)
  - [Methuselahs](#methuselahs)
  - [Guns & Infinite Growth](#guns--infinite-growth)
  - [Random Soup](#random-soup)
- [Architecture](#architecture)
  - [File Structure](#file-structure)
  - [Design Principles](#design-principles)
  - [Performance](#performance)
- [Configuration](#configuration)
- [Web Export](#web-export)
- [Development](#development)
- [Adding Your Own Patterns](#adding-your-own-patterns)

---

## Why This Exists

Conway's Game of Life is one of the most profound demonstrations in computer science: **complex behavior emerging from simple rules**. With just two states (alive/dead) and three rules (birth, survival, death), a flat grid produces spaceships that travel, guns that fire, and computers that compute. It was invented by mathematician John Conway in 1970 and has fascinated researchers, programmers, and artists ever since.

This simulator was built to:

1. **Make the invisible visible** — Cell age coloring and death trails reveal the *dynamics* of patterns that flat-color renderers hide. You can *see* which cells are newborns (white flash), which are stable veterans (deep green), and where cells just died (amber trails). This transforms the simulation from "dots on a grid" into something alive.

2. **Provide a complete pattern library** — 25 built-in patterns across every major category (still lifes, oscillators, spaceships, methuselahs, guns), browsable with a single keypress. No need to look up coordinates or paste RLE strings for the classics.

3. **Run anywhere** — Desktop via LOVE2D, browser via love.js, mobile via touch support. One codebase, responsive layout, zero external dependencies.

4. **Teach by example** — The codebase is structured as a teaching tool: pure functional simulation core, clean separation of concerns, and every design decision documented. If you're learning Lua, game architecture, or cellular automata, read the source.

---

## How It Works

### The Rules

Conway's Game of Life uses **B3/S23** notation — three rules applied simultaneously to every cell on each tick:

| Rule | Condition | Result |
|:-----|:----------|:-------|
| **Birth** | A dead cell has exactly **3** live neighbors | Becomes alive |
| **Survival** | A live cell has **2 or 3** live neighbors | Stays alive |
| **Death** | All other live cells | Dies |

Neighbors are counted using the **Moore neighborhood** — the 8 cells surrounding each cell (horizontal, vertical, and diagonal).

The key insight: all cells update **simultaneously**. The next generation is computed from the current state without intermediate mutations. This is why the code uses double-buffering — two grids ping-pong back and forth, never overwriting the state being read.

### Visual System

Unlike most Game of Life simulators that render every cell the same color, this one tracks **cell age** — how many consecutive generations each cell has been alive:

| Age | Color | What It Means |
|:----|:------|:--------------|
| 1 (just born) | White flash | A new cell was just born this generation |
| 2 | Bright white-green | Very young, just survived its first tick |
| 3–4 | Electric green | Young and thriving |
| 5–8 | Bright green | Established |
| 9–20 | Medium green | Mature |
| 21–50 | Emerald | Veteran |
| 51+ | Deep forest green | Ancient — been alive a very long time |

When a cell **dies**, it doesn't just vanish — it leaves an **amber death trail** that fades over 6 frames. This makes the dynamics visible:

- **Oscillators** pulse between bright births and amber deaths
- **Spaceships** have a bright leading edge and an amber wake trailing behind
- **Still lifes** settle into deep, uniform green (every cell is ancient)
- **Methuselahs** show chaotic swirls of every color as new structures constantly form and collapse
- **Guns** have a deep green body with a stream of bright white newborn gliders shooting out

### Toroidal Grid

The grid wraps around — the top edge connects to the bottom, the left edge connects to the right. This means gliders and spaceships that fly off one edge reappear on the opposite side, and patterns near the edges interact with patterns on the other side. Mathematically, the grid is a torus (donut shape).

---

## Quickstart

**Requirements:** [LOVE2D](https://love2d.org/) 11.x

```bash
# macOS
brew install love

# Run
love .
```

The game starts **paused** with a Block pattern loaded. Press <kbd>N</kbd> to browse patterns, or <kbd>R</kbd> for random chaos, then <kbd>Space</kbd> to run.

---

## Controls

### Simulation

| Key | Action |
|:---|:---|
| <kbd>Space</kbd> | Pause / Resume |
| <kbd>&rarr;</kbd> | Step one generation (while paused) |
| <kbd>+</kbd> / <kbd>-</kbd> | Speed up / slow down (1–60 gen/s) |

### Grid

| Key | Action |
|:---|:---|
| <kbd>R</kbd> | Random seed (20% density) |
| <kbd>C</kbd> | Clear grid |
| <kbd>Click</kbd> | Toggle cell alive/dead |
| <kbd>Click + Drag</kbd> | Paint cells alive |

### Patterns

| Key | Action |
|:---|:---|
| <kbd>N</kbd> | Next pattern |
| <kbd>P</kbd> | Previous pattern |
| <kbd>Tab</kbd> | Toggle pattern browser overlay |
| <kbd>1</kbd>–<kbd>9</kbd> | Quick-load first 9 patterns |
| <kbd>Enter</kbd> | Reload selected pattern |

### Import / Export

| Key | Action |
|:---|:---|
| <kbd>S</kbd> | Save current grid to clipboard as RLE |
| <kbd>L</kbd> | Load RLE pattern from clipboard |

RLE (Run Length Encoded) is the standard format used by [LifeWiki](https://conwaylife.com/wiki/) and the Game of Life community. You can copy any pattern from LifeWiki and paste it directly into the simulator.

---

## Pattern Browser

Press <kbd>Tab</kbd> to open the pattern browser, then <kbd>N</kbd>/<kbd>P</kbd> to cycle through all 25 patterns:

The browser shows the pattern name, category, dimensions, and cell count. Each pattern is placed centered on a cleared grid when loaded.

---

## Pattern Gallery

Every pattern shown twice: **initial state** (just placed, cells flash white) and **evolved** (after running for several generations, showing age coloring and death trails).

---

### Still Lifes

Stable patterns that never change. Once they settle, every cell is ancient (deep green).

#### Block
The simplest still life — a 2x2 square. Four cells, perfectly stable. The fundamental building block of many larger structures.

| Initial | Evolved (Gen 3) |
|:--------|:-----------------|
| ![Block initial](screenshots/01_block_initial.png) | ![Block evolved](screenshots/01_block_evolved.png) |

#### Beehive
Six cells forming a hexagonal shape. The most common naturally-occurring still life — random soups produce thousands of these.

| Initial | Evolved (Gen 3) |
|:--------|:-----------------|
| ![Beehive initial](screenshots/02_beehive_initial.png) | ![Beehive evolved](screenshots/02_beehive_evolved.png) |

#### Loaf
Seven cells. Named for its shape resembling a loaf of bread. Another extremely common still life found in random soups.

| Initial | Evolved (Gen 3) |
|:--------|:-----------------|
| ![Loaf initial](screenshots/03_loaf_initial.png) | ![Loaf evolved](screenshots/03_loaf_evolved.png) |

#### Boat
Five cells. The smallest still life that is not symmetric under 180-degree rotation.

| Initial | Evolved (Gen 3) |
|:--------|:-----------------|
| ![Boat initial](screenshots/04_boat_initial.png) | ![Boat evolved](screenshots/04_boat_evolved.png) |

#### Tub
Four cells forming a diamond shape. Along with Block, one of the two 4-cell still lifes.

| Initial | Evolved (Gen 3) |
|:--------|:-----------------|
| ![Tub initial](screenshots/05_tub_initial.png) | ![Tub evolved](screenshots/05_tub_evolved.png) |

#### Pond
Eight cells forming a hollow square. A larger still life with an empty center.

| Initial | Evolved (Gen 3) |
|:--------|:-----------------|
| ![Pond initial](screenshots/06_pond_initial.png) | ![Pond evolved](screenshots/06_pond_evolved.png) |

---

### Oscillators

Patterns that cycle through states on a fixed period, returning to their original form. The age coloring makes the pulsing visible — cells born each cycle flash white, while stable cells stay green.

#### Blinker
The simplest oscillator (period 2). Three cells in a line flip between horizontal and vertical every generation. The most common oscillator in random soups.

| Initial | Evolved (Gen 15) |
|:--------|:------------------|
| ![Blinker initial](screenshots/07_blinker_initial.png) | ![Blinker evolved](screenshots/07_blinker_evolved.png) |

#### Toad
Period 2 oscillator. Six cells that shift back and forth. Often found as a byproduct of larger interactions.

| Initial | Evolved (Gen 15) |
|:--------|:------------------|
| ![Toad initial](screenshots/08_toad_initial.png) | ![Toad evolved](screenshots/08_toad_evolved.png) |

#### Beacon
Period 2. Two blocks that blink a corner cell on and off. The interaction between two separate still lifes creates oscillation.

| Initial | Evolved (Gen 15) |
|:--------|:------------------|
| ![Beacon initial](screenshots/09_beacon_initial.png) | ![Beacon evolved](screenshots/09_beacon_evolved.png) |

#### Pulsar
Period 3 — one of the most beautiful patterns in the Game of Life. 48 cells with stunning 4-fold symmetry that pulses through three distinct phases. Watch the age colors cycle.

| Initial | Evolved (Gen 15) |
|:--------|:------------------|
| ![Pulsar initial](screenshots/10_pulsar_initial.png) | ![Pulsar evolved](screenshots/10_pulsar_evolved.png) |

#### Pentadecathlon
Period 15 — the longest-period oscillator discoverable by brute force. Twelve cells that cycle through 15 states before repeating. Named for its 15-generation period.

| Initial | Evolved (Gen 15) |
|:--------|:------------------|
| ![Pentadecathlon initial](screenshots/11_pentadecathlon_initial.png) | ![Pentadecathlon evolved](screenshots/11_pentadecathlon_evolved.png) |

#### Clock
Period 2. A small, elegant oscillator that rotates like clock hands.

| Initial | Evolved (Gen 15) |
|:--------|:------------------|
| ![Clock initial](screenshots/12_clock_initial.png) | ![Clock evolved](screenshots/12_clock_evolved.png) |

#### Figure Eight
Period 8 — one of the first known period-8 oscillators. Two 3x3 blocks placed diagonally, creating a complex interaction pattern.

| Initial | Evolved (Gen 15) |
|:--------|:------------------|
| ![Figure Eight initial](screenshots/13_figure_eight_initial.png) | ![Figure Eight evolved](screenshots/13_figure_eight_evolved.png) |

---

### Spaceships

Patterns that translate across the grid over time. The age coloring reveals a bright leading edge (newborn cells) and amber death trails in the wake. On the toroidal grid, they loop around forever.

#### Glider
The smallest and most iconic spaceship. Five cells that travel diagonally at c/4 (one cell every 4 generations). Discovered by Richard Guy in 1970, the glider is the fundamental unit of information transfer in Life.

| Initial | Evolved (Gen 15) |
|:--------|:------------------|
| ![Glider initial](screenshots/14_glider_initial.png) | ![Glider evolved](screenshots/14_glider_evolved.png) |

#### LWSS (Lightweight Spaceship)
The smallest orthogonal spaceship. Travels horizontally at c/2 (one cell every 2 generations). Nine cells.

| Initial | Evolved (Gen 15) |
|:--------|:------------------|
| ![LWSS initial](screenshots/15_lwss_initial.png) | ![LWSS evolved](screenshots/15_lwss_evolved.png) |

#### MWSS (Middleweight Spaceship)
Larger than LWSS. Travels at the same speed (c/2) but with a wider profile.

| Initial | Evolved (Gen 15) |
|:--------|:------------------|
| ![MWSS initial](screenshots/16_mwss_initial.png) | ![MWSS evolved](screenshots/16_mwss_evolved.png) |

#### HWSS (Heavyweight Spaceship)
The largest of the standard spaceships. Also c/2 orthogonal. Any spaceship wider than HWSS is unstable without additional support.

| Initial | Evolved (Gen 15) |
|:--------|:------------------|
| ![HWSS initial](screenshots/17_hwss_initial.png) | ![HWSS evolved](screenshots/17_hwss_evolved.png) |

#### Glider Fleet
Four gliders launched in formation, traveling diagonally across the grid. Demonstrates how multiple independent spaceships can coexist. On the toroidal grid, they loop forever.

| Initial | Evolved (Gen 15) |
|:--------|:------------------|
| ![Glider Fleet initial](screenshots/18_glider_fleet_initial.png) | ![Glider Fleet evolved](screenshots/18_glider_fleet_evolved.png) |

---

### Methuselahs

Small patterns with surprisingly long-lived, chaotic evolution before stabilizing. These are the most visually dramatic — the age coloring shows a constantly shifting landscape of births (white), active zones (green), and mass death events (amber trails).

#### R-pentomino
The most famous methuselah. Just 5 cells, but it takes **1,103 generations** to stabilize, eventually producing 116 still lifes, 6 oscillators, and 6 gliders. The first pattern to demonstrate that simple initial conditions can produce staggering complexity.

| Initial | Evolved (Gen 80) |
|:--------|:-------------------|
| ![R-pentomino initial](screenshots/19_r-pentomino_initial.png) | ![R-pentomino evolved](screenshots/19_r-pentomino_evolved.png) |

#### Diehard
Seven cells that produce activity for exactly **130 generations**, then die completely — every cell goes dead. One of the few patterns with a known finite lifespan.

| Initial | Evolved (Gen 80) |
|:--------|:-------------------|
| ![Diehard initial](screenshots/20_diehard_initial.png) | ![Diehard evolved](screenshots/20_diehard_evolved.png) |

#### Acorn
Seven cells that take **5,206 generations** to stabilize — the longest-lived 7-cell methuselah. Produces 633 cells worth of debris, including 13 gliders.

| Initial | Evolved (Gen 80) |
|:--------|:-------------------|
| ![Acorn initial](screenshots/21_acorn_initial.png) | ![Acorn evolved](screenshots/21_acorn_evolved.png) |

#### B-heptomino
Seven cells. Stabilizes after **148 generations**. A common intermediate form that appears during the evolution of larger patterns.

| Initial | Evolved (Gen 80) |
|:--------|:-------------------|
| ![B-heptomino initial](screenshots/22_b-heptomino_initial.png) | ![B-heptomino evolved](screenshots/22_b-heptomino_evolved.png) |

#### Pi-heptomino
Seven cells arranged in a pi (π) shape. Stabilizes after **173 generations**, producing two copies of itself plus debris. A replicator-like methuselah.

| Initial | Evolved (Gen 80) |
|:--------|:-------------------|
| ![Pi-heptomino initial](screenshots/23_pi-heptomino_initial.png) | ![Pi-heptomino evolved](screenshots/23_pi-heptomino_evolved.png) |

---

### Guns & Infinite Growth

Patterns that produce an endless stream of spaceships. The gun body settles into deep green (stable, ancient cells), while each newly fired glider appears as a bright white streak.

#### Gosper Glider Gun
The first known finite pattern with infinite growth, discovered by Bill Gosper in 1970. It fires a new **glider every 30 generations**, forever. This pattern proved that Life populations can grow without bound, answering one of Conway's original questions.

| Initial | Evolved (Gen 60) |
|:--------|:-------------------|
| ![Gosper Glider Gun initial](screenshots/24_gosper_glider_gun_initial.png) | ![Gosper Glider Gun evolved](screenshots/24_gosper_glider_gun_evolved.png) |

---

### Random Soup

Start with 20% random density and watch complexity emerge from chaos. After 50 generations, the soup has self-organized into recognizable structures — blocks, beehives, blinkers, and gliders, all visible through their distinct age coloring.

| Initial (Gen 0) | Evolved (Gen 50) |
|:-----------------|:-------------------|
| ![Random soup](screenshots/special_random_soup.png) | ![Random evolved](screenshots/special_random_evolved.png) |

---

## Architecture

### File Structure

```
conways-game-of-life/
├── conf.lua           LOVE2D engine config (window, modules)
├── config.lua         Constants (colors, grid, rules, speed)
├── grid.lua           Pure simulation core (zero mutable state)
├── patterns.lua       25 patterns + RLE parser/serializer
├── main.lua           LOVE callbacks, state, rendering, input
├── screenshot.lua     Automated screenshot capture (love . --screenshot)
├── screenshots/       50 PNG screenshots of every pattern
├── README.md
└── PROGRESS.md
```

### Design Principles

**Functional core, mutable shell** — `grid.lua` is 100% pure: every function takes data in and returns new data out. No globals, no module-level state, no side effects. `main.lua` is the only file that mutates state, and it does so through a single `state` table.

**Double-buffered simulation** — Two pre-allocated flat arrays ping-pong each generation. `grid.step(current, ..., dest)` writes the next generation into `dest` without allocating new memory. Zero GC pressure in the hot loop.

**Inlined hot path** — Neighbor counting in `grid.step` uses direct modulo arithmetic (`(x-1) % width`) instead of function calls. Row offsets are pre-computed per y-coordinate. This reduces the inner loop to 8 table reads + 2 rule lookups + 1 table write per cell.

**Separation of simulation and visuals** — Cell ages and death trails are tracked in `main.lua`, not in the simulation core. The grid remains a simple 0/1 array. This means `grid.lua` can be tested, reused, or optimized independently of the rendering system.

**Responsive layout** — Cell size is computed as `min(floor(windowW / gridW), floor(windowH / gridH))` on every resize. The grid is centered in the available space below the HUD. Touch input is supported for mobile.

**Cached grid lines** — The static grid line overlay is rendered once to an off-screen LOVE Canvas and re-blitted every frame. Only rebuilt on window resize.

### Performance

| Phase | Time |
|:------|:-----|
| `grid.step` (100x100) | ~0.5ms |
| Age/trail update | ~0.1ms |
| Cell rendering (with colors) | ~1.5ms |
| HUD + grid blit | ~0.2ms |
| **Total per frame** | **~2.3ms** (budget: 16.6ms @ 60fps) |

---

## Configuration

Edit `config.lua` to customize:

```lua
GRID_WIDTH  = 100           -- grid columns
GRID_HEIGHT = 100           -- grid rows
DEFAULT_SPEED = 10          -- generations per second
RANDOM_DENSITY = 0.20       -- 20% alive on random seed
TRAIL_LENGTH = 6            -- frames death trails persist
```

### Custom Colors

```lua
AGE_COLORS = {
    {1.0, 1.0, 1.0},    -- age 1: birth flash
    {0.7, 1.0, 0.7},    -- age 2: young
    {0.0, 1.0, 0.0},    -- age 3-4: electric green
    {0.0, 0.85, 0.0},   -- age 5-8: bright green
    {0.0, 0.65, 0.0},   -- age 9-20: medium green
    {0.0, 0.45, 0.0},   -- age 21-50: emerald
    {0.0, 0.30, 0.0},   -- age 51+: deep forest
}
TRAIL_COLOR = {0.6, 0.2, 0.0}  -- amber death trails
```

### Custom Rules

Swap the birth/survival tables to explore other cellular automata:

```lua
-- HighLife (B36/S23) — has a small replicator
BIRTH    = { [3] = true, [6] = true }
SURVIVAL = { [2] = true, [3] = true }

-- Seeds (B2/S) — explosive, every cell dies immediately but births spread
BIRTH    = { [2] = true }
SURVIVAL = {}

-- Day & Night (B3678/S34678) — symmetric rules, beautiful patterns
BIRTH    = { [3]=true, [6]=true, [7]=true, [8]=true }
SURVIVAL = { [3]=true, [4]=true, [6]=true, [7]=true, [8]=true }
```

---

## Web Export

Deploy to the browser via [love.js](https://github.com/Davidobot/love.js):

```bash
npx love.js . dist -t "Conway's Game of Life" -c
cd dist && python3 -m http.server 8000
```

The `-c` flag creates a compatibility build (no SharedArrayBuffer) that works across all browsers. Clipboard save/load gracefully degrades.

---

## Development

```bash
# Run the game
love .

# Capture screenshots of all patterns
love . --screenshot

# Run with console output (macOS)
/Applications/love.app/Contents/MacOS/love .
```

---

## Adding Your Own Patterns

### From the library

Add to `patterns.library` in `patterns.lua`:

```lua
{ name = "My Pattern", category = "Custom", width = 3, height = 3,
  cells = { {0,0}, {1,1}, {2,2} } },
```

### From LifeWiki

1. Go to [conwaylife.com/wiki](https://conwaylife.com/wiki/)
2. Find any pattern and copy its RLE code
3. In the simulator, press <kbd>L</kbd> to paste and load it

### From the simulator

1. Draw a pattern with your mouse
2. Press <kbd>S</kbd> to copy it as RLE
3. Share the RLE string with anyone

---

<p align="center">
  <sub>Built with Lua + LOVE2D &bull; B3/S23 &bull; Toroidal 100x100 &bull; 25 patterns &bull; Age coloring &bull; Death trails</sub>
</p>
