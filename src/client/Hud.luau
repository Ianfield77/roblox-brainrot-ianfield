-- Brainrot Bazaar: the whole player interface, built in code.
-- Cash and income up top, your base on the left, buttons along the bottom,
-- event banner under the cash, and the Index listing every brainrot.
-- The entry script only wires the buttons; this module owns every pixel.

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local Hud = {}

local gui = nil
local cashLabel = nil
local incomeLabel = nil
local rebirthLabel = nil
local ownedList = nil
local lockButton = nil
local rebirthButton = nil
local slotButton = nil
local speedButton = nil
local upgradesPanel = nil
local indexPanel = nil
local banner = nil
local bannerLabel = nil
local notifyLabel = nil
local hintLabel = nil
local callbacks = {}
local notifyToken = 0
local bannerToken = 0

local PANEL_BG = Color3.fromRGB(25, 25, 35)
local PANEL_STROKE = Color3.fromRGB(255, 220, 90)

local function makeFrame(parent, name, size, position, anchor)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = anchor or Vector2.new(0, 0)
	frame.BackgroundColor3 = PANEL_BG
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = PANEL_STROKE
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Parent = frame
	return frame
end

local function makeLabel(parent, name, size, position, text, textColor, textSize, anchor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.AnchorPoint = anchor or Vector2.new(0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor
	label.TextSize = textSize
	label.Font = Enum.Font.FredokaOne
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function makeButton(parent, name, size, position, text, anchor)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.AnchorPoint = anchor or Vector2.new(0, 0)
	button.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(30, 30, 30)
	button.TextSize = 20
	button.Font = Enum.Font.FredokaOne
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	return button
end

local function buildCash()
	local frame = makeFrame(gui, "CashFrame", UDim2.fromOffset(320, 84), UDim2.new(0.5, 0, 0, 12), Vector2.new(0.5, 0))
	cashLabel = makeLabel(frame, "Cash", UDim2.new(1, 0, 0, 46), UDim2.new(0, 0, 0, 4), "$100", Color3.fromRGB(255, 230, 120), 40, Vector2.new(0, 0))
	cashLabel.TextXAlignment = Enum.TextXAlignment.Center
	incomeLabel = makeLabel(frame, "Income", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 50), "$0/s", Color3.fromRGB(140, 255, 140), 22, Vector2.new(0, 0))
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Center
end

local function buildRebirthBadge()
	local frame = makeFrame(gui, "RebirthFrame", UDim2.fromOffset(230, 46), UDim2.new(1, -12, 0, 12), Vector2.new(1, 0))
	rebirthLabel = makeLabel(frame, "Rebirth", UDim2.new(1, -16, 1, 0), UDim2.new(0, 8, 0, 0), "Rebirth 0 • x1.00", Color3.fromRGB(255, 150, 220), 20)
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Center
end

local function buildBasePanel()
	local frame = makeFrame(gui, "BasePanel", UDim2.fromOffset(250, 320), UDim2.new(0, 12, 0.5, 0), Vector2.new(0, 0.5))
	makeLabel(frame, "Title", UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 0, 6), "BASEKU", Color3.fromRGB(255, 220, 90), 24)
	ownedList = Instance.new("Frame")
	ownedList.Name = "OwnedList"
	ownedList.Size = UDim2.new(1, -16, 1, -48)
	ownedList.Position = UDim2.new(0, 8, 0, 42)
	ownedList.BackgroundTransparency = 1
	ownedList.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = ownedList
end

