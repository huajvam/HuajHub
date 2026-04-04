local HyakuAsura = {}
local GAME_KEY = "hyaku_asura"

local Services = sharedRequire("@utils/Services.lua")
local Maid = sharedRequire("@utils/Maid.lua")
local CharacterUtils = sharedRequire("@utils/CharacterUtils.lua")
local EntityESP = sharedRequire("classes/EntityESP.lua")

local Players, MarketplaceService, RunService = Services:Get(
	"Players",
	"MarketplaceService",
	"RunService"
)

local Library = sharedRequire("ui/Linoria/Library.lua")
local ThemeManager = sharedRequire("ui/Linoria/addons/ThemeManager.lua")
local SaveManager = sharedRequire("ui/Linoria/addons/SaveManager.lua")

local GLOBAL_ENV = getgenv and getgenv() or _G
local HUAJ_HUB_HYAKU_INIT_KEY = "__huaj_hub_hyaku_initialized_v1"
local HUAJ_HUB_HYAKU_LIBRARY_KEY = "__huaj_hub_hyaku_library_v1"
local HUAJ_HUB_HYAKU_ESP_DRAWINGS_KEY = "__huaj_hub_hyaku_esp_drawings_v1"
local HYAKU_RHYTHM_REMOTE_INTERVAL = 0.1

local LocalPlayer = Players.LocalPlayer
local maid = Maid.new()
local unloadCallbacks = {}

local getCharacterRoot = CharacterUtils.getRoot
local getCharacterHumanoid = CharacterUtils.getHumanoid
local getEspLiveFolder = CharacterUtils.getLiveFolder

local function registerLibraryUnloadCallback(callback)
	table.insert(unloadCallbacks, callback)
end

local function sanitizeTabLabel(name)
	if type(name) ~= "string" then
		return "Hyaku Asura"
	end

	name = name:gsub("[%z\1-\31]", "")
	name = name:match("^%s*(.-)%s*$") or name
	return name ~= "" and name or "Hyaku Asura"
end

local function getGameTabName()
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)

	if ok and type(info) == "table" and type(info.Name) == "string" then
		return sanitizeTabLabel(info.Name)
	end

	return "Hyaku Asura"
end

local function isLocalCharacter(model)
	return model ~= nil and LocalPlayer and LocalPlayer.Character == model
end

local function getEspTargetType(model)
	if not model or not model:IsA("Model") or isLocalCharacter(model) then
		return nil
	end

	local ownerPlayer = Players:GetPlayerFromCharacter(model)
	if ownerPlayer then
		return ownerPlayer ~= LocalPlayer and "player" or nil
	end

	local humanoid = getCharacterHumanoid(model)
	local root = getCharacterRoot(model)
	local hasAnimator = model:FindFirstChildWhichIsA("Animator", true) ~= nil
	local hasAnimationController = model:FindFirstChildWhichIsA("AnimationController", true) ~= nil

	if humanoid and root then
		return "mob"
	end

	if root and (hasAnimator or hasAnimationController) then
		return "mob"
	end

	return nil
end

local function getEspDistance(model)
	local localCharacter = LocalPlayer and LocalPlayer.Character
	local localRoot = getCharacterRoot(localCharacter)
	local targetRoot = getCharacterRoot(model)
	if not localRoot or not targetRoot then
		return math.huge
	end

	return (targetRoot.Position - localRoot.Position).Magnitude
end

local function getEspDisplayName(model, targetType)
	if targetType == "player" then
		local player = Players:GetPlayerFromCharacter(model)
		if player then
			return player.DisplayName ~= "" and player.DisplayName or player.Name
		end
	end

	return model.Name
end

local function clearGlobalEspDrawings(globalEspDrawings)
	for index = #globalEspDrawings, 1, -1 do
		local object = globalEspDrawings[index]
		if object then
			pcall(function()
				object.Visible = false
			end)
			pcall(function()
				if type(object.Remove) == "function" then
					object:Remove()
				elseif type(object.Destroy) == "function" then
					object:Destroy()
				end
			end)
		end
		globalEspDrawings[index] = nil
	end
end

local function iterEspCandidateModels()
	local models = {}
	local seen = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character and not seen[character] then
			seen[character] = true
			table.insert(models, character)
		end
	end

	local liveFolder = getEspLiveFolder()
	if liveFolder then
		for _, child in ipairs(liveFolder:GetChildren()) do
			if child:IsA("Model") and not seen[child] then
				seen[child] = true
				table.insert(models, child)
			end
		end
	end

	return models
