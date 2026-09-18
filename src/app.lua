local http = require("src.http")
local mangadex = require("src.mangadex")
local persist = require("src.persist")
local layout = require("src.layout")
local jobs = require("src.jobs")

local app = {
  screen = "shelf",
  query = "",
  search_focus = true,
  results = {},
  favorites = {},
  progress = {},
  selected = nil,
  chapters = {},
  chapter = nil,
  pages = {},
  page_index = 1,
  single = false,
  status = "Unfold a title. Type and press Enter.",
  waiting = nil,
  scroll = 0,
  result_scroll = 0,
  chapter_scroll = 0,
  cover_cache = {},
  cover_fail = {},
  load_queued = {},
  pending_load = {},
  token = { search = 0, feed = 0, athome = 0 },
  catalog_total = 0,
  has_more = true,
  save_in = 0,
  scroll_drag = nil,
  w = 1280,
  h = 800,
}

local function rgb(c, a)
  love.graphics.setColor(c[1], c[2], c[3], a or c[4] or 1)
end

local function round_rect(x, y, w, h, r)
  love.graphics.rectangle("fill", x, y, w, h, r or 6, r or 6)
end

local function cache_name(key)
  return "cache/" .. key:gsub("[^%w%-_]", "_") .. ".img"
end

local function bump(kind)
  app.token[kind] = (app.token[kind] or 0) + 1
  return kind .. ":" .. app.token[kind]
end

local function token_of(key)
  local kind, n = key:match("^(%a+):(%d+)$")
  return kind, tonumber(n)
end

