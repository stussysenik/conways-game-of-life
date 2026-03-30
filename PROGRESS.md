# Progress

Development log for Conway's Game of Life simulator.

---

## v0.2.0 — Visual System & Documentation (2026-03-30)

### Done

- [x] **Cell age tracking** — Every cell tracks how many generations it has been alive
- [x] **Age-based color gradient** — 7-tier gradient from white birth flash → electric green → deep forest
- [x] **Death trails** — Amber glow persists for 6 frames where cells die, revealing dynamics
- [x] **Automated screenshot capture** — `love . --screenshot` captures all 50 pattern screenshots
- [x] **Comprehensive README.md** — Table of contents, why/how sections, full pattern gallery with screenshots
- [x] **50 screenshots** — Every pattern shown in initial + evolved state
- [x] **Pattern descriptions** — Each pattern documented with history, behavior, and significance

### Visual Effects

Each pattern category now has a distinct visual signature:
- **Still lifes** → uniform deep forest green (ancient, stable cells)
- **Oscillators** → pulsing bright/dim with amber death trails on each cycle
- **Spaceships** → bright white leading edge, amber wake trailing behind
- **Methuselahs** → chaotic swirl of all colors (constant births and deaths)
- **Guns** → deep green body, bright white stream of newborn gliders

---

## v0.1.0 — Initial Release (2026-03-30)

### Done

- [x] **Core simulation** — B3/S23 rules, 100x100 toroidal grid, double-buffered
- [x] **Pure functional core** — `grid.lua` has zero mutable state, all pure functions
- [x] **Inlined hot loop** — Neighbor counting with modulo arithmetic, ~0.5ms per generation
- [x] **Electric green aesthetic** — #00ff00 on #0a0a0a with subtle #1a1a1a grid lines
- [x] **Responsive layout** — Dynamic cell sizing, centered grid, scales to any window size
- [x] **Touch support** — Touch-to-toggle, drag-to-paint for mobile/tablet
- [x] **25 built-in patterns** across 5 categories:
  - Still Lifes: Block, Beehive, Loaf, Boat, Tub, Pond
  - Oscillators: Blinker, Toad, Beacon, Pulsar, Pentadecathlon, Clock, Figure Eight
  - Spaceships: Glider, LWSS, MWSS, HWSS, Glider Fleet
  - Methuselahs: R-pentomino, Diehard, Acorn, B-heptomino, Pi-heptomino
  - Guns: Gosper Glider Gun
- [x] **Pattern browser** — N/P to cycle, Tab to toggle overlay, category + details display
- [x] **Full controls** — Pause, step, clear, random, speed (1-60), draw, patterns
- [x] **RLE import/export** — Save to clipboard (S), load from clipboard (L)
- [x] **HUD overlay** — Generation count, speed, population, controls hint, temporary messages
- [x] **PAUSED overlay** — Large centered text when simulation is paused
- [x] **Cached grid rendering** — Grid lines on off-screen canvas, only rebuilt on resize
- [x] **love.js ready** — Clipboard wrapped in pcall, no threads, unused modules disabled

### Performance

- 100x100 grid at 60fps: ~2.3ms per frame (16.6ms budget)
- Zero allocations per generation (ping-pong buffer reuse)

---

## Roadmap

### v0.3.0 — Interaction Polish
- [ ] Grid zoom and pan (scroll wheel + middle-mouse drag)
- [ ] Pattern preview before placement (ghost overlay)
- [ ] Pattern rotation and flip (R/F keys before placement)
- [ ] Fullscreen toggle (F11)
- [ ] Custom monospace font for HUD

### v0.4.0 — Advanced Features
- [ ] Rule editor UI (switch between B3/S23, HighLife, Seeds, Day & Night)
- [ ] Generation history with undo/redo (ring buffer)
- [ ] Population graph overlay
- [ ] Hashlife algorithm for 1000x1000+ grids

### v0.5.0 — Web & Sharing
- [ ] love.js web build with GitHub Pages deployment
- [ ] URL-encoded pattern sharing
- [ ] Screenshot export (PNG) via in-game hotkey
- [ ] GIF recording of simulation
