local function factory()
  local set = {}

  function set.insert(element)
    set[element] = true
  end

  function set.erase(element)
    set[element] = nil
  end

  function set.contains(element)
    return set[element] ~= nil
  end

  return set
end

return factory