local awful = require('awful')

local spawn = {}

--- Spawn a program, and optionally run a callback
--- @param callback function(stdout, exitcode)
function spawn.exec(cmd, callback)
  return awful.spawn.easy_async_with_shell(
    cmd,
    function (stdout, _, _, exit_code)
      if type(callback) == 'function' then
        callback(stdout, exit_code)
      end
    end
  )
end

--- Spawn a program and asynchronously capture its output line by line.
--- @param callback function(line)
function spawn.execWithLineCallback(cmd, callback)
  return awful.spawn.with_line_callback(
    cmd,
    {
      stdout = function (line)
        if type(callback) == 'function' then
          callback(line)
        end
      end
    }
  )
end

--- Spawn a command if it has not been spawned before.
--- @param callback function(stdout, exitcode)
--- Use `pgrep` to check whether a program has already started
function spawn.execOnce(cmd, callback)
  local findMe = cmd
  local firstSpace = cmd:find(' ')
  if firstSpace then
    findMe = cmd:sub(0, firstSpace - 1)
  end
  awful.spawn.easy_async_with_shell(
    string.format('pgrep -u $USER -x %s > /dev/null || (%s)', findMe, cmd),
    function(stdout, _, _, exitcode)
      if type(callback) == 'function' then
        callback(stdout, exitcode)
      end
    end
  )
end

return spawn