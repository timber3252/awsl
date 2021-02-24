local awful= require('awful')

return function (menu, args)
  local clsTags = awful.screen.focused().selected_tags
  if clsTags == nil then return nil end
  local result = {}
  for i = 1, #clsTags do
    local t = clsTags[i]
    local cls = t:clients()

    for _, c in pairs(cls) do
      result[#result + 1] = {
        awful.util.escape(c.name) or "",
        function ()
          c.minimized = false
          client.focus = c
          c:raise()
        end,
        c.icon
      }
    end
  end

  if #result <= 0 then return nil end
  if not menu then menu = {} end
  menu.items = result
  local m = awful.menu(menu)
  m:show(args)
  return m
end
