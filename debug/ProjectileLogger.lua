local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local GLOBAL_ENV = getgenv and getgenv() or _G
local GLOBAL_KEY = "__huaj_hub_projectile_logger_v1"
local MAX_LOG_LINES = 32
local TRACK_LIFETIME = 4
local DEFAULT_MAX_DISTANCE = 60

if GLOBAL_ENV[GLOBAL_KEY] and type(GLOBAL_ENV[GLOBAL_KEY].Unload) == "function" then
	pcall(GLOBAL_ENV[GLOBAL_KEY].Unload)
end

local connections = {}
local tracked = {}
local gui
local frame
local statusLabel
local logLabel
local targetLabel
local distanceBox
local rangeIndicator
local rangeEnabled = true
local maxDistance = DEFAULT_MAX_DISTANCE
local logLines = {}
local dragState = {
	dragging = false,
	start = nil,
	origin = nil,
}

local KEYWORDS = {
	projectile = true,
	bullet = true,
	fireball = true,
	orb = true,
	beam = true,
	lance = true,
	arrow = true,
	shot = true,
	spell = true,
	magic = true,
	blast = true,
	hitbox = true,
}

local function trackConnection(connection)
	table.insert(connections, connection)
	return connection
end

local function setStatus(text)
	if statusLabel then
		statusLabel.Text = "Status: " .. tostring(text or "Idle")
	end
end

local function refreshLog()
	if logLabel then
		logLabel.Text = #logLines > 0 and table.concat(logLines, "\n") or "Waiting for projectile-like instances..."
	end
end

local function pushLog(text)
	table.insert(logLines, 1, string.format("[%s] %s", os.date("%H:%M:%S"), tostring(text)))
	while #logLines > MAX_LOG_LINES do
		table.remove(logLines)
	end
	refreshLog()
end

local function getCharacter()
	return LocalPlayer and LocalPlayer.Character
end

local function getRoot(character)
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
end

local function hasProjectileKeyword(name)
	local lowered = string.lower(tostring(name or ""))
	for keyword in pairs(KEYWORDS) do
		if string.find(lowered, keyword, 1, true) then
			return true
		end
	end
	return false
end

local function isUnderLikelyProjectileFolder(instance)
	local current = instance
	while current do
		if current == workspace:FindFirstChild("FX") then
			return true
		end
		if current == workspace:FindFirstChild("Live") then
			return true
		end
		if string.lower(current.Name) == "projectiles" then
			return true
		end
		current = current.Parent
	end
	return false
end

local function getBasePart(instance)
	if not instance then
		return nil
	end
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		return instance.PrimaryPart
			or instance:FindFirstChild("HumanoidRootPart")
			or instance:FindFirstChildWhichIsA("BasePart")
	end
	return instance:FindFirstAncestorWhichIsA("BasePart")
end

local function getInstancePosition(instance)
	local basePart = getBasePart(instance)
	if basePart then
		return basePart.Position
	end
	if instance:IsA("Attachment") then
		return instance.WorldPosition
	end
	return nil
end

local function getSpeed(instance)
	local basePart = getBasePart(instance)
	if not basePart then
		return 0
	end
	local velocity = basePart.AssemblyLinearVelocity
	return velocity and velocity.Magnitude or 0
end

local function getDistanceToLocalPlayer(instance)
	local localRoot = getRoot(getCharacter())
	local position = getInstancePosition(instance)
	if not localRoot or not position then
		return nil
	end
	return (position - localRoot.Position).Magnitude
end

local function getMaxDistance()
	return math.max(tonumber(maxDistance) or DEFAULT_MAX_DISTANCE, 1)
end

local function findOwnerHint(instance)
	local current = instance
	while current do
		local owner = current:FindFirstChild("Owner")
			or current:FindFirstChild("Creator")
			or current:FindFirstChild("CurrentAggro")
			or current:FindFirstChild("Caster")
			or current:FindFirstChild("Source")

		if owner then
			if owner:IsA("ObjectValue") and owner.Value then
				return owner.Value:GetFullName()
			end
			if owner:IsA("StringValue") then
				return owner.Value
			end
		end

		current = current.Parent
	end

	return nil
end

