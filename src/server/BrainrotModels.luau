-- Brainrot Bazaar: builds the 3D body of every brainrot character.
-- Belt walkers and base residents are the same model, built by one function,
-- so the cast looks the same everywhere a player sees it.
-- Parts are built around a local origin at the feet; callers place the model
-- with PivotTo, aiming the body centre (BODY_CENTER_Y above the feet).

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local WorldBuilder = require(script.Parent.WorldBuilder)

local BrainrotModels = {}

-- Height of the body centre (the model pivot) above the feet.
BrainrotModels.BODY_CENTER_Y = 2.1

local function part(parent, name, size, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.Parent = parent
	return p
end

local function label(parent, name, size, position, text, textColor, textSize)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.Position = position
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = textColor
	l.TextSize = textSize
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = false
	l.TextWrapped = true
	l.Parent = parent
	return l
end

-- The name / rarity / money-a-second sign floating over a brainrot.
local function attachTag(model, head, char, mutationName, rate, cost)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Tag"
	gui.Size = UDim2.fromOffset(220, 90)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = head
	local rarity = BrainrotData.getRarity(char.rarity)
	label(gui, "Name", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), char.name, Color3.fromRGB(255, 255, 255), 20)
	local mutationText = mutationName
	if mutationName ~= "Normal" then
		mutationText = mutationName .. " " .. char.rarity
	else
		mutationText = char.rarity
	end
	label(gui, "Rarity", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 30), mutationText, rarity.color, 18)
	local rateText = BrainrotData.formatMoney(rate) .. "/s"
	if cost then
		rateText = rateText .. "  •  " .. BrainrotData.formatMoney(cost)
	end
	label(gui, "Rate", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 56), rateText, Color3.fromRGB(140, 255, 140), 18)
	return gui
end

-- Builds a brainrot character with its feet at the local origin, facing +X.
function BrainrotModels.build(charId, mutationName)
	local char = BrainrotData.getCharacter(charId)
	if not char then
		return nil
	end
	local mutation = BrainrotData.getMutation(mutationName)
	local rarity = BrainrotData.getRarity(char.rarity)

	local model = Instance.new("Model")
	model.Name = char.name

	-- Body colour comes from the mutation when mutated, else the rarity.
	local bodyColor = rarity.color
	local bodyMaterial = Enum.Material.SmoothPlastic
	if mutation.color then
		bodyColor = mutation.color
		if mutationName == "Diamond" then
			bodyMaterial = Enum.Material.Neon
		end
	end

	-- Feet, body, head, eyes: a chunky little character.
	local footL = part(model, "FootL", Vector3.new(1, 0.8, 1.2), Color3.fromRGB(40, 40, 45))
	footL.Position = Vector3.new(-0.8, 0.4, 0)
	local footR = part(model, "FootR", Vector3.new(1, 0.8, 1.2), Color3.fromRGB(40, 40, 45))
	footR.Position = Vector3.new(0.8, 0.4, 0)
	local body = part(model, "Body", Vector3.new(3.2, 2.6, 2.6), bodyColor, bodyMaterial)
	body.Position = Vector3.new(0, BrainrotModels.BODY_CENTER_Y, 0)
	local head = part(model, "Head", Vector3.new(2.4, 2.2, 2.4), bodyColor, bodyMaterial)
	head.Position = Vector3.new(0, 4.5, 0)
	-- Eyes on the +X face, the direction the character walks.
	local eyeL = part(model, "EyeL", Vector3.new(0.4, 0.7, 0.5), Color3.fromRGB(20, 20, 20))
	eyeL.Position = Vector3.new(1.25, 4.7, -0.55)
	local eyeR = part(model, "EyeR", Vector3.new(0.4, 0.7, 0.5), Color3.fromRGB(20, 20, 20))
	eyeR.Position = Vector3.new(1.25, 4.7, 0.55)

	model.PrimaryPart = body
	return model, head
end

-- A brainrot walking the belt, for sale: tag shows its price too.
function BrainrotModels.buildBeltNpc(charId, mutationName)
	local char = BrainrotData.getCharacter(charId)
	local rate = BrainrotData.rateFor(char, mutationName)
	local cost = BrainrotData.costFor(char, mutationName)
	local model, head = BrainrotModels.build(charId, mutationName)
	if not model then
		return nil
	end
	attachTag(model, head, char, mutationName, rate, cost)
	model:SetAttribute("CharId", charId)
	model:SetAttribute("Mutation", mutationName)
	model:SetAttribute("Rate", rate)
	model:SetAttribute("Cost", cost)
	return model
end

-- A brainrot standing on a base slot, earning money: tag shows its rate only.
function BrainrotModels.buildOwned(charId, mutationName)
	local char = BrainrotData.getCharacter(charId)
	local rate = BrainrotData.rateFor(char, mutationName)
	local model, head = BrainrotModels.build(charId, mutationName)
	if not model then
		return nil
	end
	attachTag(model, head, char, mutationName, rate, nil)
	model:SetAttribute("CharId", charId)
	model:SetAttribute("Mutation", mutationName)
	model:SetAttribute("Rate", rate)
	return model
end

-- Places an owned entry's model on its slot of the owner's base.
function BrainrotModels.placeOwned(state, entry)
	local base = WorldBuilder.getBase(state.baseIndex)
	if not base then
		return false
	end
	local slotPos = base.slots[entry.slot]
	if not slotPos then
		return false
	end
	local model = BrainrotModels.buildOwned(entry.charId, entry.mutation)
	if not model then
		return false
	end
	-- Face the plaza centre so the tag reads from the middle of the map.
	-- The eyes sit on the model's +X face, so yaw it until +X points at the centre.
	local bodyPos = Vector3.new(slotPos.X, slotPos.Y + BrainrotModels.BODY_CENTER_Y, slotPos.Z)
	local dir = Vector3.new(-bodyPos.X, 0, -bodyPos.Z)
	local yaw = math.atan2(-dir.Z, dir.X)
	local cf = CFrame.new(bodyPos) * CFrame.Angles(0, yaw, 0)
	model:PivotTo(cf)
	model.Parent = game:GetService("Workspace").BrainrotWorld
	entry.model = model
	return true
end

return BrainrotModels