end

function HyakuAsura.init(_context)
	if GLOBAL_ENV[HUAJ_HUB_HYAKU_INIT_KEY] then
		local existingLibrary = GLOBAL_ENV[HUAJ_HUB_HYAKU_LIBRARY_KEY]
		if type(existingLibrary) == "table" and type(existingLibrary.Unload) == "function" then
			pcall(function()
				existingLibrary:Unload()
			end)
		end

		GLOBAL_ENV[HUAJ_HUB_HYAKU_INIT_KEY] = nil
		GLOBAL_ENV[HUAJ_HUB_HYAKU_LIBRARY_KEY] = nil
	end

	GLOBAL_ENV[HUAJ_HUB_HYAKU_INIT_KEY] = true
	GLOBAL_ENV[HUAJ_HUB_HYAKU_LIBRARY_KEY] = Library

	local gameTabName = getGameTabName()

	Library:OnUnload(function()
		for _, callback in ipairs(unloadCallbacks) do
			pcall(callback)
		end
	end)

	local Window = Library:CreateWindow({
		Title = "Huaj Hub",
		Center = true,
		AutoShow = true,
		Size = UDim2.fromOffset(550, 600),
		TabPadding = 0,
		MenuFadeTime = 0.2,
	})

	local Tabs = {
		Main = Window:AddTab(gameTabName),
		ESP = Window:AddTab("ESP"),
		Settings = Window:AddTab("Settings"),
	}

	do
		local infoGroup = Tabs.Main:AddLeftGroupbox("Info")
		local localCheatsGroup = Tabs.Main:AddRightGroupbox("Local Cheats")
		local infiniteRhythmLoopToken = 0

		local function getRhythmInputRemote()
			local character = LocalPlayer and LocalPlayer.Character
			if not character then
				return nil
			end

			local mainScript = character:FindFirstChild("MainScript")
			if not mainScript then
				return nil
			end

			local inputRemote = mainScript:FindFirstChild("Input")
			if inputRemote and inputRemote:IsA("RemoteEvent") then
				return inputRemote
			end

			return nil
		end

		local function fireInfiniteRhythmRemote()
			local inputRemote = getRhythmInputRemote()
			if not inputRemote then
				return false
			end

			local payload = {
				{
					KeyInfo = {
						Direction = "None",
						Name = "R",
						Airborne = false,
					},
					IsDown = true,
				},
			}

			pcall(function()
				inputRemote:FireServer(unpack(payload))
			end)

			return true
		end

		local function startInfiniteRhythmLoop()
			infiniteRhythmLoopToken += 1
			local currentToken = infiniteRhythmLoopToken
			task.spawn(function()
				while currentToken == infiniteRhythmLoopToken and Toggles.InfiniteRhythmEnabled and Toggles.InfiniteRhythmEnabled.Value do
					fireInfiniteRhythmRemote()
					task.wait(HYAKU_RHYTHM_REMOTE_INTERVAL)
				end
			end)
		end

		local function stopInfiniteRhythmLoop()
			infiniteRhythmLoopToken += 1
		end

		infoGroup:AddLabel("Hyaku Asura scaffold loaded.")
		infoGroup:AddLabel("ESP is available now.")
		infoGroup:AddLabel("Game-specific features can be added later.")

		localCheatsGroup:AddToggle("InfiniteRhythmEnabled", {
			Text = "Infinite Rhythm",
			Default = false,
		}):OnChanged(function(enabled)
			if enabled then
				startInfiniteRhythmLoop()
			else
				stopInfiniteRhythmLoop()
			end
		end)

		registerLibraryUnloadCallback(function()
			stopInfiniteRhythmLoop()
			if Toggles and Toggles.InfiniteRhythmEnabled then
				pcall(function()
					Toggles.InfiniteRhythmEnabled:SetValue(false)
				end)
			end
		end)
	end

	do
		local espGroup = Tabs.ESP:AddLeftGroupbox("ESP")
		local espVisualGroup = Tabs.ESP:AddRightGroupbox("ESP Visuals")
		local playerEspEntries = {}
		local mobEspEntries = {}
		local globalEspDrawings = GLOBAL_ENV[HUAJ_HUB_HYAKU_ESP_DRAWINGS_KEY] or {}
		local drawingAvailable = type(Drawing) == "table" and type(Drawing.new) == "function"
		local espDrawUnavailableNotified = false
		local espShuttingDown = false

		GLOBAL_ENV[HUAJ_HUB_HYAKU_ESP_DRAWINGS_KEY] = globalEspDrawings

		local function clearEspCache(cache)
			for model, entry in pairs(cache) do
				cache[model] = nil
				if entry and type(entry.Destroy) == "function" then
					entry:Destroy()
				end
			end
		end

		local function forceClearEsp()
			clearEspCache(playerEspEntries)
			clearEspCache(mobEspEntries)
			clearGlobalEspDrawings(globalEspDrawings)
		end

		local function ensureEspEntry(cache, model, accentColor)
			if espShuttingDown or not drawingAvailable or not model or not model.Parent then
				return nil
			end

			local entry = cache[model]
			if not entry then
				entry = EntityESP.new(globalEspDrawings, accentColor, function()
					return espShuttingDown
				end)
				entry.model = model
				cache[model] = entry
			end

			entry:setAccentColor(accentColor)
			return entry
		end

		local function getEspBoundingBox(model)
			local camera = workspace.CurrentCamera
			if not camera or not model then
				return nil
			end

			local cf, size = model:GetBoundingBox()
			local corners = {}
			for x = -1, 1, 2 do
				for y = -1, 1, 2 do
					for z = -1, 1, 2 do
						table.insert(corners, cf * Vector3.new(size.X * 0.5 * x, size.Y * 0.5 * y, size.Z * 0.5 * z))
					end
				end
			end

			local minX, minY = math.huge, math.huge
			local maxX, maxY = -math.huge, -math.huge
			local onScreenCorner = false

			for _, worldPoint in ipairs(corners) do
				local viewportPoint, onScreen = camera:WorldToViewportPoint(worldPoint)
				if viewportPoint.Z > 0 then
					minX = math.min(minX, viewportPoint.X)
					minY = math.min(minY, viewportPoint.Y)
					maxX = math.max(maxX, viewportPoint.X)
					maxY = math.max(maxY, viewportPoint.Y)
					onScreenCorner = onScreenCorner or onScreen
				end
			end

			if minX == math.huge or minY == math.huge or maxX == -math.huge or maxY == -math.huge then
				return nil
			end

			return {
				left = minX,
				top = minY,
				right = maxX,
				bottom = maxY,
				width = maxX - minX,
				height = maxY - minY,
				onScreen = onScreenCorner,
			}
		end

		local function getEspRigPoints(model)
			local camera = workspace.CurrentCamera
			if not camera then
				return {}
			end

			local projectedPoints = {}
			local pointNames = {
				"Head",
				"UpperTorso",
				"LowerTorso",
				"LeftUpperArm",
				"LeftLowerArm",
				"LeftHand",
				"RightUpperArm",
				"RightLowerArm",
				"RightHand",
				"LeftUpperLeg",
				"LeftLowerLeg",
				"LeftFoot",
				"RightUpperLeg",
				"RightLowerLeg",
				"RightFoot",
				"Torso",
				"Left Arm",
				"Right Arm",
				"Left Leg",
				"Right Leg",
			}

			for _, partName in ipairs(pointNames) do
				local part = model:FindFirstChild(partName, true)
				if part and part:IsA("BasePart") then
					local viewportPoint, onScreen = camera:WorldToViewportPoint(part.Position)
					if onScreen and viewportPoint.Z > 0 then
						projectedPoints[partName] = Vector2.new(viewportPoint.X, viewportPoint.Y)
					end
				end
			end

			return projectedPoints
		end

		local function updateEspSkeleton(entry, model, accentColor)
			local projectedPoints = getEspRigPoints(model)
			local lineIndex = 1
			local skeletonPairs = {
				{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"},
				{"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"},
				{"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"},
				{"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"},
				{"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}, {"Head", "Torso"},
				{"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
			}

			for _, pair in ipairs(skeletonPairs) do
				local point0 = projectedPoints[pair[1]]
				local point1 = projectedPoints[pair[2]]
				local line = entry.skeletonLines[lineIndex]
				if line then
					if point0 and point1 then
						line.From = point0
						line.To = point1
						line.Color = accentColor
						line.Visible = true
					else
						line.Visible = false
					end
					lineIndex = lineIndex + 1
				end
			end

			entry:hideSkeletonFrom(lineIndex)
		end

		local function updateEspEntry(entry, model, targetType, accentColor)
			local humanoid = getCharacterHumanoid(model)
			local distance = getEspDistance(model)
			local box = getEspBoundingBox(model)
			if not box or box.width < 2 or box.height < 2 or not box.onScreen then
				entry:hide()
				return
			end

			local topLeft = Vector2.new(box.left, box.top)
			local topRight = Vector2.new(box.right, box.top)
			local bottomLeft = Vector2.new(box.left, box.bottom)
			local bottomRight = Vector2.new(box.right, box.bottom)
			local camera = workspace.CurrentCamera
			local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
			local tracerStart = Vector2.new(viewportSize.X * 0.5, viewportSize.Y - 2)
			local tracerEnd = Vector2.new(box.left + (box.width * 0.5), box.bottom)

			entry:setBox({
				{topLeft, topRight},
				{topRight, bottomRight},
				{bottomRight, bottomLeft},
				{bottomLeft, topLeft},
			}, accentColor, Toggles.EspShowBox.Value)

			local health = humanoid and math.max(humanoid.Health, 0) or 0
			local maxHealth = humanoid and math.max(humanoid.MaxHealth, 1) or 100
			local healthRatio = math.clamp(health / maxHealth, 0, 1)
			local barHeight = math.max(box.height, 4)
			local barWidth = 4
			local barX = box.left - 7

			entry:setHealthBar(
				Vector2.new(barX, box.top),
				Vector2.new(barWidth, barHeight),
				Vector2.new(barX + 1, box.bottom - ((barHeight - 2) * healthRatio) - 1),
				Vector2.new(barWidth - 2, math.max((barHeight - 2) * healthRatio, 1)),
				Color3.fromRGB(
					math.floor(255 * (1 - healthRatio)),
					math.floor(255 * healthRatio),
					90
				),
				Toggles.EspShowHealthBar.Value and humanoid ~= nil
			)

			entry:setText(
				entry.nameText,
				getEspDisplayName(model, targetType),
				Vector2.new(box.left + (box.width * 0.5), box.top - 14),
				Toggles.EspShowNames.Value
			)

			entry:setText(
				entry.distanceText,
				string.format("%.0f studs", distance),
				Vector2.new(box.left + (box.width * 0.5), box.bottom + 1),
				Toggles.EspShowDistance.Value
			)

			entry:setText(
				entry.healthText,
				string.format("%d / %d HP", math.floor(health + 0.5), math.floor(maxHealth + 0.5)),
				Vector2.new(box.left + (box.width * 0.5), box.top - 27),
				Toggles.EspShowHealthText.Value and humanoid ~= nil
			)

			entry:setTracer(tracerStart, tracerEnd, accentColor, Toggles.EspShowTracers.Value)

			if Toggles.EspShowSkeleton.Value then
				updateEspSkeleton(entry, model, accentColor)
			else
				entry:hideSkeletonFrom(1)
			end
		end

		local function updateTypedEsp(cache, targetType, accentColor)
			local enabledToggle = targetType == "player" and Toggles.PlayerEspEnabled or Toggles.MobEspEnabled
			if not drawingAvailable then
				clearEspCache(cache)
				return
			end

			if not enabledToggle.Value then
				clearEspCache(cache)
				return
			end

			local validModels = {}
			for _, model in ipairs(iterEspCandidateModels()) do
				if getEspTargetType(model) == targetType then
					local humanoid = getCharacterHumanoid(model)
					local aliveEnough = humanoid == nil or humanoid.Health > 0
					local maxDistance = Options.EspRenderDistance.Value or 500

					if aliveEnough and getEspDistance(model) <= maxDistance then
						validModels[model] = true
						local entry = ensureEspEntry(cache, model, accentColor)
						if entry then
							updateEspEntry(entry, model, targetType, accentColor)
						end
					end
				end
			end

			for model, entry in pairs(cache) do
				if not validModels[model] then
					cache[model] = nil
					if entry and type(entry.Destroy) == "function" then
						entry:Destroy()
					end
				end
			end
		end

		local function refreshEsp()
			if espShuttingDown then
				forceClearEsp()
				return
			end

			if not drawingAvailable and not espDrawUnavailableNotified then
				espDrawUnavailableNotified = true
				Library:Notify("Drawing API is unavailable in this executor; overlay ESP cannot render.", 3)
				return
			end

			updateTypedEsp(playerEspEntries, "player", Color3.fromRGB(40, 170, 255))
			updateTypedEsp(mobEspEntries, "mob", Color3.fromRGB(80, 255, 140))
		end

		local function scheduleEspRefresh()
			task.defer(function()
				refreshEsp()
			end)
		end

		espGroup:AddToggle("PlayerEspEnabled", {
			Text = "Player ESP",
			Default = false,
		})

		espGroup:AddToggle("MobEspEnabled", {
			Text = "Mob ESP",
			Default = false,
		})

		espVisualGroup:AddToggle("EspShowNames", {
			Text = "Show Names",
			Default = true,
		})

		espVisualGroup:AddToggle("EspShowDistance", {
			Text = "Show Distance",
			Default = true,
		})

		espVisualGroup:AddToggle("EspShowHealthText", {
			Text = "Show Health Text",
			Default = false,
		})

		espVisualGroup:AddToggle("EspShowHealthBar", {
			Text = "Show Health Bar",
			Default = true,
		})

		espVisualGroup:AddToggle("EspShowBox", {
			Text = "Box ESP",
			Default = true,
		})

		espVisualGroup:AddToggle("EspShowSkeleton", {
			Text = "Skeleton ESP",
			Default = false,
		})

		espVisualGroup:AddToggle("EspShowTracers", {
			Text = "Tracer Lines",
			Default = true,
		})

		espVisualGroup:AddSlider("EspRenderDistance", {
			Text = "Render Distance",
			Default = 500,
			Min = 10,
			Max = 2000,
			Rounding = 0,
			Suffix = " studs",
		})

		Toggles.PlayerEspEnabled:OnChanged(refreshEsp)
		Toggles.MobEspEnabled:OnChanged(refreshEsp)
		Toggles.EspShowNames:OnChanged(refreshEsp)
		Toggles.EspShowDistance:OnChanged(refreshEsp)
		Toggles.EspShowHealthText:OnChanged(refreshEsp)
		Toggles.EspShowHealthBar:OnChanged(refreshEsp)
		Toggles.EspShowBox:OnChanged(refreshEsp)
		Toggles.EspShowTracers:OnChanged(refreshEsp)
		Options.EspRenderDistance:OnChanged(refreshEsp)
		Toggles.EspShowSkeleton:OnChanged(function()
			clearEspCache(playerEspEntries)
			clearEspCache(mobEspEntries)
			refreshEsp()
		end)

		maid:GiveTask(Players.PlayerAdded:Connect(function(player)
			maid:GiveTask(player.CharacterAdded:Connect(scheduleEspRefresh))
			scheduleEspRefresh()
		end))
		maid:GiveTask(Players.PlayerRemoving:Connect(scheduleEspRefresh))

		for _, player in ipairs(Players:GetPlayers()) do
			maid:GiveTask(player.CharacterAdded:Connect(scheduleEspRefresh))
		end

		local liveFolder = getEspLiveFolder()
		if liveFolder then
			maid:GiveTask(liveFolder.ChildAdded:Connect(scheduleEspRefresh))
			maid:GiveTask(liveFolder.ChildRemoved:Connect(scheduleEspRefresh))
		end

		maid:GiveTask(workspace.ChildAdded:Connect(function(child)
			if child.Name == "Live" then
				scheduleEspRefresh()
			end
		end))

		maid:GiveTask(RunService.Heartbeat:Connect(function()
			if Toggles.PlayerEspEnabled.Value or Toggles.MobEspEnabled.Value then
				refreshEsp()
			end
		end))

		registerLibraryUnloadCallback(function()
			espShuttingDown = true
			pcall(function()
				if Toggles.PlayerEspEnabled then
					Toggles.PlayerEspEnabled:SetValue(false)
				end
			end)
			pcall(function()
				if Toggles.MobEspEnabled then
					Toggles.MobEspEnabled:SetValue(false)
				end
			end)
			forceClearEsp()
		end)
	end

	do
		ThemeManager:SetLibrary(Library)
		SaveManager:SetLibrary(Library)
		SaveManager:IgnoreThemeSettings()
		ThemeManager:SetFolder("HuajHub")
		SaveManager:SetFolder("HuajHub/" .. GAME_KEY)
		SaveManager:BuildConfigSection(Tabs.Settings)
		ThemeManager:ApplyToTab(Tabs.Settings)

		local menuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
		menuGroup:AddButton("Unload", function()
			Library:Unload()
		end)
	end

	registerLibraryUnloadCallback(function()
		maid:DoCleaning()
		GLOBAL_ENV[HUAJ_HUB_HYAKU_INIT_KEY] = nil
		GLOBAL_ENV[HUAJ_HUB_HYAKU_LIBRARY_KEY] = nil
	end)
end

return HyakuAsura
