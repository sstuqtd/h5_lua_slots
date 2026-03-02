local js = require("js")
local window = js.global
local document = window.document

local now = tonumber(window.Date.now())
math.randomseed(math.floor(now % 2147483647))

Unity = {}

Unity.Debug = {}
function Unity.Debug.Log(message)
  window.console:log(tostring(message))
end
function Unity.Debug.LogWarning(message)
  window.console:warn(tostring(message))
end
function Unity.Debug.LogError(message)
  window.console:error(tostring(message))
end
function Unity.Debug.Assert(condition, message)
  if not condition then
    error(message or "Assertion failed")
  end
end

Unity.Mathf = {}
function Unity.Mathf.Clamp(value, minValue, maxValue)
  if value < minValue then
    return minValue
  end

  if value > maxValue then
    return maxValue
  end

  return value
end
function Unity.Mathf.FloorToInt(value)
  return math.floor(value)
end

Unity.Random = {}
function Unity.Random.Range(minValue, maxValue)
  local minIsInteger = math.type(minValue) == "integer"
  local maxIsInteger = math.type(maxValue) == "integer"
  if minIsInteger and maxIsInteger then
    return math.random(minValue, maxValue - 1)
  end

  return minValue + (maxValue - minValue) * math.random()
end

Unity.Time = {
  deltaTime = 0,
  time = 0,
}

Unity.UI = {}
function Unity.UI.FindById(id)
  return document:getElementById(id)
end
function Unity.UI.SetText(element, text)
  if element then
    element.textContent = tostring(text)
  end
end
function Unity.UI.GetValue(element)
  if element then
    return tostring(element.value)
  end

  return ""
end
function Unity.UI.SetValue(element, value)
  if element then
    element.value = tostring(value)
  end
end
function Unity.UI.BindClick(element, callback)
  if element then
    element.onclick = callback
  end
end
function Unity.UI.BindChange(element, callback)
  if element then
    element.onchange = callback
  end
end

Unity.MonoBehaviour = {}
function Unity.MonoBehaviour:New()
  local instance = {}
  setmetatable(instance, { __index = self })
  return instance
end

Unity.Application = {}
function Unity.Application.Run(behaviour)
  local started = false
  local lastTickMs = tonumber(window.Date.now())

  local function tick()
    local nowMs = tonumber(window.Date.now())
    local deltaSeconds = (nowMs - lastTickMs) / 1000
    lastTickMs = nowMs

    Unity.Time.deltaTime = deltaSeconds
    Unity.Time.time = Unity.Time.time + deltaSeconds

    if not started then
      started = true
      if behaviour.Start then
        behaviour:Start()
      end
    end

    if behaviour.Update then
      behaviour:Update()
    end
  end

  window:setInterval(tick, 16)
end
