local awful = require('awful')
local gears = require('gears')
local naughty = require('naughty')
local debug = require("debug")
local beautiful = require('beautiful')

local helpers = {}

helpers.moduleDir = debug.getinfo(1, 'S').source:match[[^@(.*/).*$]]
helpers.scriptsDir = helpers.moduleDir .. 'scripts/'

function helpers.dpi(num)
  return beautiful.xresources.apply_dpi(num)
end

function helpers.errorOutput(str, title)
  naughty.notify({
    preset = naughty.config.presets.critical,
    title = title or "Error",
    text = str
  })
end

function helpers.debugOutput(str)
  naughty.notify({
    title = "Debug Output",
    text = str
  })
end

function helpers.fileExists(path)
  local file = io.open(path, 'rb')
  if file then file:close() end
  return file ~= nil
end

function helpers.linesFrom(path)
  local lines = {}
  for line in io.lines(path) do
    lines[#lines + 1] = line
  end
  return lines
end

helpers.timerTable = {}

function helpers.newTimer(name, timeout, fun, nostart, stoppable)
  if not name or #name == 0 then return end
  name = (stoppable and name) or timeout
  if not helpers.timerTable[name] then
      helpers.timerTable[name] = gears.timer({ timeout = timeout })
      helpers.timerTable[name]:start()
  end
  helpers.timerTable[name]:connect_signal("timeout", fun)
  if not nostart then
      helpers.timerTable[name]:emit_signal("timeout")
  end
  return stoppable and helpers.timerTable[name]
end

function helpers.setInterval(name, timeout, fun)
  return helpers.newTimer(name, timeout, fun)
end

function helpers.async(cmd, callback)
  return awful.spawn.easy_async(
    cmd,
    function (stdout, _, _, exit_code)
      callback(stdout, exit_code)
    end
  )
end

function helpers.asyncWithShell(cmd, callback)
  return awful.spawn.easy_async_with_shell(
    cmd,
    function (stdout, _, _, exit_code)
      callback(stdout, exit_code)
    end
  )
end

return helpers