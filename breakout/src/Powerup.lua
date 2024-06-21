Powerup = Class{}

function Powerup:init(skin)
    self.skin = skin

    self.dy = 50 -- constant velocity
    self.dx = 0

    self.height = 16
    self.width = 16

    self.x = math.random(0, VIRTUAL_WIDTH - 10)
    self.y = 0
end

function Powerup:update(dt)
    self.y = self.y + self.dy * dt
end

function Powerup:collides(paddle)
    if self.x > paddle.x + paddle.width or paddle.x > self.x + self.width then
        return false
    end

    if self.y > paddle.y + paddle.height or paddle.y > self.y + self.height then
        return false
    end 

    return true
end

function Powerup:render()
    love.graphics.draw(
        gTextures['main'], 
        gFrames['powerups'][self.skin], 
        self.x, self.y
    )
end


function Powerup:powerType()
    if self.skin == 9 then
        return "two_balls"
    elseif self.skin == 10 then
        return "key"
    end
end