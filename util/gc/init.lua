local helpers = require('awsl.helpers')

local function factory(args)
  local timeout = args.timeout or 60
  helpers.setInterval(
    'garbage-collect',
    timeout,
    function ()
      collectgarbage('collect')
    end
  )
end

return factory
