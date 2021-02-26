local helpers = require('awsl.helpers')
local wibox = require('wibox')
local lgi = require('lgi')
local str = require "awsl.helpers.str"
local manager = lgi.Playerctl.PlayerManager()
local render = require('awsl.widget.playerctl.render')

local function getValidPlayers()
  local mprisPlayers = lgi.Playerctl.list_players()
  local map = helpers.map()
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
  playerctl.currentPlayer = nil
  local _playerctlPlayer = nil
  for k, v in ipairs(playerctl.trackedPlayerList) do
    trackedPlayers[k] = {}
    if mprisPlayers.contains(v) then
      trackedPlayers[k].name = v
    end
  end
  mprisPlayers = nil

  local function findFirstTrackedPlayer()
    for i = 1, #playerctl.trackedPlayerList do
      if trackedPlayers[i].name ~= nil then
        return lgi.Playerctl.PlayerName { name = trackedPlayers[i].name }
      end
    end
    return nil
  end

  local function insertTrackedPlayers(player)
    for k, v in ipairs(playerctl.trackedPlayerList) do
      if v == player.name then
        trackedPlayers[k] = {}
        trackedPlayers[k].name = player.name
      end
    end
  end

  local function deleteTrackedPlayers(player)
    for k, v in ipairs(trackedPlayers) do
      if v.name == player.name then
        trackedPlayers[k] = {}
      end
    end
  end

  local function onPlaybackStatus(current, status, _)
    if current ~= nil then
      if playerctl.currentPlayer == nil or current.player_name ~= playerctl.currentPlayer then return end
      render.onStatusChanged(current.player_name, status, playerctl)
    else
      render.onStatusChanged()
    end
  end

  local function onMetadata(current, metadata, _)
    if current ~= nil then
      if playerctl.currentPlayer == nil or current.player_name ~= playerctl.currentPlayer then return end
      render.onSongChanged(
        current.player_name,
        current:get_title(),
        current:get_artist(),
        current:get_album(),
        metadata,
        current
      )
    else
      render.onSongChanged()
    end
  end

  local function onSeeked(current, position, _)
    if current ~= nil then
      if playerctl.currentPlayer == nil or current.player_name ~= playerctl.currentPlayer then return end
      render.onPositionChanged(
        current.player_name,
        position,
        current
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
      playerctl.currentPlayer = nil
      _playerctlPlayer = nil
      updateInitialData(nil, nil)
    else
      if playerctl.currentPlayer == nil or playerctl.currentPlayer ~= player.name then
        playerctl.currentPlayer = player.name

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

        _playerctlPlayer = playerctlPlayer
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

  function playerctl.togglePlayStatus(notify)
    notify = (notify ~= nil and {notify} or {false})[1]
    if playerctl.currentPlayer ~= nil then
      helpers.spawn.exec(helpers.str.format('playerctl -p %s play-pause', playerctl.currentPlayer))
    end
    if notify then
      helpers.log.info({
        title = 'awsl.widget.playerctl',
        text = 'playback status: ' .. _playerctlPlayer.playback_status
      })
    end
  end
  function playerctl.nextTrack(notify)
    notify = (notify ~= nil and {notify} or {false})[1]
    if playerctl.currentPlayer ~= nil then
      helpers.spawn.exec(helpers.str.format('playerctl -p %s next', playerctl.currentPlayer))
    end
    if notify then
      helpers.log.info({
        title = 'awsl.widget.playerctl',
        text = 'next track',
        timeout = 3,
      })
    end
  end
  function playerctl.prevTrack(notify)
    notify = (notify ~= nil and {notify} or {false})[1]
    if playerctl.currentPlayer ~= nil then
      helpers.spawn.exec(helpers.str.format('playerctl -p %s previous', playerctl.currentPlayer))
    end
    if notify then
      helpers.log.info({
        title = 'awsl.widget.playerctl',
        text = 'previous track',
        timeout = 3,
      })
    end
  end

  function playerctl.toggleLyricsMode()
    render.toggleLyricsMode(playerctl.currentPlayer)
    onPlaybackStatus(_playerctlPlayer, _playerctlPlayer.playback_status, manager)
    onMetadata(_playerctlPlayer, _playerctlPlayer.metadata, manager)
    onSeeked(_playerctlPlayer, _playerctlPlayer.position, manager)
  end

  playerctl.widget:connect_signal(
    'button::press',
    function (_, _, _, buttonId)
      if playerctl.currentPlayer == nil then return end
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