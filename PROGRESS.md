# Progress

Development log for Conway's Game of Life simulator.

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

- 100x100 grid at 60fps: ~2-3ms per frame (16.6ms budget)
- Zero allocations per generation (ping-pong buffer reuse)

---

## Roadmap

### v0.2.0 — Visual Polish
- [ ] Cell age tracking (map age to color gradient: bright green → dark green)
- [ ] Grid zoom and pan (scroll wheel + drag)
- [ ] Smooth cell transitions (fade in/out)
- [ ] Custom font for HUD (monospace, larger)
- [ ] Fullscreen toggle (F11)

### v0.3.0 — Advanced Features
- [ ] Hashlife algorithm for 1000x1000+ grids
- [ ] Rule editor (switch between B3/S23, HighLife, Seeds, Day & Night)
- [ ] Pattern rotation and flip before placement
- [ ] Generation history (undo/redo with ring buffer)
- [ ] Population graph overlay

### v0.4.0 — Web & Sharing
- [ ] love.js web build with GitHub Pages deployment
- [ ] URL-encoded pattern sharing (pattern in query string)
- [ ] Screenshot export (PNG)
- [ ] GIF recording of simulation

---

## Architecture Notes

```
conf.lua        → LOVE2D engine config
config.lua      → Constants (colors, grid, rules)
grid.lua        → Pure simulation core
patterns.lua    → 25 patterns + RLE parser/serializer
main.lua        → State, rendering, input (only mutable file)
```

All simulation logic is in `grid.lua` as pure functions. `main.lua` is the only file with mutable state. This separation enables future features like time-travel debugging and parallel simulation.
