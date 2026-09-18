local json = require("src.json")

local mangadex = {}

mangadex.API = "https://api.mangadex.org"
mangadex.COVERS = "https://uploads.mangadex.org/covers"
mangadex.SEARCH_LIMIT = 32
mangadex.FEED_LIMIT = 100

local function url_encode(s)
  s = tostring(s or "")
  return (s:gsub("([^%w%-_%.~])", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

function mangadex.search_url(query, limit, offset)
  limit = tonumber(limit) or mangadex.SEARCH_LIMIT
  offset = tonumber(offset) or 0
  local parts = {
    "limit=" .. limit,
    "offset=" .. offset,
    "includes[]=cover_art",
    "contentRating[]=safe",
    "contentRating[]=suggestive",
    "availableTranslatedLanguage[]=en",
    "availableTranslatedLanguage[]=pt-br",
  }
  if query and query ~= "" then
    parts[#parts + 1] = "title=" .. url_encode(query)
    parts[#parts + 1] = "order[relevance]=desc"
  else
    parts[#parts + 1] = "order[followedCount]=desc"
  end
  return mangadex.API .. "/manga?" .. table.concat(parts, "&")
end

function mangadex.feed_url(manga_id, limit)
  limit = tonumber(limit) or mangadex.FEED_LIMIT
  local parts = {
    "limit=" .. tonumber(limit),
    "translatedLanguage[]=en",
    "translatedLanguage[]=pt-br",
    "order[chapter]=asc",
    "includeEmptyPages=0",
    "includeFuturePublishAt=0",
    "includeExternalUrl=0",
  }
  return mangadex.API .. "/manga/" .. manga_id .. "/feed?" .. table.concat(parts, "&")
end

function mangadex.at_home_url(chapter_id)
  return mangadex.API .. "/at-home/server/" .. chapter_id
end

function mangadex.cover_url(manga_id, file_name)
  if not manga_id or not file_name or file_name == "" then
    return nil
  end
  return mangadex.COVERS .. "/" .. manga_id .. "/" .. file_name .. ".256.jpg"
end

function mangadex.page_url(base_url, hash, filename, saver)
  local quality = saver and "data-saver" or "data"
  return string.format("%s/%s/%s/%s", base_url, quality, hash, filename)
end

local function first_localized(map, fallback)
  if type(map) ~= "table" then
    return fallback or ""
  end
  if map.en and map.en ~= "" then
    return map.en
  end
  if map["pt-br"] and map["pt-br"] ~= "" then
    return map["pt-br"]
  end
  if map.ja and map.ja ~= "" then
    return map.ja
  end
  for _, v in pairs(map) do
    if type(v) == "string" and v ~= "" then
      return v
    end
  end
  return fallback or ""
end

local function pick_title(attrs)
  return first_localized(attrs.title, "Untitled")
end

local function pick_desc(attrs)
  return first_localized(attrs.description, "")
end

function mangadex.parse_manga_list(payload)
  local data = type(payload) == "string" and json.decode(payload) or payload
  local list = {}
  for _, item in ipairs(data.data or {}) do
    local cover
    for _, rel in ipairs(item.relationships or {}) do
      if rel.type == "cover_art" then
        cover = rel.attributes and rel.attributes.fileName
      end
    end
    list[#list + 1] = {
      id = item.id,
      title = pick_title(item.attributes or {}),
      description = pick_desc(item.attributes or {}),
      status = item.attributes and item.attributes.status,
      year = item.attributes and item.attributes.year,
      cover = mangadex.cover_url(item.id, cover),
      cover_file = cover,
    }
  end
  return list, tonumber(data.total) or #list
end

function mangadex.merge_unique(dst, src)
  local seen = {}
  for _, item in ipairs(dst) do
    if item.id then
      seen[item.id] = true
    end
  end
  local added = 0
  for _, item in ipairs(src) do
    if item.id and not seen[item.id] then
      dst[#dst + 1] = item
      seen[item.id] = true
      added = added + 1
    end
  end
  return dst, added
end

function mangadex.parse_feed(payload)
  local data = type(payload) == "string" and json.decode(payload) or payload
  local list = {}
  for _, item in ipairs(data.data or {}) do
    local a = item.attributes or {}
    if not a.externalUrl then
      list[#list + 1] = {
        id = item.id,
        chapter = a.chapter or "?",
        title = a.title or "",
        lang = a.translatedLanguage or "",
        pages = a.pages or 0,
        volume = a.volume,
      }
    end
  end
  table.sort(list, function(a, b)
    return (tonumber(a.chapter) or 0) < (tonumber(b.chapter) or 0)
  end)
  return list
end

function mangadex.parse_at_home(payload)
  local data = type(payload) == "string" and json.decode(payload) or payload
  local ch = data.chapter or {}
  local files = ch.dataSaver or ch.data or {}
  local urls = {}
  for _, name in ipairs(files) do
    urls[#urls + 1] = mangadex.page_url(data.baseUrl, ch.hash, name, ch.dataSaver ~= nil)
  end
  return {
    base_url = data.baseUrl,
    hash = ch.hash,
    pages = urls,
  }
end

function mangadex.search(http, query)
  local body, err = http.get(mangadex.search_url(query))
  if not body then
    return nil, err
  end
  local ok, list = pcall(mangadex.parse_manga_list, body)
  if not ok then
    return nil, list
  end
  return list
end

function mangadex.feed(http, manga_id)
  local body, err = http.get(mangadex.feed_url(manga_id))
  if not body then
    return nil, err
  end
  local ok, list = pcall(mangadex.parse_feed, body)
  if not ok then
    return nil, list
  end
  return list
end

function mangadex.at_home(http, chapter_id)
  local body, err = http.get(mangadex.at_home_url(chapter_id))
  if not body then
    return nil, err
  end
  local ok, at = pcall(mangadex.parse_at_home, body)
  if not ok then
    return nil, at
  end
  return at
end

return mangadex
