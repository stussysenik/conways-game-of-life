-- screenshot.lua
-- Automated screenshot capture for all patterns + special scenes.
-- Run with: love . --screenshot
-- Saves PNGs to screenshots/ directory then exits.

local Config   = require("config")
local grid     = require("grid")
local patterns = require("patterns")

local AGE_COLORS   = Config.AGE_COLORS
local TRAIL_LENGTH = Config.TRAIL_LENGTH
local TRAIL_COLOR  = Config.TRAIL_COLOR
local W = Config.GRID_WIDTH
local H = Config.GRID_HEIGHT
local N = W * H

local state = {}
local queue = {}       -- list of {name, setup_fn, advance_count}
local current = 0
local framesWaited = 0
local SETTLE_FRAMES = 2  -- frames to wait before capturing (for rendering)

---------------------------------------------------------------------------
-- Same rendering functions as main.lua (needed for screenshots)
---------------------------------------------------------------------------

local function ageToColor(age)
    if age <= 0 then return nil end
    if age == 1 then return AGE_COLORS[1] end
    if age == 2 then return AGE_COLORS[2] end
    if age <= 4 then return AGE_COLORS[3] end
    if age <= 8 then return AGE_COLORS[4] end
    if age <= 20 then return AGE_COLORS[5] end
    if age <= 50 then return AGE_COLORS[6] end
    return AGE_COLORS[7]
end

local function calculateLayout(winW, winH, gridW, gridH, hudHeight)
    local availW = winW
    local availH = winH - hudHeight
    local cellW = math.floor(availW / gridW)
    local cellH = math.floor(availH / gridH)
    local cellSize = math.min(cellW, cellH)
    cellSize = math.max(cellSize, 2)
    local gpW = cellSize * gridW
    local gpH = cellSize * gridH
    local offX = math.floor((availW - gpW) / 2)
    local offY = hudHeight + math.floor((availH - gpH) / 2)
    return {
        cellSize = cellSize, offsetX = offX, offsetY = offY,
        gridPixelW = gpW, gridPixelH = gpH, hudHeight = hudHeight,
    }
end

local function newBuffer()
    local buf = {}
    for i = 1, N do buf[i] = 0 end
    return buf
end

local function resetVisuals()
    for i = 1, N do
        state.ages[i] = state.cells[i] == 1 and 1 or 0
        state.trails[i] = 0
    end
end

local function advanceGeneration()
    local old = state.cells
    local nextBuf = (old == state.bufA) and state.bufB or state.bufA
    local new = grid.step(old, W, H, Config.BIRTH, Config.SURVIVAL, nextBuf)
    for i = 1, N do
        if new[i] == 1 then
            state.ages[i] = state.ages[i] + 1
        else
            if old[i] == 1 then state.trails[i] = TRAIL_LENGTH end
            state.ages[i] = 0
        end
        if state.trails[i] > 0 and new[i] == 0 then
            state.trails[i] = state.trails[i] - 1
        end
    end
    state.cells = new
end

local function drawCells()
    local L = state.layout
    local cs = L.cellSize
    local ox, oy = L.offsetX, L.offsetY
    for y = 0, H - 1 do
        local row = y * W
        for x = 0, W - 1 do
            local i = row + x + 1
            local px = ox + x * cs + 1
            local py = oy + y * cs + 1
            local sz = cs - 1
            if state.cells[i] == 1 then
                local c = ageToColor(state.ages[i])
                if c then
                    love.graphics.setColor(c[1], c[2], c[3], 1)
                    love.graphics.rectangle("fill", px, py, sz, sz)
                end
            elseif state.trails[i] > 0 then
                local alpha = state.trails[i] / TRAIL_LENGTH * 0.6
                love.graphics.setColor(TRAIL_COLOR[1], TRAIL_COLOR[2], TRAIL_COLOR[3], alpha)
                love.graphics.rectangle("fill", px, py, sz, sz)
            end
        end
    end
end

local function drawGrid()
    love.graphics.setColor(Config.COLOR_GRID)
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("rough")
    local L = state.layout
    for i = 0, W do
        local x = L.offsetX + i * L.cellSize
        love.graphics.line(x, L.offsetY, x, L.offsetY + L.gridPixelH)
    end
    for j = 0, H do
        local y = L.offsetY + j * L.cellSize
        love.graphics.line(L.offsetX, y, L.offsetX + L.gridPixelW, y)
    end
