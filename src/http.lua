local http = {}

http.USER_AGENT = "Orihon/0.1 (desktop manga reader; Lua; personal use)"

local function shell_quote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

function http.get(url, timeout)
  timeout = timeout or 30
  local cmd = table.concat({
    "curl",
    "-sS",
    "-L",
    "-g",
    "--compressed",
    "--max-time",
    tostring(timeout),
    "-A",
    shell_quote(http.USER_AGENT),
    "-H",
    shell_quote("Accept: application/json"),
    shell_quote(url),
  }, " ")
  local pipe = io.popen(cmd, "r")
  if not pipe then
    return nil, "could not start curl"
  end
  local body = pipe:read("*a")
  local ok, _, code = pipe:close()
  if not ok and code and code ~= 0 then
    return nil, "curl failed: " .. tostring(code)
  end
  return body
end

function http.get_bytes(url, dest_path, timeout)
  timeout = timeout or 45
  local cmd = table.concat({
    "curl",
    "-sS",
    "-L",
    "-g",
    "--compressed",
    "--max-time",
    tostring(timeout),
    "-A",
    shell_quote(http.USER_AGENT),
    "-o",
    shell_quote(dest_path),
    shell_quote(url),
  }, " ")
  local ok = os.execute(cmd)
  if ok == true or ok == 0 then
    return true
  end
  return nil, "download failed"
end

return http
