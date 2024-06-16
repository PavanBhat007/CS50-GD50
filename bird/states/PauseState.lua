PauseState = Class{__includes = BaseState}

function PauseState:init()
    -- nothing to initialize
end

function PauseState:enter(params)
    self.bird = params.bird
    self.pipePairs = params.pipePairs
    self.score = params.score
    self.timer = params.timer
    self.lastY = params.lastY
end

function PauseState:update(dt)
    if love.keyboard.wasPressed('p') or 
       love.keyboard.wasPressed('P') then
        sounds['pause']:play()
        sounds['music']:play()
        gStateMachine:change('play', { 
            bird = self.bird,
            pipePairs = self.pipePairs,
            score = self.score,
            timer = self.timer,
            lastY = self.lastY
        })
    end
end

function PauseState:render()
    love.graphics.setFont(hugeFont)
    love.graphics.printf('II', 0, 120, VIRTUAL_WIDTH, 'center')
    love.graphics.setFont(mediumFont)
    love.graphics.printf('Score: ' .. tostring(self.score), 0, 180, VIRTUAL_WIDTH, 'center')
    love.graphics.setFont(mediumFont)
    love.graphics.printf('Press P to Resume', 0, 200, VIRTUAL_WIDTH, 'center')
end
