-- Background curl worker. Runs inside a LÖVE thread (no graphics).
local jobs = love.thread.getChannel("orihon_jobs")
local done = love.thread.getChannel("orihon_done")

local function quote(s)
  return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function file_ok(path)
  local f = io.open(path, "rb")
  if not f then
    return false
  end
  local size = f:seek("end")
  f:close()
  return size and size > 32
end

while true do
  local job = jobs:demand()
  if not job or job.quit then
    break
  end
  local ua = job.ua or "Orihon/0.1"
  local timeout = tostring(job.timeout or 30)
  if job.kind == "file" then
    local tmp = job.dest .. ".part"
    local cmd = table.concat({
      "curl",
      "-sS",
      "-L",
      "-g",
      "--compressed",
      "--max-time",
      timeout,
      "-A",
      quote(ua),
      "-o",
      quote(tmp),
      quote(job.url),
    }, " ")
    os.execute(cmd)
    local ok = file_ok(tmp)
    if ok then
      os.rename(tmp, job.dest)
    else
      os.remove(tmp)
    end
    done:push({ key = job.key, kind = "file", ok = ok, dest = job.dest })
  else
    local cmd = table.concat({
      "curl",
      "-sS",
      "-L",
      "-g",
      "--compressed",
      "--max-time",
      timeout,
      "-A",
      quote(ua),
      "-H",
      quote("Accept: application/json"),
      quote(job.url),
    }, " ")
    local pipe = io.popen(cmd, "r")
    local body = ""
    if pipe then
      body = pipe:read("*a") or ""
      pipe:close()
    end
    local first = body:match("^%s*(.)")
    done:push({
      key = job.key,
      kind = "text",
      ok = first == "{" or first == "[",
      body = body,
    })
  end
end
