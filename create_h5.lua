local args = { ... }

local outputDirectory = args[1] or "generated_h5"
local pageTitle = args[2] or "Lua H5 Slots"

local pathSeparator = package.config:sub(1, 1)

local function joinPath(...)
  local parts = { ... }
  return table.concat(parts, pathSeparator)
end

local function commandSucceeded(ok, _, code)
  if type(ok) == "number" then
    return ok == 0
  end

  if ok == true and (code == nil or code == 0) then
    return true
  end

  return false
end

local function ensureDirectory(path)
  local command
  if pathSeparator == "\\" then
    command = string.format('mkdir "%s" 2>nul', path)
  else
    command = string.format('mkdir -p "%s"', path)
  end

  local ok, kind, code = os.execute(command)
  if not commandSucceeded(ok, kind, code) then
    return false, string.format("unable to create directory: %s", path)
  end

  return true
end

local function writeFile(path, content)
  local fileHandle, openError = io.open(path, "w")
  if not fileHandle then
    return false, string.format("failed to open %s: %s", path, openError or "unknown error")
  end

  local writeOk, writeError = fileHandle:write(content)
  if not writeOk then
    fileHandle:close()
    return false, string.format("failed to write %s: %s", path, writeError or "unknown error")
  end

  local closeOk, closeError = fileHandle:close()
  if closeOk == nil then
    return false, string.format("failed to close %s: %s", path, closeError or "unknown error")
  end

  return true
end

