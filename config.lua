-- config.lua
-- Constants for Conway's Game of Life.
-- Every other module requires this. No functions, no state — just data.

return {
    -- Grid dimensions (logical cells)
    GRID_WIDTH  = 100,
    GRID_HEIGHT = 100,

    -- Colors (r, g, b, a) normalized 0–1
    COLOR_ALIVE    = {0, 1, 0, 1},             -- #00ff00 electric green
    COLOR_DEAD     = {0.04, 0.04, 0.04, 1},    -- #0a0a0a near black
    COLOR_GRID     = {0.1, 0.1, 0.1, 1},       -- #1a1a1a subtle grid lines
    COLOR_HUD_BG   = {0, 0, 0, 0.7},           -- semi-transparent black
    COLOR_HUD_TEXT = {0, 1, 0, 1},              -- electric green text

    -- Simulation defaults
    DEFAULT_SPEED  = 10,   -- generations per second
    MIN_SPEED      = 1,
    MAX_SPEED      = 60,
    RANDOM_DENSITY = 0.20, -- 20% alive on random seed

    -- B3/S23 rules as lookup tables
    -- Usage: BIRTH[neighborCount] → true/nil, SURVIVAL[neighborCount] → true/nil
    BIRTH    = { [3] = true },
    SURVIVAL = { [2] = true, [3] = true },

    -- HUD
    HUD_HEIGHT = 40, -- pixels reserved for top bar
}
