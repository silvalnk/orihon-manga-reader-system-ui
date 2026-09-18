local app = require("src.app")

function love.load()
  app.load()
end

function love.update(dt)
  app.update(dt)
end

function love.draw()
  app.draw()
end

function love.textinput(text)
  app.textinput(text)
end

function love.keypressed(key)
  app.keypressed(key)
end

function love.mousepressed(x, y, button)
  app.mousepressed(x, y, button)
end

function love.mousemoved(x, y)
  app.mousemoved(x, y)
end

function love.mousereleased(x, y, button)
  app.mousereleased(x, y, button)
end

function love.wheelmoved(_, y)
  app.wheelmoved(y)
end

function love.resize(w, h)
  app.resize(w, h)
end
