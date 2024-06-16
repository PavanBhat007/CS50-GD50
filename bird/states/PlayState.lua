PlayState = Class{__includes = BaseState}

PIPE_SPEED = 60
PIPE_WIDTH = 70
PIPE_HEIGHT = 288

BIRD_WIDTH = 38
BIRD_HEIGHT = 24

random_interval = 2

function PlayState:init()
    self.bird = Bird()
    self.pipePairs = {}
    self.timer = 0
    self.score = 0
    self.lastY = -PIPE_HEIGHT + math.random(80) + 20
end

function PlayState:update(dt)
    -- Puase feature: transition to pause state when 'p' or 'P' pressed
    if love.keyboard.wasPressed('p') or 
       love.keyboard.wasPressed('P') then
        sounds['pause']:play()
        sounds['music']:pause()
        
        gStateMachine:change('pause', { 
            bird = self.bird,
            pipePairs = self.pipePairs,
            score = self.score,
            timer = self.timer,
            lastY = self.lastY
        })
        return
    end

    self.timer = self.timer + dt
    -- randomizing interval between pipes
    random_interval = math.ceil(math.random(10))
    
    if self.timer > random_interval then 
        local y = math.max(-PIPE_HEIGHT + 10, 
            math.min(
                self.lastY + math.random(-20, 20), 
                VIRTUAL_HEIGHT - math.random(50, 90) - PIPE_HEIGHT
            ))
        self.lastY = y

        table.insert(self.pipePairs, PipePair(y))
        self.timer = 0
    end

    for k, pair in pairs(self.pipePairs) do
        if not pair.scored then
            if pair.x + PIPE_WIDTH < self.bird.x then
                self.score = self.score + 1
                pair.scored = true
                sounds['score']:play()
            end
        end

        pair:update(dt)
    end

    for k, pair in pairs(self.pipePairs) do
        if pair.remove then
            table.remove(self.pipePairs, k)
        end
    end

    for k, pair in pairs(self.pipePairs) do
        for l, pipe in pairs(pair.pipes) do
            if self.bird:collides(pipe) then
                sounds['explosion']:play()
                sounds['hurt']:play()

                gStateMachine:change('score', {
                    score = self.score
                })
            end
        end
    end

    self.bird:update(dt)

    if self.bird.y > VIRTUAL_HEIGHT - 15 then
        sounds['explosion']:play()
        sounds['hurt']:play()

        gStateMachine:change('score', {
            score = self.score
        })
    end
end

function PlayState:render()
    for k, pair in pairs(self.pipePairs) do
        pair:render()
    end

    love.graphics.setFont(smallFont)
    love.graphics.print(tostring(random_interval), VIRTUAL_WIDTH-10, 10)

    love.graphics.setFont(flappyFont)
    love.graphics.print('Score: ' .. tostring(self.score), 8, 8)

    self.bird:render()
end

function PlayState:enter(params)
    if params then
        self.bird = params.bird or Bird()
        self.pipePairs = params.pipePairs or {}
        self.score = params.score or 0
        self.timer = params.timer or 0
        self.lastY = params.lastY or math.random(50, 90)
    else
        self.bird = Bird()
        self.pipePairs = {}
        self.timer = 0
        self.score = 0
        self.lastY = -PIPE_HEIGHT + math.random(80) + 20
    end
    scrolling = true
end


function PlayState:exit()
    scrolling = false
end