local naughty = require('naughty')

local log = {}

--- Display message using naughty notification
--- @param args.text string
--- @param args.title string
--- @param args.timeout integer
--- @param args.icon string path to icon
function log.info(args)
  naughty.notify(args)
end

--- Display debug message using naughty notification
function log.debug(data)
  naughty.notify({
    title = "Debug",
    text = data
  })
end

--- Display error message using naughty notification
function log.error(err, title)
  naughty.notify({
    preset = naughty.config.presets.critical,
    title = title or "Error",
    text = err
  })
end

return log