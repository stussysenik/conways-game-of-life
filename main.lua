-- main.lua
-- Conway's Game of Life — LOVE2D application orchestrator.
-- This is the only file with mutable state.

local Config   = require("config")
local grid     = require("grid")
local patterns = require("patterns")

-- Pre-unpack age color table for fast lookup
local AGE_COLORS   = Config.AGE_COLORS
local TRAIL_LENGTH = Config.TRAIL_LENGTH
local TRAIL_COLOR  = Config.TRAIL_COLOR
local W = Config.GRID_WIDTH
local H = Config.GRID_HEIGHT
local N = W * H

-- Game state (the single mutable root)
local state = {
    cells       = nil,
    bufA        = nil,
    bufB        = nil,
    ages        = nil,   -- flat array: how many generations each cell has been alive
    trails      = nil,   -- flat array: countdown timer for death glow (0 = no trail)
    paused      = true,
    generation  = 0,
    speed       = Config.DEFAULT_SPEED,
    accumulator = 0,
    layout      = {
        cellSize   = 0,
        offsetX    = 0,
        offsetY    = 0,
        gridPixelW = 0,
        gridPixelH = 0,
        hudHeight  = Config.HUD_HEIGHT,
    },
    gridCanvas      = nil,
    needsGridRedraw = true,
    hudMessage      = nil,
    hudMessageTimer = 0,
    patternIndex    = 1,
    showBrowser     = false,
}

---------------------------------------------------------------------------
-- Age color mapping
---------------------------------------------------------------------------

--- Map a cell age to an (r, g, b) color from the gradient.
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

---------------------------------------------------------------------------
-- Layout
---------------------------------------------------------------------------

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
        cellSize   = cellSize,
        offsetX    = offX,
        offsetY    = offY,
        gridPixelW = gpW,
        gridPixelH = gpH,
        hudHeight  = hudHeight,
    }
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function screenToCell(px, py, layout)
    local lx = px - layout.offsetX
    local ly = py - layout.offsetY
    if lx < 0 or ly < 0 then return nil end
    local cx = math.floor(lx / layout.cellSize)
    local cy = math.floor(ly / layout.cellSize)
    if cx >= W or cy >= H then return nil end
    return cx, cy
end

local function showMessage(msg)
    state.hudMessage = msg
    state.hudMessageTimer = 2.5
end

--- Create a fresh zeroed flat array.
local function newBuffer()
    local buf = {}
    for i = 1, N do buf[i] = 0 end
    return buf
end

--- Reset ages and trails (call after clear/random/pattern load).
local function resetVisuals()
    local ages = state.ages
    local trails = state.trails
    local cells = state.cells
    for i = 1, N do
        ages[i] = cells[i] == 1 and 1 or 0
        trails[i] = 0
    end
end

--- Advance simulation by one generation, updating ages and trails.
local function advanceGeneration()
    local old = state.cells
    local nextBuf = (old == state.bufA) and state.bufB or state.bufA
    local new = grid.step(old, W, H, Config.BIRTH, Config.SURVIVAL, nextBuf)

    -- Update ages and trails by comparing old vs new
    local ages = state.ages
    local trails = state.trails
    for i = 1, N do
        if new[i] == 1 then
            -- Alive: increment age (new birth = 1, surviving = age + 1)
            ages[i] = ages[i] + 1
        else
            -- Dead: if was alive, start death trail
            if old[i] == 1 then
                trails[i] = TRAIL_LENGTH
            end
            ages[i] = 0
        end
        -- Decay existing trails
        if trails[i] > 0 and new[i] == 0 then
            trails[i] = trails[i] - 1
        end
    end

    state.cells = new
    state.generation = state.generation + 1
end

local function loadCurrentPattern()
    local pat = patterns.library[state.patternIndex]
    if not pat then return end
    state.cells = grid.placePattern(
        grid.clear(W, H), W, H, pat.cells,
        math.floor((W - pat.width) / 2),
        math.floor((H - pat.height) / 2)
    )
    state.generation = 0
    state.paused = true
    resetVisuals()
    showMessage(pat.category .. ": " .. pat.name)
end

---------------------------------------------------------------------------
-- Rendering
---------------------------------------------------------------------------

local function rebuildGridCanvas()
    local w, h = love.graphics.getDimensions()
    state.gridCanvas = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(state.gridCanvas)
    love.graphics.clear(Config.COLOR_DEAD)

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

    love.graphics.setCanvas()
    state.needsGridRedraw = false
end

