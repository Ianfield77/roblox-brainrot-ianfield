-- Brainrot Bazaar: the money side of the game.
-- Income ticks, buying a brainrot off the belt, rebirths and upgrades.
-- The spawner and the steal logic call into this; the client never touches cash.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local PlayerState = require(script.Parent.PlayerState)

local Economy = {}

local syncEvent = nil
local notifyEvent = nil

function Economy.bindEvents(sync, notify)
	syncEvent = sync
	notifyEvent = notify
end

function Economy.notify(player, message, kind)
	if notifyEvent then
		notifyEvent:FireClient(player, message, kind or "info")
	end
end

function Economy.sync(player)
	local state = PlayerState.get(player)
	if state and syncEvent then
		syncEvent:FireClient(player, PlayerState.syncSnapshot(state))
	end
end

-- One income tick for every player, once a second.
function Economy.tickAll()
	for player, state in pairs(PlayerState.all()) do
		local income = PlayerState.incomePerSecond(state)
		if income > 0 then
			PlayerState.addCash(state, income * Config.TICK_SECONDS)
		end
		Economy.sync(player)
	end
end

-- Buy a brainrot that is walking the belt. The caller removes the belt NPC
-- and places the owned model once this returns success.
function Economy.tryBuy(player, charId, mutationName)
	local state = PlayerState.get(player)
	if not state then
		return false, nil, "No state"
	end
	local char = BrainrotData.getCharacter(charId)
	if not char then
		return false, nil, "Unknown brainrot"
	end
	if PlayerState.freeSlotCount(state) <= 0 then
		return false, nil, "Your base is full! Buy a slot upgrade."
	end
	local cost = BrainrotData.costFor(char, mutationName)
	if not PlayerState.spendCash(state, cost) then
		return false, nil, "Not enough cash for " .. char.name
	end
	local entry = PlayerState.addOwned(state, charId, mutationName)
	if not entry then
		PlayerState.addCash(state, cost)
		return false, nil, "No free slot"
	end
	Economy.sync(player)
	return true, entry, "Bought " .. char.name
end

function Economy.doRebirth(player)
	local state = PlayerState.get(player)
	if not state then
		return false
	end
	if not PlayerState.doRebirth(state) then
		Economy.notify(player, "Rebirth needs " .. BrainrotData.formatMoney(PlayerState.rebirthCost(state)) .. " total earned.", "bad")
		return false
	end
	local humanoid = nil
	local character = player.Character
	if character then
		humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.WALK_SPEED_BASE + Config.SPEED_PER_LEVEL * state.speedLevel
		end
	end
	Economy.notify(player, "REBIRTH! Level " .. state.rebirths .. ", income x" .. string.format("%.2f", PlayerState.multiplier(state)), "good")
	Economy.sync(player)
	return true
end

function Economy.buyUpgrade(player, upgradeId)
	local state = PlayerState.get(player)
	if not state then
		return false
	end
	local ok, message = PlayerState.buyUpgrade(state, upgradeId)
	if ok then
		Economy.notify(player, message .. "!", "good")
	else
		Economy.notify(player, message, "bad")
	end
	Economy.sync(player)
	return ok
end

return Economy