local function buildButtons()
	local row = Instance.new("Frame")
	row.Name = "ButtonRow"
	row.Size = UDim2.fromOffset(560, 56)
	row.Position = UDim2.new(0.5, 0, 1, -12)
	row.AnchorPoint = Vector2.new(0.5, 1)
	row.BackgroundTransparency = 1
	row.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = row

	lockButton = makeButton(row, "LockButton", UDim2.fromOffset(130, 56), UDim2.new(0, 0, 0, 0), "Kunci Base")
	lockButton.MouseButton1Click:Connect(function()
		if callbacks.lock then
			callbacks.lock()
		end
	end)
	rebirthButton = makeButton(row, "RebirthButton", UDim2.fromOffset(150, 56), UDim2.new(0, 0, 0, 0), "Rebirth")
	rebirthButton.MouseButton1Click:Connect(function()
		if callbacks.rebirth then
			callbacks.rebirth()
		end
	end)
	local upgradesButton = makeButton(row, "UpgradesButton", UDim2.fromOffset(130, 56), UDim2.new(0, 0, 0, 0), "Upgrade")
	upgradesButton.MouseButton1Click:Connect(function()
		upgradesPanel.Visible = not upgradesPanel.Visible
	end)
	local indexButton = makeButton(row, "IndexButton", UDim2.fromOffset(130, 56), UDim2.new(0, 0, 0, 0), "Index")
	indexButton.MouseButton1Click:Connect(function()
		indexPanel.Visible = not indexPanel.Visible
	end)
end

local function buildUpgradesPanel()
	upgradesPanel = makeFrame(gui, "UpgradesPanel", UDim2.fromOffset(440, 120), UDim2.new(0.5, 0, 1, -80), Vector2.new(0.5, 1))
	upgradesPanel.Visible = false
	makeLabel(upgradesPanel, "Title", UDim2.new(1, -16, 0, 30), UDim2.new(0, 8, 0, 6), "UPGRADE", Color3.fromRGB(255, 220, 90), 22)
	slotButton = makeButton(upgradesPanel, "SlotButton", UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, 40), "Slot Base")
	slotButton.MouseButton1Click:Connect(function()
		if callbacks.upgrade then
			callbacks.upgrade("slot")
		end
	end)
	speedButton = makeButton(upgradesPanel, "SpeedButton", UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, 80), "Sepatu Cepat")
	speedButton.MouseButton1Click:Connect(function()
		if callbacks.upgrade then
			callbacks.upgrade("speed")
		end
	end)
end

local function buildIndexPanel()
	indexPanel = makeFrame(gui, "IndexPanel", UDim2.fromOffset(500, 430), UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5))
	indexPanel.Visible = false
	makeLabel(indexPanel, "Title", UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 0, 6), "INDEX BRAINROT", Color3.fromRGB(255, 220, 90), 24)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "List"
	scroll.Size = UDim2.new(1, -16, 1, -48)
	scroll.Position = UDim2.new(0, 8, 0, 42)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, #BrainrotData.CHARACTERS * 34)
	scroll.Parent = indexPanel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.Parent = scroll
	for _, char in ipairs(BrainrotData.CHARACTERS) do
		local rarity = BrainrotData.getRarity(char.rarity)
		local row = makeLabel(scroll, "Row" .. char.id, UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 0),
			char.name .. "  •  " .. char.rarity .. "  •  " .. BrainrotData.formatMoney(char.rate) .. "/s  •  " .. BrainrotData.formatMoney(BrainrotData.costFor(char, "Normal")),
			rarity.color, 17)
		row.TextXAlignment = Enum.TextXAlignment.Left
	end
end

local function buildBannerAndNotify()
	banner = makeFrame(gui, "Banner", UDim2.fromOffset(580, 52), UDim2.new(0.5, 0, 0, 108), Vector2.new(0.5, 0))
	banner.Visible = false
	bannerLabel = makeLabel(banner, "Text", UDim2.new(1, -16, 1, 0), UDim2.new(0, 8, 0, 0), "", Color3.fromRGB(255, 255, 255), 24)
	bannerLabel.TextXAlignment = Enum.TextXAlignment.Center

	notifyLabel = makeLabel(gui, "Notify", UDim2.fromOffset(460, 38), UDim2.new(0, 12, 1, -86), "", Color3.fromRGB(255, 255, 255), 18)
	notifyLabel.TextXAlignment = Enum.TextXAlignment.Left
	notifyLabel.BackgroundTransparency = 0.4
	notifyLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)

	hintLabel = makeLabel(gui, "Hint", UDim2.fromOffset(520, 32), UDim2.new(0.5, 0, 1, -140), "Klik brainrot di belt untuk membeli! Bawa pulang ke basemu.", Color3.fromRGB(255, 255, 255), 20, Vector2.new(0.5, 1))
	hintLabel.TextXAlignment = Enum.TextXAlignment.Center