--- Draw live cells with age-based coloring, plus death trails.
local function drawCells()
    local L = state.layout
    local cs = L.cellSize
    local ox, oy = L.offsetX, L.offsetY
    local cells = state.cells
    local ages = state.ages
    local trails = state.trails

    for y = 0, H - 1 do
        local row = y * W
        for x = 0, W - 1 do
            local i = row + x + 1
            local px = ox + x * cs + 1
            local py = oy + y * cs + 1
            local sz = cs - 1

            if cells[i] == 1 then
                -- Alive: color by age
                local c = ageToColor(ages[i])
                if c then
                    love.graphics.setColor(c[1], c[2], c[3], 1)
                    love.graphics.rectangle("fill", px, py, sz, sz)
                end
            elseif trails[i] > 0 then
                -- Death trail: amber glow fading out
                local alpha = trails[i] / TRAIL_LENGTH * 0.6
                love.graphics.setColor(TRAIL_COLOR[1], TRAIL_COLOR[2], TRAIL_COLOR[3], alpha)
                love.graphics.rectangle("fill", px, py, sz, sz)
            end
        end
    end
end

local function drawHUD()
    local winW = love.graphics.getWidth()
    local HH = state.layout.hudHeight
    local font = love.graphics.getFont()
    local fh = font:getHeight()
    local ty = math.floor((HH - fh) / 2)

    love.graphics.setColor(Config.COLOR_HUD_BG)
    love.graphics.rectangle("fill", 0, 0, winW, HH)

    love.graphics.setColor(Config.COLOR_HUD_TEXT)
    local pop = grid.population(state.cells, W, H)
    local info = string.format("Gen: %d  |  Speed: %d/s  |  Pop: %d",
        state.generation, state.speed, pop)
    love.graphics.print(info, 10, ty)

    local hint = string.format("[%d/%d] N/P:Browse  SPC:Run  R:Rand  C:Clear  +/-:Speed",
        state.patternIndex, patterns.count)
    local hintW = font:getWidth(hint)
    love.graphics.print(hint, winW - hintW - 10, ty)

    if state.hudMessage and state.hudMessageTimer > 0 then
        local alpha = math.min(state.hudMessageTimer, 1)
        love.graphics.setColor(0, 1, 0, alpha)
        local mw = font:getWidth(state.hudMessage)
        love.graphics.print(state.hudMessage, math.floor((winW - mw) / 2), ty)
    end
end