local function escapeHtml(value)
  return (value:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&#39;"))
end

local function renderIndexHtml(title)
  local safeTitle = escapeHtml(title)
  return [[<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>]] .. safeTitle .. [[</title>
  <link rel="stylesheet" href="styles.css" />
</head>
<body>
  <main class="container">
    <h1>]] .. safeTitle .. [[</h1>
    <p class="subtitle">A browser-based slot mini game powered by Lua.</p>

    <section class="hud">
      <div><span class="label">Credits:</span> <span id="credits-label">100</span></div>
      <div><span class="label">Bet:</span> <input id="bet-input" type="number" min="1" max="50" value="10" /></div>
    </section>

    <section class="reels" aria-label="slot reels">
      <div id="reel-1" class="reel">CHERRY</div>
      <div id="reel-2" class="reel">LEMON</div>
      <div id="reel-3" class="reel">BELL</div>
    </section>

    <button id="spin-button" type="button">SPIN</button>
    <p id="status-label" class="status">Press SPIN to start.</p>
  </main>

  <script src="https://unpkg.com/fengari-web/dist/fengari-web.js"></script>
  <script type="application/lua" src="unity_api.lua"></script>
  <script type="application/lua" src="main.lua"></script>
</body>
</html>
]]
end

local UNITY_API_LUA_CONTENT = [[local js = require("js")
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
]]

local MAIN_LUA_CONTENT = [[local SlotView = Unity.Component:Extend("SlotView")

function SlotView:Awake()
  self.reels = {
    Unity.UI.FindById("reel-1"),
    Unity.UI.FindById("reel-2"),
    Unity.UI.FindById("reel-3"),
  }
  self.spinButton = Unity.UI.FindById("spin-button")
  self.statusLabel = Unity.UI.FindById("status-label")
  self.creditsLabel = Unity.UI.FindById("credits-label")
  self.betInput = Unity.UI.FindById("bet-input")

  Unity.Debug.Assert(self.spinButton, "spin-button is required")
  Unity.Debug.Assert(self.statusLabel, "status-label is required")
  Unity.Debug.Assert(self.creditsLabel, "credits-label is required")
  Unity.Debug.Assert(self.betInput, "bet-input is required")
end

function SlotView:SetReels(currentReels)
  for index = 1, 3 do
    Unity.UI.SetText(self.reels[index], currentReels[index])
  end
end

function SlotView:SetCredits(value)
  Unity.UI.SetText(self.creditsLabel, value)
end

function SlotView:SetBet(value)
  Unity.UI.SetValue(self.betInput, value)
end

function SlotView:GetBet()
  return Unity.UI.GetValue(self.betInput)
end

function SlotView:SetStatus(text)
  Unity.UI.SetText(self.statusLabel, text)
end

function SlotView:BindSpin(callback)
  Unity.UI.BindClick(self.spinButton, callback)
end

function SlotView:BindBetChanged(callback)
  Unity.UI.BindChange(self.betInput, function()
    callback(self:GetBet())
  end)
end

local SlotGameController = Unity.MonoBehaviour:Extend("SlotGameController")

SlotGameController.Symbols = {
  "CHERRY",
  "LEMON",
  "BELL",
  "STAR",
  "SEVEN",
  "CLOVER",
}

function SlotGameController:Awake()
  self.credits = 100
  self.bet = 10
  self.lastUiSyncTime = 0
end

function SlotGameController:Start()
  self.view = self:GetComponent(SlotView)
  Unity.Debug.Assert(self.view, "SlotView component is required on SlotGame GameObject")

  self.view:BindSpin(function()
    self:Spin()
  end)
  self.view:BindBetChanged(function(rawValue)
    self.bet = self:ParseBet(rawValue)
    self:RefreshHud()
  end)

  self:RefreshHud()
  Unity.Debug.Log("SlotGameController started")
end

function SlotGameController:Update()
  if Unity.Time.time - self.lastUiSyncTime > 1 then
    self.lastUiSyncTime = Unity.Time.time
    self:RefreshHud()
  end
end

function SlotGameController:RefreshHud()
  self.view:SetCredits(self.credits)
  self.view:SetBet(self.bet)
end

function SlotGameController:RandomSymbol()
  local symbolIndex = Unity.Random.Range(1, #self.Symbols + 1)
  return self.Symbols[symbolIndex]
end

function SlotGameController:ParseBet(rawValue)
  local parsedValue = tonumber(rawValue) or self.bet
  return Unity.Mathf.Clamp(Unity.Mathf.FloorToInt(parsedValue), 1, 50)
end

function SlotGameController:CalculatePayout(reels, currentBet)
  if reels[1] == reels[2] and reels[2] == reels[3] then
    if reels[1] == "SEVEN" then
      return currentBet * 12, "JACKPOT! Triple SEVEN!"
    end

    return currentBet * 6, "Nice! Triple match!"
  end

  if reels[1] == reels[2] or reels[2] == reels[3] or reels[1] == reels[3] then
    return currentBet * 2, "Pair matched."
  end

  return 0, "No match. Try again."
end

function SlotGameController:Spin()
  if self.credits <= 0 then
    self.view:SetStatus("No credits left. Refresh to restart.")
    Unity.Debug.LogWarning("Spin blocked because credits are 0")
    return
  end

  self.bet = self:ParseBet(self.view:GetBet())
  if self.bet > self.credits then
    self.view:SetStatus("Bet exceeds credits.")
    self:RefreshHud()
    return
  end

  self.credits = self.credits - self.bet

  local currentReels = {
    self:RandomSymbol(),
    self:RandomSymbol(),
    self:RandomSymbol(),
  }
  self.view:SetReels(currentReels)

  local payout, message = self:CalculatePayout(currentReels, self.bet)
  self.credits = self.credits + payout

  if payout > 0 then
    self.view:SetStatus(string.format("%s Won %d credits.", message, payout))
    Unity.Debug.Log(string.format("Spin win: +%d", payout))
  else
    self.view:SetStatus(message)
  end

  self:RefreshHud()
end

local slotScene = Unity.Scene.New("SlotScene")
local slotGameObject = slotScene:CreateGameObject("SlotGame")
slotGameObject:AddComponent(SlotView)
slotGameObject:AddComponent(SlotGameController)

Unity.Application.RunScene(slotScene)
]]

local STYLE_CSS_CONTENT = [[* {
  box-sizing: border-box;
  font-family: Arial, sans-serif;
}

body {
  margin: 0;
  min-height: 100vh;
  display: grid;
  place-items: center;
  background: radial-gradient(circle at top, #2f3b52, #121721);
  color: #f4f7ff;
}

.container {
  width: min(560px, 92vw);
  padding: 28px;
  border-radius: 16px;
  background-color: rgba(13, 18, 28, 0.88);
  box-shadow: 0 16px 36px rgba(0, 0, 0, 0.35);
  text-align: center;
}

h1 {
  margin: 0 0 8px;
}

.subtitle {
  margin: 0 0 20px;
  color: #b6c3dd;
}

.hud {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 20px;
}

.label {
  font-weight: 700;
  margin-right: 6px;
}

#bet-input {
  width: 76px;
  padding: 4px 8px;
  border-radius: 6px;
  border: 1px solid #455171;
  background: #101625;
  color: #ffffff;
}

.reels {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  margin-bottom: 20px;
}

.reel {
  padding: 20px 12px;
  border-radius: 10px;
  background: #1f2940;
  border: 1px solid #314062;
  font-weight: 700;
  letter-spacing: 0.4px;
}

#spin-button {
  border: none;
  border-radius: 8px;
  padding: 10px 22px;
  background: #00a3ff;
  color: #0d1320;
  font-weight: 800;
  cursor: pointer;
}

#spin-button:hover {
  background: #3db6ff;
}

.status {
  min-height: 24px;
  margin-top: 16px;
  color: #d8e4ff;
}
]]

local function main()
  local ok, directoryError = ensureDirectory(outputDirectory)
  if not ok then
    io.stderr:write(directoryError .. "\n")
    return 1
  end

  local filesToGenerate = {
    { name = "index.html", content = renderIndexHtml(pageTitle) },
    { name = "unity_api.lua", content = UNITY_API_LUA_CONTENT },
    { name = "main.lua", content = MAIN_LUA_CONTENT },
    { name = "styles.css", content = STYLE_CSS_CONTENT },
  }

  for _, item in ipairs(filesToGenerate) do
    local filePath = joinPath(outputDirectory, item.name)
    local writeOk, writeError = writeFile(filePath, item.content)
    if not writeOk then
      io.stderr:write(writeError .. "\n")
      return 1
    end
    print("generated: " .. filePath)
  end

  print("Done. Serve " .. outputDirectory .. " with a local static server.")
  return 0
end

os.exit(main())
