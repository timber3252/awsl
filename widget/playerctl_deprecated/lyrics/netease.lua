local env = require('awsl.env')
local helpers = require('awsl.helpers')

local netease = {}
local currentSong = ""
local currentLyrics = {}

function netease.getLyrics(callback)
  if currentLyrics[-1] == currentSong then
    callback()
    return
  end
  helpers.spawn.exec(
    'playerctl metadata -p "ElectronNCM" -f "{{mpris:trackid}}" | sed "s/\'//g" | python ' .. env.scriptsDir .. 'netease_lyrics_helper.py',
    function (stdout, exitcode)
      currentLyrics = {}
      currentLyrics[-1] = currentSong
      if exitcode == 1 then
        callback()
        return
      end
      local res = {}
      string.gsub(stdout, '[^'.. '\n' ..']+', function(w) table.insert(res, w) end)
      for _, s in ipairs(res) do
        local pos = string.find(s, '#')
        currentLyrics[tonumber(string.sub(s, 1, pos - 1))] = string.sub(s, pos + 1)
      end
      callback()
    end
  )
end

function netease.getContent(_, song, callback)
  currentSong = song
  netease.getLyrics(function ()
    helpers.spawn.exec(
      'playerctl -p "ElectronNCM" position',
      function(stdout, exitcode)
        stdout = string.sub(stdout, 1, string.len(stdout) - 1)
        local res, mx = currentLyrics[-1], -1
        for k, v in pairs(currentLyrics) do
          if k < tonumber(stdout) and k > mx then
            mx, res = k, v
          end
        end
        callback(res)
      end
    )
  end)
end

return netease