end

local function drawLabel(text, subtext)
    local winW = love.graphics.getWidth()
    local HH = state.layout.hudHeight
    local font = love.graphics.getFont()
    local fh = font:getHeight()

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, winW, HH)

    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.print(text, 10, math.floor((HH - fh) / 2))

    if subtext then
        local sw = font:getWidth(subtext)
        love.graphics.setColor(0, 0.6, 0, 0.8)
        love.graphics.print(subtext, winW - sw - 10, math.floor((HH - fh) / 2))
    end
end

---------------------------------------------------------------------------
-- Build screenshot queue
---------------------------------------------------------------------------

local function buildQueue()
    -- All patterns from library (initial state — just placed)
    for idx, pat in ipairs(patterns.library) do
        -- Screenshot 1: pattern just placed (age=1, all white flash)
        queue[#queue + 1] = {
            name = string.format("%02d_%s_initial", idx, pat.name:gsub("%s+", "_"):lower()),
            label = pat.name,
            sublabel = pat.category .. " | " .. pat.width .. "x" .. pat.height,
            setup = function()
                state.cells = grid.placePattern(
                    grid.clear(W, H), W, H, pat.cells,
                    math.floor((W - pat.width) / 2),
                    math.floor((H - pat.height) / 2)
                )
                resetVisuals()
            end,
            advance = 0,
        }
        -- Screenshot 2: pattern after some evolution (shows age colors + trails)
        local gens = 15
        if pat.category == "Methuselah" then gens = 80 end
        if pat.category == "Gun" then gens = 60 end
        if pat.category == "Still Life" then gens = 3 end
        queue[#queue + 1] = {
            name = string.format("%02d_%s_evolved", idx, pat.name:gsub("%s+", "_"):lower()),
            label = pat.name .. " (evolved)",
            sublabel = pat.category .. " | Gen " .. gens,
            setup = function()
                state.cells = grid.placePattern(
                    grid.clear(W, H), W, H, pat.cells,
                    math.floor((W - pat.width) / 2),
                    math.floor((H - pat.height) / 2)
                )
                resetVisuals()
            end,
            advance = gens,
        }
    end

    -- Special: random soup
    queue[#queue + 1] = {
        name = "special_random_soup",
        label = "Random Soup",
        sublabel = "20% density | Gen 0",
        setup = function()
            math.randomseed(42) -- deterministic
            state.cells = grid.randomize(W, H, 0.20)
            resetVisuals()
        end,
        advance = 0,
    }
    queue[#queue + 1] = {
        name = "special_random_evolved",
        label = "Random Soup (evolved)",
        sublabel = "20% density | Gen 50",
        setup = function()
            math.randomseed(42)
            state.cells = grid.randomize(W, H, 0.20)
            resetVisuals()
        end,
        advance = 50,
    }
end

---------------------------------------------------------------------------
-- LOVE callbacks for screenshot mode
---------------------------------------------------------------------------

function love.load()
    love.graphics.setBackgroundColor(Config.COLOR_DEAD)
    love.graphics.setLineStyle("rough")

    state.bufA = grid.create(W, H)
    state.bufB = grid.create(W, H)
    state.cells = state.bufA
    state.ages = newBuffer()
    state.trails = newBuffer()

    local w, h = love.graphics.getDimensions()
    state.layout = calculateLayout(w, h, W, H, Config.HUD_HEIGHT)

    buildQueue()
    current = 0
    framesWaited = 0
    print(string.format("Screenshot mode: capturing %d screenshots...", #queue))
end

function love.update(dt)
    -- Nothing — all logic in draw for proper frame capture
end

function love.draw()
    current = current + 1
    if current > #queue then
        print("All screenshots captured!")
        love.event.quit()
        return
    end

    local job = queue[current]

    -- Setup the pattern
    job.setup()

    -- Advance generations
    for i = 1, job.advance do
        advanceGeneration()
    end

    -- Render
    love.graphics.clear(Config.COLOR_DEAD)
    drawGrid()
    drawCells()
    drawLabel(job.label, job.sublabel)

    -- Capture screenshot
    local filename = "screenshots/" .. job.name .. ".png"
    love.graphics.captureScreenshot(function(imageData)
        imageData:encode("png", job.name .. ".png")
        print(string.format("  [%d/%d] %s", current, #queue, filename))
    end)
end

return {}
