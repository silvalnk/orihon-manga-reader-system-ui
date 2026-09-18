-- Geometry and washi palette: accordion folds, ink, vermilion stamps.
local layout = {}

layout.colors = {
  washi = { 0.957, 0.937, 0.894 },
  ink = { 0.110, 0.078, 0.063 },
  ink_soft = { 0.110, 0.078, 0.063, 0.62 },
  vermilion = { 0.769, 0.361, 0.149 },
  moss = { 0.239, 0.361, 0.290 },
  fold = { 0.980, 0.965, 0.933 },
  shadow = { 0.110, 0.078, 0.063, 0.12 },
  line = { 0.110, 0.078, 0.063, 0.18 },
}

layout.margin = 24
layout.rail = 260
layout.header = 88
layout.brand_w = 210
layout.stamp_cluster_w = 120
layout.fold_h = 56
layout.stamp_r = 16
layout.cols = 3
layout.card_h = 128
layout.card_gap = 12
layout.stage_status_h = 36
layout.cover_w = 72
layout.cover_h = 108
layout.prefetch_ahead = { spread = 5, single = 3 }
layout.images_per_frame = 3
layout.footer_h = 64
layout.card_title_lines = 2
layout.scroll_w = 10
layout.scroll_gap = 8

function layout.header_rect(w)
  return 0, 0, w, layout.header
end

function layout.shows_footer(screen)
  return screen == "fold" or screen == "spread"
end

function layout.footer_reserve(screen)
  if layout.shows_footer(screen) then
    return layout.footer_h
  end
  return 0
end

function layout.rail_rect(h, screen)
  local y = layout.header + 16
  local bottom = h - layout.footer_reserve(screen) - 12
  return layout.margin, y, layout.rail, bottom - y
end

function layout.stage_rect(w, h, screen)
  local x = layout.margin + layout.rail + 16
  local y = layout.header + 16
  local bottom = h - layout.footer_reserve(screen) - 12
  return x, y, w - x - layout.margin, bottom - y
end

function layout.search_rect(w)
  local sx = layout.brand_w
  local sw = w - sx - layout.stamp_cluster_w - 24
  return sx, 24, math.max(200, sw), 40
end

function layout.stamp_origin(w)
  return w - layout.stamp_cluster_w, 32
end

function layout.card_rect(w, h, index, scroll, screen)
  local sx, sy, sw = layout.stage_rect(w, h, screen)
  local cols = layout.cols
  local gap = layout.card_gap
  local inner = sw - 32 - layout.scroll_w - layout.scroll_gap
  local card_w = (inner - gap * (cols - 1)) / cols
  local col = (index - 1) % cols
  local row = math.floor((index - 1) / cols)
  return {
    x = sx + 16 + col * (card_w + gap),
    y = sy + layout.stage_status_h + row * (layout.card_h + gap) - (scroll or 0),
    w = card_w,
    h = layout.card_h,
  }
end

function layout.max_result_scroll(w, h, count, screen)
  local _, _, _, sh = layout.stage_rect(w, h, screen)
  local rows = math.ceil(math.max(count, 0) / layout.cols)
  local content = layout.stage_status_h + rows * (layout.card_h + layout.card_gap)
  return math.max(0, content - sh + 8)
end

function layout.max_chapter_scroll(w, h, count)
  local _, _, _, sh = layout.stage_rect(w, h, "fold")
  local list_top = 148
  local content = list_top + count * layout.fold_h
  return math.max(0, content - sh + 8)
end

function layout.spread_pages(w, h)
  local pad = 40
  local y = layout.header + 16
  local avail_w = w - pad * 2
  local avail_h = h - y - layout.footer_h - 12
  local page_w = (avail_w - 16) / 2
  return {
    left = { x = pad, y = y, w = page_w, h = avail_h },
    right = { x = pad + page_w + 16, y = y, w = page_w, h = avail_h },
  }
end

function layout.footer_rect(w, h)
  return 0, h - layout.footer_h, w, layout.footer_h
end

function layout.stage_scroll_track(w, h, screen)
  local x, y, sw, sh = layout.stage_rect(w, h, screen)
  return {
    x = x + sw - layout.scroll_gap - layout.scroll_w,
    y = y + layout.stage_status_h + 4,
    w = layout.scroll_w,
    h = math.max(8, sh - layout.stage_status_h - 12),
  }
