local helpers = require('awsl.helpers')
local wibox = require('wibox')
local lgi = require('lgi')
local str = require "awsl.helpers.str"
local manager = lgi.Playerctl.PlayerManager()
local render = require('awsl.widget.playerctl.render')

local function getValidPlayers()
  local map = helpers.map()
  local mprisPlayers = lgi.Playerctl.list_players()
  for i = 1, #mprisPlayers do
    map.insert(mprisPlayers[i].name, mprisPlayers[i])
  end
  return map
end

--- Construct a `playerctl` widget, `playerctl` displays the current playing song (or lyrics) using `playerctl`
--- @param args.timeout number the interval between checks, default is 0.5 (in seconds) (optional)
--- @param args.trackedPlayerList table a list of players that need to track, which should support `mpris`, default is { "ElectronNCM" } (optional)
--- @param args.lyricsMode boolean whether to open lyrics mode if supported, default is true (optional)
--- @param args.defaultSpeed number speed for scrolling when content is too long (optional)
--- @param args.maxContentWidth number max width of the content part (optional)
local function factory(args)
  args = args or {}

  render.init(args)

  local playerctl = {
    widget = render.widget,
    timeout = args.timeout or 0.5,
    trackedPlayerList = args.trackedPlayerList or { "ElectronNCM" }
  }

  local mprisPlayers = getValidPlayers()
  local trackedPlayers = {}
  local currentPlayer = nil
  for k, v in ipairs(playerctl.trackedPlayerList) do
    if mprisPlayers.contains(v) then
      trackedPlayers[k] = mprisPlayers.get(v)
    end
  end

  local function findFirstTrackedPlayer()
    for i = 1, #playerctl.trackedPlayerList do
      if trackedPlayers[i] ~= nil then
        return trackedPlayers[i]
      end
    end
    return nil
  end

  local function insertTrackedPlayers(player)
    for k, v in ipairs(playerctl.trackedPlayerList) do
      if v == player.name then
        trackedPlayers[k] = player
      end
    end
  end

  local function deleteTrackedPlayers(player)
    for k, v in ipairs(trackedPlayers) do
      if v.name == player.name then
        trackedPlayers[k] = nil
      end
    end
  end

  local function onPlaybackStatus(playerctl, status, _)
    if playerctl ~= nil then
      render.onStatusChanged(playerctl.player_name, status, playerctl)
    else
      render.onStatusChanged()
    end
  end

  local function onMetadata(playerctl, metadata, _)
    if playerctl ~= nil then
      render.onSongChanged(
        playerctl.player_name,
        helpers.str.trim(playerctl:get_title()),
        helpers.str.trim(playerctl:get_artist()),
        helpers.str.trim(playerctl:get_album()),
        metadata,
        playerctl
      )
    else
      render.onSongChanged()
    end
  end

  local function onSeeked(playerctl, position, _)
    if playerctl ~= nil then
      render.onPositionChanged(
        playerctl.player_name,
        position,
        playerctl
      )
    else
      render.onPositionChanged()
    end
  end

  local function updateInitialData(playerctlPlayer, manager)
    if playerctlPlayer == nil then
      onPlaybackStatus()
      onMetadata()
      onSeeked()
    else
      onPlaybackStatus(playerctlPlayer, playerctlPlayer.playback_status, manager)
      onMetadata(playerctlPlayer, playerctlPlayer.metadata, manager)
      onSeeked(playerctlPlayer, playerctlPlayer.position, manager)
    end
  end

  local function followPlayer(player)
    if player == nil then
      currentPlayer = nil
      updateInitialData(nil, manager)
    else
      if currentPlayer == nil or currentPlayer ~= player.name then
        currentPlayer = player.name

        local playerctlPlayer = lgi.Playerctl.Player.new_from_name(player)
        function playerctlPlayer:on_playback_status(status, manager)
          onPlaybackStatus(playerctlPlayer, status, manager)                    
        end
        function playerctlPlayer:on_metadata(metadata, manager)
          onMetadata(playerctlPlayer, metadata, manager)
        end
        function playerctlPlayer:on_seeked(position, manager)
          onSeeked(playerctlPlayer, position, manager)
        end

        manager:manage_player(playerctlPlayer)
        updateInitialData(playerctlPlayer, manager)
      end
    end
  end

  local function onNameAppeared(_, player)
    insertTrackedPlayers(player)
    followPlayer(findFirstTrackedPlayer())
  end

  local function onNameVanished(_, player)
    deleteTrackedPlayers(player)
    followPlayer(findFirstTrackedPlayer())
  end

  followPlayer(findFirstTrackedPlayer())

  function manager:on_name_appeared(player) onNameAppeared(manager, player) end
  function manager:on_name_vanished(player) onNameVanished(manager, player) end
  manager.on_name_appeared:connect('name-appeared')
  manager.on_name_vanished:connect('name-vanished')

  function playerctl.togglePlayStatus()
    helpers.spawn.exec(helpers.str.format('playerctl -p %s play-pause', currentPlayer))
  end
  function playerctl.nextTrack()
    helpers.spawn.exec(helpers.str.format('playerctl -p %s next', currentPlayer))
  end
  function playerctl.prevTrack()
    helpers.spawn.exec(helpers.str.format('playerctl -p %s previous', currentPlayer))
  end

  --- TODO: doesn't work
  function playerctl.toggleLyricsMode()
    render.lyricsMode = not render.lyricsMode
    render.setSpeed(nil)
  end

  playerctl.widget:connect_signal(
    'button::press',
    function (_, _, _, buttonId)
      if currentPlayer == nil then return end
      if buttonId == 1 then
        playerctl.togglePlayStatus()
      elseif buttonId == 3 then
        playerctl.toggleLyricsMode()
      elseif buttonId == 4 then
        playerctl.nextTrack()
      elseif buttonId == 5 then
        playerctl.prevTrack()
      end
    end
  )

  return playerctl
end

return factory