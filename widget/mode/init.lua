local helpers = require('awsl.helpers')
local wibox = require('wibox')
local gears = require('gears')

local function factory(args)
  args = args or {}
  local mode = {
    widget = args.widget or wibox.widget.textbox(),
    modes = args.modes or nil,
    defaultMode = args.defaultMode or nil,
    globalKeys = args.globalKeys or {}
  }
  if mode.modes == nil or mode.defaultMode == nil then
    helpers.errorOutput('awsl.widget.mode: missing mode arguments')
    return
  end

  function mode.render(data)
    mode.widget:set_markup_silently('<b> ' .. data .. ' </b>')
  end

  function mode.setMode(name)
    if mode.modes[name] then
      root.keys(gears.table.join(mode.globalKeys, mode.modes[name].keys))
      mode.render(mode.modes[name].text)
    end
  end

  mode.setMode(mode.defaultMode)
  return mode
end

return factory