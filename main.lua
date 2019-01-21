local LSystem = require('lsystem')

function love.load()
    love.window.setMode(1280, 720)
    current = 7
    lsystem = LSystem.loadPreset(3)
    timer = 0
    clickState = 'ready'
end

function love.update(dt)
    if love.keyboard.isDown('space') then
        lsystem:update()
        local imageData = lsystem.canvas:newImageData()
        imageData:encode('png', string.format('tree%d_%d.png', 3, lsystem.step))
    elseif love.keyboard.isDown('backspace') then
        lsystem:reset()
    elseif love.keyboard.isDown('1') then
        lsystem = LSystem.loadPreset(1)
    elseif love.keyboard.isDown('2') then
        lsystem = LSystem.loadPreset(2)
    elseif love.keyboard.isDown('3') then
        lsystem = LSystem.loadPreset(3)
    elseif love.keyboard.isDown('4') then
        lsystem = LSystem.loadPreset(4)
    elseif love.keyboard.isDown('5') then
        lsystem = LSystem.loadPreset(5)
    elseif love.keyboard.isDown('6') then
        lsystem = LSystem.loadPreset(6)
    elseif love.keyboard.isDown('7') then
        lsystem = LSystem.loadPreset(7)
    elseif love.keyboard.isDown('8') then
        lsystem = LSystem.loadPreset(8)
    elseif love.keyboard.isDown('9') then
        lsystem = LSystem.loadPreset(9)
    end
    if clickState == 'clicked' then
        prevMx = mx
        mx = love.mouse.getX()
        if mx and love.mouse.isDown('l') then
            local diff = mx - prevMx
            if diff > 0 then
                lsystem[LSystem.fields[clicked]] = lsystem[LSystem.fields[clicked]] * 1.1
            elseif diff < 0 then
                lsystem[LSystem.fields[clicked]] = lsystem[LSystem.fields[clicked]] * 0.9
            end
        else
            clickState = 'ready'
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 'l' and x <= 110 and y >= 30 and y <= 270 then
        if clickState == 'ready' then
            clicked = math.floor((y - 30) / 20) + 1
            prevMx = x
            clickState = 'clicked'
        end
        mx = x
        my = y
    elseif button == 'r' and lsystem.str then
        love.system.setClipboardText(lsystem.str)
    end
end

function love.mousereleased(x, y, button)
    if button == "1" then
        mx = nil
        my = nil
        clicked = nil
        clickState = 'ready'
    end
end

function slideshowUpdate(dt)
    timer = timer + dt
    if timer > 0.41379 * 2 then
        if lsystem.step > 15 then
            current = current + 1
            if current > #LSystem.systems then
                love.event.quit()
            else
                lsystem = LSystem.load(unpack(LSystem.systems[current]))
            end
        end
        lsystem:update()
        timer = 0
    end
end

function love.draw()
    love.graphics.setBackgroundColor(255, 255, 255)
    love.graphics.push()
    lsystem:draw()
    love.graphics.pop()
    lsystem:drawGui()
end
