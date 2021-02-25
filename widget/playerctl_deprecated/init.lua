local helpers = require('awsl.helpers')
local wibox = require('wibox')
local lyrics = require('awsl.widget.playerctl.lyrics')

--- Construct a `playerctl` widget, `playerctl` displays the current playing song (or lyrics) using `playerctl`
--- @param args.timeout number the interval between checks, default is 0.5 (in seconds) (optional)
--- @param args.trackedPlayerList table a list of players that need to track, which should support `mpris`, default is { "ElectronNCM" } (optional)
--- @param args.lyricsMode boolean whether to open lyrics mode if supported, default is true (optional)
--- @param args.widget widget default is wibox.widget.textbox (optional)
local function factory(args)
  args = args or {}

  local currentValidPlayer = ""

  local playerctl = {
    widget = args.widget or wibox.widget.textbox(),
    timeout = args.timeout or 0.5,
    trackedPlayerList = args.trackedPlayerList or { "ElectronNCM" },
    lyricsMode = (args.lyricsMode ~= nil and {args.lyricsMode} or {true})[1]
  }

  function playerctl.render(status, str, callback)
    if status == "Playing" then
      playerctl.widget:set_markup_silently('<b>契 ' .. str .. '</b> ')
    elseif status == "Paused" then
      playerctl.widget:set_markup_silently('<b> ' .. str .. '</b> ')
    else
      playerctl.widget:set_markup_silently('')
    end
  end

  function playerctl.update(callback)
    for _, v in ipairs(playerctl.trackedPlayerList) do
      local res = os.execute(string.format('playerctl -p "%s" status', v))
      if res == true then
        currentValidPlayer = v
        helpers.spawn.exec(
          string.format('playerctl -p "%s" status', v),
          function (status, _)
            status = string.sub(status, 1, string.len(status) - 1)
            helpers.spawn.exec(
              string.format('playerctl -p "%s" metadata -f "{{artist}} - {{title}}"', v),
              function (song, _)
                song = string.sub(song, 1, string.len(song) - 1)
                if playerctl.lyricsMode and lyrics[v] ~= nil then
                  lyrics[v].getContent(
                    status,
                    song,
                    function (data)
                      playerctl.render(status, data)
                    end
                  )
                else
                  if string.len(song) > 56 then
                    song = status .. '...'
                  end
                  playerctl.render(status, song)
                end
              end
            )
          end
        )
        return
      end
    end
    currentValidPlayer = ""
    playerctl.render('', '')
  end

  --- toggle play status
  function playerctl.toggle()
    helpers.spawn.exec(
      string.format('playerctl -p "%s" play-pause', currentValidPlayer),
      playerctl.update
    )
  end
  
  helpers.timer.setInterval(playerctl.update, playerctl.timeout)
  playerctl.widget:connect_signal(
    'button::press',
    function (_, _, _, buttonId)
      if currentValidPlayer == "" then return end
      local cmd = ""
      if buttonId == 1 then
        cmd = "play-pause"
      elseif buttonId == 2 then
        playerctl.lyricsMode = not playerctl.lyricsMode
      elseif buttonId == 3 then
        cmd = "next"
      elseif buttonId == 4 then
        cmd = "position 5+"
      elseif buttonId == 5 then
        cmd = "position 5-"
      end
      if cmd == "" then return end
      helpers.spawn.exec(
        string.format('playerctl -p "%s" %s', currentValidPlayer, cmd),
        playerctl.update
      )
    end
  )

  return playerctl
end

return factory