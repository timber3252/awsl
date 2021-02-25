local helpers = require('awsl.helpers')

--- Run given applications automatically, some would be ignored if they have already started
--- @param args.apps table applications in a table
--- Example:
--- ```
--- require('awsl.util.autostart')({
---   apps = { 'nm-applet', 'redshift', 'picom -b' }
--- })
--- ```
local function factory(args)
  args = args or {}
  local apps = args.apps or {}

  for _, app in ipairs(apps) do
    helpers.spawn.execOnce(app)
  end
end

return factory