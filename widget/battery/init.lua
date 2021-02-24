local helpers = require('awsl.helpers')
local wibox = require('wibox')

-- acpi sample outputs
-- Battery 0: Discharging, 75%, 01:51:38 remaining
-- Battery 0: Charging, 53%, 00:57:43 until charged

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
  }

  function bat.render(data)
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
    bat.widget:set_markup_silently(icon .. '<b>' .. data .. '</b> ')
  end

  function bat.update()
    helpers.asyncWithShell(
      "acpi | sed -n 's/^.*, \\([0-9]*\\)%/\\1/p'",
      function (stdout, _)
        stdout = string.sub(stdout, 1, string.len(stdout) - 1)
        if stdout.find(stdout, 'remaining') ~= nil then
          bat.render(stdout)
          bat.status = "Discharging"
          bat.powersave = true
        elseif stdout.find(stdout, 'until charged') ~= nil then
          bat.status = "Charging"
          bat.powersave = false
          if not bat.hiddenWhileCharging then
            bat.render(stdout)
          else
            bat.render(nil)
          end
        else
          bat.render(nil)
          bat.status = "Full"
          bat.powersave = false
        end
      end
    )
  end

  helpers.setInterval('battary', bat.timeout, bat.update)

  return bat
end

return factory