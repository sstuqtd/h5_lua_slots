local SlotView = Unity.Component:Extend("SlotView")

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
