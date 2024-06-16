ScoreState = Class{__includes = BaseState}


function ScoreState:enter(params)
    self.score = params.score
end

function ScoreState:update(dt)
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gStateMachine:change('countdown')
    end
end

function ScoreState:render()
    love.graphics.setFont(flappyFont)
    love.graphics.printf('Oof! You lost!', 0, 50, VIRTUAL_WIDTH, 'center')

    -- Trophy or medal feature: trephy awarded based on score
    love.graphics.setFont(mediumFont)
    if self.score > 50 then
        love.graphics.draw(trophies['gold'], VIRTUAL_WIDTH/2 - 20, 80)
    elseif self.score > 20 and self.score < 50 then
        love.graphics.draw(trophies['silver'], VIRTUAL_WIDTH/2 - 20, 80)
    elseif self.score >= 1 and self.score < 20 then
        love.graphics.draw(trophies['bronze'], VIRTUAL_WIDTH/2 - 20, 80)
    else
        love.graphics.printf("No trophy awarded :(", 0, 80, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf("Cross at-least 1 pipe to get a trophy", 0, 100, VIRTUAL_WIDTH, 'center')
    end
    
    love.graphics.setFont(mediumFont)
    love.graphics.printf('Score: ' .. tostring(self.score), 0, 120, VIRTUAL_WIDTH, 'center')

    love.graphics.printf('Press Enter to Play Again!', 0, 160, VIRTUAL_WIDTH, 'center')
end