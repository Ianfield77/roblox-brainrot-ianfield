-- Brainrot Bazaar: server entry point.
-- Builds the world, opens the remotes, hands each player a base and a state,
-- then runs the income tick, the belt and the map events.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldBuilder = require(script.WorldBuilder)
local PlayerState = require(script.PlayerState)
local Economy = require(script.Economy)
local BrainrotSpawner = require(script.BrainrotSpawner)
local Steal = require(script.Steal)
local Events = require(script.Events)

-- Build the world first: player joins below need a free base to claim.
WorldBuilder.build()

-- The remotes every client talks through.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end
local syncEvent = makeRemote("SyncState")
local notifyEvent = makeRemote("Notify")
local announceEvent = makeRemote("Announce")
local toggleLockEvent = makeRemote("ToggleLock")
local doRebirthEvent = makeRemote("DoRebirth")
local buyUpgradeEvent = makeRemote("BuyUpgrade")

Economy.bindEvents(syncEvent, notifyEvent)
Events.bindEvents(announceEvent)

toggleLockEvent.OnServerEvent:Connect(function(player)
	Steal.toggleLock(player)
end)
doRebirthEvent.OnServerEvent:Connect(function(player)
	Economy.doRebirth(player)
end)
buyUpgradeEvent.OnServerEvent:Connect(function(player, upgradeId)
	if upgradeId == "slot" or upgradeId == "speed" then
		Economy.buyUpgrade(player, upgradeId)
	end
end)

local function applyWalkSpeed(player)
	local state = PlayerState.get(player)
	local character = player.Character
	if not state or not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Config.WALK_SPEED_BASE + Config.SPEED_PER_LEVEL * state.speedLevel
	end
end

local function onPlayerAdded(player)
	local base = WorldBuilder.getFreeBase()
	if not base then
		player:Kick("Brainrot Bazaar is full right now, try again in a bit!")
		return
	end
	WorldBuilder.claimBase(base.index, player)
	PlayerState.create(player, base.index)
	applyWalkSpeed(player)
	Economy.sync(player)
	Economy.notify(player, "Welcome to Brainrot Bazaar! Click a brainrot on the belt to buy it.", "info")
end

local function onPlayerRemoving(player)
	local state = PlayerState.get(player)
	if state then
		PlayerState.clearOwned(state)
		WorldBuilder.releaseBase(state.baseIndex)
		PlayerState.remove(player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		applyWalkSpeed(player)
	end)
end)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		applyWalkSpeed(player)
	end)
end

-- Start the loops.
BrainrotSpawner.start()
Events.start()

task.spawn(function()
	while true do
		task.wait(Config.TICK_SECONDS)
		Economy.tickAll()
	end
end)

print("Brainrot Bazaar server ready: 8 bases, belt running, events armed.")
