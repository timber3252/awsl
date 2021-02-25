local function factory()
  local map = {}

  function map.insert(key, value)
    map[key] = value
  end

  function map.erase(key)
    map[key] = nil
  end

  function map.contains(key)
    return map[key] ~= nil
  end

  function map.get(key)
    return map[key]
  end

  return map
end

return factory