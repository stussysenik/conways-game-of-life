-- patterns.lua
-- Built-in pattern library and RLE (Run Length Encoded) parser/serializer.
-- 25 patterns across 5 categories: Still Lifes, Oscillators, Spaceships,
-- Methuselahs, and Guns/Infinite Growth.

local patterns = {}

-- Each pattern: { name, category, width, height, cells = {{dx,dy}, ...} }
-- Offsets are relative to (0,0) origin, translated on placement.
patterns.library = {

    ---------------------------------------------------------------------------
    -- STILL LIFES — stable, never change
    ---------------------------------------------------------------------------

    { name = "Block", category = "Still Life", width = 2, height = 2,
      cells = { {0,0},{1,0},{0,1},{1,1} } },

    { name = "Beehive", category = "Still Life", width = 4, height = 3,
      cells = { {1,0},{2,0},{0,1},{3,1},{1,2},{2,2} } },

    { name = "Loaf", category = "Still Life", width = 4, height = 4,
      cells = { {1,0},{2,0},{0,1},{3,1},{1,2},{3,2},{2,3} } },

    { name = "Boat", category = "Still Life", width = 3, height = 3,
      cells = { {0,0},{1,0},{0,1},{2,1},{1,2} } },

    { name = "Tub", category = "Still Life", width = 3, height = 3,
      cells = { {1,0},{0,1},{2,1},{1,2} } },

    { name = "Pond", category = "Still Life", width = 4, height = 4,
      cells = { {1,0},{2,0},{0,1},{3,1},{0,2},{3,2},{1,3},{2,3} } },

    ---------------------------------------------------------------------------
    -- OSCILLATORS — cycle through states periodically
    ---------------------------------------------------------------------------

    { name = "Blinker", category = "Oscillator", width = 3, height = 1,
      cells = { {0,0},{1,0},{2,0} } },

    { name = "Toad", category = "Oscillator", width = 4, height = 2,
      cells = { {1,0},{2,0},{3,0},{0,1},{1,1},{2,1} } },

    { name = "Beacon", category = "Oscillator", width = 4, height = 4,
      cells = { {0,0},{1,0},{0,1},{1,1},{2,2},{3,2},{2,3},{3,3} } },

    { name = "Pulsar", category = "Oscillator", width = 13, height = 13,
      cells = {
          {2,0},{3,0},{4,0},{8,0},{9,0},{10,0},
          {0,2},{5,2},{7,2},{12,2},
          {0,3},{5,3},{7,3},{12,3},
          {0,4},{5,4},{7,4},{12,4},
          {2,5},{3,5},{4,5},{8,5},{9,5},{10,5},
          {2,7},{3,7},{4,7},{8,7},{9,7},{10,7},
          {0,8},{5,8},{7,8},{12,8},
          {0,9},{5,9},{7,9},{12,9},
          {0,10},{5,10},{7,10},{12,10},
          {2,12},{3,12},{4,12},{8,12},{9,12},{10,12},
      } },

    { name = "Pentadecathlon", category = "Oscillator", width = 10, height = 3,
      cells = {
          {0,1},{1,1},{2,0},{2,2},{3,1},{4,1},{5,1},{6,1},{7,0},{7,2},{8,1},{9,1},
      } },

    { name = "Clock", category = "Oscillator", width = 4, height = 4,
      cells = { {2,0},{0,1},{2,1},{1,2},{3,2},{1,3} } },

    { name = "Figure Eight", category = "Oscillator", width = 6, height = 6,
      cells = {
          {0,0},{1,0},{2,0},{0,1},{1,1},{2,1},{0,2},{1,2},{2,2},
          {3,3},{4,3},{5,3},{3,4},{4,4},{5,4},{3,5},{4,5},{5,5},
      } },

    ---------------------------------------------------------------------------
    -- SPACESHIPS — translate across the grid
    ---------------------------------------------------------------------------

    { name = "Glider", category = "Spaceship", width = 3, height = 3,
      cells = { {1,0},{2,1},{0,2},{1,2},{2,2} } },

    { name = "LWSS", category = "Spaceship", width = 5, height = 4,
      cells = { {1,0},{4,0},{0,1},{0,2},{4,2},{0,3},{1,3},{2,3},{3,3} } },

    { name = "MWSS", category = "Spaceship", width = 6, height = 5,
      cells = {
          {3,0},
          {1,1},{5,1},
          {0,2},
          {0,3},{5,3},
          {0,4},{1,4},{2,4},{3,4},{4,4},
      } },

    { name = "HWSS", category = "Spaceship", width = 7, height = 5,
      cells = {
          {3,0},{4,0},
          {1,1},{6,1},
          {0,2},
          {0,3},{6,3},
          {0,4},{1,4},{2,4},{3,4},{4,4},{5,4},
      } },

    { name = "Glider Fleet", category = "Spaceship", width = 20, height = 20,
      cells = {
          -- Glider 1 (top-left)
          {1,0},{2,1},{0,2},{1,2},{2,2},
          -- Glider 2 (offset)
          {8,5},{9,6},{7,7},{8,7},{9,7},
          -- Glider 3 (further offset)
          {15,10},{16,11},{14,12},{15,12},{16,12},
          -- Glider 4
          {4,14},{5,15},{3,16},{4,16},{5,16},
      } },

    ---------------------------------------------------------------------------
    -- METHUSELAHS — small patterns with long-lived evolution
    ---------------------------------------------------------------------------

    { name = "R-pentomino", category = "Methuselah", width = 3, height = 3,
      cells = { {1,0},{2,0},{0,1},{1,1},{1,2} } },

    { name = "Diehard", category = "Methuselah", width = 8, height = 3,
      cells = { {6,0},{0,1},{1,1},{1,2},{5,2},{6,2},{7,2} } },

    { name = "Acorn", category = "Methuselah", width = 7, height = 3,
      cells = { {1,0},{3,1},{0,2},{1,2},{4,2},{5,2},{6,2} } },

    { name = "B-heptomino", category = "Methuselah", width = 4, height = 3,
      cells = { {0,0},{1,0},{2,0},{3,0},{0,1},{2,1},{1,2} } },

    { name = "Pi-heptomino", category = "Methuselah", width = 3, height = 3,
      cells = { {0,0},{1,0},{2,0},{0,1},{2,1},{0,2},{2,2} } },

    ---------------------------------------------------------------------------
    -- GUNS & INFINITE GROWTH — produce endless streams
    ---------------------------------------------------------------------------

    { name = "Gosper Glider Gun", category = "Gun", width = 36, height = 9,
      cells = {
          {24,0},
          {22,1},{24,1},
          {12,2},{13,2},{20,2},{21,2},{34,2},{35,2},
          {11,3},{15,3},{20,3},{21,3},{34,3},{35,3},
          {0,4},{1,4},{10,4},{16,4},{20,4},{21,4},
          {0,5},{1,5},{10,5},{14,5},{16,5},{17,5},{22,5},{24,5},
          {10,6},{16,6},{24,6},
          {11,7},{15,7},
          {12,8},{13,8},
      } },
}