local function queue_image_load(key, name)
  if app.cover_cache[key] or app.cover_fail[key] or app.load_queued[key] then
    return
  end
  app.load_queued[key] = true
  app.pending_load[#app.pending_load + 1] = { key = key, name = name }
end

local function request_image(key, url)
  if not url or app.cover_cache[key] or app.cover_fail[key] then
    return
  end
  local name = cache_name(key)
  if love.filesystem.getInfo(name) then
    queue_image_load(key, name)
    return
  end
  local dest = love.filesystem.getSaveDirectory() .. "/" .. name
  jobs.file(key, url, dest)
end

local function drop_page_images()
  for key, img in pairs(app.cover_cache) do
    if type(key) == "string" and key:sub(1, 1) == "p" then
      if img.release then
        img:release()
      end
      app.cover_cache[key] = nil
      app.load_queued[key] = nil
    end
  end
  local keep = {}
  for _, item in ipairs(app.pending_load) do
    if item.key:sub(1, 1) ~= "p" then
      keep[#keep + 1] = item
    else
      app.load_queued[item.key] = nil
    end
  end
  app.pending_load = keep
end

local function drain_image_loads(limit)
  local n = 0
  while n < limit and app.pending_load[1] do
    local item = table.remove(app.pending_load, 1)
    app.load_queued[item.key] = nil
    local ok, img = pcall(love.graphics.newImage, item.name)
    if ok then
      app.cover_cache[item.key] = img
    else
      app.cover_fail[item.key] = true
    end
    n = n + 1
  end
end

local function prefetch_pages()
  if app.screen ~= "spread" or not app.chapter then
    return
  end
  local from, to = layout.prefetch_range(app.page_index, #app.pages, app.single)
  for i = from, to do
    local url = app.pages[i]
    if url then
      request_image("p" .. i .. app.chapter.id, url)
    end
  end
end

local function visible_result_covers()
  local _, y, _, h = layout.stage_rect(app.w, app.h, app.screen)
  for i, item in ipairs(app.results) do
    local r = layout.card_rect(app.w, app.h, i, app.result_scroll, app.screen)
    if r.y + r.h > y and r.y < y + h then
      request_image(item.id, item.cover)
    end
  end
end

local function prefetch_covers()
  if app.selected then
    request_image(app.selected.id, app.selected.cover)
  end
  if app.screen == "shelf" then
    visible_result_covers()
  end
  local _, y, _, h = layout.rail_rect(app.h, app.screen)
  local yy = y + 48 - app.scroll
  for _, item in ipairs(app.favorites) do
    if yy > y + 32 and yy < y + h - 20 then
      local cover = item.cover
      if not cover and item.cover_file then
        cover = mangadex.cover_url(item.id, item.cover_file)
      end
      request_image(item.id, cover)
    end
    yy = yy + 64
  end
end

local function catalog_status()
  local n = #app.results
  local total = app.catalog_total or n
  if app.waiting == "more" then
    return string.format("%d / %d folds · loading more…", n, total)
  end
  if app.waiting == "search" then
    return (app.query == "") and "Fetching popular folds…" or "Searching…"
  end
  if n == 0 then
    return "No folds match."
  end
  if app.has_more and total > n then
    return string.format("%d / %d folds", n, total)
  end
  return string.format("%d folds on the shelf.", n)
end

local function start_search()
  app.results = {}
  app.catalog_total = 0
  app.has_more = true
  app.result_scroll = 0
  app.waiting = "search"
  app.status = catalog_status()
  jobs.text(bump("search"), mangadex.search_url(app.query, nil, 0))
end

local function load_more()
  if app.screen ~= "shelf" or app.waiting or not app.has_more then
    return
  end
  if #app.results >= (app.catalog_total or math.huge) and app.catalog_total > 0 then
    app.has_more = false
    return
  end
  app.waiting = "more"
  app.status = catalog_status()
  local offset = #app.results
  jobs.text("more:" .. app.token.search .. ":" .. offset, mangadex.search_url(app.query, nil, offset))
end

local function maybe_load_more()
  if app.screen ~= "shelf" then
    return
  end
  local max_s = layout.max_result_scroll(app.w, app.h, #app.results, app.screen)
  if layout.should_page(app.result_scroll, max_s) then
    load_more()
  end
end

local function start_feed(manga)
  app.selected = manga
  app.chapters = {}
  app.chapter_scroll = 0
  app.screen = "fold"
  app.waiting = "feed"
  app.status = "Loading folds…"
  jobs.text(bump("feed"), mangadex.feed_url(manga.id))
end

local function start_pages(chapter)
  drop_page_images()
  app.chapter = chapter
  app.pages = {}
  app.page_index = 1
  app.screen = "spread"
  app.waiting = "pages"
  app.status = "Requesting pages…"
  jobs.text(bump("athome"), mangadex.at_home_url(chapter.id))
end

local function mark_progress()
  if not app.chapter then
    return
  end
  app.progress[app.chapter.id] = { page = app.page_index }
  app.save_in = 0.35
end

local function flush_progress()
  if app.save_in > 0 then
    persist.save_progress(app.progress)
    app.save_in = 0
  end
end

local function handle_text(msg)
  local more_gen = msg.key:match("^more:(%d+):")
  if more_gen then
    if tonumber(more_gen) ~= app.token.search then
      return
    end
    if not msg.ok then
      app.has_more = false
      app.waiting = nil
      app.status = catalog_status()
      return
    end
    local page, total = mangadex.parse_manga_list(msg.body)
    app.catalog_total = total or app.catalog_total
    local _, added = mangadex.merge_unique(app.results, page or {})
    if added == 0 or #app.results >= app.catalog_total then
      app.has_more = false
    end
    app.waiting = nil
    app.status = catalog_status()
    return
  end

  local kind, n = token_of(msg.key)
  if not kind or n ~= app.token[kind] then
    return
  end
  if not msg.ok then
    app.status = "Could not reach MangaDex."
    app.waiting = nil
    return
  end
  if kind == "search" then
    local list, total = mangadex.parse_manga_list(msg.body)
    app.results = list or {}
    app.catalog_total = total or #app.results
    app.result_scroll = 0
    app.has_more = #app.results < app.catalog_total
    app.waiting = nil
    app.status = catalog_status()
  elseif kind == "feed" then
    local list, err = mangadex.parse_feed(msg.body)
    if not list then
      app.status = "Feed parse failed: " .. tostring(err)
      app.chapters = {}
    else
      app.chapters = list
      local title = app.selected and app.selected.title or ""
      app.status = title .. " — " .. #list .. " folds"
    end
    app.waiting = nil
  elseif kind == "athome" then
    local at, err = mangadex.parse_at_home(msg.body)
    if not at then
      app.status = "Pages failed: " .. tostring(err)
      app.pages = {}
    else
      app.pages = at.pages
      local saved = app.chapter and app.progress[app.chapter.id]
      app.page_index = (saved and saved.page) or 1
      local ch = app.chapter and app.chapter.chapter or "?"
      app.status = string.format("Ch. %s · %d pages", ch, #app.pages)
    end
    app.waiting = nil
  end
end

function app.load()
  love.graphics.setBackgroundColor(layout.colors.washi)
  app.font = love.graphics.newFont(16)
  app.font_sm = love.graphics.newFont(13)
  app.font_lg = love.graphics.newFont(22)
  app.w, app.h = love.graphics.getDimensions()
  love.filesystem.createDirectory("cache")
  app.favorites = persist.load_library()
  app.progress = persist.load_progress()
  jobs.start(http.USER_AGENT)
  start_search()
end

function app.resize(w, h)
  app.w, app.h = w, h
end

function app.update(dt)
  local err = jobs.errors()
  if err then
    app.status = "Download thread: " .. err
  end
  for _, msg in ipairs(jobs.poll()) do
    if msg.kind == "text" then
      local ok, parsed_err = pcall(handle_text, msg)
      if not ok then
        app.status = "Parse failed: " .. tostring(parsed_err)
        app.waiting = nil
      end
    elseif msg.kind == "file" then
      if msg.ok then
        queue_image_load(msg.key, cache_name(msg.key))
      else
        app.cover_fail[msg.key] = true
      end
    end
  end
  drain_image_loads(layout.images_per_frame)
  prefetch_pages()
  prefetch_covers()
  maybe_load_more()
  if app.save_in > 0 then
    app.save_in = app.save_in - dt
    if app.save_in <= 0 then
      persist.save_progress(app.progress)
      app.save_in = 0
    end
  end
end

local function draw_seal(x, y, r, filled)
  rgb(layout.colors.vermilion)
  love.graphics.setLineWidth(2)
  love.graphics.circle(filled and "fill" or "line", x, y, r)
  if filled then
    rgb(layout.colors.washi)
  end
  love.graphics.setLineWidth(2)
  love.graphics.line(x - r * 0.4, y + r * 0.35, x - r * 0.4, y - r * 0.35, x, y - r * 0.05, x + r * 0.4, y - r * 0.35, x + r * 0.4, y + r * 0.35)
end

local function fit_image(img, x, y, w, h)
  if not img then
    return
  end
  local iw, ih = img:getWidth(), img:getHeight()
  local s = math.min(w / iw, h / ih)
  local dw, dh = iw * s, ih * s
  rgb({ 1, 1, 1 })
  love.graphics.draw(img, x + (w - dw) / 2, y + (h - dh) / 2, 0, s, s)
end

local function draw_header()
  rgb(layout.colors.fold)
  love.graphics.rectangle("fill", 0, 0, app.w, layout.header)
  rgb(layout.colors.line)
  love.graphics.rectangle("fill", 0, layout.header - 1, app.w, 1)
  draw_seal(36, 44, 18, true)
  rgb(layout.colors.ink)
  love.graphics.setFont(app.font_lg)
  love.graphics.print("Orihon", 60, 30)

  local sx, sy, sw, sh = layout.search_rect(app.w)
  rgb(layout.colors.washi)
  round_rect(sx, sy, sw, sh, 4)
  rgb(app.search_focus and layout.colors.vermilion or layout.colors.line)
  love.graphics.setLineWidth(app.search_focus and 2 or 1)
  love.graphics.rectangle("line", sx, sy, sw, sh, 4, 4)
  love.graphics.setFont(app.font)
  local shown = app.query
  if shown == "" then
    rgb(layout.colors.ink_soft)
    shown = "search a title…"
  else
    rgb(layout.colors.ink)
  end
  love.graphics.setScissor(sx + 8, sy + 4, sw - 16, sh - 8)
  love.graphics.print(shown, sx + 10, sy + 10)
  love.graphics.setScissor()

  local stamp_x, stamp_y = layout.stamp_origin(app.w)
  local stamps = { "EN", "PT" }
  for i, label in ipairs(stamps) do
    local cx = stamp_x + (i - 1) * 52 + 18
    rgb(layout.colors.vermilion)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", cx, stamp_y + 12, layout.stamp_r)
    love.graphics.setFont(app.font_sm)
    love.graphics.printf(label, cx - 18, stamp_y + 4, 36, "center")
  end
end

local function draw_rail()
  local x, y, w, h = layout.rail_rect(app.h, app.screen)
  rgb(layout.colors.fold)
  round_rect(x, y, w, h, 8)
  rgb(layout.colors.ink)
  love.graphics.setFont(app.font)
  love.graphics.print("Favorites", x + 16, y + 14)
  local list = app.favorites
  love.graphics.setFont(app.font_sm)
  if #list == 0 then
    rgb(layout.colors.ink_soft)
    love.graphics.printf("Stamp a title with the vermilion mark to keep it on the shelf.", x + 16, y + 48, w - 32, "left")
    return
  end
  local yy = y + 48 - app.scroll
  for _, item in ipairs(list) do
    if yy > y + 32 and yy < y + h - 20 then
      rgb(layout.colors.washi)
      round_rect(x + 12, yy, w - 24, 56, 4)
      rgb(layout.colors.ink)
      love.graphics.print(item.title:sub(1, 32), x + 22, yy + 18)
    end
    yy = yy + 64
  end
end

local function draw_scrollbar(bar)
  if not bar or not bar.visible then
    return
  end
  rgb(layout.colors.line)
  round_rect(bar.track.x, bar.track.y, bar.track.w, bar.track.h, 4)
  rgb(layout.colors.vermilion)
  round_rect(bar.thumb.x, bar.thumb.y, bar.thumb.w, bar.thumb.h, 4)
end

local function stage_bar()
  if app.screen == "fold" then
    local max_s = layout.max_chapter_scroll(app.w, app.h, #app.chapters)
    return layout.scrollbar(layout.fold_scroll_track(app.w, app.h), app.chapter_scroll, max_s), "chapters"
  end
  local max_s = layout.max_result_scroll(app.w, app.h, #app.results, app.screen)
  return layout.scrollbar(layout.stage_scroll_track(app.w, app.h, app.screen), app.result_scroll, max_s), "results"
end

local function apply_scroll(kind, value)
  if kind == "chapters" then
    local max_s = layout.max_chapter_scroll(app.w, app.h, #app.chapters)
    app.chapter_scroll = math.max(0, math.min(max_s, value))
    return
  end
  local max_s = layout.max_result_scroll(app.w, app.h, #app.results, app.screen)
  app.result_scroll = math.max(0, math.min(max_s, value))
  maybe_load_more()
end

local function draw_results()
  local x, y, w, h = layout.stage_rect(app.w, app.h, app.screen)
  rgb(layout.colors.fold)
  round_rect(x, y, w, h, 8)
  love.graphics.setFont(app.font_sm)
  rgb(layout.colors.ink_soft)
  love.graphics.print(app.status, x + 20, y + 10)
  local gutter = layout.scroll_w + layout.scroll_gap
  local clip = {
    x = x + 8,
    y = y + layout.stage_status_h,
    w = w - 16 - gutter,
    h = h - layout.stage_status_h - 8,
  }
  for i, item in ipairs(app.results) do
    local r = layout.card_rect(app.w, app.h, i, app.result_scroll, app.screen)
    local vis = layout.intersect(r, clip)
    if vis then
      love.graphics.setScissor(vis.x, vis.y, vis.w, vis.h)
      rgb(layout.colors.washi)
      round_rect(r.x, r.y, r.w, r.h, 6)
      rgb(layout.colors.vermilion)
      love.graphics.rectangle("fill", r.x, r.y, 6, r.h)
      local img = app.cover_cache[item.id]
      local slot_x, slot_y = r.x + 14, r.y + 10
      if img then
        fit_image(img, slot_x, slot_y, layout.cover_w, layout.cover_h)
      else
        rgb(layout.colors.line)
        love.graphics.rectangle("line", slot_x, slot_y, layout.cover_w, layout.cover_h, 3, 3)
      end
      local title_box, desc_box = layout.card_text_boxes(r, app.font:getHeight())
      local title_vis = layout.intersect(title_box, vis)
      if title_vis then
        rgb(layout.colors.ink)
        love.graphics.setFont(app.font)
        love.graphics.setScissor(title_vis.x, title_vis.y, title_vis.w, title_vis.h)
        love.graphics.printf(item.title, title_box.x, title_box.y, title_box.w, "left")
      end
      local desc_vis = layout.intersect(desc_box, vis)
      if desc_vis and desc_box.h > 8 then
        rgb(layout.colors.ink_soft)
        love.graphics.setFont(app.font_sm)
        love.graphics.setScissor(desc_vis.x, desc_vis.y, desc_vis.w, desc_vis.h)
        love.graphics.printf(item.description or "", desc_box.x, desc_box.y, desc_box.w, "left")
      end
    end
  end
  love.graphics.setScissor()
  draw_scrollbar(stage_bar())
end

local function draw_fold()
  local manga = app.selected
  local x, y, w, h = layout.stage_rect(app.w, app.h, app.screen)
  rgb(layout.colors.fold)
  round_rect(x, y, w, h, 8)
  rgb(layout.colors.ink)
  love.graphics.setFont(app.font_lg)
  local title_x = x + 24
  if manga and app.cover_cache[manga.id] then
    fit_image(app.cover_cache[manga.id], x + 20, y + 16, 88, 120)
    title_x = x + 118
  end
  rgb(layout.colors.ink)
  love.graphics.printf(manga and manga.title or "", title_x, y + 18, w - (title_x - x) - 72, "left")
  love.graphics.setFont(app.font_sm)
  rgb(layout.colors.ink_soft)
  love.graphics.printf((manga and manga.description or ""):sub(1, 280), title_x, y + 52, w - (title_x - x) - 72, "left")

  local fav = persist.is_favorite(app.favorites, manga and manga.id)
  draw_seal(x + w - 36, y + 36, 16, fav)

  local gutter = layout.scroll_w + layout.scroll_gap
  local list_top = y + 148
  love.graphics.setScissor(x + 8, list_top, w - 16 - gutter, h - 156)
  local yy = list_top - app.chapter_scroll
  local row_w = w - 40 - gutter
  for _, ch in ipairs(app.chapters) do
    rgb(layout.colors.washi)
    round_rect(x + 20, yy, row_w, 48, 4)
    rgb(layout.colors.vermilion)
    love.graphics.rectangle("fill", x + 20, yy, row_w, 3)
    rgb(layout.colors.ink)
    love.graphics.setFont(app.font)
    local label = string.format("fold %s  ·  %s  ·  %s", ch.chapter, ch.lang, ch.title)
    love.graphics.print(label:sub(1, 70), x + 36, yy + 14)
    yy = yy + layout.fold_h
  end
  love.graphics.setScissor()
  draw_scrollbar(stage_bar())
end

local function page_image(index)
  local url = app.pages[index]
  if not url or not app.chapter then
    return nil
  end
  local key = "p" .. index .. app.chapter.id
  request_image(key, url)
  return app.cover_cache[key]
end

local function draw_image(img, rect)
  if not img then
    rgb(layout.colors.washi)
    round_rect(rect.x, rect.y, rect.w, rect.h, 4)
    rgb(layout.colors.ink_soft)
    love.graphics.printf("loading page…", rect.x, rect.y + rect.h / 2, rect.w, "center")
    return
  end
  local iw, ih = img:getWidth(), img:getHeight()
  local s = math.min(rect.w / iw, rect.h / ih)
  local dw, dh = iw * s, ih * s
  local dx = rect.x + (rect.w - dw) / 2
  local dy = rect.y + (rect.h - dh) / 2
  rgb({ 1, 1, 1 })
  love.graphics.draw(img, dx, dy, 0, s, s)
end

local function go_home()
  flush_progress()
  app.scroll_drag = nil
  app.screen = "shelf"
  app.search_focus = true
  app.query = ""
  app.result_scroll = 0
  start_search()
end

local function draw_button(btn, label)
  rgb(layout.colors.washi)
  round_rect(btn.x, btn.y, btn.w, btn.h, 6)
  rgb(layout.colors.vermilion)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 6, 6)
  rgb(layout.colors.ink)
  love.graphics.setFont(app.font)
  love.graphics.printf(label, btn.x, btn.y + 8, btn.w, "center")
end

local function draw_nav_bar()
  local fx, fy, fw, fh = layout.footer_rect(app.w, app.h)
  rgb(layout.colors.fold)
  love.graphics.rectangle("fill", fx, fy, fw, fh)
  rgb(layout.colors.line)
  love.graphics.rectangle("fill", fx, fy, fw, 1)
  local buttons = layout.nav_buttons(app.screen, app.w, app.h)
  local order = { "back", "prev", "next", "mode" }
  local last
  for _, id in ipairs(order) do
    local btn = buttons[id]
    if btn then
      local label = btn.label
      if id == "mode" then
        label = app.single and "Double" or "Single"
      end
      draw_button(btn, label)
      last = btn
    end
  end
  rgb(layout.colors.ink_soft)
  love.graphics.setFont(app.font_sm)
  local info_x = last and (last.x + last.w + 16) or 24
  love.graphics.printf(app.status or "", info_x, fy + 22, fw - info_x - 16, "left")
end

local function draw_reader_bar()
  draw_nav_bar()
end

local function draw_spread()
  local pages = layout.spread_pages(app.w, app.h)
  if app.single then
    local mid = {
      x = pages.left.x,
      y = pages.left.y,
      w = pages.right.x + pages.right.w - pages.left.x,
      h = pages.left.h,
    }
    draw_image(page_image(app.page_index), mid)
  else
    draw_image(page_image(app.page_index + 1), pages.left)
    draw_image(page_image(app.page_index), pages.right)
  end
  draw_reader_bar()
end

function app.draw()
  rgb(layout.colors.washi)
  love.graphics.rectangle("fill", 0, 0, app.w, app.h)
  draw_header()
  if app.screen == "spread" then
    draw_spread()
    return
  end
  draw_rail()
  if app.screen == "shelf" then
    draw_results()
  else
    draw_fold()
  end
  if layout.shows_footer(app.screen) then
    draw_nav_bar()
  end
end

function app.textinput(text)
  if app.screen ~= "shelf" or not app.search_focus then
    return
  end
  app.query = app.query .. text
end

function app.keypressed(key)
  if key == "backspace" and app.search_focus and app.screen == "shelf" then
    app.query = app.query:sub(1, -2)
  elseif key == "return" and app.screen == "shelf" then
    start_search()
  elseif key == "escape" then
    flush_progress()
    if app.screen == "spread" then
      app.screen = "fold"
    elseif app.screen == "fold" then
      app.screen = "shelf"
    end
  elseif key == "d" and app.screen == "spread" then
    app.single = not app.single
  elseif key == "right" and app.screen == "spread" then
    app.page_index = math.min(math.max(1, #app.pages), app.page_index + (app.single and 1 or 2))
    mark_progress()
  elseif key == "left" and app.screen == "spread" then
    app.page_index = math.max(1, app.page_index - (app.single and 1 or 2))
    mark_progress()
  elseif key == "/" then
    app.search_focus = true
    app.screen = "shelf"
  end
end

local function hit_results(mx, my)
  local _, sy, _, sh = layout.stage_rect(app.w, app.h, app.screen)
  local bar = select(1, stage_bar())
  if bar.visible and (layout.hit(mx, my, bar.track) or layout.hit(mx, my, bar.thumb)) then
    return
  end
  if my < sy + layout.stage_status_h or my > sy + sh then
    return
  end
  for i, item in ipairs(app.results) do
    local r = layout.card_rect(app.w, app.h, i, app.result_scroll, app.screen)
    if layout.hit(mx, my, r) then
      return item
    end
  end
end

local function hit_favorite(mx, my)
  local x, y, w = layout.rail_rect(app.h, app.screen)
  local yy = y + 48 - app.scroll
  for _, item in ipairs(app.favorites) do
    if mx >= x + 12 and mx <= x + w - 12 and my >= yy and my <= yy + 56 then
      return item
    end
    yy = yy + 64
  end
end

local function hit_chapter(mx, my)
  local x, y, w, h = layout.stage_rect(app.w, app.h, app.screen)
  local bar = select(1, stage_bar())
  if bar.visible and (layout.hit(mx, my, bar.track) or layout.hit(mx, my, bar.thumb)) then
    return
  end
  local list_top = y + 148
  if my < list_top or my > y + h then
    return
  end
  local yy = list_top - app.chapter_scroll
  local right = x + w - 20 - layout.scroll_w - layout.scroll_gap
  for _, ch in ipairs(app.chapters) do
    if mx >= x + 20 and mx <= right and my >= yy and my <= yy + 48 then
      return ch
    end
    yy = yy + layout.fold_h
  end
end

local function handle_scroll_click(mx, my)
  if app.screen ~= "shelf" and app.screen ~= "fold" then
    return false
  end
  local bar, kind = stage_bar()
  if not bar.visible then
    return false
  end
  if layout.hit(mx, my, bar.thumb) then
    app.scroll_drag = { kind = kind, grab = my - bar.thumb.y }
    return true
  end
  if layout.hit(mx, my, bar.track) then
    apply_scroll(kind, layout.scroll_from_y(bar, my))
    local next_bar = select(1, stage_bar())
    app.scroll_drag = { kind = kind, grab = my - next_bar.thumb.y }
    return true
  end
  return false
end

local function handle_nav_click(mx, my)
  if not layout.shows_footer(app.screen) then
    return false
  end
  local buttons = layout.nav_buttons(app.screen, app.w, app.h)
  for _, btn in pairs(buttons) do
    if layout.hit(mx, my, btn) then
      if btn.id == "back" then
        app.keypressed("escape")
      elseif btn.id == "prev" then
        app.keypressed("left")
      elseif btn.id == "next" then
        app.keypressed("right")
      elseif btn.id == "mode" then
        app.keypressed("d")
      end
      return true
    end
  end
  local _, fy = layout.footer_rect(app.w, app.h)
  return my >= fy
end

function app.mousepressed(mx, my, button)
  if button ~= 1 then
    return
  end
  if mx < layout.brand_w and my < layout.header then
    go_home()
    return
  end
  local sx, sy, sw, sh = layout.search_rect(app.w)
  app.search_focus = mx >= sx and mx <= sx + sw and my >= sy and my <= sy + sh

  if handle_nav_click(mx, my) then
    return
  end

  if handle_scroll_click(mx, my) then
    return
  end

  if app.screen == "spread" then
    local pages = layout.spread_pages(app.w, app.h)
    if app.single then
      local mid_x = pages.left.x + (pages.right.x + pages.right.w - pages.left.x) / 2
      if mx >= mid_x then
        app.keypressed("right")
      else
        app.keypressed("left")
      end
      return
    end
    if mx >= pages.right.x then
      app.keypressed("right")
    elseif mx >= pages.left.x then
      app.keypressed("left")
    end
    return
  end

  if app.screen == "fold" and app.selected then
    local x, y, w = layout.stage_rect(app.w, app.h, app.screen)
    local dx = mx - (x + w - 40)
    local dy = my - (y + 36)
    if dx * dx + dy * dy <= 16 * 16 then
      app.favorites = select(1, persist.toggle_favorite(app.favorites, app.selected))
      return
    end
    local ch = hit_chapter(mx, my)
    if ch then
      start_pages(ch)
      return
    end
  end

  local fav = hit_favorite(mx, my)
  if fav then
    start_feed(fav)
    return
  end

  if app.screen == "shelf" then
    local item = hit_results(mx, my)
    if item then
      start_feed(item)
    end
  end
end

function app.mousemoved(mx, my)
  local drag = app.scroll_drag
  if not drag then
    return
  end
  local bar = select(1, stage_bar())
  apply_scroll(drag.kind, layout.scroll_from_y(bar, my, drag.grab))
end

function app.mousereleased(_, _, button)
  if button == 1 then
    app.scroll_drag = nil
  end
end

function app.wheelmoved(y)
  local mx = love.mouse.getX()
  local rx, _, rw = layout.rail_rect(app.h, app.screen)
  if mx >= rx and mx <= rx + rw then
    app.scroll = math.max(0, app.scroll - y * 24)
  elseif app.screen == "fold" then
    apply_scroll("chapters", app.chapter_scroll - y * 40)
  else
    apply_scroll("results", app.result_scroll - y * 40)
  end
end

return app
