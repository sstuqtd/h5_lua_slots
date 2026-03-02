local js = require("js")
local window = js.global
local document = window.document

local function createClass(className, baseClass)
  local class = { __name = className }
  class.__index = class
  setmetatable(class, { __index = baseClass })

  function class:New()
    local instance = setmetatable({}, class)
    if instance.enabled == nil then
      instance.enabled = true
    end
    return instance
  end

  function class:TypeName()
    return self.__name or "UnnamedClass"
  end

  function class:Extend(childName)
    return createClass(childName, self)
  end

  return class
end

local function getBaseClass(class)
  local meta = getmetatable(class)
  if not meta then
    return nil
  end

  if type(meta.__index) == "table" then
    return meta.__index
  end

  return nil
end

local function isSubclassOf(class, baseClass)
  local current = class
  while current do
    if current == baseClass then
      return true
    end
    current = getBaseClass(current)
  end
  return false
end

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
  frameCount = 0,
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

Unity.Object = createClass("Object", nil)
Unity.Component = Unity.Object:Extend("Component")
function Unity.Component:GetComponent(componentClass)
  if not self.gameObject then
    return nil
  end

  return self.gameObject:GetComponent(componentClass)
end
function Unity.Component:AddComponent(componentClass)
  Unity.Debug.Assert(self.gameObject, "Component has no gameObject")
  return self.gameObject:AddComponent(componentClass)
end

Unity.MonoBehaviour = Unity.Component:Extend("MonoBehaviour")

Unity.GameObject = {}
Unity.GameObject.__index = Unity.GameObject
function Unity.GameObject.New(name)
  local instance = {
    name = name or "GameObject",
    activeSelf = true,
    _components = {},
  }
  setmetatable(instance, Unity.GameObject)
  return instance
end

function Unity.GameObject:AddExistingComponent(component)
  Unity.Debug.Assert(type(component) == "table", "component instance is required")
  component.gameObject = self
  if component.enabled == nil then
    component.enabled = true
  end
  table.insert(self._components, component)

  if component.Awake then
    component:Awake()
  end

  return component
end

function Unity.GameObject:AddComponent(componentClass)
  Unity.Debug.Assert(type(componentClass) == "table", "AddComponent expects class table")

  local component
  if componentClass.New then
    component = componentClass:New()
  else
    component = setmetatable({}, { __index = componentClass })
  end

  return self:AddExistingComponent(component)
end

function Unity.GameObject:GetComponent(componentClass)
  for _, component in ipairs(self._components) do
    if componentClass == nil or isSubclassOf(getmetatable(component), componentClass) then
      return component
    end
  end

  return nil
end

function Unity.GameObject:GetComponents(componentClass)
  local result = {}
  for _, component in ipairs(self._components) do
    if componentClass == nil or isSubclassOf(getmetatable(component), componentClass) then
      table.insert(result, component)
    end
  end

  return result
end

Unity.Scene = {}
Unity.Scene.__index = Unity.Scene
function Unity.Scene.New(name)
  local instance = {
    name = name or "Scene",
    _gameObjects = {},
  }
  setmetatable(instance, Unity.Scene)
  return instance
end

function Unity.Scene:CreateGameObject(name)
  local gameObject = Unity.GameObject.New(name)
  table.insert(self._gameObjects, gameObject)
  return gameObject
end

function Unity.Scene:GetComponents(componentClass)
  local result = {}
  for _, gameObject in ipairs(self._gameObjects) do
    local components = gameObject:GetComponents(componentClass)
    for _, component in ipairs(components) do
      table.insert(result, component)
    end
  end
  return result
end

Unity.Application = {}
function Unity.Application.RunScene(scene)
  local startedComponents = setmetatable({}, { __mode = "k" })
  local lastTickMs = tonumber(window.Date.now())

  local function tick()
    local nowMs = tonumber(window.Date.now())
    local deltaSeconds = (nowMs - lastTickMs) / 1000
    lastTickMs = nowMs

    Unity.Time.deltaTime = deltaSeconds
    Unity.Time.time = Unity.Time.time + deltaSeconds
    Unity.Time.frameCount = Unity.Time.frameCount + 1

    local components = scene:GetComponents(Unity.Component)
    for _, component in ipairs(components) do
      if component.gameObject.activeSelf and component.enabled ~= false then
        if not startedComponents[component] then
          startedComponents[component] = true
          if component.Start then
            component:Start()
          end
        end

        if component.Update then
          component:Update()
        end
      end
    end
  end

  window:setInterval(tick, 16)
end

function Unity.Application.Run(target)
  if type(target) == "table" and target._gameObjects then
    return Unity.Application.RunScene(target)
  end

  local scene = Unity.Scene.New("AutoScene")
  local host = scene:CreateGameObject("AutoRunner")
  if type(target) == "table" and target.gameObject then
    host:AddExistingComponent(target)
  elseif type(target) == "table" then
    host:AddComponent(target)
  else
    error("Unity.Application.Run expects scene, component class, or component instance")
  end

  return Unity.Application.RunScene(scene)
end