--- Total count of patterns in the library.
patterns.count = #patterns.library

--- Category order for display.
patterns.categories = { "Still Life", "Oscillator", "Spaceship", "Methuselah", "Gun" }

--- Parse an RLE string into a pattern table.
-- Handles: comment lines (#), header (x = N, y = N, rule = ...),
-- b (dead), o (alive), $ (newline), ! (end), run counts.
-- @param rle_string  the RLE-encoded pattern string
-- @return pattern table {name, width, height, cells} or nil on failure
function patterns.parseRLE(rle_string)
    if not rle_string or rle_string == "" then return nil end

    local name = "Imported"
    local width, height = 0, 0
    local data = ""
    local header_found = false

    for line in rle_string:gmatch("[^\r\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed:sub(1, 2) == "#N" then
            name = trimmed:sub(3):match("^%s*(.-)%s*$") or name
        elseif trimmed:sub(1, 1) == "#" then
            -- skip other comments
        elseif not header_found then
            local w, h = trimmed:match("x%s*=%s*(%d+).-y%s*=%s*(%d+)")
            if w and h then
                width = tonumber(w)
                height = tonumber(h)
                header_found = true
            else
                data = data .. trimmed
            end
        else
            data = data .. trimmed
        end
    end

    if width == 0 or height == 0 then
        if data == "" then return nil end
    end

    local cells = {}
    local x, y = 0, 0
    local run_count = 0

    for i = 1, #data do
        local ch = data:sub(i, i)
        if ch:match("%d") then
            run_count = run_count * 10 + tonumber(ch)
        elseif ch == "b" then
            local count = math.max(run_count, 1)
            x = x + count
            run_count = 0
        elseif ch == "o" then
            local count = math.max(run_count, 1)
            for j = 0, count - 1 do
                cells[#cells + 1] = { x + j, y }
            end
            x = x + count
            run_count = 0
        elseif ch == "$" then
            local count = math.max(run_count, 1)
            y = y + count
            x = 0
            run_count = 0
        elseif ch == "!" then
            break
        end
    end

    if width == 0 or height == 0 then
        local maxX, maxY = 0, 0
        for _, c in ipairs(cells) do
            if c[1] > maxX then maxX = c[1] end
            if c[2] > maxY then maxY = c[2] end
        end
        width = maxX + 1
        height = maxY + 1
    end

    return {
        name = name,
        category = "Imported",
        width = width,
        height = height,
        cells = cells,
    }
end

--- Serialize a grid region to an RLE string.
-- Finds the bounding box of live cells and encodes only that region.
-- @param cells  flat grid array (0/1 integers)
-- @param width  grid width
-- @param height grid height
-- @return string  complete RLE with header, or nil if grid is empty
function patterns.toRLE(cells, width, height)
    local minX, minY = width, height
    local maxX, maxY = -1, -1
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            if cells[y * width + x + 1] == 1 then
                if x < minX then minX = x end
                if x > maxX then maxX = x end
                if y < minY then minY = y end
                if y > maxY then maxY = y end
            end
        end
    end

    if maxX == -1 then
        return "x = 0, y = 0, rule = B3/S23\n!\n"
    end

    local patW = maxX - minX + 1
    local patH = maxY - minY + 1
    local result = "x = " .. patW .. ", y = " .. patH .. ", rule = B3/S23\n"
    local line = ""

    for row = minY, maxY do
        local lastAlive = minX - 1
        for x = maxX, minX, -1 do
            if cells[row * width + x + 1] == 1 then
                lastAlive = x
                break
            end
        end

        local run = 0
        local currentChar = nil
        local endX = math.max(lastAlive, minX)
        for x = minX, endX do
            local ch = cells[row * width + x + 1] == 1 and "o" or "b"
            if ch == currentChar then
                run = run + 1
            else
                if currentChar then
                    if run > 1 then line = line .. tostring(run) end
                    line = line .. currentChar
                end
                currentChar = ch
                run = 1
            end
        end
        if currentChar then
            if run > 1 then line = line .. tostring(run) end
            line = line .. currentChar
        end

        if row < maxY then
            line = line .. "$"
        else
            line = line .. "!"
        end
    end

    local wrapped = ""
    while #line > 70 do
        wrapped = wrapped .. line:sub(1, 70) .. "\n"
        line = line:sub(71)
    end
    wrapped = wrapped .. line .. "\n"

    return result .. wrapped
end

return patterns