local function describeInstance(instance)
	local speed = getSpeed(instance)
	local distance = getDistanceToLocalPlayer(instance)
	local ownerHint = findOwnerHint(instance)
	local parentName = instance.Parent and instance.Parent:GetFullName() or "nil"

	return string.format(
		"%s (%s) speed=%.1f dist=%s parent=%s%s",
		instance:GetFullName(),
		instance.ClassName,
		speed,
		distance and string.format("%.1f", distance) or "?",
		parentName,
		ownerHint and (" owner=" .. tostring(ownerHint)) or ""
	)
end

local function shouldTrackInstance(instance)
	if not instance or not instance.Parent then
		return false
	end

	if instance:IsDescendantOf(getCharacter() or Instance.new("Folder")) then
		return false
	end

	if instance:IsA("Beam") or instance:IsA("Trail") or instance:IsA("ParticleEmitter") then
		return hasProjectileKeyword(instance.Name) or isUnderLikelyProjectileFolder(instance)
	end

	if instance:IsA("Attachment") then
		return hasProjectileKeyword(instance.Name) and isUnderLikelyProjectileFolder(instance)
	end

	if instance:IsA("BasePart") or instance:IsA("Model") then
		local distance = getDistanceToLocalPlayer(instance)
		if distance and distance > getMaxDistance() then
			return false
		end

		local speed = getSpeed(instance)
		if speed >= 30 then
			return true
		end
		if hasProjectileKeyword(instance.Name) then
			return true
		end
		return isUnderLikelyProjectileFolder(instance) and speed >= 12
	end

	return false
end

local function addTrackedInstance(instance, reason)
	if tracked[instance] then
		return
	end

	local distance = getDistanceToLocalPlayer(instance)
	if distance and distance > getMaxDistance() then
		return
	end

	tracked[instance] = {
		addedAt = os.clock(),
		reason = reason or "matched",
	}

	pushLog(string.format("track %s | reason=%s", describeInstance(instance), tostring(reason or "matched")))
end

local function scanExisting()
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if shouldTrackInstance(descendant) then
			addTrackedInstance(descendant, "existing")
		end
	end
end

local function unload()
	for _, connection in ipairs(connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(connections)
	table.clear(tracked)

	if rangeIndicator then
		pcall(function()
			rangeIndicator:Destroy()
		end)
		rangeIndicator = nil
	end

	if gui then
		pcall(function()
			gui:Destroy()
		end)
		gui = nil
	end

	GLOBAL_ENV[GLOBAL_KEY] = nil
end

local function parseDistance(text)
	local value = tonumber(text)
	if not value then
		return DEFAULT_MAX_DISTANCE
	end
	return math.max(value, 1)
end

local function updateRangeIndicator()
	if not rangeIndicator then
		return
	end

	local character = getCharacter()
	local root = getRoot(character)
	if not rangeEnabled or not root then
		rangeIndicator.Transparency = 1
		return
	end

	rangeIndicator.Size = Vector3.new(getMaxDistance() * 2, 0.15, getMaxDistance() * 2)
	rangeIndicator.CFrame = CFrame.new(root.Position.X, root.Position.Y - 2.8, root.Position.Z) * CFrame.Angles(math.rad(90), 0, 0)
	rangeIndicator.Transparency = 0.65
end

local function createLabel(parent, text, position, size, color, wrapped)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.Code
	label.TextSize = 14
	label.TextWrapped = wrapped == true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextColor3 = color or Color3.fromRGB(230, 230, 230)
	label.Text = text
	label.Parent = parent
	return label
end

local function createButton(parent, text, position, size, color)
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.Code
	button.TextSize = 15
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = text
	button.Parent = parent
	return button
end

local function createBox(parent, text, position, size)
	local box = Instance.new("TextBox")
	box.Size = size
	box.Position = position
	box.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	box.BorderColor3 = Color3.fromRGB(60, 60, 60)
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.Code
	box.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.TextSize = 15
	box.Text = text
	box.Parent = parent
	return box
end

gui = Instance.new("ScreenGui")
gui.Name = "HuajHubProjectileLogger"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0, 700, 0, 430)
frame.Position = UDim2.new(0.5, -350, 0.5, -215)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
frame.BorderColor3 = Color3.fromRGB(120, 90, 255)
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame

createLabel(frame, "Projectile Logger", UDim2.new(0, 12, 0, 8), UDim2.new(1, -100, 0, 24), Color3.fromRGB(245, 245, 245)).TextSize = 18

