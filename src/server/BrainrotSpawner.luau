-- Brainrot Bazaar: the conveyor belt.
-- Spawns brainrots at the west end, walks them east along the belt,
-- and sells them when a player clicks one. A wave can sweep the belt clean.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local PlayerState = require(script.Parent.PlayerState)
local Economy = require(script.Parent.Economy)
local BrainrotModels = require(script.Parent.BrainrotModels)

local BrainrotSpawner = {}

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local npcs = {} -- npcId -> { model, charId, mutation, x, speed }
local nextNpcId = 1
local rushUntil = 0
local running = false

function BrainrotSpawner.isRushing()
	return os.clock() < rushUntil
end

function BrainrotSpawner.startRush(seconds)
	rushUntil = os.clock() + seconds
end

function BrainrotSpawner.rushRemaining()
	return math.max(0, rushUntil - os.clock())
end

local function beltGroundY()
	return 0.6 -- top of the belt strip
end

local function spawnOne()
	if #npcs >= Config.BELT_MAX_NPCS then
		return
	end
	local rushing = BrainrotSpawner.isRushing()
	local rarity = BrainrotData.rollRarity(rushing)
	local char = BrainrotData.randomCharacterOfRarity(rarity)
	local mutation = BrainrotData.rollMutation()
	local model = BrainrotModels.buildBeltNpc(char.id, mutation)
	if not model then
		return
	end
	local npcId = nextNpcId
	nextNpcId += 1
	local speed = if rushing then Config.BELT_SPEED_RUSH else Config.BELT_SPEED
	local npc = {
		id = npcId,
		model = model,
		charId = char.id,
		mutation = mutation,
		x = Config.BELT_START_X,
		speed = speed,
	}
	npcs[npcId] = npc
	model:SetAttribute("NpcId", npcId)
	model.Parent = Workspace.BrainrotWorld

	-- Click the brainrot to buy it.
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 40
	detector.Parent = model.PrimaryPart
	detector.MouseClick:Connect(function(player)
		BrainrotSpawner.buyNpc(player, npcId)
	end)
end

-- Move every belt NPC one step east. Runs on Heartbeat.
local function stepNpcs(dt)
	local toRemove = {}
	for id, npc in pairs(npcs) do
		npc.x += npc.speed * dt
		if npc.x >= Config.BELT_END_X then
			table.insert(toRemove, id)
		else
			-- The model is built facing +X, which is the direction of travel,
			-- so no rotation is needed here.
			local bodyPos = Vector3.new(npc.x, beltGroundY() + BrainrotModels.BODY_CENTER_Y, Config.BELT_Z)
			npc.model:PivotTo(CFrame.new(bodyPos))
		end
	end
	for _, id in ipairs(toRemove) do
		BrainrotSpawner.removeNpc(id)
	end
end

function BrainrotSpawner.removeNpc(npcId)
	local npc = npcs[npcId]
	if npc then
		npcs[npcId] = nil
		if npc.model then
			npc.model:Destroy()
		end
	end
end

-- The wave sweeps the belt: every walker is washed away.
function BrainrotSpawner.clearBelt()
	local ids = {}
	for id in pairs(npcs) do
		table.insert(ids, id)
	end
	for _, id in ipairs(ids) do
		BrainrotSpawner.removeNpc(id)
	end
end

function BrainrotSpawner.count()
	local n = 0
	for _ in pairs(npcs) do
		n += 1
	end
	return n
end

function BrainrotSpawner.buyNpc(player, npcId)
	local npc = npcs[npcId]
	if not npc then
		return
	end
	local ok, entry, message = Economy.tryBuy(player, npc.charId, npc.mutation)
	if not ok then
		Economy.notify(player, message, "bad")
		return
	end
	local state = PlayerState.get(player)
	BrainrotSpawner.removeNpc(npcId)
	if state and BrainrotModels.placeOwned(state, entry) then
		Economy.notify(player, message .. " for " .. BrainrotData.formatMoney(BrainrotData.costFor(BrainrotData.getCharacter(npc.charId), npc.mutation)) .. "!", "good")
		-- Hook the owned model up for stealing.
		local Steal = require(script.Parent.Steal)
		Steal.watchOwned(player, entry)
	else
		-- Placement failed: refund the purchase instead of eating the cash.
		-- Add it straight to cash: addCash would count it as earnings.
		local char = BrainrotData.getCharacter(npc.charId)
		PlayerState.removeOwned(state, entry)
		if state and char then
			state.cash += BrainrotData.costFor(char, npc.mutation)
		end
		Economy.notify(player, "Could not place " .. npc.charId .. " on your base.", "bad")
	end
end

function BrainrotSpawner.start()
	if running then
		return
	end
	running = true
	task.spawn(function()
		while true do
			spawnOne()
			local interval = if BrainrotSpawner.isRushing() then Config.SPAWN_INTERVAL_RUSH else Config.SPAWN_INTERVAL
			task.wait(interval)
		end
	end)
	RunService.Heartbeat:Connect(stepNpcs)
end

return BrainrotSpawner
