--Adapted from CS50x's code for the game Pong https://cs50.harvard.edu/x/2020/tracks/games/pong/
push = require 'push'

Class = require 'class'

require 'Paddle'

require 'Ball'

require 'Bullet'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

function love.load()
    
    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.window.setTitle('Pong')

    math.randomseed(os.time())

    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    giantFont = love.graphics.newFont('font.ttf', 48)
    love.graphics.setFont(smallFont)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static'),
        ['accelerate'] = love.audio.newSource('sounds/accelerate.wav', 'static'),
        ['shoot'] = love.audio.newSource('sounds/shoot.wav', 'static'),
        ['dmg'] = love.audio.newSource('sounds/dmg.wav', 'static'),
        ['song'] = love.audio.newSource('sounds/sound.wav', 'static')
    }

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    player1Score = 0
    player2Score = 0

    p1Health = 3
    p2Health = 10

    frames = 0
    starts = 0

    ballSpeed = 200
    multiplier = 1.03

    servingPlayer = 1

    player1 = Paddle(5, 30, 5, 30)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 50, 5, 30)
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    obstacles = {}

    bullets = {}

    ebullets = {}

    gameState = 'start'
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.update(dt)

    frames = frames + 1

    if gameState == 'serve' then
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = ballSpeed
        end
    elseif gameState == 'play' then
        
        if player1Score == 2 then
            if frames %  75 == 0 then
                fireBall(ebullets,VIRTUAL_WIDTH,player1.y + math.random(-75,75),15,15,-400,0)
            end
        end

        if player1Score == 3 then
            if frames %  180 == 0 then
                spawnObstacle()
            end
        end

        if ball:collides(player1) then
            ball.dx = -ball.dx * multiplier
            ball.x = player1.x + 5

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * multiplier
            ball.x = player2.x - 4

            if player1Score == 1 then
                fireBall(ebullets,player2.x,player2.y,player2.height,player2.height,-700,0)
            end

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end

        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end
 
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            p2Health = 10
            if player1Score == 4 then
                p2Health = 15
            end
            sounds['score']:play()
            p1Health = p1Health - 1

            if player1Score == 4 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
                for i=1, #bullets do
                    bullets[i] = nil
                end
                for i=1, #ebullets do
                    ebullets[i] = nil
                end
                for i=1, #obstacles do
                    obstacles[i] = nil
                end
            end
        end

        if ball.x > VIRTUAL_WIDTH or p2Health < 1 then
            servingPlayer = 1
            player1Score = player1Score + 1
            p2Health = 10
            if player1Score == 4 then
                p2Health = 15
            end
            sounds['score']:play()

            if player1Score == 4 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
                for i=1, #bullets do
                    bullets[i] = nil
                end
                for i=1, #ebullets do
                    ebullets[i] = nil
                end
                for i=1, #obstacles do
                    obstacles[i] = nil
                end
            end
        end
    end

    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    if p2Health > 0 then
        if math.floor(ball.y + (player2.x - ball.x)*(ball.dy/ball.dx)) > player2.y + 10 then
            player2.dy = PADDLE_SPEED
        elseif math.floor(ball.y + (player2.x - ball.x)*(ball.dy/ball.dx)) < player2.y + 10 then
            player2.dy = -PADDLE_SPEED
        else
            player2.dy = 0
        end
    else
        player2.dy = 0
    end

    for k, obstacle in pairs(obstacles) do
        if obstacle.y > obstacle.y1+50 or obstacle.y < obstacle.y1-50 then
            obstacle.dy = -obstacle.dy
        end
    end

    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)

    for k, v in pairs(bullets) do
        v:update(dt)
    end

    for k, v in pairs(ebullets) do
        v:update(dt)
    end

    for k, v in pairs(obstacles) do
        v:update(dt)
    end

    for k, obstacle in pairs(obstacles) do
        if ball:collides(obstacle) then
            if ball.dx > 0 then
                ball.dx = -ball.dx * 1.1
                ball.dy = 0
            else
                ball.dx = ball.dx * 1.1
                ball.dy = 0
            end

            ball.x = obstacle.x - 4

            sounds['accelerate']:play()
        end
    end

    for k, v in pairs(bullets) do
        if v:collides(player2) then
            bullets[k] = nil
            p2Health = p2Health - 1
            sounds['dmg']:play()
        end
        for x, y in pairs(obstacles) do
            if v:collides(y) then
                bullets[k] = nil
                obstacles[x] = nil
                sounds['dmg']:play()
            end
        end
    end

    for k, v in pairs(ebullets) do
        if v:collides(player1) then
            ebullets[k] = nil
            p1Health = p1Health - 1
            sounds['dmg']:play()
        end
    end

    if p1Health < 1 then
        gameState = 'death'
    end
end

function love.keypressed(key)
    music = false

    if key == 'x' then
        gameState = 'start'
    end
    --Code for music toggle from: https://github.com/khanna-aditya/CS-50-Assignments/blob/master/A0:%20Pong/main.lua
    if key == 'm' then
        if music == false then
            sounds['song']:setLooping(true)
            sounds['song']:play()
            music = true
        elseif music == true then
            sounds['song']:setLooping(false)
            love.audio.stop(sounds['song'])
            music = false
        end
    end

    if gameState == 'play' then
        if key == 'space' then
            if frames - starts > 35 then
            fireRound(bullets,player1.x + player1.width,player1.y + player1.height/2 - 1,750)
            starts = frames
            end
        end
    end

    if key == 'escape' then
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            gameState = 'serve'

            ball:reset()

            player1Score = 0
            player2Score = 0
        elseif gameState == 'death' then
            p1Health = 3
            p2Health = 10
            player1Score = 0
            player2Score = 0
            gameState = 'serve'

            ball:reset()
        end
    end
