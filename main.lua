-- main.lua
-- Conway's Game of Life — LOVE2D application orchestrator.
-- This is the only file with mutable state.

local Config   = require("config")
local grid     = require("grid")
local patterns = require("patterns")

-- Game state (the single mutable root)
local state = {
    cells       = nil,
    bufA        = nil,
    bufB        = nil,
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
    patternIndex    = 1,        -- current pattern in browser
    showBrowser     = false,    -- pattern browser overlay visible
}

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
-- Input helpers
---------------------------------------------------------------------------

local function screenToCell(px, py, layout)
    local lx = px - layout.offsetX
    local ly = py - layout.offsetY
    if lx < 0 or ly < 0 then return nil end
    local cx = math.floor(lx / layout.cellSize)
    local cy = math.floor(ly / layout.cellSize)
    if cx >= Config.GRID_WIDTH or cy >= Config.GRID_HEIGHT then return nil end
    return cx, cy
end

local function showMessage(msg)
    state.hudMessage = msg
    state.hudMessageTimer = 2.5
end

local function advanceGeneration()
    local nextBuf = (state.cells == state.bufA) and state.bufB or state.bufA
    state.cells = grid.step(
        state.cells, Config.GRID_WIDTH, Config.GRID_HEIGHT,
        Config.BIRTH, Config.SURVIVAL, nextBuf
    )
    state.generation = state.generation + 1
end

--- Load the current pattern from the browser onto the grid.
local function loadCurrentPattern()
    local pat = patterns.library[state.patternIndex]
    if not pat then return end
    state.cells = grid.placePattern(
        grid.clear(Config.GRID_WIDTH, Config.GRID_HEIGHT),
        Config.GRID_WIDTH, Config.GRID_HEIGHT,
        pat.cells,
        math.floor((Config.GRID_WIDTH - pat.width) / 2),
        math.floor((Config.GRID_HEIGHT - pat.height) / 2)
    )
    state.generation = 0
    state.paused = true
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
    for i = 0, Config.GRID_WIDTH do
        local x = L.offsetX + i * L.cellSize
        love.graphics.line(x, L.offsetY, x, L.offsetY + L.gridPixelH)
    end
    for j = 0, Config.GRID_HEIGHT do
        local y = L.offsetY + j * L.cellSize
        love.graphics.line(L.offsetX, y, L.offsetX + L.gridPixelW, y)
    end

    love.graphics.setCanvas()
    state.needsGridRedraw = false
end

local function drawCells()
    love.graphics.setColor(Config.COLOR_ALIVE)
    local L = state.layout
    local W = Config.GRID_WIDTH
    local H = Config.GRID_HEIGHT
    local cs = L.cellSize
    local cells = state.cells

    for y = 0, H - 1 do
        local row = y * W
        for x = 0, W - 1 do
            if cells[row + x + 1] == 1 then
                love.graphics.rectangle("fill",
                    L.offsetX + x * cs + 1,
                    L.offsetY + y * cs + 1,
                    cs - 1, cs - 1)
            end
        end
    end
end

local function drawHUD()
    local winW = love.graphics.getWidth()
    local H = state.layout.hudHeight
    local font = love.graphics.getFont()
    local fh = font:getHeight()
    local ty = math.floor((H - fh) / 2)

    -- Background bar
    love.graphics.setColor(Config.COLOR_HUD_BG)
    love.graphics.rectangle("fill", 0, 0, winW, H)

    -- Left: status info
    love.graphics.setColor(Config.COLOR_HUD_TEXT)
    local pop = grid.population(state.cells, Config.GRID_WIDTH, Config.GRID_HEIGHT)
    local info = string.format("Gen: %d  |  Speed: %d/s  |  Pop: %d",
        state.generation, state.speed, pop)
    love.graphics.print(info, 10, ty)

    -- Right: pattern browser hint
    local hint = string.format("[%d/%d] N/P:Browse  SPC:Run  R:Rand  C:Clear  +/-:Speed",
        state.patternIndex, patterns.count)
    local hintW = font:getWidth(hint)
    love.graphics.print(hint, winW - hintW - 10, ty)

    -- Center: temporary message
    if state.hudMessage and state.hudMessageTimer > 0 then
        local alpha = math.min(state.hudMessageTimer, 1)
        love.graphics.setColor(0, 1, 0, alpha)
        local mw = font:getWidth(state.hudMessage)
        love.graphics.print(state.hudMessage, math.floor((winW - mw) / 2), ty)
    end
end

