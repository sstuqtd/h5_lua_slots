local js = require("js")
local document = js.global.document
local mathFloor = math.floor

local symbols = {
  "CHERRY",
  "LEMON",
  "BELL",
  "STAR",
  "SEVEN",
  "CLOVER",
}

local credits = 100
local bet = 10

local reelElements = {
  document:getElementById("reel-1"),
  document:getElementById("reel-2"),
  document:getElementById("reel-3"),
}

local spinButton = document:getElementById("spin-button")
local statusLabel = document:getElementById("status-label")
local creditsLabel = document:getElementById("credits-label")
local betInput = document:getElementById("bet-input")

local function updateHud()
  creditsLabel.textContent = tostring(credits)
  betInput.value = tostring(bet)
end

local function randomSymbol()
  return symbols[math.random(1, #symbols)]
end

local function calculatePayout(reels, currentBet)
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

local function clamp(value, minValue, maxValue)
  if value < minValue then
    return minValue
  end

  if value > maxValue then
    return maxValue
  end

  return value
end

local function parseBetInput(rawValue)
  local numericValue = tonumber(rawValue) or bet
  return clamp(mathFloor(numericValue), 1, 50)
end

local function spin()
  if credits <= 0 then
    statusLabel.textContent = "No credits left. Refresh to restart."
    return
  end

  bet = parseBetInput(betInput.value)

  if bet > credits then
    statusLabel.textContent = "Bet exceeds credits."
    updateHud()
    return
  end

  credits = credits - bet

  local reels = { randomSymbol(), randomSymbol(), randomSymbol() }
  for index = 1, 3 do
    reelElements[index].textContent = reels[index]
  end

  local payout, message = calculatePayout(reels, bet)
  credits = credits + payout

  if payout > 0 then
    statusLabel.textContent = string.format("%s Won %d credits.", message, payout)
  else
    statusLabel.textContent = message
  end

  updateHud()
end

local now = js.global.Date.now()
math.randomseed(mathFloor(now % 2147483647))

spinButton.onclick = spin
betInput.onchange = function()
  bet = parseBetInput(betInput.value)
  updateHud()
end

updateHud()
