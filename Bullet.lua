
Bullet = Class{}

function Bullet:init(x,y)
    self.x = x
    self.y = y
    self.width = 2
    self.height = 2
    self.dx = 500
    self.dy = 0
end

function Bullet:collides(paddle)
    
    if self.x > paddle.x + paddle.width or paddle.x > self.x + self.width then
        return false
    end

    if self.y > paddle.y + paddle.height or paddle.y > self.y + self.height then
        return false
    end 

    return true
end

function Bullet:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
end

function Bullet:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end