end

function layout.fold_scroll_track(w, h)
  local x, y, sw, sh = layout.stage_rect(w, h, "fold")
  local list_top = 148
  return {
    x = x + sw - layout.scroll_gap - layout.scroll_w,
    y = y + list_top,
    w = layout.scroll_w,
    h = math.max(8, sh - list_top - 8),
  }
end

function layout.scrollbar(track, scroll, max_scroll)
  max_scroll = math.max(0, tonumber(max_scroll) or 0)
  scroll = math.max(0, math.min(max_scroll, tonumber(scroll) or 0))
  local thumb_h = track.h
  if max_scroll > 0 then
    local content = track.h + max_scroll
    thumb_h = math.max(28, track.h * track.h / content)
  end
  local travel = math.max(0, track.h - thumb_h)
  local thumb_y = 0
  if max_scroll > 0 and travel > 0 then
    thumb_y = scroll / max_scroll * travel
  end
  return {
    track = track,
    thumb = { x = track.x, y = track.y + thumb_y, w = track.w, h = thumb_h },
    max_scroll = max_scroll,
    scroll = scroll,
    visible = max_scroll > 0,
  }
end

function layout.scroll_from_y(bar, pointer_y, grab)
  grab = grab or (bar.thumb.h / 2)
  local travel = math.max(1, bar.track.h - bar.thumb.h)
  local rel = pointer_y - bar.track.y - grab
  return math.max(0, math.min(bar.max_scroll, (rel / travel) * bar.max_scroll))
end

function layout.nav_buttons(screen, w, h)
  if screen == "spread" then
    return layout.reader_buttons(w, h)
  end
  if screen ~= "fold" then
    return {}
  end
  local _, fy, _, fh = layout.footer_rect(w, h)
  local bh = 36
  local cy = fy + (fh - bh) / 2
  return {
    back = { x = 20, y = cy, w = 110, h = bh, id = "back", label = "Back" },
  }
end

function layout.reader_buttons(w, h)
  local _, fy, _, fh = layout.footer_rect(w, h)
  local bw, bh = 96, 36
  local cy = fy + (fh - bh) / 2
  local mid = w / 2
  return {
    back = { x = 20, y = cy, w = bw, h = bh, id = "back", label = "Back" },
    prev = { x = mid - 160, y = cy, w = bw, h = bh, id = "prev", label = "Prev" },
    next = { x = mid - 48, y = cy, w = bw, h = bh, id = "next", label = "Next" },
    mode = { x = mid + 64, y = cy, w = 120, h = bh, id = "mode", label = "Single" },
  }
end

function layout.card_text_boxes(r, title_line_h)
  title_line_h = title_line_h or 18
  local text_x = r.x + 14 + layout.cover_w + 10
  local text_w = math.max(8, r.x + r.w - text_x - 12)
  local title = {
    x = text_x,
    y = r.y + 10,
    w = text_w,
    h = title_line_h * layout.card_title_lines,
  }
  local desc_y = title.y + title.h + 6
  local desc = {
    x = text_x,
    y = desc_y,
    w = text_w,
    h = math.max(0, r.y + r.h - 10 - desc_y),
  }
  return title, desc
end

function layout.hit(x, y, r)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function layout.overlaps(ax, aw, bx, bw)
  return ax < bx + bw and bx < ax + aw
end

function layout.should_page(scroll, max_scroll)
  scroll = tonumber(scroll) or 0
  max_scroll = tonumber(max_scroll) or 0
  if max_scroll <= 80 then
    return true
  end
  return scroll >= max_scroll - 280
end

function layout.intersect(a, b)
  local x = math.max(a.x, b.x)
  local y = math.max(a.y, b.y)
  local right = math.min(a.x + a.w, b.x + b.w)
  local bottom = math.min(a.y + a.h, b.y + b.h)
  if right <= x or bottom <= y then
    return nil
  end
  return { x = x, y = y, w = right - x, h = bottom - y }
end

function layout.prefetch_range(index, total, single)
  local ahead = single and layout.prefetch_ahead.single or layout.prefetch_ahead.spread
  local from = math.max(1, tonumber(index) or 1)
  local to = math.min(tonumber(total) or 0, from + ahead)
  return from, to
end

return layout
