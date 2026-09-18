-- Non-blocking download queue. curl lives in download_thread.lua only.
local jobs = {
  N = 3,
  inflight = {},
  threads = {},
}

function jobs.start(ua)
  jobs.ua = ua
  jobs.in_ch = love.thread.getChannel("orihon_jobs")
  jobs.out_ch = love.thread.getChannel("orihon_done")
  jobs.inflight = {}
  for i = 1, jobs.N do
    local thread = love.thread.newThread("src/download_thread.lua")
    thread:start()
    jobs.threads[i] = thread
  end
end

function jobs.pending(key)
  return jobs.inflight[key] ~= nil
end

function jobs.file(key, url, dest)
  if not url or not dest or jobs.inflight[key] then
    return false
  end
  jobs.inflight[key] = true
  jobs.in_ch:push({
    kind = "file",
    key = key,
    url = url,
    dest = dest,
    ua = jobs.ua,
    timeout = 45,
  })
  return true
end

function jobs.text(key, url)
  if not url or jobs.inflight[key] then
    return false
  end
  jobs.inflight[key] = true
  jobs.in_ch:push({
    kind = "text",
    key = key,
    url = url,
    ua = jobs.ua,
    timeout = 30,
  })
  return true
end

function jobs.poll()
  local out = {}
  while true do
    local msg = jobs.out_ch:pop()
    if not msg then
      break
    end
    jobs.inflight[msg.key] = nil
    out[#out + 1] = msg
  end
  return out
end

function jobs.errors()
  for _, thread in ipairs(jobs.threads) do
    local err = thread:getError()
    if err then
      return err
    end
  end
end

return jobs
