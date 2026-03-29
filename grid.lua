-- grid.lua
-- Pure simulation core for Conway's Game of Life.
-- Every function is pure: data in, new data out. No globals, no module state.
-- Grid is a flat 1D table of 0/1 integers, indexed as y * width + x + 1.

local grid = {}

--- Create a new grid filled with zeros.
-- @param width  number of columns
-- @param height number of rows
-- @return table  flat array of length width*height, all zeros
function grid.create(width, height)
    local cells = {}
    local n = width * height
    for i = 1, n do
        cells[i] = 0
    end
    return cells
end

--- Convert 0-based (x, y) to 1-based flat index.
function grid.index(x, y, width)
    return y * width + x + 1
end

--- Get cell value with toroidal wrapping.
-- x, y can be any integer (negative, >= width/height).
-- Lua's % returns non-negative for positive divisor, giving free wrapping.
function grid.get(cells, x, y, width, height)
    return cells[(y % height) * width + (x % width) + 1]
end

--- Return a NEW grid with cell (x,y) set to value.
-- Does not mutate the input grid.
function grid.set(cells, x, y, width, height, value)
    local new = {}
    local n = width * height
    for i = 1, n do
        new[i] = cells[i]
    end
    local idx = (y % height) * width + (x % width) + 1
    new[idx] = value
    return new
end

--- Toggle a single cell, return new grid.
function grid.toggle(cells, x, y, width, height)
    local new = {}
    local n = width * height
    for i = 1, n do
        new[i] = cells[i]
    end
    local idx = (y % height) * width + (x % width) + 1
    new[idx] = 1 - new[idx]
    return new
end

--- Count live neighbors of cell (x,y) using Moore neighborhood.
-- Cells store 0/1 integers so we sum directly — no conditionals.
function grid.countNeighbors(cells, x, y, width, height)
    return grid.get(cells, x-1, y-1, width, height)
         + grid.get(cells, x,   y-1, width, height)
         + grid.get(cells, x+1, y-1, width, height)
         + grid.get(cells, x-1, y,   width, height)
         + grid.get(cells, x+1, y,   width, height)
         + grid.get(cells, x-1, y+1, width, height)
         + grid.get(cells, x,   y+1, width, height)
         + grid.get(cells, x+1, y+1, width, height)
end

--- Advance the entire grid by one generation (B3/S23).
-- Inlined neighbor counting with modulo wrapping for performance.
-- @param cells    current grid (flat array)
-- @param width    grid width
-- @param height   grid height
-- @param birth    lookup table e.g. {[3]=true}
-- @param survival lookup table e.g. {[2]=true,[3]=true}
-- @param dest     optional pre-allocated destination buffer (ping-pong)
-- @return table   the next generation grid
function grid.step(cells, width, height, birth, survival, dest)
    dest = dest or {}
    for y = 0, height - 1 do
        local ym1 = ((y - 1) % height) * width
        local y0  = y * width
        local yp1 = ((y + 1) % height) * width
        for x = 0, width - 1 do
            local xm1 = (x - 1) % width
            local xp1 = (x + 1) % width
            -- Sum 8 Moore neighbors (cells are 0/1 integers)
            local n = cells[ym1 + xm1 + 1]
                    + cells[ym1 + x   + 1]
                    + cells[ym1 + xp1 + 1]
                    + cells[y0  + xm1 + 1]
                    + cells[y0  + xp1 + 1]
                    + cells[yp1 + xm1 + 1]
                    + cells[yp1 + x   + 1]
                    + cells[yp1 + xp1 + 1]
            local idx = y0 + x + 1
            if cells[idx] == 1 then
                dest[idx] = survival[n] and 1 or 0
            else
                dest[idx] = birth[n] and 1 or 0
            end
        end
    end
    return dest
end

--- Fill grid randomly with given density (0.0 to 1.0).
function grid.randomize(width, height, density)
    local cells = {}
    local n = width * height
    for i = 1, n do
        cells[i] = (math.random() < density) and 1 or 0
    end
    return cells
end

--- Return a cleared (all-zero) grid.
function grid.clear(width, height)
    return grid.create(width, height)
end

--- Place a pattern onto the grid at (ox, oy). Wraps toroidally.
-- pattern is a list of {dx, dy} offsets relative to (0,0).
-- Returns a new grid (does not mutate input).
function grid.placePattern(cells, width, height, pattern, ox, oy)
    local new = {}
    local n = width * height
    for i = 1, n do
        new[i] = cells[i]
    end
    for _, cell in ipairs(pattern) do
        local x = (ox + cell[1]) % width
        local y = (oy + cell[2]) % height
        new[y * width + x + 1] = 1
    end
    return new
end

--- Count total live cells.
function grid.population(cells, width, height)
    local count = 0
    local n = width * height
    for i = 1, n do
        count = count + cells[i]
    end
    return count
end

return grid
