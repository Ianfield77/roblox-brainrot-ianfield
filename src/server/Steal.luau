-- Brainrot Bazaar: stealing and the base lock.
-- Touch another player's brainrot while their base is unlocked and it is yours,
-- but you walk away slowed, so the dash home is real. A locked base is safe.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local PlayerState = require(script.Parent.PlayerState)
local Economy = require(script.Parent.Economy)
local BrainrotModels = require(script.Parent.BrainrotModels)
local WorldBuilder = require(script.Parent.WorldBuilder)

local Steal = {}

-- Hook an owned brainrot's body up so touching it can steal it.
function Steal.watchOwned(owner, entry)
	local model = entry.model
	if not model then
		return
	end
	local body = model.PrimaryPart
	if not body then
		return
	end
	body.Touched:Connect(function(hit)
		Steal.onTouch(owner, entry, hit)
	end)
end

function Steal.onTouch(owner, entry, hit)
	if not entry.model then
		return
	end
	if os.clock() < entry.stealReadyAt then
		return
	end
	local character = hit.Parent
	if not character then
		return
	end
	local player = game:GetService("Players"):GetPlayerFromCharacter(character)
	if not player or player == owner then
		return
	end
	local thiefState = PlayerState.get(player)
	local ownerState = PlayerState.get(owner)
	if not thiefState or not ownerState then
		return
	end
	if PlayerState.isLocked(ownerState) then
		Economy.notify(player, owner.DisplayName .. "'s base is locked!", "bad")
		entry.stealReadyAt = os.clock() + 2
		return
	end
	if PlayerState.freeSlotCount(thiefState) <= 0 then
		Economy.notify(player, "Your base is full! No room to steal.", "bad")
		entry.stealReadyAt = os.clock() + 2
		return
	end

	-- The steal lands: the brainrot moves to the thief's base.
	local charId = entry.charId
	local mutation = entry.mutation
	local char = BrainrotData.getCharacter(charId)
	local displayName = char and char.name or charId
	PlayerState.removeOwned(ownerState, entry)
	local newEntry = PlayerState.addOwned(thiefState, charId, mutation)
	if not newEntry then
		return
	end
	BrainrotModels.placeOwned(thiefState, newEntry)
	Steal.watchOwned(player, newEntry)

	-- The thief walks away slowed, so the victim has a chance to react.
	thiefState.slowedUntil = os.clock() + Config.STEAL_SLOW_SECONDS
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Config.STEAL_SLOW_SPEED
		task.delay(Config.STEAL_SLOW_SECONDS, function()
			if humanoid.Parent then
				humanoid.WalkSpeed = Config.WALK_SPEED_BASE + Config.SPEED_PER_LEVEL * thiefState.speedLevel
			end
		end)
	end

	Economy.notify(player, "You stole " .. displayName .. " from " .. owner.DisplayName .. "! Run!", "good")
	Economy.notify(owner, player.DisplayName .. " stole your " .. displayName .. "!", "bad")
	Economy.sync(player)
	Economy.sync(owner)
end

-- The lock button: shields the base for LOCK_SECONDS, then cools down.
function Steal.toggleLock(player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local ok, message = PlayerState.tryLock(state)
	local base = WorldBuilder.getBase(state.baseIndex)
	if ok and base then
		base.shield.Visible = true
		task.delay(Config.LOCK_SECONDS, function()
			if base.shield then
				base.shield.Visible = false
			end
		end)
		Economy.notify(player, message .. " for " .. Config.LOCK_SECONDS .. "s!", "good")
	else
		local remaining = PlayerState.lockCooldownRemaining(state)
		if remaining > 0 then
			Economy.notify(player, "Lock cools down for " .. math.floor(remaining + 0.5) .. "s.", "bad")
		else
			Economy.notify(player, message, "bad")
		end
	end
	Economy.sync(player)
end

return Steal
