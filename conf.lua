function love.conf(t)
  t.identity = "orihon"
  t.version = "11.5"
  t.console = false
  t.window.title = "Orihon — accordion manga reader"
  t.window.width = 1280
  t.window.height = 800
  t.window.minwidth = 960
  t.window.minheight = 640
  t.window.resizable = true
  t.modules.joystick = false
  t.modules.physics = false
  t.modules.audio = false
  t.modules.video = false
  t.modules.thread = true
end
