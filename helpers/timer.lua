local gears = require('gears')
local log = require('awsl.helpers.log')
local timer = {}

--- Schedules a function to execute **every time** a given number of **seconds** elapses.
function timer.setInterval(fn, timeout, startnow)
  return gears.timer({
    timeout = timeout,
    call_now = (startnow ~= nil and {startnow} or {true})[1],
    autostart = true,
    callback = fn,
  })
end

--- Schedules a function to execute in a given amount of time (in **seconds**).
function timer.setTimeout(fn, timeout)
  local count = 0
  gears.timer.start_new(
    timeout,
    function ()
      if count == 1 then
        fn()
        count = nil
        return false
      end
      count = count + 1
      return true
    end
  )
end

return timer