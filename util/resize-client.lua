local awful = require('awful')
local floating_resize_amount = 50
local tiling_resize_factor = 0.05

--- Resize a client in given direction
--- @param c client given client
--- @param direction string "up", "down", "left", "right", represents the direction of resize
--- Example:
--- ```
--- require('awsl.util.resize-client')(c, "up")
--- ```
local function factory(c, direction)
  if awful.layout.get(mouse.screen) == awful.layout.suit.floating or (c and c.floating) then
    if direction == "up" then
      c:relative_move(0, 0, 0, -floating_resize_amount)
    elseif direction == "down" then
      c:relative_move(0, 0, 0, floating_resize_amount)
    elseif direction == "left" then
      c:relative_move(0, 0, -floating_resize_amount, 0)
    elseif direction == "right" then
      c:relative_move(0, 0, floating_resize_amount, 0)
    end
  else
    if direction == "up" then
      awful.client.incwfact(-tiling_resize_factor)
    elseif direction == "down" then
      awful.client.incwfact(tiling_resize_factor)
    elseif direction == "left" then
      awful.tag.incmwfact(-tiling_resize_factor)
    elseif direction == "right" then
      awful.tag.incmwfact(tiling_resize_factor)
    end
  end
end

return factory