--- Draw the pattern browser overlay when active.
local function drawBrowser()
    if not state.showBrowser then return end

    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    local font = love.graphics.getFont()
    local fh = font:getHeight()
    local pat = patterns.library[state.patternIndex]
    if not pat then return end

    -- Semi-transparent overlay on the bottom
    local panelH = fh * 4 + 20
    local panelY = winH - panelH

    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, panelY, winW, panelH)

    -- Green border line at top of panel
    love.graphics.setColor(0, 1, 0, 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.line(0, panelY, winW, panelY)

    -- Pattern info
    love.graphics.setColor(0, 1, 0, 1)
    local y = panelY + 8

    -- Title line
    local title = string.format("[%d/%d]  %s", state.patternIndex, patterns.count, pat.name)
    love.graphics.print(title, 15, y)
    y = y + fh + 2

    -- Category + dimensions
    love.graphics.setColor(0, 0.7, 0, 0.8)
    local details = string.format("Category: %s  |  Size: %dx%d  |  Cells: %d",
        pat.category, pat.width, pat.height, #pat.cells)
    love.graphics.print(details, 15, y)
    y = y + fh + 2

    -- Controls
    love.graphics.setColor(0, 0.5, 0, 0.6)
    love.graphics.print("N: Next    P: Previous    Enter: Load    Tab: Close browser", 15, y)
end

--- Draw PAUSED overlay.
local function drawPaused()
    if not state.paused then return end

    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    local font = love.graphics.getFont()

    love.graphics.setColor(0, 1, 0, 0.15)
    local pauseText = "PAUSED"
    local scale = 4
    local tw = font:getWidth(pauseText) * scale
    local th = font:getHeight() * scale
    love.graphics.print(pauseText,
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

    state.bufA = grid.create(Config.GRID_WIDTH, Config.GRID_HEIGHT)
    state.bufB = grid.create(Config.GRID_WIDTH, Config.GRID_HEIGHT)
    state.cells = state.bufA

    local w, h = love.graphics.getDimensions()
    state.layout = calculateLayout(w, h, Config.GRID_WIDTH, Config.GRID_HEIGHT, Config.HUD_HEIGHT)
    state.needsGridRedraw = true

    -- Load first pattern on startup so the grid isn't empty
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

    -- Layer 1: cached grid lines
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(state.gridCanvas)

    -- Layer 2: live cells
    drawCells()

    -- Layer 3: overlays
    drawPaused()
    drawHUD()
    drawBrowser()
end

function love.keypressed(key)
    -- Pattern browser controls
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

    -- Simulation controls
    if key == "space" then
        state.paused = not state.paused
        state.accumulator = 0

    elseif key == "right" and state.paused then
        advanceGeneration()

    elseif key == "c" then
        state.cells = grid.clear(Config.GRID_WIDTH, Config.GRID_HEIGHT)
        state.generation = 0
        showMessage("Grid cleared")

    elseif key == "r" then
        state.cells = grid.randomize(Config.GRID_WIDTH, Config.GRID_HEIGHT, Config.RANDOM_DENSITY)
        state.generation = 0
        showMessage("Random seed (20%)")

    elseif key == "=" or key == "kp+" then
        state.speed = math.min(state.speed + 1, Config.MAX_SPEED)
        showMessage("Speed: " .. state.speed .. "/s")

    elseif key == "-" or key == "kp-" then
        state.speed = math.max(state.speed - 1, Config.MIN_SPEED)
        showMessage("Speed: " .. state.speed .. "/s")

    elseif key == "s" then
        local rle = patterns.toRLE(state.cells, Config.GRID_WIDTH, Config.GRID_HEIGHT)
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
                    grid.clear(Config.GRID_WIDTH, Config.GRID_HEIGHT),
                    Config.GRID_WIDTH, Config.GRID_HEIGHT,
                    pat.cells,
                    math.floor((Config.GRID_WIDTH - pat.width) / 2),
                    math.floor((Config.GRID_HEIGHT - pat.height) / 2)
                )
                state.generation = 0
                showMessage("Loaded: " .. pat.name)
            else
                showMessage("Invalid RLE data")
            end
        else
            showMessage("Clipboard empty or unavailable")
        end

    else
        -- Number keys 1-9: quick access (maps to first 9 patterns)
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
            state.cells = grid.toggle(state.cells, cx, cy,
                Config.GRID_WIDTH, Config.GRID_HEIGHT)
        end
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if istouch then return end
    if love.mouse.isDown(1) then
        local cx, cy = screenToCell(x, y, state.layout)
        if cx then
            local idx = grid.index(cx, cy, Config.GRID_WIDTH)
            if state.cells[idx] == 0 then
                state.cells = grid.set(state.cells, cx, cy,
                    Config.GRID_WIDTH, Config.GRID_HEIGHT, 1)
            end
        end
    end
end

function love.touchpressed(id, x, y)
    local cx, cy = screenToCell(x, y, state.layout)
    if cx then
        state.cells = grid.toggle(state.cells, cx, cy,
            Config.GRID_WIDTH, Config.GRID_HEIGHT)
    end
end

function love.touchmoved(id, x, y)
    local cx, cy = screenToCell(x, y, state.layout)
    if cx then
        local idx = grid.index(cx, cy, Config.GRID_WIDTH)
        if state.cells[idx] == 0 then
            state.cells = grid.set(state.cells, cx, cy,
                Config.GRID_WIDTH, Config.GRID_HEIGHT, 1)
        end
    end
end

function love.resize(w, h)
    state.layout = calculateLayout(w, h, Config.GRID_WIDTH, Config.GRID_HEIGHT, Config.HUD_HEIGHT)
    state.needsGridRedraw = true
end