local function drawBrowser()
    if not state.showBrowser then return end

    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    local font = love.graphics.getFont()
    local fh = font:getHeight()
    local pat = patterns.library[state.patternIndex]
    if not pat then return end

    local panelH = fh * 4 + 20
    local panelY = winH - panelH

    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, panelY, winW, panelH)

    love.graphics.setColor(0, 1, 0, 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.line(0, panelY, winW, panelY)

    love.graphics.setColor(0, 1, 0, 1)
    local y = panelY + 8
    love.graphics.print(string.format("[%d/%d]  %s", state.patternIndex, patterns.count, pat.name), 15, y)
    y = y + fh + 2

    love.graphics.setColor(0, 0.7, 0, 0.8)
    love.graphics.print(string.format("Category: %s  |  Size: %dx%d  |  Cells: %d",
        pat.category, pat.width, pat.height, #pat.cells), 15, y)
    y = y + fh + 2

    love.graphics.setColor(0, 0.5, 0, 0.6)
    love.graphics.print("N: Next    P: Previous    Enter: Load    Tab: Close browser", 15, y)
end

local function drawPaused()
    if not state.paused then return end

    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    local font = love.graphics.getFont()

    love.graphics.setColor(0, 1, 0, 0.15)
    local scale = 4
    local text = "PAUSED"
    local tw = font:getWidth(text) * scale
    local th = font:getHeight() * scale
    love.graphics.print(text,
        math.floor((winW - tw) / 2),
        math.floor((winH - th) / 2),
        0, scale, scale)
end

---------------------------------------------------------------------------
-- LOVE2D Callbacks
---------------------------------------------------------------------------

function love.load()
    love.graphics.setBackgroundColor(Config.COLOR_DEAD)
    love.graphics.setLineStyle("rough")
    math.randomseed(os.time())

    state.bufA = grid.create(W, H)
    state.bufB = grid.create(W, H)
    state.cells = state.bufA
    state.ages = newBuffer()
    state.trails = newBuffer()

    local w, h = love.graphics.getDimensions()
    state.layout = calculateLayout(w, h, W, H, Config.HUD_HEIGHT)
    state.needsGridRedraw = true

    loadCurrentPattern()
end

function love.update(dt)
    if state.hudMessageTimer > 0 then
        state.hudMessageTimer = state.hudMessageTimer - dt
    end

    if state.paused then return end

    local interval = 1.0 / state.speed
    state.accumulator = state.accumulator + dt

    if state.accumulator > interval * 3 then
        state.accumulator = interval * 3
    end

    while state.accumulator >= interval do
        state.accumulator = state.accumulator - interval
        advanceGeneration()
    end
end

function love.draw()
    if state.needsGridRedraw then
        rebuildGridCanvas()
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(state.gridCanvas)

    drawCells()
    drawPaused()
    drawHUD()
    drawBrowser()
end

function love.keypressed(key)
    if key == "n" then
        state.patternIndex = (state.patternIndex % patterns.count) + 1
        state.showBrowser = true
        loadCurrentPattern()
        return
    elseif key == "p" then
        state.patternIndex = ((state.patternIndex - 2) % patterns.count) + 1
        state.showBrowser = true
        loadCurrentPattern()
        return
    elseif key == "return" or key == "kpenter" then
        if state.showBrowser then
            loadCurrentPattern()
            return
        end
    elseif key == "tab" then
        state.showBrowser = not state.showBrowser
        return
    end

    if key == "space" then
        state.paused = not state.paused
        state.accumulator = 0

    elseif key == "right" and state.paused then
        advanceGeneration()

    elseif key == "c" then
        state.cells = grid.clear(W, H)
        state.generation = 0
        resetVisuals()
        showMessage("Grid cleared")

    elseif key == "r" then
        state.cells = grid.randomize(W, H, Config.RANDOM_DENSITY)
        state.generation = 0
        resetVisuals()
        showMessage("Random seed (20%)")

    elseif key == "=" or key == "kp+" then
        state.speed = math.min(state.speed + 1, Config.MAX_SPEED)
        showMessage("Speed: " .. state.speed .. "/s")

    elseif key == "-" or key == "kp-" then
        state.speed = math.max(state.speed - 1, Config.MIN_SPEED)
        showMessage("Speed: " .. state.speed .. "/s")

    elseif key == "s" then
        local rle = patterns.toRLE(state.cells, W, H)
        local ok = pcall(love.system.setClipboardText, rle)
        if ok then
            showMessage("RLE copied to clipboard")
        else
            showMessage("Clipboard not available")
        end

    elseif key == "l" then
        local ok, text = pcall(love.system.getClipboardText)
        if ok and text and text ~= "" then
            local pat = patterns.parseRLE(text)
            if pat and #pat.cells > 0 then
                state.cells = grid.placePattern(
                    grid.clear(W, H), W, H, pat.cells,
                    math.floor((W - pat.width) / 2),
                    math.floor((H - pat.height) / 2)
                )
                state.generation = 0
                resetVisuals()
                showMessage("Loaded: " .. pat.name)
            else
                showMessage("Invalid RLE data")
            end
        else
            showMessage("Clipboard empty or unavailable")
        end

    else
        local num = tonumber(key)
        if num and num >= 1 and num <= 9 and num <= patterns.count then
            state.patternIndex = num
            loadCurrentPattern()
        end
    end
end

function love.mousepressed(x, y, button, istouch)
    if istouch then return end
    if button == 1 then
        local cx, cy = screenToCell(x, y, state.layout)
        if cx then
            state.cells = grid.toggle(state.cells, cx, cy, W, H)
            -- Update age for the toggled cell
            local idx = grid.index(cx, cy, W)
            state.ages[idx] = state.cells[idx] == 1 and 1 or 0
            state.trails[idx] = 0
        end
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if istouch then return end
    if love.mouse.isDown(1) then
        local cx, cy = screenToCell(x, y, state.layout)
        if cx then
            local idx = grid.index(cx, cy, W)
            if state.cells[idx] == 0 then
                state.cells = grid.set(state.cells, cx, cy, W, H, 1)
                state.ages[idx] = 1
                state.trails[idx] = 0
            end
        end
    end
end

function love.touchpressed(id, x, y)
    local cx, cy = screenToCell(x, y, state.layout)
    if cx then
        state.cells = grid.toggle(state.cells, cx, cy, W, H)
        local idx = grid.index(cx, cy, W)
        state.ages[idx] = state.cells[idx] == 1 and 1 or 0
        state.trails[idx] = 0
    end
end

function love.touchmoved(id, x, y)
    local cx, cy = screenToCell(x, y, state.layout)
    if cx then
        local idx = grid.index(cx, cy, W)
        if state.cells[idx] == 0 then
            state.cells = grid.set(state.cells, cx, cy, W, H, 1)
            state.ages[idx] = 1
            state.trails[idx] = 0
        end
    end
end

function love.resize(w, h)
    state.layout = calculateLayout(w, h, W, H, Config.HUD_HEIGHT)
    state.needsGridRedraw = true
end
