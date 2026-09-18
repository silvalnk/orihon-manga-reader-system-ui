-- CAP-7: lock the numbers that keep the reader fluid.
-- Stubs LÖVE channels so src/jobs.lua can be tested with plain Lua.

return function(check)
  local function read(path)
    local f = assert(io.open(path, "r"))
    local src = f:read("*a")
    f:close()
    return src
  end

  local app_src = read("src/app.lua")
  local main_src = read("main.lua")
  local thread_src = read("src/download_thread.lua")
  local jobs_src = read("src/jobs.lua")
  local conf_src = read("conf.lua")

  check("app has no curl", app_src:find("curl", 1, true) == nil)
  check("main has no curl", main_src:find("curl", 1, true) == nil)
  check("app has no popen", app_src:find("io.popen", 1, true) == nil)
  check("app has no os.execute", app_src:find("os.execute", 1, true) == nil)
  check("app has no http.get", app_src:find("http.get", 1, true) == nil)
  check("app has no sync search", app_src:find("mangadex.search(", 1, true) == nil)
  check("app has no sync feed", app_src:find("mangadex.feed(", 1, true) == nil)
  check("app has no sync at-home", app_src:find("mangadex.at_home(", 1, true) == nil)
  check("app uses search_url", app_src:find("mangadex.search_url", 1, true) ~= nil)
  check("app uses feed_url", app_src:find("mangadex.feed_url", 1, true) ~= nil)
  check("app uses at_home_url", app_src:find("mangadex.at_home_url", 1, true) ~= nil)
  check("app queues text jobs", app_src:find("jobs.text", 1, true) ~= nil)
  check("app queues file jobs", app_src:find("jobs.file", 1, true) ~= nil)
  check("app prefetches pages", app_src:find("prefetch_pages", 1, true) ~= nil)
  check("app uses prefetch_range", app_src:find("layout.prefetch_range", 1, true) ~= nil)
  check("app drains budget constant", app_src:find("drain_image_loads(layout.images_per_frame)", 1, true) ~= nil)
  check("threads module stays on", conf_src:find("t.modules.thread = true", 1, true) ~= nil)

  local draw_at = app_src:find("function app.draw", 1, true)
  local text_at = app_src:find("function app.textinput", 1, true)
  local draw_fn = draw_at and text_at and app_src:sub(draw_at, text_at - 1)
  check("draw does not poll jobs", draw_fn and draw_fn:find("jobs.poll", 1, true) == nil)
  check("draw does not start json jobs", draw_fn and draw_fn:find("jobs.text", 1, true) == nil)

  check("worker runs curl", thread_src:find("curl", 1, true) ~= nil)
  check("ui queue pops never demands", jobs_src:find(":demand", 1, true) == nil and jobs_src:find(":pop", 1, true) ~= nil)
  check("jobs starts download_thread", jobs_src:find("src/download_thread.lua", 1, true) ~= nil)

  local layout = require("src.layout")
  check("prefetch spread locked", layout.prefetch_ahead.spread == 5)
  check("prefetch single locked", layout.prefetch_ahead.single == 3)
  check("images per frame locked", layout.images_per_frame == 3)
  local from, to = layout.prefetch_range(10, 20, false)
  check("prefetch from current page", from == 10 and to == 15)
  from, to = layout.prefetch_range(1, 0, false)
  check("prefetch empty chapter", from == 1 and to == 0)
  from, to = layout.prefetch_range(1, 20, true)
  check("prefetch single window", from == 1 and to == 4)

  local channels = {}
  local function chan()
    local q = {}
    return {
      push = function(_, v)
        q[#q + 1] = v
      end,
      pop = function()
        if not q[1] then
          return nil
        end
        return table.remove(q, 1)
      end,
    }
  end
  _G.love = {
    thread = {
      getChannel = function(name)
        if not channels[name] then
          channels[name] = chan()
        end
        return channels[name]
      end,
      newThread = function(path)
        return {
          path = path,
          started = false,
          start = function(self)
            self.started = true
          end,
          getError = function()
            return nil
          end,
        }
      end,
    },
  }
  package.loaded["src.jobs"] = nil
  local jobs = require("src.jobs")
  jobs.start("Orihon/0.1")
  check("jobs worker count locked", jobs.N == 3 and #jobs.threads == 3)
  check("jobs threads started", jobs.threads[1].started and jobs.threads[1].path == "src/download_thread.lua")

  local t0 = os.clock()
  local empty = jobs.poll()
  local elapsed = os.clock() - t0
  check("empty poll is nonblocking", #empty == 0 and elapsed < 0.05)

  t0 = os.clock()
  check("jobs file enqueues", jobs.file("cover1", "https://example.com/a.jpg", "/tmp/a.img") == true)
  check("enqueue is nonblocking", (os.clock() - t0) < 0.05)
  check("jobs file skips duplicate", jobs.file("cover1", "https://example.com/a.jpg", "/tmp/a.img") == false)
  check("jobs file pending", jobs.pending("cover1") == true)
  check("jobs file needs dest", jobs.file("x", "https://example.com/a.jpg", nil) == false)
  check("jobs text needs url", jobs.text("search:1", nil) == false)

  jobs.out_ch:push({ key = "cover1", kind = "file", ok = true })
  local msgs = jobs.poll()
  check("jobs poll delivers", #msgs == 1 and msgs[1].key == "cover1")
  check("jobs pending cleared", jobs.pending("cover1") == false)
  check("jobs can enqueue after poll", jobs.file("cover1", "https://example.com/a.jpg", "/tmp/a.img") == true)
end
