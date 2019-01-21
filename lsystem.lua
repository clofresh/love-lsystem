local Matrix
pcall(function()
    Matrix = require('matrix')
end)
if not Matrix then
    print('No matrix.so found, falling back to lua')
    Matrix = {
        mult = function(h, l, u, rot)
            local h1, h2, h3,
                  l1, l2, l3,
                  u1, u2, u3 = h[1], h[2], h[3],
                               l[1], l[2], l[3],
                               u[1], u[2], u[3]
            local r11, r12, r13,
                  r21, r22, r23,
                  r31, r32, r33 = rot[1], rot[2], rot[3],
                                  rot[4], rot[5], rot[6],
                                  rot[7], rot[8], rot[9]
            h[1] = h1 * r11 + l1 * r21 + u1 * r31
            h[2] = h2 * r11 + l2 * r21 + u2 * r31
            h[3] = h3 * r11 + l3 * r21 + u3 * r31
            l[1] = h1 * r12 + l1 * r22 + u1 * r32
            l[2] = h2 * r12 + l2 * r22 + u2 * r32
            l[3] = h3 * r12 + l3 * r22 + u3 * r32
            u[1] = h1 * r13 + l1 * r23 + u1 * r33
            u[2] = h2 * r13 + l2 * r23 + u2 * r33
            u[3] = h3 * r13 + l3 * r23 + u3 * r33
        end
    }
end

local module = {
    fields = {'r1', 'r2', 'alpha1', 'alpha2', 'phi1', 'phi2', 's0', 'omega0', 'q', 'e', 'min'},
    systems = {
        {.75, .77, 35, -35, 0, 0, 180, 30, .50, .40, 0.0, 10},
        {.65, .71, 27, -68, 0, 0, 180, 20, .53, .50, 1.7, 12},
        -- {.50, .85, 25, -15, 180, 0, 180, 20, .45, .50, 0.5, 9},
        {.60, .85, 25, -15, 180, 180, 180, 20, .45, .50, 0.0, 10},
        {.58, .83, 30, 15, 0, 180, 180, 20, .40, .50, 1.0, 11},
        -- {.92, .37, 0, 60, 180, 0, 180, 2, .50, .00, 0.5, 15},
        {.80, .80, 30, -30, 137, 137, 180, 30, .50, .50, 0.0, 10},
        {.95, .75, 5, -30, -90, 90, 180, 40, .60, .45, 25.0, 12},
        {.55, .95, -5, 30, 137, 137, 180, 5, .40, .00, 5.0, 12},
    },
}

function module.load(r1, r2, alpha1, alpha2, phi1, phi2, s0, omega0, q, e, min)
    local self = {
        r1 = r1,
        r2 = r2,
        alpha1 = alpha1,
        alpha2 = alpha2,
        phi1 = phi1,
        phi2 = phi2,
        omega0 = omega0,
        q = q,
        e = e,
        min = min,
        s0 = s0,
        omega0 = omega0,
    }
    setmetatable(self, {
        __index = function(obj, key)
            return module[key]
        end
    })
    self:reset()

    return self
end

function module.loadPreset(num, pos, step)
    local self = module.load(unpack(module.systems[num]))
    self.pos = pos or {0, 0, 0}
    if step then
        for i = 1, step do
            self:update()
        end
    end
    return self
end

function module:reset()
    self.step = 0
    self.state = {
        {
            type = 'apex',
            s = self.s0,
            omega = self.omega0,
        }
    }
    self.turtle = {
        position = {0, 0, 0},
        heading = {0, 0, -1},
        left = {-1, 0, 0},
        up = {0, 1, 0},
        lineWidth = 0,
    }
    self.canvas = love.graphics.newCanvas(1280, 720)
end

function module:update()
    local newState = {}
    for i, symbol in pairs(self.state) do
        if symbol.type == 'apex' then
            if symbol.s >= self.min then
                local s, omega = symbol.s, symbol.omega

                -- !(w)
                table.insert(newState, {
                    type = 'setLineWidth',
                    val = omega
                })
                -- F(s)
                table.insert(newState, {
                    type = 'forward',
                    val = s
                })
                -- [
                table.insert(newState, {type = 'pushState'})

                -- +(alpha1)
                table.insert(newState, {
                    type = 'turn',
                    val = math.rad(self.alpha1)
                })

                -- /(phi1)
                table.insert(newState, {
                    type = 'roll',
                    val = math.rad(self.phi1)
                })

                -- A(s * r1, omega * q^e)
                table.insert(newState, {
                    type = 'apex',
                    s = s * self.r1,
                    omega = omega * math.pow(self.q, self.e)
                })

                -- ]
                table.insert(newState, {type = 'popState'})

                -- [
                table.insert(newState, {type = 'pushState'})
                -- +(alpha2)
                table.insert(newState, {
                    type = 'turn',
                    val = math.rad(self.alpha2)
                })
                -- /(phi2)
                table.insert(newState, {
                    type = 'roll',
                    val = math.rad(self.phi2)
                })
                -- A(s * r2, omega * (1 - q)^e)
                table.insert(newState, {
                    type = 'apex',
                    s = s * self.r2,
                    omega = omega * math.pow(1 - self.q, self.e)
                })
                -- ]
                table.insert(newState, {type = 'popState'})
            end
        else
            table.insert(newState, symbol)
        end
    end
    self.state = newState
    self.step = self.step + 1


    self.canvas:renderTo(function()
        love.graphics.translate(640, 720)
        love.graphics.setColor(0, 0, 0)
        local x, y, z = unpack(self.pos)
        local scale = 0.5
        local segments = self:getSegments(scale)
        for i, line in pairs(segments) do
            local l1, l2, width = unpack(line)
            local x1, y1, z1 = unpack(l1)
            local x2, y2, z2 = unpack(l2)
            love.graphics.setLineWidth(width * scale)
            love.graphics.line(x + x1, y + y1 + z + z1, x + x2, y + y2 + z + z2)
        end
    end)

    return newState
