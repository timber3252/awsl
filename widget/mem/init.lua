local helpers = require('awsl.helpers')
local wibox = require('wibox')
local gmatch, lines, floor = string.gmatch, io.lines, math.floor

--- Construct a simple memory usage meter
--- @param args.widget widget (optional)
--- @param args.timeout number (optional)
local function factory(args)
  args = args or {}

  local mem = {
    widget = args.widget or wibox.widget.textbox(),
    timeout = args.timeout or 2,
  }

  local showPercent = false

  local function render(status)
    if showPercent then
      mem.widget:set_markup_silently(helpers.str.format('<b> %d%%</b> ', status.percent))
    else
      if (status.used < 10000) then
        mem.widget:set_markup_silently(helpers.str.format('<b> %.0fMB</b> ', status.used))
      else
        mem.widget:set_markup_silently(helpers.str.format('<b> %.1fGB</b> ', status.used / 1024))
      end
    end
  end

  local function update()
    local now = {}
    for line in lines("/proc/meminfo") do
      for k, v in gmatch(line, "([%a]+):[%s]+([%d]+).+") do
        if     k == "MemTotal"     then now.total = floor(v / 1024 + 0.5)
        elseif k == "MemFree"      then now.free  = floor(v / 1024 + 0.5)
        elseif k == "Buffers"      then now.buf   = floor(v / 1024 + 0.5)
        elseif k == "Cached"       then now.cache = floor(v / 1024 + 0.5)
        elseif k == "SwapTotal"    then now.swap  = floor(v / 1024 + 0.5)
        elseif k == "SwapFree"     then now.swapf = floor(v / 1024 + 0.5)
        elseif k == "SReclaimable" then now.srec  = floor(v / 1024 + 0.5)
        end
      end
    end

    now.used = now.total - now.free - now.buf - now.cache - now.srec
    now.percent = floor(now.used / now.total * 100)

    render(now)
  end

  mem.widget:connect_signal(
    'button::press',
    function (_, _, _, buttonId)
      showPercent = not showPercent
      update()
    end
  )

  helpers.timer.setInterval(update, mem.timeout)

  return mem
end

return factory