end

function love.draw()

    push:apply('start')

    love.graphics.clear(107/255, 235/255, 255/255, 255/255)
    if player1Score == 3 then
        love.graphics.clear(0, 0, 0, 1)
    end
    if gameState == 'menu-pong' then
        love.graphics.clear(221/255,221/255,221/255,255/255)
        love.graphics.setFont(largeFont)
        love.graphics.printf('Welcome to Pong!', 0, 80, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press m to toggle music :D', 0, 220, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('hit x to start',0, 125,VIRTUAL_WIDTH,'center')
    elseif gameState == 'start' then
        love.graphics.setColor(0.4,0,1,1)
        love.graphics.setFont(giantFont)
        love.graphics.printf('ACTION PONG', 0, VIRTUAL_HEIGHT/2-30, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(0,0,0,1)
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to Start!', 0, VIRTUAL_HEIGHT/2+15, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('m to toggle music', 0, 220, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setColor(0,0,1,1)
        displayScore()
        displayHealth()

        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to serve!', 0, VIRTUAL_HEIGHT-20, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(0,0,1,1)
        player1:render()

        love.graphics.setColor(1,0,0,1)
        player2:render()

        love.graphics.setColor(0.5,0,1,1)
        ball:render()

        for k, v in pairs(bullets) do
            v:render()
        end

        for k, v in pairs(ebullets) do
            v:render()
        end
    elseif gameState == 'play' then
        love.graphics.setColor(0,0,1,1)
        displayScore()
        displayHealth()

        love.graphics.setColor(0,0,1,1)
        player1:render()

        love.graphics.setColor(1,0,0,1)
        player2:render()

        love.graphics.setColor(0.5,0,1,1)
        ball:render()

        for k, v in pairs(bullets) do
            v:render()
        end

        for k, v in pairs(ebullets) do
            love.graphics.setColor(1,0,0,1)
            v:render()
        end

        for k, v in pairs(obstacles) do
            love.graphics.setColor(1,85/255,0,1)
            v:render()
        end

    elseif gameState == 'done' then
        love.graphics.setColor(1,1,0,1)
        love.graphics.setFont(scoreFont)
        love.graphics.printf('YOU WON', 0, VIRTUAL_HEIGHT/2-30, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to play again!', 0, VIRTUAL_HEIGHT/2 + 10, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'death' then
        love.graphics.clear(0, 0, 0, 1)
        love.graphics.setColor(1,0,0,1)
        love.graphics.setFont(scoreFont)
        love.graphics.printf('YOU DIED', 0, VIRTUAL_HEIGHT/2-30, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, VIRTUAL_HEIGHT/2 + 10, VIRTUAL_WIDTH, 'center')
    end

    push:apply('end')
end

function displayScore()
    love.graphics.setFont(scoreFont)
    love.graphics.setColor(0,0,0,1)
    if player1Score == 3 then
        love.graphics.setColor(1,0,0,1)
    end
    love.graphics.printf("Stage " .. tostring(player1Score+1), 0, 5, VIRTUAL_WIDTH, 'center')
end

function displayHealth()
    love.graphics.setFont(scoreFont)
    love.graphics.setColor(0,0,1,1)
    love.graphics.print(tostring(p1Health), 30, VIRTUAL_HEIGHT - 35)
    love.graphics.setFont(smallFont)
    love.graphics.print('Lives', 30, VIRTUAL_HEIGHT - 40)
    love.graphics.setFont(scoreFont)
    love.graphics.setColor(1,0,0,1)
    love.graphics.print(tostring(p2Health), VIRTUAL_WIDTH -60, VIRTUAL_HEIGHT -35)
    love.graphics.setFont(smallFont)
    love.graphics.print('Enemy', VIRTUAL_WIDTH -60, VIRTUAL_HEIGHT - 40)
end

function spawnObstacle()
    local obstacle = Paddle()
    obstacle.width = 5
    obstacle.height = 50 
    obstacle.x = math.random(VIRTUAL_WIDTH/2,VIRTUAL_WIDTH-obstacle.width-10)
    obstacle.y = math.random(50,VIRTUAL_HEIGHT-obstacle.height-50)
    obstacle.y1 = obstacle.y
    obstacle.dy = 100

    table.insert(obstacles, obstacle)
end

function fireRound(t,px,py,pdx)
    local bullet = Bullet()
    bullet.x = px
    bullet.y = py
    bullet.dx = pdx

    table.insert(t, bullet)
    sounds['shoot']:play()
end

function fireBall(t,px,py,pw,ph,pdx,pdy)
    local bullet = Bullet()
    bullet.x = px
    bullet.y = py
    bullet.width = pw
    bullet.height = ph
    bullet.dx = pdx
    bullet.dy = pdy

    table.insert(t, bullet)
    sounds['shoot']:play()
end