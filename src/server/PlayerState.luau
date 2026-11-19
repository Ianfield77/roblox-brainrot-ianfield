-- Brainrot Bazaar: every player's state lives in this one module.
-- Cash, lifetime earnings, rebirths, upgrades, owned brainrots, base and lock.
-- Other server modules read and change state only through these functions.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local PlayerState = {}

local states = {}

function PlayerState.create(player, baseIndex)
	local state = {
		player = player,
		baseIndex = baseIndex,
		cash = Config.START_CASH,
		totalEarned = 0,
		rebirths = 0,
		slots = Config.SLOTS_START,
		speedLevel = 0,
		owned = {}, -- each entry: { charId, mutation, rate, model, slot, stealReadyAt }
		lockUntil = 0,
		lockCooldownUntil = 0,
		slowedUntil = 0,
	}
	states[player] = state
	return state
end

function PlayerState.get(player)
	return states[player]
end

function PlayerState.remove(player)
	states[player] = nil
end

function PlayerState.all()
	return states
end

function PlayerState.multiplier(state)
	return 1 + Config.REBIRTH_MULT_PER * state.rebirths
end

function PlayerState.incomePerSecond(state)
	local total = 0
	for _, entry in ipairs(state.owned) do
		total += entry.rate
	end
	return total * PlayerState.multiplier(state)
end

function PlayerState.addCash(state, amount)
	state.cash += amount
	if amount > 0 then
		state.totalEarned += amount
	end
end

function PlayerState.spendCash(state, amount)
	if state.cash < amount then
		return false
	end
	state.cash -= amount
	return true
end

function PlayerState.freeSlotCount(state)
	return state.slots - #state.owned
end

function PlayerState.addOwned(state, charId, mutation)
	local char = BrainrotData.getCharacter(charId)
	if not char then
		return nil
	end
	local used = {}
	for _, entry in ipairs(state.owned) do
		used[entry.slot] = true
	end
	local slot = nil
	for i = 1, state.slots do
		if not used[i] then
			slot = i
			break
		end
	end
	if not slot then
		return nil
	end
	local entry = {
		charId = charId,
		mutation = mutation,
		rate = BrainrotData.rateFor(char, mutation),
		model = nil,
		slot = slot,
		stealReadyAt = 0,
	}
	table.insert(state.owned, entry)
	return entry
end

function PlayerState.removeOwned(state, entry)
	for i, owned in ipairs(state.owned) do
		if owned == entry then
			table.remove(state.owned, i)
			if entry.model then
				entry.model:Destroy()
				entry.model = nil
			end
			return true
		end
	end
	return false
end

function PlayerState.clearOwned(state)
	for _, entry in ipairs(state.owned) do
		if entry.model then
			entry.model:Destroy()
			entry.model = nil
		end
	end
	state.owned = {}
end

function PlayerState.isLocked(state)
	return os.clock() < state.lockUntil
end

function PlayerState.lockRemaining(state)
	return math.max(0, state.lockUntil - os.clock())
end

function PlayerState.lockCooldownRemaining(state)
	return math.max(0, state.lockCooldownUntil - os.clock())
end

function PlayerState.tryLock(state)
	if PlayerState.isLocked(state) then
		return false, "Base already locked"
	end
	if PlayerState.lockCooldownRemaining(state) > 0 then
		return false, "Lock is cooling down"
	end
	state.lockUntil = os.clock() + Config.LOCK_SECONDS
	state.lockCooldownUntil = os.clock() + Config.LOCK_SECONDS + Config.LOCK_COOLDOWN
	return true, "Base locked"
end

function PlayerState.rebirthCost(state)
	return Config.REBIRTH_BASE_COST * (state.rebirths + 1)
end

function PlayerState.canRebirth(state)
	return state.totalEarned >= PlayerState.rebirthCost(state)
end

function PlayerState.doRebirth(state)
	if not PlayerState.canRebirth(state) then
		return false
	end
	PlayerState.clearOwned(state)
	state.cash = Config.START_CASH
	state.rebirths += 1
	return true
end

function PlayerState.slotCost(state)
	if state.slots >= Config.SLOTS_MAX then
		return nil
	end
	return Config.SLOT_COST_BASE * (state.slots - 3)
end

function PlayerState.speedCost(state)
	if state.speedLevel >= Config.SPEED_LEVEL_MAX then
		return nil
	end
	return Config.SPEED_COST_BASE * (state.speedLevel + 1)
end

function PlayerState.buyUpgrade(state, upgradeId)
	if upgradeId == "slot" then
		local cost = PlayerState.slotCost(state)
		if not cost then
			return false, "Max slots reached"
		end
		if not PlayerState.spendCash(state, cost) then
			return false, "Not enough cash"
		end
		state.slots += 1
		return true, "Slot unlocked"
	elseif upgradeId == "speed" then
		local cost = PlayerState.speedCost(state)
		if not cost then
			return false, "Max speed reached"
		end
		if not PlayerState.spendCash(state, cost) then
			return false, "Not enough cash"
		end
		state.speedLevel += 1
		local character = state.player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = Config.WALK_SPEED_BASE + Config.SPEED_PER_LEVEL * state.speedLevel
			end
		end
		return true, "Speed boots upgraded"
	end
	return false, "Unknown upgrade"
end

-- The small table the client HUD needs, sent every tick.
function PlayerState.syncSnapshot(state)
	local owned = {}
	for _, entry in ipairs(state.owned) do
		local char = BrainrotData.getCharacter(entry.charId)
		table.insert(owned, {
			name = char and char.name or entry.charId,
			rarity = char and char.rarity or "Common",
			rate = entry.rate,
			mutation = entry.mutation,
		})
	end
	return {
		cash = math.floor(state.cash),
		income = PlayerState.incomePerSecond(state),
		totalEarned = math.floor(state.totalEarned),
		rebirths = state.rebirths,
		multiplier = PlayerState.multiplier(state),
		slots = state.slots,
		maxSlots = Config.SLOTS_MAX,
		owned = owned,
		rebirthCost = PlayerState.rebirthCost(state),
		canRebirth = PlayerState.canRebirth(state),
		slotCost = PlayerState.slotCost(state),
		speedCost = PlayerState.speedCost(state),
		speedLevel = state.speedLevel,
		lockRemaining = math.floor(PlayerState.lockRemaining(state) + 0.5),
		lockCooldown = math.floor(PlayerState.lockCooldownRemaining(state) + 0.5),
		isLocked = PlayerState.isLocked(state),
	}
end

return PlayerState
