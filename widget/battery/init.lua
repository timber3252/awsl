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
    lowPowerWarningColor = args.lowPowerWarningColor or '#F48FB1',
    lowPowerThreshold = args.lowPowerThreshold or 20,
  }

  local currentStatus = nil
  local currentPower = nil
  local currentWarningStatus = false

  local function render(text)
    if text == nil then
      bat.widget:set_markup_silently('')
      return
    end
    local percent = tonumber(text)
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

    local data = icon .. '<b>' .. text .. '</b> '
    if percent >= 0 and percent < bat.lowPowerThreshold then
      data = string.format('<span color="%s">%s</span>', bat.lowPowerWarningColor, data)
    end
    bat.widget:set_markup_silently(data)
  end

  local function onStatusChanged(status)
    -- do nothing
  end

  local function onPercentChanged(status, percent)
    if status == 'discharging' then
      if currentWarningStatus == false and tonumber(percent) < bat.lowPowerThreshold then
        currentWarningStatus = true
        helpers.log.warning({
          title = 'awsl.widget.battery',
          text = 'low-battery alert'
        })
      end
      render(percent)
    elseif status == 'charging' then
      if currentWarningStatus == true and tonumber(percent) >= bat.lowPowerThreshold then
        currentWarningStatus = false
      end
      render(nil)
    else
      render(nil)
    end
  end

  local function timeUpdate()
    helpers.spawn.exec(
      'acpi | sed -n "s/^.*, \\([0-9]*\\)%/\\1/p"',
      function (stdout, _)
        stdout = string.sub(stdout, 1, string.len(stdout) - 1)
        if stdout.find(stdout, 'remaining') ~= nil then
          local first = (currentStatus == nil)
          currentPower = helpers.str.split(stdout, ',')[1]
          if currentStatus ~= 'discharging' then
            currentStatus = 'discharging'
            onStatusChanged(currentStatus)
            if not first then
              helpers.log.info({
                title = 'awsl.widget.battery',
                text = 'status changed: discharging' .. '\n' .. stdout
              })
            end
          end
          onPercentChanged(currentStatus, currentPower)
        elseif stdout.find(stdout, 'until charged') then
          local first = (currentStatus == nil)
          currentPower = helpers.str.split(stdout, ',')[1]
          if currentStatus ~= 'charging' then
            currentStatus = 'charging'
            onStatusChanged(currentStatus)
            if not first then
              helpers.log.info({
                title = 'awsl.widget.battery',
                text = 'status changed: charging' .. '\n' .. stdout
              })
            end
          end
          onPercentChanged(currentStatus, currentPower)
        else
          if helpers.str.find(stdout,'zero rate') == nil then
            -- helpers.log.error(stdout)
          end
        end
      end
    )
  end

  helpers.timer.setInterval(timeUpdate, bat.timeout)

  return bat
end

return factory