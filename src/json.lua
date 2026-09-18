-- Minimal JSON encode/decode for MangaDex payloads (objects, arrays, strings, numbers).
local json = {}

local function skip(s, i)
  while true do
    local c = s:sub(i, i)
    if c == " " or c == "\n" or c == "\r" or c == "\t" then
      i = i + 1
    else
      return i
    end
  end
end

local decode_value

local function decode_string(s, i)
  i = i + 1
  local buf = {}
  while i <= #s do
    local c = s:sub(i, i)
    if c == '"' then
      return table.concat(buf), i + 1
    elseif c == "\\" then
      local n = s:sub(i + 1, i + 1)
      local map = { b = "\b", f = "\f", n = "\n", r = "\r", t = "\t", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }
      if n == "u" then
        local hex = s:sub(i + 2, i + 5)
        local cp = tonumber(hex, 16) or 0
        if cp < 0x80 then
          buf[#buf + 1] = string.char(cp)
        elseif cp < 0x800 then
          buf[#buf + 1] = string.char(0xC0 + math.floor(cp / 64), 0x80 + (cp % 64))
        else
          buf[#buf + 1] = string.char(
            0xE0 + math.floor(cp / 4096),
            0x80 + math.floor(cp / 64) % 64,
            0x80 + (cp % 64)
          )
        end
        i = i + 6
      else
        buf[#buf + 1] = map[n] or n
        i = i + 2
      end
    else
      buf[#buf + 1] = c
      i = i + 1
    end
  end
  error("unterminated string")
end

local function decode_number(s, i)
  local j = s:match("%-?%d+%.?%d*[eE]?[%+%-]?%d*", i)
  if not j then
    error("bad number at " .. i)
  end
  return tonumber(j), i + #j
end

local function decode_array(s, i)
  i = skip(s, i + 1)
  local arr = {}
  if s:sub(i, i) == "]" then
    return arr, i + 1
  end
  while true do
    local v
    v, i = decode_value(s, skip(s, i))
    arr[#arr + 1] = v
    i = skip(s, i)
    local c = s:sub(i, i)
    if c == "]" then
      return arr, i + 1
    elseif c ~= "," then
      error("expected comma in array at " .. i)
    end
    i = i + 1
  end
end

local function decode_object(s, i)
  i = skip(s, i + 1)
  local obj = {}
  if s:sub(i, i) == "}" then
    return obj, i + 1
  end
  while true do
    i = skip(s, i)
    if s:sub(i, i) ~= '"' then
      error("expected string key at " .. i)
    end
    local key
    key, i = decode_string(s, i)
    i = skip(s, i)
    if s:sub(i, i) ~= ":" then
      error("expected colon at " .. i)
    end
    local val
    val, i = decode_value(s, skip(s, i + 1))
    obj[key] = val
    i = skip(s, i)
    local c = s:sub(i, i)
    if c == "}" then
      return obj, i + 1
    elseif c ~= "," then
      error("expected comma in object at " .. i)
    end
    i = i + 1
  end
end

decode_value = function(s, i)
  i = skip(s, i)
  local c = s:sub(i, i)
  if c == '"' then
    return decode_string(s, i)
  elseif c == "{" then
    return decode_object(s, i)
  elseif c == "[" then
    return decode_array(s, i)
  elseif c == "t" and s:sub(i, i + 3) == "true" then
    return true, i + 4
  elseif c == "f" and s:sub(i, i + 4) == "false" then
    return false, i + 5
  elseif c == "n" and s:sub(i, i + 3) == "null" then
    return nil, i + 4
  elseif c == "-" or c:match("%d") then
    return decode_number(s, i)
  end
  error("unexpected char " .. c .. " at " .. i)
end

function json.decode(s)
  local v, i = decode_value(s, 1)
  i = skip(s, i)
  if i <= #s then
    error("trailing junk at " .. i)
  end
  return v
end

local encode_value

local function encode_string(str)
  str = tostring(str)
  str = str:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
  return '"' .. str .. '"'
end

local function is_array(t)
  local n = 0
  for k, _ in pairs(t) do
    if type(k) ~= "number" then
      return false
    end
    n = n + 1
  end
  return n == 0 or t[1] ~= nil
end

encode_value = function(v)
  local tv = type(v)
  if v == nil then
    return "null"
  elseif tv == "boolean" then
    return v and "true" or "false"
  elseif tv == "number" then
    return tostring(v)
  elseif tv == "string" then
    return encode_string(v)
  elseif tv == "table" then
    if is_array(v) then
      local parts = {}
      for i = 1, #v do
        parts[i] = encode_value(v[i])
      end
      return "[" .. table.concat(parts, ",") .. "]"
    end
    local parts = {}
    for k, val in pairs(v) do
      parts[#parts + 1] = encode_string(k) .. ":" .. encode_value(val)
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  error("cannot encode " .. tv)
end

function json.encode(v)
  return encode_value(v)
end

return json
