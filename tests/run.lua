package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("src.json")
local mangadex = require("src.mangadex")
local persist = require("src.persist")
local layout = require("src.layout")

local failed = 0
local passed = 0

local function check(name, cond, extra)
  if cond then
    passed = passed + 1
    print("ok  - " .. name)
  else
    failed = failed + 1
    print("FAIL - " .. name .. (extra and (" :: " .. extra) or ""))
  end
end

local payload = json.encode({ a = 1, b = { "x", "y" }, ok = true })
local back = json.decode(payload)
check("json roundtrip object", back.a == 1 and back.b[2] == "y" and back.ok == true)

local nested = json.decode('{"n":12,"x":[3,4]}')
check("json nested numbers", nested.n == 12 and nested.x[2] == 4)

local unicode = json.decode('"\\u0041"')
check("json unicode A", unicode == "A")

local url = mangadex.search_url("one piece")
check("search url host", url:find("https://api.mangadex.org/manga?", 1, true) == 1)
check("search url safe rating", url:find("contentRating%[%]=safe", 1, false) ~= nil)
check("search url no porn", url:find("pornographic", 1, true) == nil)
check("search url encodes space", url:find("one%20piece", 1, true) ~= nil)
check("search url limit 32", url:find("limit=32", 1, true) ~= nil)
check("search url offset 0", url:find("offset=0", 1, true) ~= nil)
check("search offset page", mangadex.search_url("", 32, 32):find("offset=32", 1, true) ~= nil)
check("search default limit const", mangadex.SEARCH_LIMIT == 32)
check("feed url limit 100", mangadex.feed_url("abc"):find("limit=100", 1, true) ~= nil)

local popular = mangadex.search_url("")
check("popular uses followedCount", popular:find("followedCount", 1, true) ~= nil)

check("at-home url", mangadex.at_home_url("abc") == "https://api.mangadex.org/at-home/server/abc")
check("page url saver", mangadex.page_url("https://x", "h", "1.jpg", true) == "https://x/data-saver/h/1.jpg")

local list, total = mangadex.parse_manga_list([[
{"total":99,"data":[{"id":"m1","attributes":{"title":{"en":"Paper Crane"},"description":{"en":"A quiet story."},"status":"ongoing"},
"relationships":[{"type":"cover_art","attributes":{"fileName":"cover.png"}}]}]}
]])
check("parse title", list[1] and list[1].title == "Paper Crane")
check("parse cover", list[1] and list[1].cover:find("cover.png.256.jpg", 1, true) ~= nil)
check("parse total", total == 99)

