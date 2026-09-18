-- Optional live smoke against MangaDex. Needs network + curl.
package.path = "./?.lua;./?/init.lua;" .. package.path

local http = require("src.http")
local mangadex = require("src.mangadex")

local list, err = mangadex.search(http, "")
if not list then
  io.stderr:write("search failed: " .. tostring(err) .. "\n")
  os.exit(1)
end
assert(#list > 0, "expected popular titles")
assert(list[1].id and list[1].title ~= "", "expected id and title")
assert(list[1].cover, "expected cover from includes[]=cover_art")

local feed, ferr = mangadex.feed(http, list[1].id)
if not feed then
  io.stderr:write("feed failed: " .. tostring(ferr) .. "\n")
  os.exit(1)
end
assert(#feed > 0, "expected chapters")

local at, aerr = mangadex.at_home(http, feed[1].id)
if not at then
  io.stderr:write("at-home failed: " .. tostring(aerr) .. "\n")
  os.exit(1)
end
assert(#at.pages > 0, "expected page urls")
assert(at.pages[1]:find("https://", 1, true) == 1, "page url must be https")

print(string.format("live ok — %q · %d chapters · %d pages", list[1].title, #feed, #at.pages))
