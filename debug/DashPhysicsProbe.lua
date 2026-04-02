local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local GLOBAL_KEY = "__huaj_hub_dash_probe_v1"
local globalState = getgenv()

if globalState[GLOBAL_KEY] and type(globalState[GLOBAL_KEY].Unload) == "function" then
	pcall(globalState[GLOBAL_KEY].Unload)
end

local connections = {}
local activeSample = nil
local gui = nil
local resultLabel = nil
local detailLabel = nil
local statusLabel = nil

local function trackConnection(connection)
	table.insert(connections, connection)
	return connection
end

local function setStatus(text)
	if statusLabel then
		statusLabel.Text = "Status: " .. tostring(text or "Idle")
	end
end

local function setResult(summary, detail)
	if resultLabel then
		resultLabel.Text = "Result: " .. tostring(summary or "Waiting for dash...")
	end
	if detailLabel then
		detailLabel.Text = tostring(detail or "")
	end
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

local function getHorizontalMagnitude(vector)
	return Vector3.new(vector.X, 0, vector.Z).Magnitude
end

local function summarizeSample(sample)
	local moverNames = {}
	local seen = {}
	for _, moverName in ipairs(sample.movers) do
		if not seen[moverName] then
			seen[moverName] = true
			table.insert(moverNames, moverName)
		end
	end

	local method = "Direct position / CFrame"
	if #moverNames > 0 then
		method = table.concat(moverNames, ", ")
	elseif sample.peakVelocity >= 6 then
		method = "RootPart velocity"
	end

	local summary = string.format(
		"%s | peak vel %.1f | dist %.1f",
		method,
		sample.peakVelocity,
		sample.distance
	)

	local detail = string.format(
		"Velocity-based: %s | Body movers: %s | Frames: %d",
		sample.peakVelocity >= 6 and "yes" or "no",
		#moverNames > 0 and table.concat(moverNames, ", ") or "none",
		sample.frames
	)

	return summary, detail
end

local function finishSample(sample)
	activeSample = nil
	setStatus("Idle")
	local summary, detail = summarizeSample(sample)
	setResult(summary, detail)
end

local function beginSample()
	local character = getCharacter()
	local root = getRoot(character)
	if not character or not root then
		setResult("No character/root found", "Dash sample could not start.")
		return
	end

	activeSample = {
		startedAt = os.clock(),
		root = root,
		lastPosition = root.Position,
		distance = 0,
		peakVelocity = 0,
		movers = {},
		frames = 0,
	}

	setStatus("Sampling dash...")
	setResult("Sampling...", "Press Q once and wait for the result.")
end

local function sampleHeartbeat()
	local sample = activeSample
	if not sample then
		return
	end

	local root = sample.root
	if not root or not root.Parent then
		finishSample(sample)
		return
	end

	sample.frames += 1
	sample.distance += getHorizontalMagnitude(root.Position - sample.lastPosition)
	sample.lastPosition = root.Position
	sample.peakVelocity = math.max(sample.peakVelocity, getHorizontalMagnitude(root.AssemblyLinearVelocity))

	for _, descendant in ipairs(root:GetDescendants()) do
		local className = descendant.ClassName
		if className == "BodyVelocity"
			or className == "LinearVelocity"
			or className == "VectorForce"
			or className == "BodyPosition"
			or className == "AlignPosition"
			or className == "BodyGyro"
			or className == "AngularVelocity" then
			table.insert(sample.movers, className)
		end
	end

	if os.clock() - sample.startedAt >= 0.45 then
		finishSample(sample)
	end
end

local function unload()
	for _, connection in ipairs(connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(connections)

	activeSample = nil

	if gui then
		pcall(function()
			gui:Destroy()
		end)
		gui = nil
	end

	globalState[GLOBAL_KEY] = nil
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HuajHubDashProbe"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game:GetService("CoreGui")
gui = screenGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0, 360, 0, 180)
frame.Position = UDim2.new(0.5, -180, 0.5, -90)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
frame.BorderColor3 = Color3.fromRGB(50, 120, 255)
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -80, 0, 28)
title.Position = UDim2.new(0, 12, 0, 8)
title.Font = Enum.Font.Code
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.Text = "Huaj Hub Dash Probe"
title.Parent = frame

local exitButton = Instance.new("TextButton")
exitButton.Size = UDim2.new(0, 64, 0, 24)
exitButton.Position = UDim2.new(1, -76, 0, 10)
exitButton.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
exitButton.BorderSizePixel = 0
exitButton.Font = Enum.Font.Code
exitButton.TextSize = 16
exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
exitButton.Text = "Exit"
exitButton.Parent = frame

local info = Instance.new("TextLabel")
info.BackgroundTransparency = 1
info.Size = UDim2.new(1, -24, 0, 20)
info.Position = UDim2.new(0, 12, 0, 42)
info.Font = Enum.Font.Code
info.TextSize = 15
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextColor3 = Color3.fromRGB(185, 185, 185)
info.Text = "Press Q to sample one dash."
info.Parent = frame

statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Size = UDim2.new(1, -24, 0, 20)
statusLabel.Position = UDim2.new(0, 12, 0, 68)
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 15
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextColor3 = Color3.fromRGB(110, 200, 255)
statusLabel.Text = "Status: Idle"
statusLabel.Parent = frame

resultLabel = Instance.new("TextLabel")
resultLabel.BackgroundTransparency = 1
resultLabel.Size = UDim2.new(1, -24, 0, 40)
resultLabel.Position = UDim2.new(0, 12, 0, 98)
resultLabel.Font = Enum.Font.Code
resultLabel.TextWrapped = true
resultLabel.TextSize = 15
resultLabel.TextXAlignment = Enum.TextXAlignment.Left
resultLabel.TextYAlignment = Enum.TextYAlignment.Top
resultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
resultLabel.Text = "Result: Waiting for dash..."
resultLabel.Parent = frame

detailLabel = Instance.new("TextLabel")
detailLabel.BackgroundTransparency = 1
detailLabel.Size = UDim2.new(1, -24, 0, 28)
detailLabel.Position = UDim2.new(0, 12, 0, 138)
detailLabel.Font = Enum.Font.Code
detailLabel.TextWrapped = true
detailLabel.TextSize = 14
detailLabel.TextXAlignment = Enum.TextXAlignment.Left
detailLabel.TextYAlignment = Enum.TextYAlignment.Top
detailLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
detailLabel.Text = ""
detailLabel.Parent = frame

trackConnection(exitButton.MouseButton1Click:Connect(unload))

trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q and not activeSample then
		beginSample()
	end
end))

trackConnection(RunService.Heartbeat:Connect(sampleHeartbeat))

do
	local dragging = false
	local dragStart
	local startPos

	trackConnection(frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end))

	trackConnection(frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end))

	trackConnection(UserInputService.InputChanged:Connect(function(input)
		if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end))
end

TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	BackgroundTransparency = 0,
}):Play()

globalState[GLOBAL_KEY] = {
	Unload = unload,
}

return globalState[GLOBAL_KEY]