local merged = { { id = "m1", title = "A" } }
mangadex.merge_unique(merged, { { id = "m1" }, { id = "m2", title = "B" } })
check("merge unique", #merged == 2 and merged[2].id == "m2")

local feed_json = [[
{"data":[
  {"id":"c1","attributes":{"chapter":"2","title":"Later","translatedLanguage":"en","pages":10}},
  {"id":"c0","attributes":{"chapter":"1","title":"Start","translatedLanguage":"pt-br","pages":8}},
  {"id":"cx","attributes":{"chapter":"9","externalUrl":"https://example.com","translatedLanguage":"en"}}
]}
]]
local feed = mangadex.parse_feed(feed_json)
check("feed skips external", #feed == 2)
check("feed sorts chapters", feed[1].id == "c0" and feed[2].id == "c1")

local at = mangadex.parse_at_home([[
{"baseUrl":"https://uploads.example","chapter":{"hash":"hh","dataSaver":["a.jpg","b.jpg"]}}
]])
check("at-home pages", #at.pages == 2 and at.pages[1]:find("/data-saver/hh/a.jpg", 1, true) ~= nil)

persist._override = "/tmp/orihon-test-data"
os.execute("rm -rf /tmp/orihon-test-data")

local favs = {}
favs = persist.toggle_favorite(favs, { id = "m1", title = "Paper Crane" })
check("favorite add", persist.is_favorite(favs, "m1") == true)
favs = persist.toggle_favorite(favs, { id = "m1", title = "Paper Crane" })
check("favorite remove", persist.is_favorite(favs, "m1") == false)
check("persist uses override dir", persist.dir():find("orihon-test-data", 1, true) ~= nil)

local r = { x = 10, y = 10, w = 50, h = 20 }
check("layout hit inside", layout.hit(12, 12, r) == true)
check("layout hit outside", layout.hit(0, 0, r) == false)

local from, to = layout.prefetch_range(1, 20, false)
check("prefetch spread ahead", from == 1 and to == 6)
from, to = layout.prefetch_range(18, 20, true)
check("prefetch single clamps", from == 18 and to == 20)

local sx, sy, sw, sh = layout.search_rect(1280)
check("search right of brand", sx >= layout.brand_w)
local stamp_x = layout.stamp_origin(1280)
check("search left of stamps", sx + sw <= stamp_x)
check("search inside header", sy + sh <= layout.header)
local _, stage_y = layout.stage_rect(1280, 800)
check("stage below header", stage_y >= layout.header)
local card = layout.card_rect(1280, 800, 1, 0)
check("first card below status", card.y >= stage_y + layout.stage_status_h - 0.5)
check("result scroll has overflow", layout.max_result_scroll(1280, 800, 32) > 0)
check("page when list is short", layout.should_page(0, 0) == true)
check("page near the end", layout.should_page(400, 500) == true)
check("no page at the top", layout.should_page(0, 500) == false)

local _, fy, _, fh = layout.footer_rect(1280, 800)
check("footer sits on the bottom", fy + fh == 800)
local pages = layout.spread_pages(1280, 800)
check("pages sit above footer", pages.left.y + pages.left.h <= fy)
local _, sy, _, sh = layout.stage_rect(1280, 800)
check("shelf stage uses full height", sy + sh > fy)
local _, fsy, _, fsh = layout.stage_rect(1280, 800, "fold")
check("fold stage above footer", fsy + fsh <= fy)
local _, ry, _, rh = layout.rail_rect(800)
check("shelf rail uses full height", ry + rh > fy)
local _, fry, _, frh = layout.rail_rect(800, "fold")
check("fold rail above footer", fry + frh <= fy)
local btns = layout.reader_buttons(1280, 800)
check("reader has back and next", btns.back and btns.next and layout.hit(btns.next.x + 2, btns.next.y + 2, btns.next))
local shelf_nav = layout.nav_buttons("shelf", 1280, 800)
check("shelf has no footer nav", shelf_nav.back == nil and shelf_nav.home == nil and layout.shows_footer("shelf") == false)
local fold_nav = layout.nav_buttons("fold", 1280, 800)
check("fold has only back", fold_nav.back and not fold_nav.home and not fold_nav.next)
local spread_nav = layout.nav_buttons("spread", 1280, 800)
check("spread nav is reader buttons", spread_nav.next and spread_nav.mode and spread_nav.back)
local title_box, desc_box = layout.card_text_boxes(card, 18)
check("card title above desc", desc_box.y >= title_box.y + title_box.h)
check("card desc stays in card", desc_box.y + desc_box.h <= card.y + card.h + 0.5)
local bar = layout.scrollbar(layout.stage_scroll_track(1280, 800), 0, 400)
check("scrollbar visible when overflow", bar.visible == true)
check("thumb inside track", bar.thumb.y >= bar.track.y and bar.thumb.y + bar.thumb.h <= bar.track.y + bar.track.h + 0.5)
local at_end = layout.scrollbar(layout.stage_scroll_track(1280, 800), 400, 400)
check("thumb at bottom when scrolled", math.abs((at_end.thumb.y + at_end.thumb.h) - (at_end.track.y + at_end.track.h)) < 1)
check("cards leave scrollbar gutter", card.x + card.w <= bar.track.x + 0.5)
local none = layout.scrollbar(layout.stage_scroll_track(1280, 800), 0, 0)
check("scrollbar hidden when no overflow", none.visible == false)
check("scroll maps pointer to end", layout.scroll_from_y(bar, bar.track.y + bar.track.h) == 400)

require("tests.perf")(check)

print(string.format("\n%d passed, %d failed", passed, failed))
if failed > 0 then
  os.exit(1)
end
