local helpers = require('awsl.helpers')
local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")

local function factory(args)
  if awesome.startup_errors then
    helpers.errorOutput(awesome.startup_errors, "Oops, there were errors during startup!")
  end
  do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
      if in_error then return end
      in_error = true
      helpers.errorOutput(tostring(err), "Oops, an error happened!")
      in_error = false
    end)
  end
end

return factory
