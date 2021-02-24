local helpers = require('awsl.helpers')
local awful = require('awful')

local magnifyClient = nil

local function magnify(c, width_f, height_f)
  magnifyClient = c
  c.floating = true
  c.ontop = true
  local s = awful.screen.focused()
  local mg = s.workarea
  local g = {}
  local mwfact = width_f or 0.5
  g.width = math.sqrt(mwfact) * mg.width
  g.height = math.sqrt(height_f or mwfact) * mg.height
  g.x = mg.x + (mg.width - g.width) / 2
  g.y = mg.y + (mg.height - g.height) / 2
  if c then
    c:geometry(g)
  end
end

return function (c, width_f, height_f)
  if magnifyClient == nil or magnifyClient.valid == false then
    magnify(c, width_f, height_f)
    magnifyClient = c
  elseif magnifyClient == c then
    c.floating = false
    c.ontop = false
    magnifyClient = nil
  else
    magnifyClient.floating = false
    magnifyClient.ontop = false
    magnify(c, width_f, height_f)
    magnifyClient = c
  end
end