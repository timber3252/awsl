local helpers = require('awsl.helpers')
local awful = require('awful')

local function factory(args)
  args = args or {}
  local autostart = {
    debugMode = args.debugMode or false,
    apps = args.apps or {}
  }
  function autostart.runOnce(cmd)
    local findMe = cmd
    local firstSpace = cmd:find(' ')
    if firstSpace then
      findMe = cmd:sub(0, firstSpace - 1)
    end
    awful.spawn.easy_async_with_shell(
      string.format('pgrep -u $USER -x %s > /dev/null || (%s)', findMe, cmd),
      function(stdout, stderr)
        if not stderr or stderr == '' or not autostart.debugMode then
          return 
        end
        helpers.Error(stderr:gsub('%\n', ''), 'Error detected when starting an application')
      end
    )
  end
  for _, app in ipairs(autostart.apps) do
    autostart.runOnce(app)
  end
end

return factory