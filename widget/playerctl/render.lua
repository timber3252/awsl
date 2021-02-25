local wibox = require('wibox')
local lyrics = require('awsl.widget.playerctl.lyrics')
local helpers = require('awsl.helpers')

--- {{{ Prepare widgets

local settings = {}
local render = {}
render.widget = nil

local statusBox = wibox.widget {
  markup = '',
  widget = wibox.widget.textbox
}

local contentBox = wibox.widget {
  markup = '',
  widget = wibox.widget.textbox
}

local scrollContainer = wibox.widget {
  layout = wibox.container.scroll.horizontal,
  step_function = function (elapsed, size, visible_size, speed)
    local state = ((elapsed * speed)) / size
    if state > 1 then
        return (size - visible_size)
    end
    if state < 1/3 then
        -- In the first 1/3rd of time, do a quadratic increase in speed
        state = 2 * state * state
    elseif state < 2/3 then
        -- In the center, do a linear increase. That means we need:
        -- If state is 1/3, result is 2/9 = 2 * 1/3 * 1/3
        -- If state is 2/3, result is 7/9 = 1 - 2 * (1 - 2/3) * (1 - 2/3)
        state = 5/3*state - 3/9
    elseif state <= 1 then
        -- In the last 1/3rd of time, do a quadratic decrease in speed
        state = 1 - 2 * (1 - state) * (1 - state)
    end
    return (size - visible_size) * state
  end,
  extra_space = 100,
  contentBox,
}

function render.setSpeed(num)
  if num ~= nil then
    scrollContainer.speed = num
  else
    scrollContainer.speed = settings.defaultSpeed
  end
end

function contentBox.resetScrolling()
  scrollContainer:reset_scrolling()
  scrollContainer:emit_signal("widget::redraw_needed")
end

function contentBox:setSpeed(num)
  render.setSpeed(num)
end

function render.init(args)
  args = args or {}

  settings.maxContentWidth = args.maxContentWidth or 600
  settings.defaultSpeed = args.defaultSpeed or 60
  settings.lyricsMode = (args.lyricsMode ~= nil and {args.lyricsMode} or {true})[1]

  scrollContainer.max_size = settings.maxContentWidth
  scrollContainer.speed = settings.defaultSpeed

  render.widget = wibox.widget {
    layout = wibox.layout.align.horizontal,
    expand = 'none',
    nil,
    {
      layout = wibox.layout.fixed.horizontal,
      statusBox,
      scrollContainer,
    }
  }
end
--- }}}

--- {{{ Render Process

function render.onStatusChanged(playerName, status, playerctl)
  if playerName == nil then
    statusBox:set_markup_silently('')
    return
  end
  if settings.lyricsMode and lyrics[playerName] and lyrics[playerName].onStatusChanged then
    lyrics[playerName].onStatusChanged(statusBox, status, playerctl)
    return
  end
  if status == "PLAYING" then
    statusBox:set_markup_silently('<b>契</b> ')
  elseif status == "PAUSED" or status == "STOPPED" then
    statusBox:set_markup_silently('<b></b> ')
  else
    statusBox:set_markup_silently('')
  end
end

function render.onSongChanged(playerName, title, artist, album, raw, playerctl)
  if playerName == nil then
    contentBox:set_markup_silently('')
    return
  end
  if settings.lyricsMode and lyrics[playerName] and lyrics[playerName].onSongChanged then
    lyrics[playerName].onSongChanged(contentBox, title, artist, album, raw, playerctl)
    return
  end
  contentBox:set_markup_silently(helpers.str.format('<b>%s - %s</b> ', artist, title))
end

function render.onPositionChanged(playerName, position, playerctl)
  if settings.lyricsMode and lyrics[playerName] and lyrics[playerName].onPositionChanged then
    lyrics[playerName].onPositionChanged(contentBox, position, playerctl)
    return
  end
end

--- }}}

return render