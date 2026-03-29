-- conf.lua
-- LOVE2D engine configuration. Runs before any other file.

function love.conf(t)
    t.identity = "conways-game-of-life"
    t.version  = "11.5"

    t.window.title          = "Conway's Game of Life"
    t.window.width          = 800
    t.window.height         = 600
    t.window.resizable      = true
    t.window.minwidth       = 320
    t.window.minheight      = 240
    t.window.vsync          = 1
    t.window.fullscreentype = "desktop"

    -- Disable unused modules for love.js memory savings
    t.modules.joystick = false
    t.modules.physics  = false
    t.modules.video    = false
end
