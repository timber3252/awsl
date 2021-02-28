local helpers = require('awsl.helpers')
local wibox = require('wibox')
local beautiful = require('beautiful')

--- Construct a simple cpu usage meter
--- @param args.widget widget (optional)
--- @param args.timeout number (optional)
local function factory(args)
  args = args or {}

  local cpu = {
    timeout = args.timeout or 2,
    widget = args.widget or wibox.widget.textbox()
  }

  local total_prev = 0
  local idle_prev = 0

  local function render(percent)
    if percent < 10 then
      cpu.widget:set_markup_silently(helpers.str.format('<b> %.2f%% </b>', percent))
    elseif percent < 100 then
      cpu.widget:set_markup_silently(helpers.str.format('<b> %.1f%% </b>', percent))
    else
      cpu.widget:set_markup_silently(helpers.str.format('<b> %.0f%% </b>', percent))
    end
  end

  local function update()
    helpers.spawn.exec(
      'head -1 /proc/stat',
      function (stdout)
        local user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice =
			    stdout:match('(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s')
        local total = user + nice + system + idle + iowait + irq + softirq + steal
        local diff_idle = idle - idle_prev
        local diff_total = total - total_prev
        local diff_usage = (1000 * (diff_total - diff_idle) / diff_total + 5) / 10

        total_prev = total
        idle_prev = idle

        render(diff_usage)
        collectgarbage('collect')
      end
    )
  end

  helpers.timer.setInterval(update, cpu.timeout)

  return cpu
end

return factory

