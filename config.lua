-- config.lua
-- Constants for Conway's Game of Life.
-- Every other module requires this. No functions, no state — just data.

return {
    -- Grid dimensions (logical cells)
    GRID_WIDTH  = 100,
    GRID_HEIGHT = 100,

    -- Base colors (r, g, b, a) normalized 0–1
    COLOR_DEAD     = {0.04, 0.04, 0.04, 1},    -- #0a0a0a near black
    COLOR_GRID     = {0.1, 0.1, 0.1, 1},       -- #1a1a1a subtle grid lines
    COLOR_HUD_BG   = {0, 0, 0, 0.7},           -- semi-transparent black
    COLOR_HUD_TEXT = {0, 1, 0, 1},              -- electric green text

    -- Age-based color gradient for alive cells (indexed by age bracket)
    -- Each entry: {r, g, b}
    -- Birth flash → electric green → emerald → deep forest
    AGE_COLORS = {
        {1.0,  1.0,  1.0 },   -- age 1: white birth flash
        {0.7,  1.0,  0.7 },   -- age 2: bright white-green
        {0.0,  1.0,  0.0 },   -- age 3-4: electric green
        {0.0,  0.85, 0.0 },   -- age 5-8: bright green
        {0.0,  0.65, 0.0 },   -- age 9-20: medium green
        {0.0,  0.45, 0.0 },   -- age 21-50: emerald
        {0.0,  0.30, 0.0 },   -- age 51+: deep forest green
    },

    -- Death trail: recently dead cells glow briefly
    TRAIL_LENGTH  = 6,          -- frames the trail persists
    TRAIL_COLOR   = {0.6, 0.2, 0.0},  -- amber/orange base (fades with alpha)

    -- Simulation defaults
    DEFAULT_SPEED  = 10,   -- generations per second
    MIN_SPEED      = 1,
    MAX_SPEED      = 60,
    RANDOM_DENSITY = 0.20, -- 20% alive on random seed

    -- B3/S23 rules as lookup tables
    BIRTH    = { [3] = true },
    SURVIVAL = { [2] = true, [3] = true },

    -- HUD
    HUD_HEIGHT = 40,
}
