local helpers = require('awsl.helpers')
local wibox = require('wibox')

--- Construct a `battery` widget, `battery` displays the current power status using `acpi`
--- @param args.timeout number the interval between checks, default is 5 (in seconds) (optional)
--- @param args.icons table icons, it should have five stats from low to high (optional)
--- @param args.hiddenWhileCharging boolean if hides when charging, default is true (optional)
--- @param args.lowPowerWarningColor string a color uses as the warning color when power is low (optional)
--- @param args.lowPowerThreshold number the threshold of low power warning (optional)
--- @param args.widget widget default is wibox.widget.textbox (optional)
--- It doesn't support multi-battery.
local function factory(args)
  args = args or {}

  local bat = {
    widget = args.widget or wibox.widget.textbox(),
    timeout = args.timeout or 5,
    icons = args.icons or {
      [1] = '<b> </b>',
      [2] = '<b> </b>',
      [3] = '<b> </b>',
      [4] = '<b> </b>',
      [5] = '<b> </b>',
    },
    hiddenWhileCharging = args.hiddenWhileCharging or true,
    status = "",
    powersave = false,
    lowPowerWarningColor = args.lowPowerWarningColor or '#F48FB1',
    lowPowerThreshold = args.lowPowerThreshold or 20,
  }

  local function render(data)
    if data == nil then
      bat.widget:set_markup_silently("")
      return
    end
    local pos = string.find(data, ',')
    local percent = tonumber(string.sub(data, 1, pos - 1))
    local icon = ""
    if percent >= 0 and percent < 15 then
      icon = bat.icons[1]
    elseif percent >= 15 and percent < 40 then
      icon = bat.icons[2]
    elseif percent >= 40 and percent < 60 then
      icon = bat.icons[3]
    elseif percent >= 60 and percent < 80 then
      icon = bat.icons[4]
    elseif percent >= 80 and percent <= 100 then
      icon = bat.icons[5]
    end
    local data = icon .. '<b>' .. data .. '</b> '
    if percent >= 0 and percent < battery.lowPowerThreshold then
      data = string.format('<span color="%s"> %s </span>', battery.lowPowerWarningColor, data)
    end
    bat.widget:set_markup_silently(data)
  end

  local function update()
    helpers.spawn.exec(
      'acpi | sed -n "s/^.*, \\([0-9]*\\)%/\\1/p"',
      function (stdout, _)
        stdout = string.sub(stdout, 1, string.len(stdout) - 1)
        if stdout.find(stdout, 'remaining') ~= nil then
          render(stdout)
          bat.status = "Discharging"
          bat.powersave = true
        elseif stdout.find(stdout, 'until charged') ~= nil then
          bat.status = "Charging"
          bat.powersave = false
          if not bat.hiddenWhileCharging then
            render(stdout)
          else
            render(nil)
          end
        else
          render(nil)
          bat.status = "Full"
          bat.powersave = false
        end
      end
    )
  end

  helpers.timer.setInterval(update, bat.timeout)

  return bat
end

return factory