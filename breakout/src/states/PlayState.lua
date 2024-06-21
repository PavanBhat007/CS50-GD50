PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.level = params.level
    self.ball = params.ball
    self.recoverPoints = 5000
    self.ballCount = 1

    -- additional functionality to carry over keys from previous level
    self.keys = params.keys or 0
    
    self.powerups = {} -- table to maintain powerups
    self.balls = {
        self.ball
    }

    -- timer to drop powerups
    self.ballTimer = 0
    self.keyTimer = 0

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    for k, ball in pairs(self.balls) do
        ball:update(dt)

        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        for j, ball in pairs(self.balls) do

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                -- add to score
                if brick.locked and self.keys > 0 then
                    self.score = self.score + 1500 -- higher points if locked brick destroyed
                elseif brick.locked and self.keys == 0 then
                    ::continue::
                else
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)
                end

                -- trigger the brick's hit function, which removes it from play
                if brick.locked and self.keys == 0 then
                    ::continue:: -- if player hs no keys locked bricks wont be affected
                else
                    brick:hit()
                    if brick.locked then
                        self.keys = self.keys - 1
                    end
                end

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints + math.random(100, 500) then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    -- increase paddle size upon scoring enough points
                    -- but the paddle size annot go above 3
                    if self.paddle.size < 3 then
                        self.paddle.size = self.paddle.size + 1
                        self.paddle.width = self.paddle.width + 32
                    end
                    
                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.ball,
                        recoverPoints = self.recoverPoints,
                        keys = self.keys
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end

    for k, ball in pairs(self.balls) do
        -- if ball goes below bounds, revert to serve state and decrease health
        if ball.y >= VIRTUAL_HEIGHT then
            table.remove(self.balls, k)

            if next(self.balls) == nil then
                self.health = self.health - 1
                gSounds['hurt']:play()

                -- reset score to 1000 when heart lost else it will give player infinite hearts
                -- i.e., if score > 5000 and then player loses heart, it always gives
                -- extra heart because score > recovery points = 5000
                self.score = 1000

                -- reduce paddle size upon losing a heart
                -- but the paddle size mustr not go below 1
                if self.paddle.size > 1 then
                    self.paddle.size = self.paddle.size - 1
                    self.paddle.width = self.paddle.width - 32
                end

                if self.health <= 0 then
                    gStateMachine:change('game-over', {
                        score = self.score,
                        highScores = self.highScores
                    })
                else
                    gStateMachine:change('serve', {
                        paddle = self.paddle,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        recoverPoints = self.recoverPoints
                    })
                end
            end
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end
        
    -- spawning the ball powerup
    self.ballTimer = self.ballTimer + dt
    local ball_spawn = math.random(10, 30)
    if self.ballTimer > ball_spawn then
        table.insert(self.powerups, Powerup(9))
        -- reset timer
        self.ballTimer = 0
    end

    -- spawning the key powerup
    self.keyTimer = self.keyTimer + dt
    local key_spawn = math.random(20, 50)
    if self.keys < 3 and self.keyTimer > key_spawn then
        table.insert(self.powerups, Powerup(10))
        self.keyTimer = 0
    end

    -- do the update for the powerups
    for k, powerup in pairs(self.powerups) do
        powerup:update(dt)
        if powerup:collides(self.paddle) then
            if powerup:powerType() == "two_balls" then
                gSounds['paddle-hit']:play()
                gSounds['ball-powerup']:play()
                table.remove(self.powerups, k)
                table.insert(self.balls, Ball(math.random(7), self.paddle.x + (self.paddle.width / 2) - 4, 
                self.paddle.y - 8, math.random(-200, 200), math.random(-50, -60)))
                table.insert(self.balls, Ball(math.random(7), self.paddle.x + (self.paddle.width / 2) - 4, 
                self.paddle.y - 8, math.random(-200, 200), math.random(-50, -60)))

            elseif powerup:powerType() == "key" then
                gSounds['paddle-hit']:play()
                table.remove(self.powerups, k)
                if self.keys < 3 then
                    self.keys = self.keys + 1
                    gSounds['key-pickup']:play()
                end
            end
        end

        if powerup.y > VIRTUAL_HEIGHT + 16 then
            table.remove(self.powerups, k)
        end
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    -- render powerups
    for k, powerup in pairs(self.powerups) do
        powerup:render()
    end

    -- render extra balls if there are any
    for k, ball in pairs(self.balls) do
        ball:render()
    end

    self.paddle:render()

    renderScore(self.score)
    renderHealth(self.health)
    renderKeys(self.keys)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end