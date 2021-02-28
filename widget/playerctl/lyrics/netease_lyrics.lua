local helpers = require('awsl.helpers')
local str = helpers.str
local http = require('socket.http')

local netease = {}
local lyrics = {}
local currentLine = 1

local function calcTimestamp(s)
  local res = str.split(s, ':')
  return tonumber(res[1]) * 60 + tonumber(res[2])
end

--- TODO: async using coroutine
local function fetchLyrics(id, length)
  local data = ""
  local ok, statusCode, headers, statusText = http.request {
    method = 'GET',
    url = 'http://music.163.com/api/song/lyric?&lv=-1&kv=-1&tv=-1&id=' .. id,
    sink = function (chunk)
      if chunk ~= nil then
        data = data .. chunk
      end
      return true
    end
  }
  if statusCode == 200 then
    local content = helpers.json.parse(data).lrc
    lyrics = {}
    if content == nil then return false end
    content = helpers.json.parse(data).lrc.lyric
    lyrics[1] = {
      start = -1,
      data = '...',
    }
    for i, v in ipairs(str.split(content, '\n')) do
      local res = str.split(str.sub(v, 2), ']')
      lyrics[i + 1] = {
        start = calcTimestamp(res[1]),
        data = res[2] or '...',
      }
    end
    for i = 1, #lyrics - 1 do
      lyrics[i].timeout = lyrics[i + 1].start - lyrics[i].start
    end
    lyrics[#lyrics].timeout = length / 1000000 - lyrics[#lyrics].start
    return true
  else
    helpers.log.error('failed to fetch lyrics', 'netease lyrics')
    return false
  end
end

local function refreshPlayStatus(playerctl, pos)
  local position = (pos ~= nil and {pos} or {playerctl.position / 1000000})[1]
  for i = 1, #lyrics do
    if position >= lyrics[i].start and position < lyrics[i].start + lyrics[i].timeout then
      currentLine = i
      return
    end
  end
  currentLine = #lyrics
end

local function update(contentBox, playerctl)
  local position = playerctl.position / 1000000
  while 1 <= currentLine and currentLine <= #lyrics and position >= lyrics[currentLine].start + lyrics[currentLine].timeout do
    currentLine = currentLine + 1
  end
  if 1 <= currentLine and currentLine <= #lyrics and position >= lyrics[currentLine].start then
    contentBox.setMarkup(lyrics[currentLine].data)
    contentBox:setSpeed(str.len(lyrics[currentLine].data) * 5)
    contentBox.resetScrolling()
    currentLine = currentLine + 1
  end
  if currentLine > #lyrics then
    contentBox:setSpeed(nil)
    contentBox.setMarkup()
  end
end

local function stopTimer()
  if netease.timer ~= nil then
    netease.timer:stop()
    netease.timer = nil
  end
end

local function refresh(contentBox, playerctl, pos)
  stopTimer()
  refreshPlayStatus(playerctl, pos)
  netease.timer = helpers.timer.setInterval(
    function ()
      update(contentBox, playerctl)
    end,
    0.2,
    false
  )
end

function netease.onSongChanged(contentBox, title, artist, _, raw, playerctl)
  if fetchLyrics(
    str.split(raw.value['mpris:trackid'], '/')[4],
    raw.value['mpris:length']
  ) then
    refresh(contentBox, playerctl, 0)
  else
    stopTimer()
    contentBox:setSpeed(nil)
    if artist and title then
      contentBox.setMarkup(artist .. ' - ' .. title)
    else
      contentBox.setMarkup()
    end
  end
end

function netease.onPositionChanged(contentBox, _, playerctl)
  if #lyrics ~= 0 then
    refresh(contentBox, playerctl)
  end
end

function netease.onReset()
  stopTimer()
end

return netease