end

function module:drawGui()
    love.graphics.push()
    love.graphics.setColor(0, 0, 0)
    if mx and my then
        love.graphics.print(string.format('(%d, %d)', mx, my), 10, 10)
    end
    for i, field in pairs(module.fields) do
        local x
        love.graphics.print(string.format('%s: %.2f', field, self[field]), 10, 10 + (i * 20))
    end
    love.graphics.print(string.format('step: %d', self.step), 10, 10 + (#module.fields + 1) * 20)
    love.graphics.pop()
end

function module:draw()
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.canvas)
end

local parser = {}

function parser.new(turtle, scale, segments, stack)
    local t = {
        lineWidth = nil,
        position = {},
        heading = {},
        left = {},
        up = {},
    }
    for i = 1, #turtle.position do
        t.position[i] = turtle.position[i]
        t.heading[i] = turtle.heading[i]
        t.left[i] = turtle.left[i]
        t.up[i] = turtle.up[i]
    end

    local self = {
        turtle = t,
        segments = segments or {},
        stack = stack or {},
        scale = scale or 1,
    }
    local meta = {
        __index = function(obj, key)
            return parser[key]
        end
    }
    setmetatable(self, meta)
    return self
end

function parser:setLineWidth(symbol)
    -- str = string.format('%s!(%s)', str, symbol.val)
    self.turtle.lineWidth = symbol.val
end

function parser:forward(symbol)
    -- str = string.format('%sF(%s)', str, symbol.val)
    local turtle = self.turtle
    local p = turtle.position
    local val = symbol.val
    local scale = self.scale
    local x1, y1, z1 = p[1], p[2], p[3]
    for i, h in pairs(turtle.heading) do
        p[i] = p[i] + val * h * scale
    end
    local x2, y2, z2 = p[1], p[2], p[3]
    table.insert(self.segments, {{x1, y1, z1}, {x2, y2, z2}, turtle.lineWidth})
end

function parser:pushState(symbol)
    -- str = str .. '['
    local turtle = self.turtle
    local saved = {
        lineWidth = turtle.lineWidth,
        position = {},
        heading = {},
        left = {},
        up = {},
    }
    for i = 1, #turtle.position do
        saved.position[i] = turtle.position[i]
        saved.heading[i] = turtle.heading[i]
        saved.left[i] = turtle.left[i]
        saved.up[i] = turtle.up[i]
    end
    table.insert(self.stack, saved)
end

function parser:popState(symbol)
    -- str = str .. ']'
    self.turtle = table.remove(self.stack)
end

function parser:turn(symbol)
    -- str = string.format('%s+(%s)', str, symbol.val)
    local turtle = self.turtle
    local angle = symbol.val
    local c = math.cos(angle)
    local s = math.sin(angle)

    -- Rotate around the up axis
    Matrix.mult(turtle.heading, turtle.left, turtle.up, {c, s, 0,
                                                        -s, c, 0,
                                                         0, 0, 1})
end

function parser:roll(symbol)
    -- str = string.format('%s/(%s)', str, symbol.val)
    local turtle = self.turtle
    local angle = symbol.val
    local c = math.cos(angle)
    local s = math.sin(angle)

    -- Rotate around the heading axis
    Matrix.mult(turtle.heading, turtle.left, turtle.up, {1, 0, 0,
                                                         0, c, -s,
                                                         0, s, c})
end

-- function parser:apex(symbol)
    -- str = string.format('%sA(%s, %s)', str, symbol.s, symbol.omega)
-- end

function parser:parse(state)
    for i, symbol in pairs(state) do
        local func = self[symbol.type]
        if func then
            func(self, symbol)
        end
    end
    return self.segments
end

function module:getSegments(scale)
    return parser.new(self.turtle, scale):parse(self.state)
end

return module
