local str = {}

---{{{ Native Lua Functions

str.upper = string.upper
str.lower = string.lower
str.gsub = string.gsub
str.find = string.find
str.reverse = string.reverse
str.format = string.format
str.len = string.len
str.rep = string.rep
str.gmatch = string.gmatch
str.match = string.match
str.sub = string.sub

---}}}

---{{{ utilities

--- Returns a set of **non-empty** strings separated between `sep`
function str.split(s, sep)
  sep = sep or ' '
  local res = {}
  local pattern = string.format("([^%s]+)", sep)
  str.gsub(s, pattern, function(w) table.insert(res, w) end)
  return res
end

--- Returns a string that removes whitespace from both ends of the given string
function str.trim(s)
  return str.match(s, '^%s*(.-)%s*$')
end

--- Returns the position (begin and end) of the first occurrence of specified character(s) in a string
function str.indexOf(s, pattern, startPos)
  return str.find(s, pattern, startPos or 1)
end

--- Returns the position (begin and end) of the last occurrence of specified character(s) in a string
function str.lastIndexOf(s, pattern, startPos)
  return str.find(s, str.format('%s[^%s]*$', pattern, pattern), startPos or 1)
end

--- Returns a string in which the string elements of sequence have been joined by str separator
function str.join(tbl, ch)
  return table.concat(tbl, ch or ' ')
end

---}}}

return str