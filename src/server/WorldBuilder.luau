-- Brainrot Bazaar: builds the whole 3D world from code.
-- Plaza, conveyor belt, eight player bases, trees, lamps and signs.
-- The place file only holds a baseplate, so this module IS the world.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local WorldBuilder = {}

local Workspace = game:GetService("Workspace")

local bases = {}

local function makePart(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.Parent = parent
	return part
end

local function makeCylinder(parent, name, radius, height, position, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(height, radius * 2, radius * 2)
	part.Position = position
	part.Color = color
	part.Anchored = true
	part.CanCollide = false
	part.Parent = parent
	return part
end

local function makeBall(parent, name, radius, position, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
	part.Position = position
	part.Color = color
	part.Anchored = true
	part.CanCollide = false
	part.Parent = parent
	return part
end

local function makeBillboard(parent, name, size, offset, text, textColor, textSize)
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.ExtentsOffsetWorldSpace = offset
	gui.AlwaysOnTop = true
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor
	label.TextSize = textSize
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = false
	label.TextWrapped = true
	label.Parent = gui
	return label
end

local function buildPlaza(world)
	-- Plaza floor, its top exactly at y = 0 so players walk on it.
	makePart(world, "PlazaFloor", Vector3.new(140, 1, 140), Vector3.new(0, -0.5, 0), Color3.fromRGB(96, 180, 110), Enum.Material.Grass)
	-- Low border walls framing the play area.
	makePart(world, "WallNorth", Vector3.new(140, 2, 1), Vector3.new(0, 1, -70), Color3.fromRGB(240, 200, 90))
	makePart(world, "WallSouth", Vector3.new(140, 2, 1), Vector3.new(0, 1, 70), Color3.fromRGB(240, 200, 90))
	makePart(world, "WallWest", Vector3.new(1, 2, 140), Vector3.new(-70, 1, 0), Color3.fromRGB(240, 200, 90))
	makePart(world, "WallEast", Vector3.new(1, 2, 140), Vector3.new(70, 1, 0), Color3.fromRGB(240, 200, 90))
end

local function buildBelt(world)
	-- The conveyor strip the brainrots walk along, north side of the plaza.
	local belt = makePart(world, "Belt", Vector3.new(110, 0.6, 10), Vector3.new(0, 0.3, Config.BELT_Z), Color3.fromRGB(60, 60, 75), Enum.Material.Metal)
	belt.CanCollide = true
	-- Rails framing the belt.
	makePart(world, "BeltRailNorth", Vector3.new(110, 1, 0.6), Vector3.new(0, 0.8, Config.BELT_Z - 5), Color3.fromRGB(255, 200, 60))
	makePart(world, "BeltRailSouth", Vector3.new(110, 1, 0.6), Vector3.new(0, 0.8, Config.BELT_Z + 5), Color3.fromRGB(255, 200, 60))
	-- Chevron arrows on the belt so players read its direction at a glance.
	for x = -45, 45, 15 do
		local chevron = makePart(world, "Chevron", Vector3.new(4, 0.15, 6), Vector3.new(x, 0.65, Config.BELT_Z), Color3.fromRGB(255, 220, 90), Enum.Material.Neon)
		chevron.CanCollide = false
	end
end

local function buildBase(world, index, center)
	local base = {}
	base.index = index
	base.center = center
	base.owner = nil
	base.slots = {}

	-- Pad.
	local pad = makePart(world, "BasePad" .. index, Vector3.new(Config.BASE_SIZE, 1, Config.BASE_SIZE), Vector3.new(center.X, 0.5, center.Z), Color3.fromRGB(120, 120, 200))
	pad.CanCollide = true
	base.pad = pad

	-- Slot markers: eight spots where owned brainrots stand.
	local offsets = {
		Vector3.new(-4.5, 0, -4.5), Vector3.new(0, 0, -4.5), Vector3.new(4.5, 0, -4.5),
		Vector3.new(-4.5, 0, 0), Vector3.new(4.5, 0, 0),
		Vector3.new(-4.5, 0, 4.5), Vector3.new(0, 0, 4.5), Vector3.new(4.5, 0, 4.5),
	}
	for i, offset in ipairs(offsets) do
		local marker = makePart(world, "Slot" .. i, Vector3.new(3.4, 0.2, 3.4), Vector3.new(center.X + offset.X, 1.1, center.Z + offset.Z), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
		marker.Transparency = 0.6
		marker.CanCollide = false
		base.slots[i] = Vector3.new(center.X + offset.X, 1.2, center.Z + offset.Z)
	end

	-- Lock shield: shown while the base lock is active.
	local shield = makePart(world, "LockShield" .. index, Vector3.new(Config.BASE_SIZE, 7, Config.BASE_SIZE), Vector3.new(center.X, 4.5, center.Z), Color3.fromRGB(80, 160, 255), Enum.Material.ForceField)
	shield.Transparency = 0.75
	shield.CanCollide = false
	shield.CanQuery = false
	shield.Visible = false
	base.shield = shield

	-- Sign pole with a billboard naming the base and its owner.
	local pole = makeCylinder(world, "SignPole" .. index, 0.4, 7, Vector3.new(center.X, 3.5, center.Z - 9), Color3.fromRGB(90, 60, 30))
	pole.CanCollide = false
	local sign = makeBillboard(pole, "BaseSign", Vector2.new(220, 70), Vector3.new(0, 4.5, 0), "BASE " .. index, Color3.fromRGB(255, 255, 255), 28)
	base.signLabel = sign

	bases[index] = base
	return base
end

local function buildCenterpiece(world)
	-- Central tower with a fountain ring.
	makeCylinder(world, "Tower", 4, 12, Vector3.new(0, 6, 0), Color3.fromRGB(200, 120, 60), Enum.Material.Metal)
	makeBall(world, "TowerTop", 5, Vector3.new(0, 13.5, 0), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
	makeCylinder(world, "FountainRing", 7, 1, Vector3.new(0, 0.5, 0), Color3.fromRGB(80, 160, 255))
	-- Big floating sign over the plaza.
	local signPost = makeCylinder(world, "BigSignPost", 0.6, 14, Vector3.new(0, 7, -62), Color3.fromRGB(90, 60, 30))
	signPost.CanCollide = false
	makeBillboard(signPost, "BigSign", Vector2.new(520, 120), Vector3.new(0, 8.5, 0), "BRAINROT BAZAAR", Color3.fromRGB(255, 220, 90), 44)
end

local function buildTrees(world)
	local spots = {
		Vector3.new(-66, 0, -60), Vector3.new(66, 0, -60),
		Vector3.new(-66, 0, 60), Vector3.new(66, 0, 60),
		Vector3.new(-66, 0, -20), Vector3.new(66, 0, -20),
		Vector3.new(-66, 0, 20), Vector3.new(66, 0, 20),
	}
	for i, spot in ipairs(spots) do
		makeCylinder(world, "TreeTrunk" .. i, 0.8, 6, Vector3.new(spot.X, 3, spot.Z), Color3.fromRGB(120, 80, 40))
		makeBall(world, "TreeTop" .. i, 3.5, Vector3.new(spot.X, 8, spot.Z), Color3.fromRGB(40, 160, 70))
		makeBall(world, "TreeTopB" .. i, 2.2, Vector3.new(spot.X + 2, 6.5, spot.Z), Color3.fromRGB(50, 180, 80))
	end
end

local function buildLamps(world)
	for _, x in ipairs({ -40, -13, 13, 40 }) do
		local pole = makeCylinder(world, "LampPole" .. x, 0.35, 7, Vector3.new(x, 3.5, Config.BELT_Z - 8), Color3.fromRGB(50, 50, 60))
		pole.CanCollide = false
		local bulb = makeBall(world, "LampBulb" .. x, 1, Vector3.new(x, 7.2, Config.BELT_Z - 8), Color3.fromRGB(255, 240, 150), Enum.Material.Neon)
		bulb.CanCollide = false
	end
end

function WorldBuilder.build()
	local world = Instance.new("Folder")
	world.Name = "BrainrotWorld"
	world.Parent = Workspace
	buildPlaza(world)
	buildBelt(world)
	local spots = {
		Vector3.new(-55, 0, -15), Vector3.new(-55, 0, 5), Vector3.new(-55, 0, 25), Vector3.new(-55, 0, 45),
		Vector3.new(55, 0, -15), Vector3.new(55, 0, 5), Vector3.new(55, 0, 25), Vector3.new(55, 0, 45),
	}
	for i, spot in ipairs(spots) do
		buildBase(world, i, spot)
	end
	buildCenterpiece(world)
	buildTrees(world)
	buildLamps(world)
	return bases
end

function WorldBuilder.getBase(index)
	return bases[index]
end

function WorldBuilder.getFreeBase()
	for i = 1, Config.BASE_COUNT do
		if bases[i] and bases[i].owner == nil then
			return bases[i]
		end
	end
	return nil
end

function WorldBuilder.claimBase(index, player)
	local base = bases[index]
	if base then
		base.owner = player
		base.signLabel.Text = player.DisplayName .. "'s Base"
		base.pad.Color = Color3.fromRGB(90, 200, 120)
	end
end

function WorldBuilder.releaseBase(index)
	local base = bases[index]
	if base then
		base.owner = nil
		base.signLabel.Text = "BASE " .. index
		base.pad.Color = Color3.fromRGB(120, 120, 200)
		base.shield.Visible = false
	end
end

-- True when the position stands on the player's own base pad (wave safe zone).
function WorldBuilder.isOnOwnBase(player, position)
	for _, base in ipairs(bases) do
		if base.owner == player then
			local half = Config.BASE_SIZE / 2
			if math.abs(position.X - base.center.X) <= half and math.abs(position.Z - base.center.Z) <= half then
				return true
			end
		end
	end
	return false
end

return WorldBuilder