local exitButton = createButton(frame, "Exit", UDim2.new(1, -76, 0, 10), UDim2.new(0, 64, 0, 24), Color3.fromRGB(120, 30, 30))
local rescanButton = createButton(frame, "Rescan", UDim2.new(1, -152, 0, 10), UDim2.new(0, 64, 0, 24), Color3.fromRGB(45, 95, 60))
local visualizerButton = createButton(frame, "Visualizer", UDim2.new(1, -238, 0, 10), UDim2.new(0, 78, 0, 24), Color3.fromRGB(65, 65, 105))

targetLabel = createLabel(
	frame,
	"Watching nearby projectile-like instances under FX, Live, or projectile-named objects.",
	UDim2.new(0, 12, 0, 40),
	UDim2.new(1, -24, 0, 36),
	Color3.fromRGB(185, 185, 185),
	true
)

createLabel(frame, "Distance", UDim2.new(0, 12, 0, 80), UDim2.new(0, 80, 0, 18), Color3.fromRGB(220, 220, 220))
distanceBox = createBox(frame, tostring(DEFAULT_MAX_DISTANCE), UDim2.new(0, 82, 0, 76), UDim2.new(0, 70, 0, 24))
statusLabel = createLabel(frame, "Status: Starting...", UDim2.new(0, 12, 0, 108), UDim2.new(1, -24, 0, 18), Color3.fromRGB(110, 200, 255))

local logFrame = Instance.new("Frame")
logFrame.Size = UDim2.new(1, -24, 1, -120)
logFrame.Position = UDim2.new(0, 12, 0, 136)
logFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
logFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
logFrame.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = logFrame

logLabel = createLabel(logFrame, "Waiting for projectile-like instances...", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Color3.fromRGB(240, 240, 240), true)

trackConnection(exitButton.MouseButton1Click:Connect(unload))
trackConnection(rescanButton.MouseButton1Click:Connect(function()
	table.clear(tracked)
	pushLog("manual rescan started")
	scanExisting()
end))
trackConnection(visualizerButton.MouseButton1Click:Connect(function()
	rangeEnabled = not rangeEnabled
	visualizerButton.Text = rangeEnabled and "Visualizer" or "Visualizer Off"
	updateRangeIndicator()
end))
trackConnection(distanceBox.FocusLost:Connect(function()
	maxDistance = parseDistance(distanceBox.Text)
	distanceBox.Text = tostring(math.floor(getMaxDistance() + 0.5))
	table.clear(tracked)
	pushLog("distance set to " .. tostring(distanceBox.Text))
	scanExisting()
end))

trackConnection(frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragState.dragging = true
		dragState.start = input.Position
		dragState.origin = frame.Position
	end
end))

trackConnection(frame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragState.dragging = false
	end
end))

trackConnection(UserInputService.InputChanged:Connect(function(input)
	if not dragState.dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local delta = input.Position - dragState.start
	frame.Position = UDim2.new(
		dragState.origin.X.Scale,
		dragState.origin.X.Offset + delta.X,
		dragState.origin.Y.Scale,
		dragState.origin.Y.Offset + delta.Y
	)
end))

trackConnection(workspace.DescendantAdded:Connect(function(instance)
	if shouldTrackInstance(instance) then
		addTrackedInstance(instance, "added")
	end
end))

trackConnection(RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for instance, state in pairs(tracked) do
		if not instance or not instance.Parent then
			tracked[instance] = nil
		elseif (getDistanceToLocalPlayer(instance) or math.huge) > getMaxDistance() then
			tracked[instance] = nil
		elseif now - (state.addedAt or now) > TRACK_LIFETIME then
			tracked[instance] = nil
		end
	end

	updateRangeIndicator()
	setStatus(string.format("Tracking %d recent projectile-like instance(s)", (function()
		local count = 0
		for _ in pairs(tracked) do
			count += 1
		end
		return count
	end)()))
end))

pushLog("logger started")
scanExisting()

rangeIndicator = Instance.new("Part")
rangeIndicator.Name = "HuajHubProjectileLoggerRange"
rangeIndicator.Anchored = true
rangeIndicator.CanCollide = false
rangeIndicator.CanQuery = false
rangeIndicator.CanTouch = false
rangeIndicator.Material = Enum.Material.ForceField
rangeIndicator.Color = Color3.fromRGB(120, 90, 255)
rangeIndicator.Shape = Enum.PartType.Cylinder
rangeIndicator.Transparency = 0.65
rangeIndicator.Parent = workspace
updateRangeIndicator()

GLOBAL_ENV[GLOBAL_KEY] = {
	Unload = unload,
}

return GLOBAL_ENV[GLOBAL_KEY]
