-- Brainrot Bazaar: client entry point.
-- Builds the HUD, then wires its buttons to the server remotes
-- and listens for state syncs, notifications and event banners.
-- The 3D camera is Roblox's default follow camera: the player walks
-- the plaza in 3D and the HUD floats over that world.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Hud = require(script.Parent.Hud)

local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
local syncEvent = remotes:WaitForChild("SyncState", 30)
local notifyEvent = remotes:WaitForChild("Notify", 30)
local announceEvent = remotes:WaitForChild("Announce", 30)
local toggleLockEvent = remotes:WaitForChild("ToggleLock", 30)
local doRebirthEvent = remotes:WaitForChild("DoRebirth", 30)
local buyUpgradeEvent = remotes:WaitForChild("BuyUpgrade", 30)

local playerGui = player:WaitForChild("PlayerGui")
Hud.build(playerGui)

Hud.setCallbacks({
	lock = function()
		toggleLockEvent:FireServer()
	end,
	rebirth = function()
		doRebirthEvent:FireServer()
	end,
	upgrade = function(upgradeId)
		buyUpgradeEvent:FireServer(upgradeId)
	end,
})

syncEvent.OnClientEvent:Connect(function(state)
	Hud.update(state)
end)

notifyEvent.OnClientEvent:Connect(function(message, kind)
	Hud.notify(message, kind)
end)

announceEvent.OnClientEvent:Connect(function(message, seconds)
	Hud.announce(message, seconds)
end)
