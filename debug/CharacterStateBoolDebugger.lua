local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local GLOBAL_ENV = getgenv and getgenv() or _G
local GLOBAL_KEY = "__huaj_hub_character_state_bool_debugger_v1"
local MAX_LOG_LINES = 28

if GLOBAL_ENV[GLOBAL_KEY] and type(GLOBAL_ENV[GLOBAL_KEY].Unload) == "function" then
	pcall(GLOBAL_ENV[GLOBAL_KEY].Unload)
end

local connections = {}
local gui = nil
local frame = nil
local logLabel = nil
local statusLabel = nil
local logLines = {}

local function trackConnection(connection)
	table.insert(connections, connection)
	return connection
end

local function getCharacter()
	return LocalPlayer and LocalPlayer.Character
end

local function getLiveCharacter()
	local liveFolder = workspace:FindFirstChild("Live")
	if not liveFolder then
		return nil
	end

	local playerCharacter = getCharacter()
	if playerCharacter and playerCharacter.Parent == liveFolder then
		return playerCharacter
	end

	if LocalPlayer then
		local byName = liveFolder:FindFirstChild(LocalPlayer.Name)
		if byName and byName:IsA("Model") then
			return byName
		end
	end

	local fallback = liveFolder:FindFirstChild("TestAccNotRlly")
	if fallback and fallback:IsA("Model") then
		return fallback
	end

	return nil
end

local function getCharacterStateFolder()
	local character = getLiveCharacter()
	if not character then
		return nil
	end

	local stateFolder = character:FindFirstChild("CharacterState")
	if stateFolder and stateFolder:IsA("Folder") then
		return stateFolder
	end

	return nil
end

local function setStatus(text)
	if statusLabel then
		statusLabel.Text = "Status: " .. tostring(text or "Idle")
	end
end

local function refreshLog()
	if logLabel then
		logLabel.Text = #logLines > 0 and table.concat(logLines, "\n") or "Waiting for CharacterState bools..."
	end
end

local function pushLog(text)
	table.insert(logLines, 1, string.format("[%s] %s", os.date("%H:%M:%S"), tostring(text)))
	while #logLines > MAX_LOG_LINES do
		table.remove(logLines)
	end
	refreshLog()
end

local function describeBoolValue(instance, action)
	local lifetime = nil
	pcall(function()
		lifetime = instance:GetAttribute("Lifetime")
	end)

	pushLog(string.format(
		"%s %s value=%s lifetime=%s",
		tostring(action or "bool"),
		instance.Name,
		tostring(instance.Value),
		tostring(lifetime)
	))
end

local function disconnectAll()
	for _, connection in ipairs(connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(connections)
end

local function unload()
	disconnectAll()

	if gui then
		pcall(function()
			gui:Destroy()
		end)
		gui = nil
	end

	GLOBAL_ENV[GLOBAL_KEY] = nil
end

local function hookCharacterStateFolder(stateFolder)
	if not stateFolder then
		setStatus("CharacterState not found")
		return
	end

	setStatus("Watching " .. stateFolder:GetFullName())
	pushLog("Hooked " .. stateFolder:GetFullName())

	for _, child in ipairs(stateFolder:GetChildren()) do
		if child:IsA("BoolValue") then
			describeBoolValue(child, "existing")
		end
	end

	trackConnection(stateFolder.ChildAdded:Connect(function(child)
		if child:IsA("BoolValue") then
			describeBoolValue(child, "added")

			trackConnection(child:GetPropertyChangedSignal("Value"):Connect(function()
				describeBoolValue(child, "changed")
			end))

			trackConnection(child.AttributeChanged:Connect(function(attributeName)
				if attributeName == "Lifetime" then
					describeBoolValue(child, "attribute")
				end
			end))
		end
	end))
end

local function startWatching()
	disconnectAll()

	local function tryHook()
		local stateFolder = getCharacterStateFolder()
		if stateFolder then
			hookCharacterStateFolder(stateFolder)
			return true
		end
		setStatus("Waiting for CharacterState...")
		return false
	end

	if tryHook() then
		return
	end

	trackConnection(workspace.ChildAdded:Connect(function(child)
		if child.Name == "Live" then
			task.defer(tryHook)
		end
	end))

	trackConnection(Players.LocalPlayer.CharacterAdded:Connect(function()
		task.defer(tryHook)
	end))
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HuajHubCharacterStateBoolDebugger"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = CoreGui
gui = screenGui

frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0, 520, 0, 430)
frame.Position = UDim2.new(0.5, -260, 0.5, -215)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
frame.BorderColor3 = Color3.fromRGB(50, 120, 255)
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -90, 0, 28)
title.Position = UDim2.new(0, 12, 0, 8)
title.Font = Enum.Font.Code
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.Text = "CharacterState Bool Debugger"
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

local targetLabel = Instance.new("TextLabel")
targetLabel.BackgroundTransparency = 1
targetLabel.Size = UDim2.new(1, -24, 0, 20)
targetLabel.Position = UDim2.new(0, 12, 0, 42)
targetLabel.Font = Enum.Font.Code
targetLabel.TextSize = 14
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.TextColor3 = Color3.fromRGB(185, 185, 185)
targetLabel.Text = "Target: workspace.Live." .. tostring(LocalPlayer and LocalPlayer.Name or "Player") .. ".CharacterState"
targetLabel.Parent = frame

statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Size = UDim2.new(1, -24, 0, 20)
statusLabel.Position = UDim2.new(0, 12, 0, 66)
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextColor3 = Color3.fromRGB(110, 200, 255)
statusLabel.Text = "Status: Waiting..."
statusLabel.Parent = frame

local logFrame = Instance.new("Frame")
logFrame.Size = UDim2.new(1, -24, 1, -102)
logFrame.Position = UDim2.new(0, 12, 0, 90)
logFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
logFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
logFrame.Parent = frame

local logPadding = Instance.new("UIPadding")
logPadding.PaddingTop = UDim.new(0, 8)
logPadding.PaddingLeft = UDim.new(0, 8)
logPadding.PaddingRight = UDim.new(0, 8)
logPadding.PaddingBottom = UDim.new(0, 8)
logPadding.Parent = logFrame

logLabel = Instance.new("TextLabel")
logLabel.BackgroundTransparency = 1
logLabel.Size = UDim2.new(1, 0, 1, 0)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 14
logLabel.TextWrapped = false
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
logLabel.Text = "Waiting for CharacterState bools..."
logLabel.Parent = logFrame

trackConnection(exitButton.MouseButton1Click:Connect(unload))

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

startWatching()

GLOBAL_ENV[GLOBAL_KEY] = {
	Unload = unload,
}

return GLOBAL_ENV[GLOBAL_KEY]