end

function Hud.build(playerGui)
	gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui
	buildCash()
	buildRebirthBadge()
	buildBasePanel()
	buildButtons()
	buildUpgradesPanel()
	buildIndexPanel()
	buildBannerAndNotify()
end

function Hud.setCallbacks(cb)
	callbacks = cb
end

function Hud.update(state)
	if not gui then
		return
	end
	cashLabel.Text = BrainrotData.formatMoney(state.cash)
	incomeLabel.Text = BrainrotData.formatMoney(state.income) .. "/s"
	rebirthLabel.Text = "Rebirth " .. state.rebirths .. " • x" .. string.format("%.2f", state.multiplier)
	if state.isLocked then
		lockButton.Text = "Terkunci (" .. state.lockRemaining .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(120, 180, 255)
	elseif state.lockCooldown > 0 then
		lockButton.Text = "Kunci (" .. state.lockCooldown .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
	else
		lockButton.Text = "Kunci Base"
		lockButton.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
	end
	if state.canRebirth then
		rebirthButton.Text = "Rebirth: " .. BrainrotData.formatMoney(state.rebirthCost) .. "!"
		rebirthButton.BackgroundColor3 = Color3.fromRGB(140, 255, 140)
	else
		rebirthButton.Text = "Rebirth: " .. BrainrotData.formatMoney(state.rebirthCost)
		rebirthButton.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
	end
	if state.slotCost then
		slotButton.Text = "Slot Base (" .. state.slots .. "/" .. state.maxSlots .. "): " .. BrainrotData.formatMoney(state.slotCost)
	else
		slotButton.Text = "Slot Base: MAX"
	end
	if state.speedCost then
		speedButton.Text = "Sepatu Cepat Lv " .. state.speedLevel .. ": " .. BrainrotData.formatMoney(state.speedCost)
	else
		speedButton.Text = "Sepatu Cepat: MAX"
	end
	-- Rebuild the owned list.
	for _, child in ipairs(ownedList:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	if #state.owned == 0 then
		makeLabel(ownedList, "Empty", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 0), "Belum ada brainrot.", Color3.fromRGB(200, 200, 200), 16)
	else
		for _, owned in ipairs(state.owned) do
			local rarity = BrainrotData.getRarity(owned.rarity)
			local row = makeLabel(ownedList, "Owned" .. owned.name, UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 0),
				owned.name .. "  " .. BrainrotData.formatMoney(owned.rate) .. "/s", rarity.color, 16)
			row.TextXAlignment = Enum.TextXAlignment.Left
		end
	end
	if #state.owned > 0 then
		hintLabel.Visible = false
	end
end

function Hud.notify(message, kind)
	if not gui then
		return
	end
	notifyToken += 1
	local token = notifyToken
	if kind == "good" then
		notifyLabel.TextColor3 = Color3.fromRGB(140, 255, 140)
	elseif kind == "bad" then
		notifyLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
	else
		notifyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	notifyLabel.Text = message
	task.delay(5, function()
		if token == notifyToken then
			notifyLabel.Text = ""
		end
	end)
end

function Hud.announce(message, seconds)
	if not gui then
		return
	end
	bannerToken += 1
	local token = bannerToken
	bannerLabel.Text = message
	banner.Visible = true
	task.delay(seconds or 5, function()
		if token == bannerToken then
			banner.Visible = false
		end
	end)
end

return Hud
