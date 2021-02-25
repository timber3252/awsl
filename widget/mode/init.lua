local helpers = require('awsl.helpers')
local wibox = require('wibox')
local gears = require('gears')

--- Construct a `mode` widget, `mode` provides a simple solution to
--- implement `vi-like` key bindings
--- @param args.modes table mode data to initialize
--- @param args.defaultMode string the default mode, should be appeared in modes
--- @param args.globalKeys table a table of global keys
--- @param args.widget widget default is wibox.widget.textbox (optional)
--- To switch the mode, you need to define certain keys like the following.
--- And that why `mode` is defined global in the example.
--- ```
--- awful.key( { modKey }, "o", function () mode.setMode('open') end )
--- ```
--- Example:
--- ```
--- mode = require('awsl.widget.mode')({
---   modes = {
---     normal = {
---       text = 'NORMAL',
---       keys = gears.table.join(...),
---     },
---     open = {
---       text = 'OPEN',
---       keys = gears.table.join(...),
---     },
---   },
---   defaultMode = 'normal',
---   globalKeys = gears.table.join(...),
--- })
--- ```
local function factory(args)
  args = args or {}  
  local mode = {
    widget = args.widget or wibox.widget.textbox(),
    modes = args.modes or helpers.log.error('modes is required', 'Errors in `mode` widget'),
    defaultMode = args.defaultMode or helpers.log.error('defaultMode is required', 'Errors in `mode` widget'),
    globalKeys = args.globalKeys or helpers.log.error('globalKeys is required', 'Errors in `mode` widget'),
  }

  local function render(data)
    mode.widget:set_markup_silently('<b> ' .. data .. ' </b>')
  end

  --- Set current mode
  --- @param name string the name of target mode
  --- Example: `mode.setMode('normal')`
  function mode.setMode(name)
    if mode.modes[name] then
      root.keys(gears.table.join(mode.globalKeys, mode.modes[name].keys))
      render(mode.modes[name].text)
    end
  end

  mode.setMode(mode.defaultMode)
  return mode
end

return factory
