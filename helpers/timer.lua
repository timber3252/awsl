local gears = require('gears')
local log = require('awsl.helpers.log')
local timer = {}

--- Schedules a function to execute **every time** a given number of **seconds** elapses.
function timer.setInterval(fn, timeout)
  gears.timer({
    timeout = timeout,
    call_now = true,
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

timer.timerTable = {}

--- Stoppable timer, requires name as label
--- @param fun function callback function
--- @param timeout number interval between executions (in **seconds**)
--- @param name string label
--- @param nostart boolean whether to start right now
--- Return a timer, you could use `ret:stop()` to stop a timer
function timer.setTimer(fun, timeout, name, nostart)
  if not name or #name == 0 then return end
  if not timer.timerTable[name] then
    timer.timerTable[name] = gears.timer({ timeout = timeout })
    timer.timerTable[name]:start()
  end
  timer.timerTable[name]:connect_signal("timeout", fun)
  if not nostart then
    timer.timerTable[name]:emit_signal("timeout")
  end
  return timer.timerTable[name]
end

return timer