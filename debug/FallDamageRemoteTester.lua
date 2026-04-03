local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local GLOBAL_ENV = getgenv and getgenv() or _G
local GLOBAL_KEY = "__huaj_hub_fall_damage_remote_tester_v1"

if GLOBAL_ENV[GLOBAL_KEY] and type(GLOBAL_ENV[GLOBAL_KEY].Unload) == "function" then
	pcall(GLOBAL_ENV[GLOBAL_KEY].Unload)
end

local connections = {}
local gui = nil
local frame = nil
local statusLabel = nil
local healthLabel = nil
local totalBox = nil
local damageBox = nil

local function trackConnection(connection)
	table.insert(connections, connection)
	return connection
end

local function getRequestModuleRemote()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local requestModule = remotes and remotes:FindFirstChild("RequestModule")
	if requestModule and requestModule:IsA("RemoteEvent") then
		return requestModule
	end
	return nil
end

local function getHumanoid()
	local character = LocalPlayer and LocalPlayer.Character
	return character and character:FindFirstChildOfClass("Humanoid") or nil
end

local function setStatus(text)
	if statusLabel then
		statusLabel.Text = "Status: " .. tostring(text or "Idle")
	end
end

local function refreshHealth()
	local humanoid = getHumanoid()
	if healthLabel then
		if humanoid then
			healthLabel.Text = string.format("Health: %.1f / %.1f", humanoid.Health, humanoid.MaxHealth)
		else
			healthLabel.Text = "Health: no humanoid"
		end
	end
end

local function parseNumber(text, fallback)
	local value = tonumber(text)
	if value == nil then
		return fallback
	end
	return value
end

local function firePayload(total, damage)
	local requestModule = getRequestModuleRemote()
	if not requestModule then
		setStatus("RequestModule not found")
		return
	end

	local ok, err = pcall(function()
		requestModule:FireServer("Misc", "FallDamage", nil, {
			FallDamageValueTotal = total,
			FallDamage = damage,
		})
	end)

	if ok then
		setStatus(string.format("Sent total=%s damage=%s", tostring(total), tostring(damage)))
	else
		setStatus("Send failed: " .. tostring(err))
	end
end

local function sendFromInputs()
	firePayload(
		parseNumber(totalBox and totalBox.Text, 0),
		parseNumber(damageBox and damageBox.Text, 0)
	)
end

local function setInputs(total, damage)
	if totalBox then
		totalBox.Text = tostring(total)
	end
	if damageBox then
		damageBox.Text = tostring(damage)
	end
	setStatus(string.format("Preset loaded total=%s damage=%s", tostring(total), tostring(damage)))
end

local function unload()
	for _, connection in ipairs(connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(connections)

	if gui then
		pcall(function()
			gui:Destroy()
		end)
		gui = nil
	end

	GLOBAL_ENV[GLOBAL_KEY] = nil
end

local function createButton(parent, text, position, size, backgroundColor)
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = backgroundColor
	button.BorderSizePixel = 0
	button.Font = Enum.Font.Code
	button.TextSize = 15
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = text
	button.Parent = parent
	return button
end

local function createLabel(parent, text, position, size, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.Code
	label.TextSize = 15
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = color or Color3.fromRGB(230, 230, 230)
	label.Text = text
	label.Parent = parent
	return label
end

local function createBox(parent, text, position)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 220, 0, 28)
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

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HuajHubFallDamageRemoteTester"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = CoreGui
gui = screenGui

frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0, 420, 0, 285)
frame.Position = UDim2.new(0.5, -210, 0.5, -142)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
frame.BorderColor3 = Color3.fromRGB(50, 120, 255)
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame

createLabel(frame, "FallDamage Remote Tester", UDim2.new(0, 12, 0, 8), UDim2.new(1, -90, 0, 24), Color3.fromRGB(245, 245, 245)).TextSize = 18

local exitButton = createButton(
	frame,
	"Exit",
	UDim2.new(1, -76, 0, 10),
	UDim2.new(0, 64, 0, 24),
	Color3.fromRGB(120, 30, 30)
)

createLabel(frame, "Target remote: ReplicatedStorage.Remotes.RequestModule", UDim2.new(0, 12, 0, 38), UDim2.new(1, -24, 0, 18), Color3.fromRGB(185, 185, 185))
healthLabel = createLabel(frame, "Health: ...", UDim2.new(0, 12, 0, 60), UDim2.new(1, -24, 0, 18), Color3.fromRGB(110, 200, 255))
statusLabel = createLabel(frame, "Status: Idle", UDim2.new(0, 12, 0, 82), UDim2.new(1, -24, 0, 18), Color3.fromRGB(255, 225, 140))

createLabel(frame, "FallDamageValueTotal", UDim2.new(0, 12, 0, 112), UDim2.new(0, 180, 0, 18))
totalBox = createBox(frame, "2.686142883300781", UDim2.new(0, 12, 0, 134))

createLabel(frame, "FallDamage", UDim2.new(0, 12, 0, 170), UDim2.new(0, 180, 0, 18))
damageBox = createBox(frame, "84.30714416503906", UDim2.new(0, 12, 0, 192))

local sendButton = createButton(
	frame,
	"Send Once",
	UDim2.new(1, -128, 0, 134),
	UDim2.new(0, 116, 0, 28),
	Color3.fromRGB(35, 90, 150)
)

local sendFiveButton = createButton(
	frame,
	"Send x5",
	UDim2.new(1, -128, 0, 170),
	UDim2.new(0, 116, 0, 28),
	Color3.fromRGB(45, 110, 65)
)

local safePresetButton = createButton(
	frame,
	"Preset: 0 / 0",
	UDim2.new(0, 12, 1, -46),
	UDim2.new(0, 122, 0, 28),
	Color3.fromRGB(55, 55, 55)
)

local negativePresetButton = createButton(
	frame,
	"Preset: -1 / -1",
	UDim2.new(0, 142, 1, -46),
	UDim2.new(0, 122, 0, 28),
	Color3.fromRGB(55, 55, 55)
)

local samplePresetButton = createButton(
	frame,
	"Preset: sample",
	UDim2.new(0, 272, 1, -46),
	UDim2.new(0, 122, 0, 28),
	Color3.fromRGB(55, 55, 55)
)

trackConnection(exitButton.MouseButton1Click:Connect(unload))
trackConnection(sendButton.MouseButton1Click:Connect(sendFromInputs))
trackConnection(sendFiveButton.MouseButton1Click:Connect(function()
	for _ = 1, 5 do
		sendFromInputs()
	end
end))
trackConnection(safePresetButton.MouseButton1Click:Connect(function()
	setInputs(0, 0)
end))
trackConnection(negativePresetButton.MouseButton1Click:Connect(function()
	setInputs(-1, -1)
end))
trackConnection(samplePresetButton.MouseButton1Click:Connect(function()
	setInputs(2.686142883300781, 84.30714416503906)
end))

trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Return and (UserInputService:GetFocusedTextBox() == totalBox or UserInputService:GetFocusedTextBox() == damageBox) then
		sendFromInputs()
	end
end))

trackConnection(game:GetService("RunService").Heartbeat:Connect(refreshHealth))

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

refreshHealth()

GLOBAL_ENV[GLOBAL_KEY] = {
	Unload = unload,
}

return GLOBAL_ENV[GLOBAL_KEY]
