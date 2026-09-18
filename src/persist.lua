local json = require("src.json")

local persist = {}

local function home()
  return os.getenv("HOME") or "."
end

function persist.dir()
  if persist._override then
    return persist._override
  end
  local env = os.getenv("ORIHON_DATA_DIR")
  if env and env ~= "" then
    return env
  end
  if love and love.filesystem then
    return love.filesystem.getSaveDirectory()
  end
  return home() .. "/.local/share/love/orihon"
end

local function join(dir, name)
  if dir:sub(-1) == "/" then
    return dir .. name
  end
  return dir .. "/" .. name
end

function persist.ensure_dir(path)
  if love and love.filesystem then
    return true
  end
  os.execute("mkdir -p " .. string.format("%q", path))
end

function persist.read_json(name, default)
  default = default or {}
  if love and love.filesystem then
    if not love.filesystem.getInfo(name) then
      return default
    end
    local raw = love.filesystem.read(name)
    if not raw or raw == "" then
      return default
    end
    local ok, data = pcall(json.decode, raw)
    if ok then
      return data
    end
    return default
  end
  persist.ensure_dir(persist.dir())
  local f = io.open(join(persist.dir(), name), "r")
  if not f then
    return default
  end
  local raw = f:read("*a")
  f:close()
  local ok, data = pcall(json.decode, raw)
  if ok then
    return data
  end
  return default
end

function persist.write_json(name, value)
  local raw = json.encode(value)
  if love and love.filesystem then
    love.filesystem.write(name, raw)
    return true
  end
  persist.ensure_dir(persist.dir())
  local f = io.open(join(persist.dir(), name), "w")
  if not f then
    return nil, "cannot write " .. name
  end
  f:write(raw)
  f:close()
  return true
end

function persist.load_library()
  local data = persist.read_json("library.json", { favorites = {} })
  return data.favorites or {}
end

function persist.save_library(favorites)
  return persist.write_json("library.json", { favorites = favorites })
end

function persist.load_progress()
  return persist.read_json("progress.json", {})
end

function persist.save_progress(progress)
  return persist.write_json("progress.json", progress)
end

function persist.toggle_favorite(favorites, manga)
  for i, item in ipairs(favorites) do
    if item.id == manga.id then
      table.remove(favorites, i)
      persist.save_library(favorites)
      return favorites, false
    end
  end
  favorites[#favorites + 1] = {
    id = manga.id,
    title = manga.title,
    cover = manga.cover,
    cover_file = manga.cover_file,
  }
  persist.save_library(favorites)
  return favorites, true
end

function persist.is_favorite(favorites, id)
  for _, item in ipairs(favorites) do
    if item.id == id then
      return true
    end
  end
  return false
end

return persist
