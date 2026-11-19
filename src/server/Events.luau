-- Brainrot Bazaar: the two map events that keep the loop tense.
-- Brainrot Rush: rare spawns tilt rarer for a minute.
-- Mie Tsunami: a wave sweeps the plaza; only your own base is safe,
-- and it washes every brainrot off the belt.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local PlayerState = require(script.Parent.PlayerState)
local Economy = require(script.Parent.Economy)
local BrainrotSpawner = require(script.Parent.BrainrotSpawner)
local WorldBuilder = require(script.Parent.WorldBuilder)

local Events = {}

local announceEvent = nil
local Workspace = game:GetService("Workspace")

function Events.bindEvents(announce)
	announceEvent = announce
end

function Events.announce(message, seconds)
	if announceEvent then
		announceEvent:FireAllClients(message, seconds or 5)
	end
end

-- The wave wall: a big translucent slab that crosses the plaza southward.
local function runWave()
	Events.announce("TSUNAMI MIE DATANG! Lari ke basemu!", Config.WAVE_WARNING)
	task.wait(Config.WAVE_WARNING)

	local wall = Instance.new("Part")
	wall.Name = "MieWave"
	wall.Size = Vector3.new(140, 14, 4)
	wall.Position = Vector3.new(0, 7, -75)
	wall.Color = Color3.fromRGB(120, 200, 255)
	wall.Material = Enum.Material.ForceField
	wall.Transparency = 0.4
	wall.Anchored = true
	wall.CanCollide = false
	wall.Parent = Workspace.BrainrotWorld

	local sweptBelt = false
	local hitPlayers = {}

	wall.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then
			return
		end
		local player = game:GetService("Players"):GetPlayerFromCharacter(character)
		if not player or hitPlayers[player] then
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		-- Standing on your own base keeps you safe.
		if WorldBuilder.isOnOwnBase(player, root.Position) then
			return
		end
		hitPlayers[player] = true
		local state = PlayerState.get(player)
		if state then
			local loss = math.floor(state.cash * Config.WAVE_CASH_LOSS)
			if loss > 0 then
				PlayerState.addCash(state, -loss)
				Economy.notify(player, "The wave caught you! Lost " .. BrainrotData.formatMoney(loss) .. ".", "bad")
			else
				Economy.notify(player, "The wave caught you! Get to your base next time!", "bad")
			end
			Economy.sync(player)
		end
		-- Fling the player southward.
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			root.AssemblyLinearVelocity = Vector3.new(0, 25, 45)
			task.delay(1, function()
				if humanoid.Parent then
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end)
		end
	end)

	-- Sweep south across the whole plaza.
	local steps = 60
	for i = 1, steps do
		wall.Position = Vector3.new(0, 7, -75 + (150 * i / steps))
		if not sweptBelt and wall.Position.Z >= Config.BELT_Z then
			sweptBelt = true
			BrainrotSpawner.clearBelt()
			Events.announce("Tsunami menyapu belt! Semua brainrot hanyut!", 4)
		end
		task.wait(0.13)
	end
	wall:Destroy()
end

local function runRush()
	BrainrotSpawner.startRush(Config.RUSH_DURATION)
	Events.announce("BRAINROT RUSH! Karakter langka lebih sering muncul!", Config.RUSH_DURATION)
end

function Events.start()
	task.spawn(function()
		task.wait(45) -- let the first players settle in
		while true do
			runRush()
			task.wait(math.random(Config.RUSH_EVERY_MIN, Config.RUSH_EVERY_MAX))
		end
	end)
	task.spawn(function()
		task.wait(90)
		while true do
			runWave()
			task.wait(math.random(Config.WAVE_EVERY_MIN, Config.WAVE_EVERY_MAX))
		end
	end)
end

return Events
