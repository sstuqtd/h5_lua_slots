local SlotGame = Unity.MonoBehaviour:New()

SlotGame.Symbols = {
  "CHERRY",
  "LEMON",
  "BELL",
  "STAR",
  "SEVEN",
  "CLOVER",
}

function SlotGame:Start()
  self.credits = 100
  self.bet = 10
  self.lastUiSyncTime = 0

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

  Unity.UI.BindClick(self.spinButton, function()
    self:Spin()
  end)
  Unity.UI.BindChange(self.betInput, function()
    self.bet = self:ParseBet(Unity.UI.GetValue(self.betInput))
    self:RefreshHud()
  end)

  self:RefreshHud()
  Unity.Debug.Log("SlotGame started")
end

function SlotGame:Update()
  if Unity.Time.time - self.lastUiSyncTime > 1 then
    self.lastUiSyncTime = Unity.Time.time
    self:RefreshHud()
  end
end

function SlotGame:RefreshHud()
  Unity.UI.SetText(self.creditsLabel, self.credits)
  Unity.UI.SetValue(self.betInput, self.bet)
end

function SlotGame:RandomSymbol()
  local symbolIndex = Unity.Random.Range(1, #self.Symbols + 1)
  return self.Symbols[symbolIndex]
end

function SlotGame:ParseBet(rawValue)
  local parsedValue = tonumber(rawValue) or self.bet
  return Unity.Mathf.Clamp(Unity.Mathf.FloorToInt(parsedValue), 1, 50)
end

function SlotGame:CalculatePayout(reels, currentBet)
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

function SlotGame:Spin()
  if self.credits <= 0 then
    Unity.UI.SetText(self.statusLabel, "No credits left. Refresh to restart.")
    Unity.Debug.LogWarning("Spin blocked because credits are 0")
    return
  end

  self.bet = self:ParseBet(Unity.UI.GetValue(self.betInput))
  if self.bet > self.credits then
    Unity.UI.SetText(self.statusLabel, "Bet exceeds credits.")
    self:RefreshHud()
    return
  end

  self.credits = self.credits - self.bet

  local currentReels = {
    self:RandomSymbol(),
    self:RandomSymbol(),
    self:RandomSymbol(),
  }
  for index = 1, 3 do
    Unity.UI.SetText(self.reels[index], currentReels[index])
  end

  local payout, message = self:CalculatePayout(currentReels, self.bet)
  self.credits = self.credits + payout

  if payout > 0 then
    Unity.UI.SetText(self.statusLabel, string.format("%s Won %d credits.", message, payout))
    Unity.Debug.Log(string.format("Spin win: +%d", payout))
  else
    Unity.UI.SetText(self.statusLabel, message)
  end

  self:RefreshHud()
end

Unity.Application.Run(SlotGame)
