local MashleAcademy = {}
local REPO_BASE = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local GAME_KEY = "mashle_academy"

local Services = sharedRequire("@utils/Services.lua")
local Maid = sharedRequire("@utils/Maid.lua")
local AnimationInfo = sharedRequire("@utils/AnimationInfo.lua")
local CharacterUtils = sharedRequire("@utils/CharacterUtils.lua")
local AnimatorUtils = sharedRequire("@utils/AnimatorUtils.lua")
local AutoParryConfigUtils = sharedRequire("@utils/AutoParryConfigUtils.lua")
local AdaptiveTimingUtils = sharedRequire("@utils/AdaptiveTimingUtils.lua")
local EntityESP = sharedRequire("classes/EntityESP.lua")
local TrackedAnimatorRegistry = sharedRequire("classes/TrackedAnimatorRegistry.lua")

local Players, ContextActionService, HttpService, MarketplaceService, ReplicatedStorage, RunService, Stats, UserInputService, VirtualInputManager = Services:Get(
	"Players",
	"ContextActionService",
	"HttpService",
	"MarketplaceService",
	"ReplicatedStorage",
	"RunService",
	"Stats",
	"UserInputService",
	"VirtualInputManager"
)

local GLOBAL_ENV = getgenv and getgenv() or _G
local ANIM_LOGGER_RUNTIME_KEY = "__anim_logger_v254_runtime"
local ANIM_LOGGER_OPTIONS_KEY = "__anim_logger_v254_options"
local HUAJ_HUB_MANUAL_ACTION_CALLBACK_KEY = "__huaj_hub_manual_action_callback_v1"
local HUAJ_HUB_MANUAL_ACTION_HOOK_KEY = "__huaj_hub_manual_action_hook_v1"
local HUAJ_HUB_MANUAL_ACTION_SUPPRESS_KEY = "__huaj_hub_manual_action_suppress_v1"
local HUAJ_HUB_REQUEST_MODULE_FIRESERVER_HOOK_KEY = "__huaj_hub_requestmodule_fireserver_hook_v1"
local HUAJ_HUB_ESP_DRAWINGS_KEY = "__huaj_hub_esp_drawings_v1"
local HUAJ_HUB_MASHLE_INIT_KEY = "__huaj_hub_mashle_initialized_v1"
local HUAJ_HUB_MASHLE_LIBRARY_KEY = "__huaj_hub_mashle_library_v1"

local ANIM_LOGGER_FILE_CANDIDATES = {
	"AnimLogger.lua",
	".\\AnimLogger.lua",
	"./AnimLogger.lua",
	".\\legacy\\AnimLogger.lua",
	"./legacy/AnimLogger.lua",
	".\\scripts\\AnimLogger.lua",
	"./scripts/AnimLogger.lua",
	"scripts/AnimLogger.lua",
	".\\src\\games\\mashle_academy\\AnimLogger.lua",
	"./src/games/mashle_academy/AnimLogger.lua",
}

local Library = loadstring(game:HttpGet(REPO_BASE .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(REPO_BASE .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(REPO_BASE .. "addons/SaveManager.lua"))()
local maid = Maid.new()

local normalizeAnimationId = AnimationInfo.normalizeId
local normalizeBuilderAnimationId = AnimationInfo.extractNumericId
local resolveDetectedAnimationName = AnimationInfo.resolveDetectedName
local getCharacterRoot = CharacterUtils.getRoot
local getCharacterHumanoid = CharacterUtils.getHumanoid
local getHorizontalEdgeDistance = CharacterUtils.getHorizontalEdgeDistance
local getEspLiveFolder = CharacterUtils.getLiveFolder
local getTargetAnimator = AnimatorUtils.getPrimaryAnimator
local getTargetAnimators = AnimatorUtils.getAllAnimators
local getConfigActionType = AutoParryConfigUtils.getConfigActionType
local buildRuntimeMoveConfig = AutoParryConfigUtils.buildRuntimeMoveConfig
local resolveConfiguredTiming = AutoParryConfigUtils.resolveConfiguredTiming
local unloadCallbacks = {}
local MASHLE_TELEPORT_LOCATIONS = {
	{
		name = "Example Spot",
		cframe = CFrame.new(0, 10, 0),
	},
	-- {
	-- 	name = "Arena",
	-- 	cframe = CFrame.new(100, 15, -250),
	-- },
	-- {
	-- 	name = "Shop",
	-- 	cframe = CFrame.new(-320, 12, 480),
	-- },
}

local function registerLibraryUnloadCallback(callback)
	table.insert(unloadCallbacks, callback)
end

Library:OnUnload(function()
	for _, callback in ipairs(unloadCallbacks) do
		pcall(callback)
	end
end)

local function sanitizeTabLabel(name)
	if type(name) ~= "string" then
		return "Cheats"
	end

	name = name:gsub("🤡", "")
	name = name:gsub("[%z\1-\31]", "")
	name = name:match("^%s*(.-)%s*$") or name

	if name == "" then
		return "Cheats"
	end

	return name
end

function MashleAcademy.init(_context)
	if GLOBAL_ENV[HUAJ_HUB_MASHLE_INIT_KEY] then
		local existingLibrary = GLOBAL_ENV[HUAJ_HUB_MASHLE_LIBRARY_KEY]
		if type(existingLibrary) == "table" and type(existingLibrary.Unload) == "function" then
			pcall(function()
				existingLibrary:Unload()
			end)
		end

		GLOBAL_ENV[HUAJ_HUB_MASHLE_INIT_KEY] = nil
		GLOBAL_ENV[HUAJ_HUB_MASHLE_LIBRARY_KEY] = nil
	end

	GLOBAL_ENV[HUAJ_HUB_MASHLE_INIT_KEY] = true
	GLOBAL_ENV[HUAJ_HUB_MASHLE_LIBRARY_KEY] = Library

local function getGameTabName()
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)

	if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
		return sanitizeTabLabel(info.Name)
	end

	if type(game.Name) == "string" and game.Name ~= "" then
		return sanitizeTabLabel(game.Name)
	end

	return "Cheats"
end

local gameTabName = getGameTabName()
local LocalPlayer = Players.LocalPlayer
local function makeAutoParryAction(config)
	return config
end

local AUTO_PARRY_ANIMATION_TABLE = {
	Players = {
		["PLAYER_ANIMATION_ID_HERE"] = 0.08,
		["PLAYER_SPECIAL_MOVE_ID_HERE"] = makeAutoParryAction({
			timing = 0.08,
			dash = true,
			block = false,
		}),
	},
	Mobs = {
		["rbxassetid://15445854546"] = 0.33,
        ["rbxassetid://15445853798"] = 0.45,
		["rbxassetid://0"] = 0.75,
		["rbxassetid://0"] = makeAutoParryAction({
			timing = 1.95,
			dash = true,
			block = false,
		}),
	},
}

GLOBAL_ENV.HuajHubAutoParryAnimations = AUTO_PARRY_ANIMATION_TABLE

local function appendUniquePath(pathList, seenPaths, path)
	if type(path) ~= "string" or path == "" or seenPaths[path] then
		return
	end

	seenPaths[path] = true
	table.insert(pathList, path)
end

local function getCurrentChunkSource()
	if type(debug) == "table" and type(debug.info) == "function" then
		local ok, source = pcall(function()
			return debug.info(1, "s")
		end)
		if ok and type(source) == "string" and source ~= "" then
			return source
		end
	end

	if type(debug) == "table" and type(debug.getinfo) == "function" then
		local ok, info = pcall(function()
			return debug.getinfo(1, "S")
		end)
		if ok and type(info) == "table" and type(info.source) == "string" and info.source ~= "" then
			return info.source
		end
	end
end

local function getSourceDirectory(source)
	if type(source) ~= "string" or source == "" then
		return nil
	end

	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end

	local normalized = source:gsub("/", "\\")
	return normalized:match("^(.*)\\[^\\]+$")
end

local function getAnimLoggerPathCandidates()
	local candidates = {}
	local seenPaths = {}

	for _, path in ipairs(ANIM_LOGGER_FILE_CANDIDATES) do
		appendUniquePath(candidates, seenPaths, path)
	end

	local sourceDir = getSourceDirectory(getCurrentChunkSource())
	if sourceDir then
		appendUniquePath(candidates, seenPaths, sourceDir .. "\\AnimLogger.lua")
		appendUniquePath(candidates, seenPaths, sourceDir .. "/AnimLogger.lua")
	end

	if type(listfiles) == "function" then
		for _, root in ipairs({
			".",
			".\\legacy",
			"./legacy",
			".\\scripts",
			"./scripts",
			"scripts",
			".\\src\\games\\mashle_academy",
			"./src/games/mashle_academy",
		}) do
			local ok, files = pcall(function()
				return listfiles(root)
			end)

			if ok and type(files) == "table" then
				for _, filePath in ipairs(files) do
					if type(filePath) == "string" and filePath:match("[/\\]AnimLogger%.lua$") then
						appendUniquePath(candidates, seenPaths, filePath)
					end
				end
			end
		end
	end

	return candidates
end

local function canUsePath(path)
	if type(isfile) ~= "function" then
		return true
	end

	local existsOk, exists = pcall(function()
		return isfile(path)
	end)

	if existsOk then
		return exists
	end

	return true
end

local function executeAnimLoggerChunk(chunk, runtimeOptions)
	GLOBAL_ENV[ANIM_LOGGER_OPTIONS_KEY] = runtimeOptions or {
		headless = true,
	}

	local runOk, runErr = pcall(chunk)
	GLOBAL_ENV[ANIM_LOGGER_OPTIONS_KEY] = nil

	if not runOk then
		return false, tostring(runErr)
	end

	local runtime = GLOBAL_ENV[ANIM_LOGGER_RUNTIME_KEY]
	if type(runtime) ~= "table" or type(runtime.api) ~= "table" then
		return false, "logger runtime did not expose api"
	end

	return true, runtime
end

local function tryExecuteAnimLoggerFromPath(path, runtimeOptions)
	local loaderErrors = {}

	if type(loadfile) == "function" then
		local compileOk, chunkOrErr = pcall(function()
			return loadfile(path)
		end)
		local hasChunk = compileOk and type(chunkOrErr) == "function"

		if hasChunk then
			local runOk, runtimeOrErr = executeAnimLoggerChunk(chunkOrErr, runtimeOptions)
			if runOk then
				return runtimeOrErr
			end
			table.insert(loaderErrors, "loadfile run failed: " .. tostring(runtimeOrErr))
		end

		if not compileOk then
			table.insert(loaderErrors, "loadfile failed: " .. tostring(chunkOrErr))
		elseif not hasChunk and chunkOrErr ~= nil then
			table.insert(loaderErrors, "loadfile returned unsupported value")
		end
	end

	if type(readfile) == "function" and type(loadstring) == "function" then
		local readOk, source = pcall(function()
			return readfile(path)
		end)

		if readOk and type(source) == "string" and source ~= "" then
			local compileOk, chunkOrErr = pcall(loadstring, source)
			local hasChunk = compileOk and type(chunkOrErr) == "function"
			if hasChunk then
				local runOk, runtimeOrErr = executeAnimLoggerChunk(chunkOrErr, runtimeOptions)
				if runOk then
					return runtimeOrErr
				end
				table.insert(loaderErrors, "loadstring run failed: " .. tostring(runtimeOrErr))
			end

			if not compileOk then
				table.insert(loaderErrors, "loadstring compile failed: " .. tostring(chunkOrErr))
			elseif not hasChunk and chunkOrErr ~= nil then
				table.insert(loaderErrors, "loadstring returned unsupported value")
			end
		elseif readOk then
			table.insert(loaderErrors, "readfile returned empty source")
		end

		if not readOk then
			table.insert(loaderErrors, "readfile failed: " .. tostring(source))
		end
	end

	if type(dofile) == "function" then
		GLOBAL_ENV[ANIM_LOGGER_OPTIONS_KEY] = runtimeOptions or {
			headless = true,
		}

		local runOk, runErr = pcall(function()
			return dofile(path)
		end)
		GLOBAL_ENV[ANIM_LOGGER_OPTIONS_KEY] = nil

		if runOk then
			local runtime = GLOBAL_ENV[ANIM_LOGGER_RUNTIME_KEY]
			if type(runtime) == "table" and type(runtime.api) == "table" then
				return runtime
			end
			table.insert(loaderErrors, "dofile did not expose runtime")
		else
			table.insert(loaderErrors, "dofile failed: " .. tostring(runErr))
		end
	end

	if #loaderErrors == 0 then
		return nil, "no supported file loader succeeded for " .. path
	end

	return nil, "failed to load logger from " .. path .. " (" .. table.concat(loaderErrors, "; ") .. ")"
end

local function ensureAnimLoggerRuntime()
	local existing = GLOBAL_ENV[ANIM_LOGGER_RUNTIME_KEY]
	if type(existing) == "table" and type(existing.api) == "table" then
		return existing
	end

	local lastError = "failed to load AnimLogger.lua"
	local triedPaths = {}

	for _, path in ipairs(getAnimLoggerPathCandidates()) do
		local runtime, err = tryExecuteAnimLoggerFromPath(path)
		if runtime then
			return runtime
		end
		table.insert(triedPaths, path)
		lastError = err or ("failed to load logger from " .. path)
	end

	if #triedPaths > 0 then
		lastError = string.format("%s (tried %d path%s; last: %s)", "failed to load AnimLogger.lua", #triedPaths, #triedPaths == 1 and "" or "s", tostring(lastError))
	end

	return nil, lastError
end

local function openAnimLoggerUi()
	local existing = GLOBAL_ENV[ANIM_LOGGER_RUNTIME_KEY]
	if type(existing) == "table" and type(existing.api) == "table" and type(existing.api.openUi) == "function" then
		existing.api.openUi()
		return existing
	end

	local lastError = "failed to load AnimLogger.lua"
	local triedPaths = {}

	for _, path in ipairs(getAnimLoggerPathCandidates()) do
		local runtime, err = tryExecuteAnimLoggerFromPath(path, {
			headless = false,
		})
		if runtime then
			if type(runtime.api) == "table" and type(runtime.api.openUi) == "function" then
				runtime.api.openUi()
			end
			return runtime
		end
		table.insert(triedPaths, path)
		lastError = err or ("failed to load logger from " .. path)
	end

	if #triedPaths > 0 then
		lastError = string.format("%s (tried %d path%s; last: %s)", "failed to load AnimLogger.lua", #triedPaths, #triedPaths == 1 and "" or "s", tostring(lastError))
	end

	return nil, lastError
end

local function getRequestModuleRemote()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local requestModule = remotes and remotes:FindFirstChild("RequestModule")
	if requestModule and requestModule:IsA("RemoteEvent") then
		return requestModule
	end
	return nil
end

local function getUpdateCharacterStateRemote()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local updateCharacterState = remotes and remotes:FindFirstChild("UpdateCharacterState")
	if updateCharacterState and updateCharacterState:IsA("RemoteEvent") then
		return updateCharacterState
	end
	return nil
end

local function fireBlockingStateRemote(isBlocking)
	local updateCharacterState = getUpdateCharacterStateRemote()
	if not updateCharacterState then
		return false
	end

	pcall(function()
		updateCharacterState:FireServer("Blocking", isBlocking and true or false)
	end)

	return true
end

local function getOtherPlayerNames()
	local names = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(names, player.Name)
		end
	end

	table.sort(names)
	return names
end

local fallDebugState = {
	windowUntil = 0,
	lastArmAt = 0,
	lastHealth = nil,
	lastSampleAt = 0,
	lastFloorMaterial = nil,
	lastHumanoidState = nil,
}

local function isFallDebugEnabled()
	return Toggles and Toggles.FallDamageDebugEnabled and Toggles.FallDamageDebugEnabled.Value == true
end

local function isAutoParryEnabled()
	return Toggles and Toggles.AutoParryEnabled and Toggles.AutoParryEnabled.Value == true
end

local function beginFallDebugWindow(reason, duration)
	if not isFallDebugEnabled() then
		return
	end

	local now = os.clock()
	fallDebugState.windowUntil = math.max(fallDebugState.windowUntil or 0, now + math.max(duration or 3, 0.25))
	warn(string.format("[HuajHub FallDebug] window opened: %s", tostring(reason or "unknown")))
end

local function shouldLogFallDebug()
	return isFallDebugEnabled() and os.clock() <= (fallDebugState.windowUntil or 0)
end

local function logFallDebug(message)
	if shouldLogFallDebug() then
		warn("[HuajHub FallDebug] " .. tostring(message))
	end
end

local function encodeDebugPayload(value)
	if not shouldLogFallDebug() then
		return ""
	end

	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(value)
	end)
	return ok and encoded or "<unencodable>"
end

local Window = Library:CreateWindow({
	Title = "Huaj Hub",
	Center = true,
	AutoShow = true,
	Size = UDim2.fromOffset(550, 600),
	TabPadding = 0,
	MenuFadeTime = 0.2,
})

warn("[HuajHub] Window created for mashle_academy")

local tabDefinitions = {
	{key = "Local Cheats", label = gameTabName, group = gameTabName},
	{key = "Auto Parry", label = "Auto Parry", group = "Auto Parry"},
	{key = "Player Mods", label = "ESP", group = "ESP"},
	{key = "Misc", label = "Misc"},
	{key = "Settings", label = "Settings"},
}

local Tabs = {
}

for _, tab in ipairs(tabDefinitions) do
	Tabs[tab.key] = Window:AddTab(tab.label)
end

for _, tab in ipairs(tabDefinitions) do
	if tab.key == "Misc" or tab.key == "Settings" or tab.key == "Player Mods" or tab.key == "Auto Parry" then
		continue
	end

	if tab.key ~= "Local Cheats" then
		local group = Tabs[tab.key]:AddLeftGroupbox(tab.group or tab.key)
		group:AddLabel("Scaffold ready.")
		group:AddLabel("Features will be added later.")
	end
end

local function setupLocalCheatsTab()
	local mainTab = Tabs["Local Cheats"]
	local combatGroup = mainTab:AddLeftGroupbox("Local Cheats")
	local teleportGroup = mainTab:AddRightGroupbox("Teleports")
	local speedHackConnection = nil
	local flyConnection = nil
	local noclipConnection = nil
	local noclipPartStates = {}
	local antiFallConnection = nil
	local antiFallHeartbeatConnection = nil
	local antiFallCharacterConnection = nil
	local knockedOwnershipCharacterConnection = nil
	local knockedOwnershipStateAddedConnection = nil
	local knockedOwnershipStateRemovedConnection = nil
	local speedHackVelocity = nil
	local flyVelocity = nil
	local antiFallState = nil
	local antiFallProtectedUntil = 0
	local knockedOwnershipLoopToken = 0
	local teleportLocations = {}
	local teleportLabels = {"(none)"}
	local triggerAntiFallBypass
	local ensureAntiFallState

	local function setTeleportDropdownValues(selectedLabel)
		table.sort(teleportLabels, function(left, right)
			if left == "(none)" then
				return true
			end
			if right == "(none)" then
				return false
			end
			return left < right
		end)

		Options.TeleportDestination:SetValues(teleportLabels)

		if selectedLabel and teleportLocations[selectedLabel] then
			Options.TeleportDestination:SetValue(selectedLabel)
		elseif not teleportLocations[Options.TeleportDestination.Value] then
			Options.TeleportDestination:SetValue("(none)")
		end
	end

	local function refreshTeleportLocations()
		teleportLocations = {}
		teleportLabels = {"(none)"}

		for _, location in ipairs(MASHLE_TELEPORT_LOCATIONS) do
			if type(location) == "table" and type(location.name) == "string" and typeof(location.cframe) == "CFrame" then
				local label = location.name
				local duplicateIndex = 2

				while teleportLocations[label] do
					label = string.format("%s (%d)", location.name, duplicateIndex)
					duplicateIndex += 1
				end

				teleportLocations[label] = {
					name = location.name,
					cframe = location.cframe,
				}
				table.insert(teleportLabels, label)
			end
		end

		setTeleportDropdownValues(teleportLabels[2])
	end

	local function teleportToSelectedDestination()
		local selection = Options.TeleportDestination.Value
		local destination = selection and teleportLocations[selection]
		if not destination then
			Library:Notify("No teleport destination selected.", 2)
			return
		end

		local character = LocalPlayer and LocalPlayer.Character
		local root = getCharacterRoot(character)
		local targetCFrame = destination.cframe
		if not character or not root or typeof(targetCFrame) ~= "CFrame" then
			Library:Notify("Selected destination is unavailable.", 2)
			return
		end

		triggerAntiFallBypass(character, 2.5)
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = targetCFrame
		task.defer(function()
			if character and character.Parent then
				triggerAntiFallBypass(character, 1.5)
			end
		end)
		Library:Notify("Teleported to " .. tostring(selection) .. ".", 2)
	end

	local function destroyBodyMover(bodyMover)
		if bodyMover then
			pcall(function()
				bodyMover:Destroy()
			end)
		end
	end

	local function stopSpeedHack()
		if speedHackConnection then
			speedHackConnection:Disconnect()
			speedHackConnection = nil
		end
		destroyBodyMover(speedHackVelocity)
		speedHackVelocity = nil
	end

	local function stopFly()
		if flyConnection then
			flyConnection:Disconnect()
			flyConnection = nil
		end
		destroyBodyMover(flyVelocity)
		flyVelocity = nil
	end

	local function setCharacterNoclip(enabled)
		local character = LocalPlayer and LocalPlayer.Character
		if not character then
			return
		end

		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") then
				if enabled then
					if noclipPartStates[descendant] == nil then
						noclipPartStates[descendant] = descendant.CanCollide
					end
					descendant.CanCollide = false
				elseif noclipPartStates[descendant] ~= nil then
					descendant.CanCollide = noclipPartStates[descendant]
					noclipPartStates[descendant] = nil
				end
			end
		end
	end

	local function stopNoclip()
		if noclipConnection then
			noclipConnection:Disconnect()
			noclipConnection = nil
		end
		setCharacterNoclip(false)
		table.clear(noclipPartStates)
	end

	local function stopKnockedOwnership()
		knockedOwnershipLoopToken += 1
		if knockedOwnershipStateAddedConnection then
			knockedOwnershipStateAddedConnection:Disconnect()
			knockedOwnershipStateAddedConnection = nil
		end
		if knockedOwnershipStateRemovedConnection then
			knockedOwnershipStateRemovedConnection:Disconnect()
			knockedOwnershipStateRemovedConnection = nil
		end
		if knockedOwnershipCharacterConnection then
			knockedOwnershipCharacterConnection:Disconnect()
			knockedOwnershipCharacterConnection = nil
		end
	end

	local function isAntiFallActive()
		return Toggles and Toggles.AntiFallDamageEnabled and Toggles.AntiFallDamageEnabled.Value == true
	end

	local function shouldMaintainAntiFallState()
		return isAntiFallActive() and os.clock() <= antiFallProtectedUntil
	end

	local function getCharacterStateFolder(character)
		if not character then
			return nil
		end

		local characterState = character:FindFirstChild("CharacterState")
		if characterState and characterState:IsA("Folder") then
			return characterState
		end

		return nil
	end

	local function removeAntiFallState()
		if antiFallState then
			pcall(function()
				antiFallState:Destroy()
			end)
		end

		antiFallState = nil
	end

	ensureAntiFallState = function(character)
		if not shouldMaintainAntiFallState() or not character then
			return
		end

		local characterState = getCharacterStateFolder(character)
		if not characterState then
			return
		end

		if antiFallState and antiFallState.Parent ~= characterState then
			antiFallState = nil
		end

		if not antiFallState then
			local existing = characterState:FindFirstChild("FallNegate")
			if existing and existing:IsA("BoolValue") then
				antiFallState = existing
			else
				local fallNegate = Instance.new("BoolValue")
				fallNegate.Name = "FallNegate"
				fallNegate.Value = true
				fallNegate.Parent = characterState
				antiFallState = fallNegate
				logFallDebug(string.format("anti-fall created: %s", fallNegate:GetFullName()))
			end
		end

		if antiFallState then
			pcall(function()
				antiFallState.Value = true
			end)
		end
	end

	local function stopAntiFall()
		if antiFallConnection then
			antiFallConnection:Disconnect()
			antiFallConnection = nil
		end
		if antiFallCharacterConnection then
			antiFallCharacterConnection:Disconnect()
			antiFallCharacterConnection = nil
		end
		if antiFallHeartbeatConnection then
			antiFallHeartbeatConnection:Disconnect()
			antiFallHeartbeatConnection = nil
		end

		antiFallProtectedUntil = 0
		removeAntiFallState()
	end

	local function getCharacterMovementState()
		local character = LocalPlayer and LocalPlayer.Character
		local humanoid = getCharacterHumanoid(character)
		local rootPart = getCharacterRoot(character)
		if not humanoid or not rootPart then
			return nil, nil
		end

		return humanoid, rootPart
	end

	local function getKnockedOwnershipTool(character)
		local backpack = LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack")
		local handle = backpack and backpack:FindFirstChild("Handle", true)
		local handleTool = handle and handle.Parent
		local weapon = (backpack and backpack:FindFirstChild("Weapon")) or (character and character:FindFirstChild("Weapon"))

		return handleTool or weapon
	end

	local function beginKnockedOwnershipLoop(character, knockedValue)
		knockedOwnershipLoopToken += 1
		local loopToken = knockedOwnershipLoopToken

		task.spawn(function()
			while loopToken == knockedOwnershipLoopToken do
				if not Toggles.KnockedOwnershipEnabled or not Toggles.KnockedOwnershipEnabled.Value then
					break
				end
				if not character or not character.Parent or not knockedValue or not knockedValue.Parent then
					break
				end

				local tool = getKnockedOwnershipTool(character)
				local backpack = LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack")
				if tool and tool.Parent then
					pcall(function()
						tool.Parent = character
					end)
					task.wait(tool.Name == "Weapon" and 0.15 or 0.05)
					if loopToken ~= knockedOwnershipLoopToken then
						break
					end
					if backpack and tool.Parent == character then
						pcall(function()
							tool.Parent = backpack
						end)
					end
					task.wait(tool.Name == "Weapon" and 0.15 or 0.05)
				else
					task.wait(0.1)
				end
			end

			if loopToken == knockedOwnershipLoopToken and Toggles.KnockedOwnershipEnabled and Toggles.KnockedOwnershipEnabled.Value then
				local tool = getKnockedOwnershipTool(character)
				if tool and character and character.Parent then
					pcall(function()
						tool.Parent = character
					end)
				end
			end
		end)
	end

	local function startKnockedOwnership()
		stopKnockedOwnership()

		local function hookCharacter(character)
			if knockedOwnershipStateAddedConnection then
				knockedOwnershipStateAddedConnection:Disconnect()
				knockedOwnershipStateAddedConnection = nil
			end
			if knockedOwnershipStateRemovedConnection then
				knockedOwnershipStateRemovedConnection:Disconnect()
				knockedOwnershipStateRemovedConnection = nil
			end

			local characterState = getCharacterStateFolder(character)
			if not characterState then
				return
			end

			local function refreshKnockedState()
				local knockedValue = characterState:FindFirstChild("Knocked")
				if knockedValue and knockedValue:IsA("BoolValue") then
					beginKnockedOwnershipLoop(character, knockedValue)
				else
					knockedOwnershipLoopToken += 1
				end
			end

			knockedOwnershipStateAddedConnection = characterState.ChildAdded:Connect(function(child)
				if child.Name == "Knocked" and child:IsA("BoolValue") then
					refreshKnockedState()
				end
			end)

			knockedOwnershipStateRemovedConnection = characterState.ChildRemoved:Connect(function(child)
				if child.Name == "Knocked" then
					knockedOwnershipLoopToken += 1
				end
			end)

			refreshKnockedState()
		end

		local currentCharacter = LocalPlayer and LocalPlayer.Character
		if currentCharacter then
			hookCharacter(currentCharacter)
		end

		knockedOwnershipCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
			knockedOwnershipLoopToken += 1
			task.defer(function()
				if Toggles.KnockedOwnershipEnabled and Toggles.KnockedOwnershipEnabled.Value then
					hookCharacter(character)
				end
			end)
		end)
	end

	local function ensureSpeedHackVelocity(rootPart)
		if speedHackVelocity and speedHackVelocity.Parent ~= rootPart then
			destroyBodyMover(speedHackVelocity)
			speedHackVelocity = nil
		end

		if not speedHackVelocity then
			speedHackVelocity = Instance.new("BodyVelocity")
			speedHackVelocity.Name = "HuajHubSpeedHackVelocity"
			speedHackVelocity.MaxForce = Vector3.new(100000, 0, 100000)
			speedHackVelocity.P = 10000
		end

		speedHackVelocity.Parent = rootPart
		return speedHackVelocity
	end

	local function ensureFlyVelocity(rootPart)
		if flyVelocity and flyVelocity.Parent ~= rootPart then
			destroyBodyMover(flyVelocity)
			flyVelocity = nil
		end

		if not flyVelocity then
			flyVelocity = Instance.new("BodyVelocity")
			flyVelocity.Name = "HuajHubFlyVelocity"
			flyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			flyVelocity.P = 10000
		end

		flyVelocity.Parent = rootPart
		return flyVelocity
	end

	local function getFlyMoveVector()
		local moveVector = Vector3.zero

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveVector += Vector3.new(0, 0, -1)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveVector += Vector3.new(0, 0, 1)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveVector += Vector3.new(-1, 0, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveVector += Vector3.new(1, 0, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			moveVector += Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
			moveVector += Vector3.new(0, -1, 0)
		end

		if moveVector.Magnitude > 1 then
			moveVector = moveVector.Unit
		end

		return moveVector
	end

	local function startSpeedHack()
		stopSpeedHack()
		speedHackConnection = RunService.Heartbeat:Connect(function()
			local humanoid, rootPart = getCharacterMovementState()
			if not humanoid or not rootPart then
				return
			end

			if Toggles.FlyEnabled and Toggles.FlyEnabled.Value then
				stopSpeedHack()
				return
			end

			local moveDirection = humanoid.MoveDirection
			local bodyVelocity = ensureSpeedHackVelocity(rootPart)
			bodyVelocity.Velocity = moveDirection * (Options.SpeedHackValue.Value or 16)
		end)
	end

	local function startFly()
		stopFly()
		flyConnection = RunService.Heartbeat:Connect(function()
			local _, rootPart = getCharacterMovementState()
			local camera = workspace.CurrentCamera
			if not rootPart or not camera then
				return
			end

			local bodyVelocity = ensureFlyVelocity(rootPart)
			local moveVector = getFlyMoveVector()
			bodyVelocity.Velocity = camera.CFrame:VectorToWorldSpace(moveVector) * (Options.FlyHackValue.Value or 16)
		end)
	end

	local function startNoclip()
		stopNoclip()
		noclipConnection = RunService.Stepped:Connect(function()
			setCharacterNoclip(true)
		end)
	end

	triggerAntiFallBypass = function(character, duration)
		local now = os.clock()
		antiFallProtectedUntil = math.max(antiFallProtectedUntil, now + math.max(duration or 1.5, 0.25))
		ensureAntiFallState(character)
	end

	local function startAntiFall()
		stopAntiFall()
		local function hookCharacter(character)
			if antiFallConnection then
				antiFallConnection:Disconnect()
				antiFallConnection = nil
			end

			local humanoid = getCharacterHumanoid(character)
			if not humanoid then
				return
			end

			antiFallConnection = humanoid.StateChanged:Connect(function(_, newState)
				if not isAntiFallActive() then
					return
				end

				if newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.FallingDown then
					triggerAntiFallBypass(character, 2)
				elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.PlatformStanding then
					triggerAntiFallBypass(character, 0.6)
				end
			end)
		end

		local currentCharacter = LocalPlayer and LocalPlayer.Character
		if currentCharacter then
			hookCharacter(currentCharacter)
		end

		antiFallCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
			removeAntiFallState()
			antiFallProtectedUntil = 0
			task.defer(function()
				if isAntiFallActive() then
					hookCharacter(character)
				end
			end)
		end)

		antiFallHeartbeatConnection = RunService.Heartbeat:Connect(function()
			if not isAntiFallActive() then
				removeAntiFallState()
				return
			end

			if shouldMaintainAntiFallState() then
				local character = LocalPlayer and LocalPlayer.Character
				ensureAntiFallState(character)
			elseif antiFallState then
				removeAntiFallState()
			end
		end)
	end

	combatGroup:AddToggle("SpeedHackEnabled", {
		Text = "Speedhack",
		Default = false,
	}):AddKeyPicker("SpeedHackKeybind", {
		Default = "None",
		SyncToggleState = true,
		Mode = "Toggle",
		Text = "Speedhack",
		NoUI = false,
	})

	combatGroup:AddSlider("SpeedHackValue", {
		Text = "Speed Value",
		Default = 32,
		Min = 16,
		Max = 200,
		Rounding = 0,
	})

	combatGroup:AddToggle("FlyEnabled", {
		Text = "Fly",
		Default = false,
	}):AddKeyPicker("FlyKeybind", {
		Default = "None",
		SyncToggleState = true,
		Mode = "Toggle",
		Text = "Fly",
		NoUI = false,
	})

	combatGroup:AddSlider("FlyHackValue", {
		Text = "Fly Value",
		Default = 32,
		Min = 16,
		Max = 200,
		Rounding = 0,
	})

	combatGroup:AddToggle("NoclipEnabled", {
		Text = "Noclip",
		Default = false,
	}):AddKeyPicker("NoclipKeybind", {
		Default = "None",
		SyncToggleState = true,
		Mode = "Toggle",
		Text = "Noclip",
		NoUI = false,
	})

	combatGroup:AddToggle("AntiFallDamageEnabled", {
		Text = "Anti Fall Damage",
		Default = false,
	})

	combatGroup:AddToggle("KnockedOwnershipEnabled", {
		Text = "Knocked Ownership",
		Default = false,
	})

	teleportGroup:AddDropdown("TeleportDestination", {
		Text = "Destination",
		Values = teleportLabels,
		Default = 1,
	})

	teleportGroup:AddButton("Refresh Teleports", function()
		refreshTeleportLocations()
		Library:Notify("Teleport list refreshed.", 2)
	end)

	teleportGroup:AddButton("Teleport To Selected", function()
		teleportToSelectedDestination()
	end)

	refreshTeleportLocations()

	Toggles.SpeedHackEnabled:OnChanged(function()
		if Toggles.SpeedHackEnabled.Value then
			startSpeedHack()
		else
			stopSpeedHack()
		end
	end)

	Toggles.FlyEnabled:OnChanged(function()
		if Toggles.FlyEnabled.Value then
			stopSpeedHack()
			startFly()
		else
			stopFly()
		end
	end)

	Toggles.NoclipEnabled:OnChanged(function()
		if Toggles.NoclipEnabled.Value then
			startNoclip()
		else
			stopNoclip()
		end
	end)

	Toggles.AntiFallDamageEnabled:OnChanged(function()
		if Toggles.AntiFallDamageEnabled.Value then
			startAntiFall()
		else
			stopAntiFall()
		end
	end)

	Toggles.KnockedOwnershipEnabled:OnChanged(function()
		if Toggles.KnockedOwnershipEnabled.Value then
			startKnockedOwnership()
		else
			stopKnockedOwnership()
		end
	end)

	Options.SpeedHackValue:OnChanged(function()
		if Toggles.SpeedHackEnabled.Value then
			startSpeedHack()
		end
	end)

	Options.FlyHackValue:OnChanged(function()
		if Toggles.FlyEnabled.Value then
			startFly()
		end
	end)

	local function hookFallDamageHealthDebug(character)
		local humanoid = getCharacterHumanoid(character)
		local rootPart = getCharacterRoot(character)
		if not humanoid then
			return
		end

		fallDebugState.lastHealth = humanoid.Health
		fallDebugState.lastFloorMaterial = humanoid.FloorMaterial
		pcall(function()
			fallDebugState.lastHumanoidState = humanoid:GetState()
		end)
		maid:GiveTask(humanoid.HealthChanged:Connect(function(newHealth)
			local oldHealth = fallDebugState.lastHealth or newHealth
			if newHealth < oldHealth then
				if not shouldLogFallDebug() and isFallDebugEnabled() then
					beginFallDebugWindow(string.format("health drop %.1f -> %.1f", oldHealth, newHealth), 3)
				end
				logFallDebug(string.format("health dropped: %.1f -> %.1f", oldHealth, newHealth))
			end
			fallDebugState.lastHealth = newHealth
		end))

		maid:GiveTask(humanoid.StateChanged:Connect(function(oldState, newState)
			if not isFallDebugEnabled() then
				return
			end

			if shouldLogFallDebug() then
				logFallDebug(string.format(
					"state changed: %s -> %s",
					tostring(oldState),
					tostring(newState)
				))
			end

			fallDebugState.lastHumanoidState = newState
		end))

		maid:GiveTask(humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
			local oldMaterial = fallDebugState.lastFloorMaterial
			local newMaterial = humanoid.FloorMaterial
			if isFallDebugEnabled() and shouldLogFallDebug() then
				logFallDebug(string.format(
					"floor material: %s -> %s",
					tostring(oldMaterial),
					tostring(newMaterial)
				))
			end
			fallDebugState.lastFloorMaterial = newMaterial
		end))

		if rootPart then
			maid:GiveTask(rootPart:GetPropertyChangedSignal("AssemblyLinearVelocity"):Connect(function()
				if not shouldLogFallDebug() then
					return
				end

				local velocity = rootPart.AssemblyLinearVelocity
				if math.abs(velocity.Y) >= 20 then
					logFallDebug(string.format(
						"velocity sample: x=%.1f y=%.1f z=%.1f",
						velocity.X,
						velocity.Y,
						velocity.Z
					))
				end
			end))
		end

		maid:GiveTask(character.AttributeChanged:Connect(function(attributeName)
			if not shouldLogFallDebug() then
				return
			end

			local ok, value = pcall(function()
				return character:GetAttribute(attributeName)
			end)
			if ok then
				logFallDebug(string.format("character attribute: %s=%s", tostring(attributeName), tostring(value)))
			end
		end))

		maid:GiveTask(humanoid.AttributeChanged:Connect(function(attributeName)
			if not shouldLogFallDebug() then
				return
			end

			local ok, value = pcall(function()
				return humanoid:GetAttribute(attributeName)
			end)
			if ok then
				logFallDebug(string.format("humanoid attribute: %s=%s", tostring(attributeName), tostring(value)))
			end
		end))

		maid:GiveTask(character.DescendantAdded:Connect(function(descendant)
			if isAntiFallActive() and shouldMaintainAntiFallState() and descendant.Name == "FallNegate" then
				antiFallState = descendant
				logFallDebug(string.format("anti-fall detected existing: %s", descendant:GetFullName()))
			end

			if not shouldLogFallDebug() then
				return
			end

			if descendant:IsA("Folder") or descendant:IsA("Configuration") or descendant:IsA("BoolValue") or descendant:IsA("NumberValue") or descendant:IsA("StringValue") or descendant:IsA("IntValue") then
				logFallDebug(string.format(
					"descendant added: %s (%s)",
					descendant:GetFullName(),
					descendant.ClassName
				))
			end
		end))

		maid:GiveTask(character.DescendantRemoving:Connect(function(descendant)
			if descendant == antiFallState then
				antiFallState = nil
				if isAntiFallActive() and shouldMaintainAntiFallState() then
					task.defer(function()
						ensureAntiFallState(character)
					end)
				end
			end

			if not shouldLogFallDebug() then
				return
			end

			if descendant:IsA("Folder") or descendant:IsA("Configuration") or descendant:IsA("BoolValue") or descendant:IsA("NumberValue") or descendant:IsA("StringValue") or descendant:IsA("IntValue") then
				logFallDebug(string.format(
					"descendant removing: %s (%s)",
					descendant:GetFullName(),
					descendant.ClassName
				))
			end
		end))
	end

	if LocalPlayer.Character then
		hookFallDamageHealthDebug(LocalPlayer.Character)
	end

	maid:GiveTask(LocalPlayer.CharacterAdded:Connect(function(character)
		task.defer(function()
			hookFallDamageHealthDebug(character)
		end)
	end))

	maid:GiveTask(RunService.Heartbeat:Connect(function()
		if not isFallDebugEnabled() then
			return
		end

		local character = LocalPlayer and LocalPlayer.Character
		local rootPart = getCharacterRoot(character)
		if not character or not rootPart then
			return
		end

		fallDebugRaycastParams.FilterDescendantsInstances = {character}
		local velocity = rootPart.AssemblyLinearVelocity
		local raycastResult = workspace:Raycast(rootPart.Position, Vector3.new(0, -16, 0), fallDebugRaycastParams)
		local distanceToGround = raycastResult and (rootPart.Position.Y - raycastResult.Position.Y) or math.huge
		local now = os.clock()

		if velocity.Y <= -45 and distanceToGround <= 18 and now - (fallDebugState.lastArmAt or 0) >= 0.75 then
			fallDebugState.lastArmAt = now
			beginFallDebugWindow(string.format("falling vY=%.1f ground=%.1f", velocity.Y, distanceToGround), 3)
		end

		if shouldLogFallDebug() and now - (fallDebugState.lastSampleAt or 0) >= 0.5 then
			fallDebugState.lastSampleAt = now
			local humanoid = getCharacterHumanoid(character)
			local floorMaterial = humanoid and humanoid.FloorMaterial or "?"
			local stateName = "?"
			if humanoid then
				local ok, state = pcall(function()
					return humanoid:GetState()
				end)
				if ok then
					stateName = tostring(state)
				end
			end

			logFallDebug(string.format(
				"snapshot: health=%.1f vY=%.1f ground=%.1f floor=%s state=%s",
				humanoid and humanoid.Health or -1,
				velocity.Y,
				distanceToGround,
				tostring(floorMaterial),
				stateName
			))
		end
	end))

	registerLibraryUnloadCallback(function()
		stopSpeedHack()
		stopFly()
		stopNoclip()
		stopAntiFall()
		stopKnockedOwnership()
	end)
end
setupLocalCheatsTab()

local function setupEspTab()
	local espTab = Tabs["Player Mods"]
	local espGroup = espTab:AddLeftGroupbox("ESP")
	local espVisualGroup = espTab:AddRightGroupbox("ESP Visuals")
	local playerEspEntries = {}
	local mobEspEntries = {}
	local globalEspDrawings = GLOBAL_ENV[HUAJ_HUB_ESP_DRAWINGS_KEY] or {}
	local drawingAvailable = type(Drawing) == "table" and type(Drawing.new) == "function"
	local espDrawUnavailableNotified = false
	local espShuttingDown = false

	GLOBAL_ENV[HUAJ_HUB_ESP_DRAWINGS_KEY] = globalEspDrawings

	local function getEspTargetType(model)
		if not model or not model:IsA("Model") then
			return nil
		end

		local ownerPlayer = Players:GetPlayerFromCharacter(model)
		if ownerPlayer then
			if ownerPlayer == LocalPlayer then
				return nil
			end
			return "player"
		end

		local hasAnimationController = model:FindFirstChildWhichIsA("AnimationController", true) ~= nil
		local hasAiConfigurations = model:FindFirstChild("AI_Configurations", true) ~= nil
		local hasAnimator = model:FindFirstChildWhichIsA("Animator", true) ~= nil
		local hasHumanoid = model:FindFirstChildOfClass("Humanoid") ~= nil
		local hasBone = model:FindFirstChildWhichIsA("Bone", true) ~= nil
		local hasMotor6D = model:FindFirstChildWhichIsA("Motor6D", true) ~= nil

		if hasAnimationController and hasAiConfigurations then
			return "mob"
		end

		if hasAnimationController or hasAnimator or hasHumanoid or hasBone or hasMotor6D then
			return "mob"
		end

		return nil
	end

	local function getEspHumanoid(model)
		if not model or not model:IsA("Model") then
			return nil
		end

		return model:FindFirstChildOfClass("Humanoid")
	end

	local function getEspRoot(model)
		return getCharacterRoot(model)
	end

	local function getEspDistance(model)
		local localCharacter = LocalPlayer and LocalPlayer.Character
		local localRoot = getEspRoot(localCharacter)
		local targetRoot = getEspRoot(model)
		if not localRoot or not targetRoot then
			return math.huge
		end

		return (targetRoot.Position - localRoot.Position).Magnitude
	end

	local function getEspDisplayName(model, targetType)
		if targetType == "player" then
			local ownerPlayer = Players:GetPlayerFromCharacter(model)
			if ownerPlayer then
				return ownerPlayer.DisplayName ~= "" and ownerPlayer.DisplayName or ownerPlayer.Name
			end
		end

		return model.Name
	end

	local function destroyDrawingObject(object)
		if not object then
			return
		end

		pcall(function()
			object.Visible = false
		end)
		pcall(function()
			object:Remove()
		end)
		pcall(function()
			object:Destroy()
		end)
	end

	local function clearGlobalEspDrawings()
		for index, object in pairs(globalEspDrawings) do
			destroyDrawingObject(object)
			globalEspDrawings[index] = nil
		end
	end

	clearGlobalEspDrawings()

	local function destroyEspEntry(cache, model, entry)
		if not entry then
			return
		end

		entry.destroyed = true
		if type(entry.hide) == "function" then
			entry:hide()
		end
		for _, object in ipairs(entry.objects or {}) do
			destroyDrawingObject(object)
		end

		if cache and model then
			cache[model] = nil
		end
	end

	local function removeEspEntry(cache, model)
		local entry = cache[model]
		if not entry then
			return
		end

		if type(entry.Destroy) == "function" then
			entry:Destroy()
			return
		end

		destroyEspEntry(cache, model, entry)
	end

	local function clearEspCache(cache)
		for model in pairs(cache) do
			removeEspEntry(cache, model)
		end
	end

	local function forceClearEsp()
		clearEspCache(playerEspEntries)
		clearEspCache(mobEspEntries)
		clearGlobalEspDrawings()
	end

	local function ensureEspEntry(cache, model, accentColor)
		if espShuttingDown or not drawingAvailable or not model or not model.Parent then
			return nil
		end

		local entry = cache[model]
		if entry and entry.model ~= model then
			removeEspEntry(cache, model)
			entry = nil
		end

		if not entry then
			entry = EntityESP.new(globalEspDrawings, accentColor, function()
				return espShuttingDown
			end)
			entry.model = model
			entry.Destroy = function(self)
				destroyEspEntry(cache, model, self)
			end
			cache[model] = entry
		end

		entry:setAccentColor(accentColor)
		return entry
	end

	local function shouldShowPlayerEsp(model)
		local targetType = getEspTargetType(model)
		if targetType ~= "player" then
			return false
		end

		local humanoid = model:FindFirstChildOfClass("Humanoid")
		return humanoid == nil or humanoid.Health > 0
	end

	local function shouldShowMobEsp(model)
		local targetType = getEspTargetType(model)
		if targetType ~= "mob" then
			return false
		end

		local humanoid = model:FindFirstChildOfClass("Humanoid")
		return humanoid == nil or humanoid.Health > 0
	end

	local function shouldRenderEspModel(model, targetType)
		if not model or not model.Parent then
			return false
		end

		if targetType == "player" and not Toggles.PlayerEspEnabled.Value then
			return false
		end

		if targetType == "mob" and not Toggles.MobEspEnabled.Value then
			return false
		end

		local maxDistance = Options.EspRenderDistance.Value or 150
		return getEspDistance(model) <= maxDistance
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

	local function hideEspEntry(entry)
		entry:hide()
	end

	local function updateEspEntry(entry, model, targetType, accentColor)
		local humanoid = getEspHumanoid(model)
		local distance = getEspDistance(model)
		local box = getEspBoundingBox(model)
		if not box or box.width < 2 or box.height < 2 or not box.onScreen then
			hideEspEntry(entry)
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

		local showBox = Toggles.EspShowBox.Value
		entry:setBox({
			{topLeft, topRight},
			{topRight, bottomRight},
			{bottomRight, bottomLeft},
			{bottomLeft, topLeft},
		}, accentColor, showBox)

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
			Vector2.new(box.left + (box.width * 0.5), box.top - 16),
			Toggles.EspShowNames.Value
		)

		entry:setText(
			entry.distanceText,
			string.format("%.0f studs", distance),
			Vector2.new(box.left + (box.width * 0.5), box.bottom + 2),
			Toggles.EspShowDistance.Value
		)

		entry:setText(
			entry.healthText,
			string.format("%d / %d HP", math.floor(health + 0.5), math.floor(maxHealth + 0.5)),
			Vector2.new(box.left + (box.width * 0.5), box.top - 30),
			Toggles.EspShowHealthText.Value and humanoid ~= nil
		)

		entry:setTracer(tracerStart, tracerEnd, accentColor, Toggles.EspShowTracers.Value)

		if Toggles.EspShowSkeleton.Value then
			updateEspSkeleton(entry, model, accentColor)
		else
			entry:hideSkeletonFrom(1)
		end
	end

	local function updatePlayerEsp()
		if not drawingAvailable then
			clearEspCache(playerEspEntries)
			return
		end

		if not Toggles.PlayerEspEnabled.Value then
			clearEspCache(playerEspEntries)
			return
		end

		local validModels = {}
		for _, model in ipairs(iterEspCandidateModels()) do
			if shouldShowPlayerEsp(model) and shouldRenderEspModel(model, "player") then
				validModels[model] = true
				local entry = ensureEspEntry(
					playerEspEntries,
					model,
					Color3.fromRGB(40, 170, 255)
				)
				if entry then
					updateEspEntry(entry, model, "player", Color3.fromRGB(40, 170, 255))
				end
			end
		end

		for model in pairs(playerEspEntries) do
			if not validModels[model] then
				removeEspEntry(playerEspEntries, model)
			end
		end
	end

	local function updateMobEsp()
		if not drawingAvailable then
			clearEspCache(mobEspEntries)
			return
		end

		if not Toggles.MobEspEnabled.Value then
			clearEspCache(mobEspEntries)
			return
		end

		local validModels = {}
		for _, model in ipairs(iterEspCandidateModels()) do
			if shouldShowMobEsp(model) and shouldRenderEspModel(model, "mob") then
				validModels[model] = true
				local entry = ensureEspEntry(
					mobEspEntries,
					model,
					Color3.fromRGB(80, 255, 140)
				)
				if entry then
					updateEspEntry(entry, model, "mob", Color3.fromRGB(80, 255, 140))
				end
			end
		end

		for model in pairs(mobEspEntries) do
			if not validModels[model] then
				removeEspEntry(mobEspEntries, model)
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
		end
		updatePlayerEsp()
		updateMobEsp()
	end

	local function isAnyEspEnabled()
		return (Toggles.PlayerEspEnabled and Toggles.PlayerEspEnabled.Value)
			or (Toggles.MobEspEnabled and Toggles.MobEspEnabled.Value)
	end

	local function scheduleEspRefresh()
		task.defer(function()
			if espShuttingDown then
				return
			end
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

	espGroup:AddButton("Force Clear ESP", function()
		forceClearEsp()
	end)

	espVisualGroup:AddSlider("EspRenderDistance", {
		Text = "Render Distance",
		Default = 150,
		Min = 10,
		Max = 500,
		Rounding = 0,
		Suffix = " studs",
	})

	espVisualGroup:AddToggle("EspShowHighlight", {
		Text = "Highlight",
		Default = true,
	})

	espVisualGroup:AddToggle("EspShowNames", {
		Text = "Name Text",
		Default = true,
	})

	espVisualGroup:AddToggle("EspShowDistance", {
		Text = "Distance Text",
		Default = true,
	})

	espVisualGroup:AddToggle("EspShowHealthText", {
		Text = "Health Text",
		Default = true,
	})

	espVisualGroup:AddToggle("EspShowHealthBar", {
		Text = "Health Bar",
		Default = true,
	})

	espVisualGroup:AddToggle("EspShowBox", {
		Text = "Box ESP",
		Default = false,
	})

	espVisualGroup:AddToggle("EspShowSkeleton", {
		Text = "Skeleton ESP",
		Default = false,
	})

	espVisualGroup:AddToggle("EspShowTracers", {
		Text = "Tracer Lines",
		Default = false,
	})

	Toggles.PlayerEspEnabled:OnChanged(function()
		if not Toggles.PlayerEspEnabled.Value and not Toggles.MobEspEnabled.Value then
			forceClearEsp()
			return
		end
		updatePlayerEsp()
	end)

	Toggles.MobEspEnabled:OnChanged(function()
		if not Toggles.PlayerEspEnabled.Value and not Toggles.MobEspEnabled.Value then
			forceClearEsp()
			return
		end
		updateMobEsp()
	end)

	Options.EspRenderDistance:OnChanged(function()
		refreshEsp()
	end)

	Toggles.EspShowHighlight:OnChanged(function()
		refreshEsp()
	end)

	Toggles.EspShowNames:OnChanged(function()
		refreshEsp()
	end)

	Toggles.EspShowDistance:OnChanged(function()
		refreshEsp()
	end)

	Toggles.EspShowHealthText:OnChanged(function()
		refreshEsp()
	end)

	Toggles.EspShowHealthBar:OnChanged(function()
		refreshEsp()
	end)

	Toggles.EspShowBox:OnChanged(function()
		refreshEsp()
	end)

	Toggles.EspShowSkeleton:OnChanged(function()
		clearEspCache(playerEspEntries)
		clearEspCache(mobEspEntries)
		refreshEsp()
	end)

	Toggles.EspShowTracers:OnChanged(function()
		refreshEsp()
	end)

	maid:GiveTask(Players.PlayerAdded:Connect(function(player)
		maid:GiveTask(player.CharacterAdded:Connect(function()
			scheduleEspRefresh()
		end))
		scheduleEspRefresh()
	end))

	maid:GiveTask(Players.PlayerRemoving:Connect(function()
		scheduleEspRefresh()
	end))

	for _, player in ipairs(Players:GetPlayers()) do
		maid:GiveTask(player.CharacterAdded:Connect(function()
			scheduleEspRefresh()
		end))
	end

	local liveFolder = getEspLiveFolder()
	if liveFolder then
		maid:GiveTask(liveFolder.ChildAdded:Connect(function()
			scheduleEspRefresh()
		end))
		maid:GiveTask(liveFolder.ChildRemoved:Connect(function()
			scheduleEspRefresh()
		end))
	end

	maid:GiveTask(workspace.ChildAdded:Connect(function(child)
		if child.Name == "Live" then
			maid:GiveTask(child.ChildAdded:Connect(function()
				scheduleEspRefresh()
			end))
			maid:GiveTask(child.ChildRemoved:Connect(function()
				scheduleEspRefresh()
			end))
			scheduleEspRefresh()
		end
	end))

	maid:GiveTask(RunService.Heartbeat:Connect(function()
		if espShuttingDown then
			return
		end

		if isAnyEspEnabled() then
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
		task.defer(forceClearEsp)
		task.delay(0.1, forceClearEsp)
		task.delay(0.5, forceClearEsp)
	end)
end
setupEspTab()

local function setupAutoParryTab()
	local autoParryTab = Tabs["Auto Parry"]
	local autoParryGroup = autoParryTab:AddLeftGroupbox("Auto Parry")
	local autoParryMakerGroup = autoParryTab:AddRightGroupbox("Auto Parry Maker")
	local autoParryRuntime = {}
	GLOBAL_ENV[HUAJ_HUB_MANUAL_ACTION_CALLBACK_KEY] = nil
	local AUTO_PARRY_BLOCK_ACTION = "HuajHubAutoParryInputBlock"
	local AUTO_PARRY_BLOCK_DURATION = 0.16
	local AUTO_PARRY_BLOCK_INPUTS = {
		Enum.UserInputType.MouseButton1,
		Enum.UserInputType.MouseButton2,
		Enum.KeyCode.W,
		Enum.KeyCode.A,
		Enum.KeyCode.S,
		Enum.KeyCode.D,
		Enum.KeyCode.Space,
		Enum.KeyCode.LeftShift,
		Enum.KeyCode.RightShift,
		Enum.KeyCode.Q,
		Enum.KeyCode.E,
		Enum.KeyCode.R,
		Enum.KeyCode.F,
		Enum.KeyCode.One,
		Enum.KeyCode.Two,
		Enum.KeyCode.Three,
		Enum.KeyCode.Four,
		Enum.KeyCode.Five,
		Enum.PlayerActions.CharacterForward,
		Enum.PlayerActions.CharacterBackward,
		Enum.PlayerActions.CharacterLeft,
		Enum.PlayerActions.CharacterRight,
		Enum.PlayerActions.CharacterJump,
	}
	local autoParryCooldown = 0.18
	local autoParryBlockHoldDuration = 0.35
	local blatantDashCooldown = 2
	local dashOnFailCooldown = 0.5
	local adaptiveTimingUpdateInterval = 1
	local autoParryTrackSweepInterval = 0.2
	local onCreateMakerConfig
	local onSaveMakerConfig
	local onAutoGetMakerConfig
	local AUTO_PARRY_MAKER_FOLDER = "huajhub/" .. GAME_KEY
	local AUTO_PARRY_MAKER_FILE = AUTO_PARRY_MAKER_FOLDER .. "/AutoParryConfig"
	local AUTO_PARRY_MAKER_OLD_SHARED_FILE = "huajhub/AutoParryConfig"
	local AUTO_PARRY_MAKER_OLD_WORKSPACE_FILE = "workspace/huajhub/AutoParryConfig"
	local AUTO_PARRY_MAKER_LEGACY_FILE = "HuajHubAutoParryConfigs.json"
	local autoParryMakerConfigs = {
		Players = {},
		Mobs = {},
	}
	local detectedAnimationEntries = {
		Players = {},
		Mobs = {},
	}
	local builderConfigLabelMap = {}
	local detectedAnimationLabelMap = {}
	local lastManualParryCapture = nil
	local lastManualDashCapture = nil
	local lastManualJumpCapture = nil
	local autoParryState = {
		lastState = {
			remoteMissing = false,
		},
		visualizer = {
			part = nil,
		},
		manualActionRequestRemote = getRequestModuleRemote(),
		trackedTargets = {},
		handledTracks = {},
		queuedTracks = {},
		inputBlockUntil = 0,
		inputBlockActive = false,
		lastParryAt = 0,
		lastBlatantDashAt = 0,
		lastDashOnFailAt = 0,
		lastAdaptiveTimingUpdateAt = 0,
		lastTrackSweepAt = 0,
		manualDashInputSuppressUntil = 0,
		manualParryInputSuppressUntil = 0,
		lastManualParryAnimationId = nil,
		lastManualParryAssetUrl = nil,
		lastManualDashAnimationId = nil,
		lastManualDashAssetUrl = nil,
		pendingParryFailCheck = nil,
		pendingManualParryDebugMessage = nil,
		pendingManualDashDebugMessage = nil,
		queuedMoveActions = {},
		pendingBlockReleaseAt = 0,
		currentBuilderConfigId = nil,
		adaptiveTiming = {
			pingSamples = {},
			smoothedPingMs = 0,
			lastComputedOffsetMs = 0,
			actionBiasMs = {
				Parry = 0,
				Dash = 14,
				Jump = 20,
				Block = 6,
			},
			learnedOffsets = {},
		},
	}

	GLOBAL_ENV.HuajHubAutoParryMakerConfigs = autoParryMakerConfigs

	autoParryGroup:AddToggle("AutoParryEnabled", {
		Text = "Auto Parry",
		Default = false,
	})

	autoParryGroup:AddSlider("AutoParryTimingOffset", {
		Text = "Timing Offset",
		Default = 0,
		Min = 0,
		Max = 250,
		Rounding = 0,
		Suffix = " ms",
	})

	autoParryGroup:AddToggle("AutoParryAdaptiveTiming", {
		Text = "Adaptive Timing",
		Default = false,
	})

	local function readCurrentPingMs()
		local pingValue
		pcall(function()
			pingValue = Stats.Network.ServerStatsItem["Data Ping"]
		end)
		if not pingValue then
			return nil
		end

		local pingText = ""
		pcall(function()
			pingText = pingValue:GetValueString()
		end)

		return tonumber((pingText or ""):match("([%d%.]+)"))
	end

	local function updateAdaptiveTimingOffset(showNotification)
		local pingMs = readCurrentPingMs()
		if not pingMs then
			if showNotification then
				Library:Notify("Could not read ping for Adaptive Timing.", 2)
			end
			return false
		end

		table.insert(autoParryState.adaptiveTiming.pingSamples, pingMs)
		while #autoParryState.adaptiveTiming.pingSamples > 8 do
			table.remove(autoParryState.adaptiveTiming.pingSamples, 1)
		end

		local totalPing = 0
		for _, sample in ipairs(autoParryState.adaptiveTiming.pingSamples) do
			totalPing = totalPing + sample
		end

		autoParryState.adaptiveTiming.smoothedPingMs = totalPing / math.max(#autoParryState.adaptiveTiming.pingSamples, 1)
		autoParryState.adaptiveTiming.lastComputedOffsetMs = math.clamp(math.floor((autoParryState.adaptiveTiming.smoothedPingMs * 0.35) + 0.5), -60, 120)
		if showNotification then
			Library:Notify(string.format(
				"Adaptive Timing active. Base slider is preserved; live ping correction is %d ms from %.0f ms smoothed ping.",
				autoParryState.adaptiveTiming.lastComputedOffsetMs,
				autoParryState.adaptiveTiming.smoothedPingMs
			), 3)
		end
		return true
	end

	Toggles.AutoParryAdaptiveTiming:OnChanged(function()
		if Toggles.AutoParryAdaptiveTiming.Value then
			autoParryState.lastAdaptiveTimingUpdateAt = 0
			updateAdaptiveTimingOffset(true)
		end
	end)

	autoParryGroup:AddSlider("AutoParryDistance", {
		Text = "Distance",
		Default = 18,
		Min = 5,
		Max = 40,
		Rounding = 0,
		Suffix = " studs",
	})

	autoParryGroup:AddToggle("AutoParryVisualizer", {
		Text = "Distance Visualizer",
		Default = false,
	})

	autoParryGroup:AddToggle("AutoParryBlockInputs", {
		Text = "Block Inputs On Parry",
		Default = false,
	})

	autoParryGroup:AddToggle("AutoParryBlatantDash", {
		Text = "Blatant Dash",
		Default = false,
	})

	autoParryGroup:AddToggle("AutoParryDontBlatantDashPlayers", {
		Text = "Dont Blatant Dash Players",
		Default = false,
	})

	autoParryGroup:AddToggle("AutoParryDashOnFail", {
		Text = "Dash if Parry Fail",
		Default = false,
	})

	autoParryGroup:AddDropdown("AutoParryMode", {
		Values = {"Mobs+Players", "Mobs", "Players"},
		Default = 1,
		Multi = false,
		Text = "Auto Parry Mode",
	})

	autoParryGroup:AddDropdown("AutoParryWhitelist", {
		Values = getOtherPlayerNames(),
		Default = {},
		Multi = true,
		Text = "Auto Parry Whitelist",
	})

	local manualParryTimingLabel = autoParryMakerGroup:AddLabel("Manual Parry Timing: parry manually to capture timing.", true)
	autoParryMakerGroup:AddButton("Copy Last Parry ID", function()
		if not autoParryState.lastManualParryAnimationId or not autoParryState.lastManualParryAssetUrl then
			Library:Notify("No manual parry animation has been captured yet.", 2)
			return
		end

		if type(setclipboard) == "function" then
			pcall(setclipboard, autoParryState.lastManualParryAssetUrl)
			Library:Notify("Copied parry rbxassetid for " .. autoParryState.lastManualParryAnimationId .. ".", 2)
		else
			Library:Notify("Clipboard is unavailable in this executor.", 2)
		end
	end)
	autoParryMakerGroup:AddBlank(4)
	local manualDashTimingLabel = autoParryMakerGroup:AddLabel("Manual Dash Timing: dash manually to capture timing.", true)
	autoParryMakerGroup:AddButton("Copy Last Dash ID", function()
		if not autoParryState.lastManualDashAnimationId or not autoParryState.lastManualDashAssetUrl then
			Library:Notify("No manual dash animation has been captured yet.", 2)
			return
		end

		if type(setclipboard) == "function" then
			pcall(setclipboard, autoParryState.lastManualDashAssetUrl)
			Library:Notify("Copied dash rbxassetid for " .. autoParryState.lastManualDashAnimationId .. ".", 2)
		else
			Library:Notify("Clipboard is unavailable in this executor.", 2)
		end
	end)
	autoParryMakerGroup:AddBlank(6)
	local makerDetectedDropdown = autoParryMakerGroup:AddDropdown("AutoParryMakerDetectedAnimation", {
		Values = {"(none)"},
		Default = 1,
		Multi = false,
		Text = "Detected Animation",
	})
	local makerSourceDropdown = autoParryMakerGroup:AddDropdown("AutoParryMakerSource", {
		Values = {"Players", "Mobs"},
		Default = 1,
		Multi = false,
		Text = "Config",
	})
	local makerSavedConfigDropdown = autoParryMakerGroup:AddDropdown("AutoParryMakerSavedConfig", {
		Values = {"(none)"},
		Default = 1,
		Multi = false,
		Text = "Saved Config",
	})
	local makerAnimationIdInput = autoParryMakerGroup:AddInput("AutoParryMakerAnimationId", {
		Text = "Animation ID",
		Default = "",
	})
	local makerRepeatAmountInput = autoParryMakerGroup:AddInput("AutoParryMakerRepeatAmount", {
		Text = "Repeat Parry Amount",
		Default = "1",
		Numeric = true,
	})
	local makerRepeatDelayInput = autoParryMakerGroup:AddInput("AutoParryMakerRepeatDelay", {
		Text = "Repeat Parry Delay",
		Default = "0",
		Numeric = true,
	})
	local makerWaitInput = autoParryMakerGroup:AddInput("AutoParryMakerWait", {
		Text = "Wait",
		Default = "0",
		Numeric = true,
	})
	local makerNicknameInput = autoParryMakerGroup:AddInput("AutoParryMakerNickname", {
		Text = "Config Nickname",
		Default = "",
	})
	local makerActionTypeDropdown = autoParryMakerGroup:AddDropdown("AutoParryMakerActionType", {
		Values = {"Parry", "Dash", "Block", "Jump"},
		Default = 1,
		Multi = false,
		Text = "Action Type",
	})
	local makerDelayDropdown = autoParryMakerGroup:AddDropdown("AutoParryMakerDelay", {
		Values = {"Off", "On"},
		Default = 1,
		Multi = false,
		Text = "Delay",
	})
	local makerDelayRangeInput = autoParryMakerGroup:AddInput("AutoParryMakerDelayRange", {
		Text = "Delay Range",
		Default = "0",
		Numeric = true,
	})
	local makerRangeSlider = autoParryMakerGroup:AddSlider("AutoParryMakerRange", {
		Text = "Range",
		Default = 16,
		Min = 1,
		Max = 40,
		Rounding = 0,
		Suffix = " studs",
	})
	local createMakerConfigButton = autoParryMakerGroup:AddButton("Create Config", function()
		if onCreateMakerConfig then
			onCreateMakerConfig()
		end
	end)
	local saveMakerConfigButton = createMakerConfigButton:AddButton("Save Config", function()
		if onSaveMakerConfig then
			onSaveMakerConfig()
		end
	end)
	local autoGetMakerConfigButton = autoParryMakerGroup:AddButton("Attempt Automatic Get", function()
		if onAutoGetMakerConfig then
			onAutoGetMakerConfig()
		end
	end)

	local function setAutoParryDebugText(message)
		return message
	end

	local function setAutoParryTrackingText(message)
		return message
	end

	local function setManualParryDebugText(message)
		autoParryState.pendingManualParryDebugMessage = "Manual Parry Timing: " .. tostring(message or "")
	end

	local function setManualDashDebugText(message)
		autoParryState.pendingManualDashDebugMessage = "Manual Dash Timing: " .. tostring(message or "")
	end

	local function setLastManualParryAnimationId(animationId)
		local normalizedAnimationId = tostring(animationId or ""):match("%d+")
		if not normalizedAnimationId or normalizedAnimationId == "" then
			autoParryState.lastManualParryAnimationId = nil
			autoParryState.lastManualParryAssetUrl = nil
			return
		end

		autoParryState.lastManualParryAnimationId = normalizedAnimationId
		autoParryState.lastManualParryAssetUrl = "rbxassetid://" .. normalizedAnimationId
	end

	local function setLastManualDashAnimationId(animationId)
		local normalizedAnimationId = tostring(animationId or ""):match("%d+")
		if not normalizedAnimationId or normalizedAnimationId == "" then
			autoParryState.lastManualDashAnimationId = nil
			autoParryState.lastManualDashAssetUrl = nil
			return
		end

		autoParryState.lastManualDashAnimationId = normalizedAnimationId
		autoParryState.lastManualDashAssetUrl = "rbxassetid://" .. normalizedAnimationId
	end

	local function getMakerSourceKey(targetType)
		return targetType == "player" and "Players" or "Mobs"
	end

	local function formatDetectedAnimationLabel(entry)
		return string.format(
			"%s | %s | %s",
			entry.sourceKey,
			entry.animationName or entry.targetName or "Unknown",
			entry.animationId
		)
	end

	local function buildSavedConfigLabel(sourceKey, animationId, configData)
		local nickname = tostring(configData.nickname or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if nickname ~= "" then
			return string.format("%s | %s | %s", sourceKey, nickname, animationId)
		end

		return string.format("%s | %s", sourceKey, animationId)
	end

	local function cloneConfigData(configData)
		local cloned = {}
		for key, value in pairs(configData or {}) do
			cloned[key] = value
		end
		return cloned
	end

	local function generateMakerConfigId()
		if HttpService and type(HttpService.GenerateGUID) == "function" then
			local ok, generatedId = pcall(function()
				return HttpService:GenerateGUID(false)
			end)
			if ok and type(generatedId) == "string" and generatedId ~= "" then
				return generatedId
			end
		end

		return string.format("cfg_%d_%d", math.floor(os.clock() * 1000), math.random(1000, 9999))
	end

	local function normalizeLoadedConfigRecord(sourceKey, storageKey, configData)
		if type(configData) ~= "table" then
			return nil
		end

		local normalizedAnimationId = normalizeBuilderAnimationId(configData.animationId or storageKey)
		if not normalizedAnimationId or normalizedAnimationId == "" then
			return nil
		end

		local normalizedConfig = cloneConfigData(configData)
		normalizedConfig.sourceKey = sourceKey
		normalizedConfig.animationId = normalizedAnimationId
		normalizedConfig.configId = normalizedAnimationId

		return normalizedConfig
	end

	local function getMakerConfigList(sourceKey)
		local sourceConfigs = autoParryMakerConfigs[sourceKey]
		if type(sourceConfigs) ~= "table" then
			sourceConfigs = {}
			autoParryMakerConfigs[sourceKey] = sourceConfigs
		end
		return sourceConfigs
	end

	local function upsertMakerConfig(configData, forceNew)
		if type(configData) ~= "table" then
			return nil
		end

		local sourceConfigs = getMakerConfigList(configData.sourceKey)
		local savedConfig = cloneConfigData(configData)
		savedConfig.animationId = normalizeBuilderAnimationId(savedConfig.animationId)
		if not savedConfig.animationId or savedConfig.animationId == "" then
			return nil
		end
		savedConfig.configId = savedConfig.animationId

		for index, existingConfig in ipairs(sourceConfigs) do
			if type(existingConfig) == "table" and normalizeBuilderAnimationId(existingConfig.animationId) == savedConfig.animationId then
				sourceConfigs[index] = savedConfig
				return savedConfig
			end
		end

		table.insert(sourceConfigs, savedConfig)
		return savedConfig
	end

	local function dedupeMakerConfigList(sourceKey, sourceConfigs)
		local dedupedByAnimationId = {}
		local orderedAnimationIds = {}

		for _, configData in ipairs(sourceConfigs or {}) do
			local normalizedConfig = normalizeLoadedConfigRecord(sourceKey, configData.animationId or configData.configId, configData)
			if normalizedConfig then
				local animationId = normalizedConfig.animationId
				if dedupedByAnimationId[animationId] == nil then
					table.insert(orderedAnimationIds, animationId)
				end
				dedupedByAnimationId[animationId] = normalizedConfig
			end
		end

		local dedupedConfigs = {}
		for _, animationId in ipairs(orderedAnimationIds) do
			local configData = dedupedByAnimationId[animationId]
			if configData then
				table.insert(dedupedConfigs, configData)
			end
		end

		return dedupedConfigs
	end

	local function findMakerConfigById(sourceKey, configId)
		if type(configId) ~= "string" or configId == "" then
			return nil
		end

		for _, configData in ipairs(getMakerConfigList(sourceKey)) do
			if type(configData) == "table" and configData.configId == configId then
				return configData
			end
		end

		return nil
	end

	local function findMakerConfigByAnimationId(sourceKey, animationId)
		local normalizedAnimationId = normalizeBuilderAnimationId(animationId)
		if not normalizedAnimationId or normalizedAnimationId == "" then
			return nil
		end

		for _, configData in ipairs(getMakerConfigList(sourceKey)) do
			if type(configData) == "table" and normalizeBuilderAnimationId(configData.animationId) == normalizedAnimationId then
				return configData
			end
		end

		return nil
	end

	local function updateLearnedAdaptiveOffset(sourceKey, animationId, actionType, deltaMs, weight)
		AdaptiveTimingUtils.updateLearnedOffset(
			autoParryState.adaptiveTiming.learnedOffsets,
			normalizeBuilderAnimationId,
			sourceKey,
			animationId,
			actionType,
			deltaMs,
			weight
		)
	end

	local function getAdaptiveTimingOffsetMs(sourceKey, animationId, moveConfig, distance)
		local actionType = (moveConfig and moveConfig.actionType) or "Parry"
		local key = AdaptiveTimingUtils.getAdaptiveAnimationKey(normalizeBuilderAnimationId, sourceKey, animationId, actionType)
		return AdaptiveTimingUtils.getTimingOffsetMs({
			manualOffsetMs = tonumber(Options.AutoParryTimingOffset.Value) or 0,
			adaptiveEnabled = Toggles.AutoParryAdaptiveTiming.Value == true,
			actionType = actionType,
			pingCorrectionMs = tonumber(autoParryState.adaptiveTiming.lastComputedOffsetMs) or 0,
			actionBiasMs = tonumber(autoParryState.adaptiveTiming.actionBiasMs[actionType]) or 0,
			learnedOffsetMs = tonumber(autoParryState.adaptiveTiming.learnedOffsets[key]) or 0,
			distance = distance,
		})
	end

	local function getBuilderConfigData()
		local animationId = normalizeBuilderAnimationId(Options.AutoParryMakerAnimationId.Value)
		local sourceKey = Options.AutoParryMakerSource.Value or "Players"
		local actionType = Options.AutoParryMakerActionType.Value or "Parry"

		if not animationId or animationId == "" then
			return nil
		end

		return {
			configId = autoParryState.currentBuilderConfigId,
			sourceKey = sourceKey,
			animationId = animationId,
			nickname = tostring(Options.AutoParryMakerNickname.Value or ""),
			wait = tonumber(Options.AutoParryMakerWait.Value) or 0,
			repeatAmount = math.max(1, math.floor(tonumber(Options.AutoParryMakerRepeatAmount.Value) or 1)),
			repeatDelay = tonumber(Options.AutoParryMakerRepeatDelay.Value) or 0,
			actionType = actionType,
			delay = Options.AutoParryMakerDelay.Value == "On",
			delayRange = tonumber(Options.AutoParryMakerDelayRange.Value) or 0,
			range = tonumber(Options.AutoParryMakerRange.Value) or 16,
		}
	end

	local function applyBuilderConfigData(configData)
		if not configData then
			return
		end

		autoParryState.currentBuilderConfigId = configData.configId
		Options.AutoParryMakerSource:SetValue(configData.sourceKey or "Players")
		Options.AutoParryMakerAnimationId:SetValue(tostring(configData.animationId or ""))
		Options.AutoParryMakerRepeatAmount:SetValue(tostring(configData.repeatAmount or 1))
		Options.AutoParryMakerRepeatDelay:SetValue(tostring(configData.repeatDelay or 0))
		Options.AutoParryMakerWait:SetValue(tostring(configData.wait or 0))
		Options.AutoParryMakerNickname:SetValue(tostring(configData.nickname or ""))
		Options.AutoParryMakerActionType:SetValue(getConfigActionType(configData))
		Options.AutoParryMakerDelay:SetValue(configData.delay and "On" or "Off")
		Options.AutoParryMakerDelayRange:SetValue(tostring(configData.delayRange or 0))
		Options.AutoParryMakerRange:SetValue(tonumber(configData.range) or 16)
	end

	local normalizeMoveConfig

	local function selectBestMoveConfig(configEntries, candidateDistance)
		if type(configEntries) ~= "table" then
			return nil
		end

		local bestConfig = nil
		local bestRange = nil

		for _, entry in ipairs(configEntries) do
			local normalizedEntry = normalizeMoveConfig(entry, candidateDistance)
			local entryRange = tonumber(normalizedEntry and normalizedEntry.range) or math.huge
			if normalizedEntry and candidateDistance <= entryRange then
				if not bestConfig or entryRange < bestRange then
					bestConfig = normalizedEntry
					bestRange = entryRange
				end
			end
		end

		if bestConfig then
			return bestConfig
		end

		for _, entry in ipairs(configEntries) do
			local normalizedEntry = normalizeMoveConfig(entry, candidateDistance)
			if normalizedEntry then
				return normalizedEntry
			end
		end

		return nil
	end

	local function syncAutoParryBuilderConfigsToRuntime()
		for sourceKey, sourceConfigs in pairs(autoParryMakerConfigs) do
			local runtimeTable = AUTO_PARRY_ANIMATION_TABLE[sourceKey]
			if type(runtimeTable) ~= "table" then
				runtimeTable = {}
				AUTO_PARRY_ANIMATION_TABLE[sourceKey] = runtimeTable
			end

			local groupedConfigs = {}
			for _, configData in ipairs(sourceConfigs) do
				if type(configData) == "table" then
					local animationId = normalizeBuilderAnimationId(configData.animationId)
					if animationId then
						groupedConfigs[animationId] = groupedConfigs[animationId] or {}
						table.insert(groupedConfigs[animationId], buildRuntimeMoveConfig(configData))
					end
				end
			end

			for animationId, runtimeConfigs in pairs(groupedConfigs) do
				if #runtimeConfigs == 1 then
					runtimeTable[animationId] = runtimeConfigs[1]
				elseif #runtimeConfigs > 1 then
					runtimeTable[animationId] = {
						entries = runtimeConfigs,
					}
				end
			end
		end

		GLOBAL_ENV.HuajHubAutoParryAnimations = AUTO_PARRY_ANIMATION_TABLE
	end

	local function refreshSavedConfigDropdown(selectedLabel)
		local labels = {"(none)"}
		builderConfigLabelMap = {}

		for _, sourceKey in ipairs({"Players", "Mobs"}) do
			local sourceConfigs = autoParryMakerConfigs[sourceKey]
			for _, configData in ipairs(sourceConfigs) do
				local animationId = normalizeBuilderAnimationId(configData.animationId)
				if animationId then
				local label = buildSavedConfigLabel(sourceKey, animationId, configData)
					if builderConfigLabelMap[label] then
						label = string.format("%s | %s", label, tostring(configData.configId or ""):sub(1, 8))
					end
					builderConfigLabelMap[label] = {
						sourceKey = sourceKey,
						configId = configData.configId,
					}
				table.insert(labels, label)
				end
			end
		end

		table.sort(labels, function(left, right)
			if left == "(none)" then
				return true
			end
			if right == "(none)" then
				return false
			end
			return left < right
		end)

		Options.AutoParryMakerSavedConfig:SetValues(labels)
		Options.AutoParryMakerSavedConfig:SetValue(builderConfigLabelMap[selectedLabel] and selectedLabel or "(none)")
	end

	local function refreshDetectedAnimationDropdown(selectedLabel)
		local labels = {"(none)"}
		detectedAnimationLabelMap = {}

		for _, sourceKey in ipairs({"Players", "Mobs"}) do
			local sourceEntries = detectedAnimationEntries[sourceKey]
			for animationId, entry in pairs(sourceEntries) do
				local label = formatDetectedAnimationLabel(entry)
				detectedAnimationLabelMap[label] = {
					sourceKey = sourceKey,
					animationId = animationId,
				}
				table.insert(labels, label)
			end
		end

		table.sort(labels, function(left, right)
			if left == "(none)" then
				return true
			end
			if right == "(none)" then
				return false
			end
			return left < right
		end)

		Options.AutoParryMakerDetectedAnimation:SetValues(labels)
		Options.AutoParryMakerDetectedAnimation:SetValue(detectedAnimationLabelMap[selectedLabel] and selectedLabel or "(none)")
	end

	local function applyDetectedEntryToBuilder(detectedEntry)
		if not detectedEntry then
			return
		end

		autoParryState.currentBuilderConfigId = nil
		Options.AutoParryMakerSource:SetValue(detectedEntry.sourceKey)
		Options.AutoParryMakerAnimationId:SetValue(detectedEntry.animationId)
		Options.AutoParryMakerNickname:SetValue(detectedEntry.animationName or detectedEntry.targetName or "")
		Options.AutoParryMakerWait:SetValue(string.format("%.2f", detectedEntry.timePosition or 0))
		Options.AutoParryMakerRange:SetValue(math.max(1, math.floor(detectedEntry.distance or 16)))
	end

	local function registerDetectedAnimation(targetType, targetName, animationId, timePosition, distance, animationName)
		local sourceKey = getMakerSourceKey(targetType)
		local normalizedAnimationId = normalizeBuilderAnimationId(animationId)
		if not normalizedAnimationId or normalizedAnimationId == "" then
			return
		end

		local entry = detectedAnimationEntries[sourceKey][normalizedAnimationId] or {
			sourceKey = sourceKey,
			animationId = normalizedAnimationId,
		}

		entry.targetName = targetName or entry.targetName or "Unknown"
		entry.animationName = animationName or entry.animationName or targetName or "Unknown"
		entry.timePosition = tonumber(timePosition) or entry.timePosition or 0
		entry.distance = tonumber(distance) or entry.distance or 16
		entry.updatedAt = os.clock()

		detectedAnimationEntries[sourceKey][normalizedAnimationId] = entry
		local selectedLabel = formatDetectedAnimationLabel(entry)
		refreshDetectedAnimationDropdown(selectedLabel)
		applyDetectedEntryToBuilder(entry)
	end

	local function loadAutoParryMakerConfigsFromFile()
		if type(isfile) ~= "function" or type(readfile) ~= "function" then
			return
		end

		local filePath = nil
		for _, candidatePath in ipairs({
			AUTO_PARRY_MAKER_FILE,
			AUTO_PARRY_MAKER_OLD_SHARED_FILE,
			AUTO_PARRY_MAKER_OLD_WORKSPACE_FILE,
			AUTO_PARRY_MAKER_LEGACY_FILE,
		}) do
			local readOk, fileExists = pcall(function()
				return isfile(candidatePath)
			end)
			if readOk and fileExists then
				filePath = candidatePath
				break
			end
		end

		if not filePath then
			return
		end

		local sourceOk, source = pcall(function()
			return readfile(filePath)
		end)
		if not sourceOk or type(source) ~= "string" or source == "" then
			return
		end

		local decodeOk, decoded = pcall(function()
			return HttpService:JSONDecode(source)
		end)
		if not decodeOk or type(decoded) ~= "table" then
			return
		end

		for _, sourceKey in ipairs({"Players", "Mobs"}) do
			local normalizedConfigs = {}
			if type(decoded[sourceKey]) == "table" then
				for storageKey, configData in pairs(decoded[sourceKey]) do
					local normalizedConfig = normalizeLoadedConfigRecord(sourceKey, storageKey, configData)
					if normalizedConfig then
						table.insert(normalizedConfigs, normalizedConfig)
					end
				end
			end
			autoParryMakerConfigs[sourceKey] = dedupeMakerConfigList(sourceKey, normalizedConfigs)
		end
	end

	local function ensureAutoParryMakerConfigFile()
		if type(writefile) ~= "function" or type(isfile) ~= "function" then
			return
		end

		if type(makefolder) == "function" then
			pcall(makefolder, "huajhub")
			pcall(makefolder, AUTO_PARRY_MAKER_FOLDER)
		end

		local existsOk, exists = pcall(function()
			return isfile(AUTO_PARRY_MAKER_FILE)
		end)
		if existsOk and exists then
			return
		end

		local encodeOk, payload = pcall(function()
			return HttpService:JSONEncode(autoParryMakerConfigs)
		end)
		if not encodeOk or type(payload) ~= "string" then
			return
		end

		pcall(function()
			writefile(AUTO_PARRY_MAKER_FILE, payload)
		end)
	end

	local function saveAutoParryMakerConfigsToFile()
		if type(writefile) ~= "function" then
			Library:Notify("writefile is unavailable in this executor.", 2)
			return false
		end

		if type(makefolder) == "function" then
			pcall(makefolder, "huajhub")
			pcall(makefolder, AUTO_PARRY_MAKER_FOLDER)
		end

		for _, sourceKey in ipairs({"Players", "Mobs"}) do
			autoParryMakerConfigs[sourceKey] = dedupeMakerConfigList(sourceKey, autoParryMakerConfigs[sourceKey])
		end

		local encodeOk, payload = pcall(function()
			return HttpService:JSONEncode(autoParryMakerConfigs)
		end)
		if not encodeOk or type(payload) ~= "string" then
			Library:Notify("Failed to encode Auto Parry Maker configs.", 2)
			return false
		end

		local writeOk, writeErr = pcall(function()
			writefile(AUTO_PARRY_MAKER_FILE, payload)
		end)
		if not writeOk then
			Library:Notify("Failed to save Auto Parry Maker configs: " .. tostring(writeErr), 2)
			return false
		end

		Library:Notify("Saved Auto Parry Maker configs.", 2)
		return true
	end

	onCreateMakerConfig = function()
		local configData = getBuilderConfigData()
		if not configData then
			Library:Notify("Animation ID is required before creating a config.", 2)
			return
		end

		local savedConfig = upsertMakerConfig(configData, true)
		autoParryState.currentBuilderConfigId = savedConfig and savedConfig.configId or nil
		syncAutoParryBuilderConfigsToRuntime()

		local selectedLabel = buildSavedConfigLabel(savedConfig.sourceKey, savedConfig.animationId, savedConfig)
		refreshSavedConfigDropdown(selectedLabel)
		Library:Notify("Created Auto Parry config for " .. savedConfig.animationId .. ".", 2)
	end

	onSaveMakerConfig = function()
		local configData = getBuilderConfigData()
		if configData then
			local savedConfig = upsertMakerConfig(configData, false)
			autoParryState.currentBuilderConfigId = savedConfig and savedConfig.configId or nil
			syncAutoParryBuilderConfigsToRuntime()
			refreshSavedConfigDropdown(buildSavedConfigLabel(savedConfig.sourceKey, savedConfig.animationId, savedConfig))
		end

		saveAutoParryMakerConfigsToFile()
	end

	onAutoGetMakerConfig = function()
		local latestCapture = lastManualParryCapture
		if lastManualDashCapture and (not latestCapture or (lastManualDashCapture.capturedAt or 0) > (latestCapture.capturedAt or 0)) then
			latestCapture = lastManualDashCapture
		end
		if lastManualJumpCapture and (not latestCapture or (lastManualJumpCapture.capturedAt or 0) > (latestCapture.capturedAt or 0)) then
			latestCapture = lastManualJumpCapture
		end

		if not latestCapture then
			Library:Notify("No manual parry, dash, or jump capture is available yet.", 2)
			return
		end

		applyBuilderConfigData({
			configId = nil,
			sourceKey = latestCapture.sourceKey,
			animationId = latestCapture.animationId,
			repeatAmount = 1,
			repeatDelay = 0,
			wait = latestCapture.wait or 0,
			nickname = latestCapture.nickname or "",
			actionType = latestCapture.actionKind == "manual dash" and "Dash" or (latestCapture.actionKind == "manual jump" and "Jump" or "Parry"),
			delay = false,
			delayRange = 0,
			range = latestCapture.range or 16,
		})

		Library:Notify("Loaded latest manual capture into Auto Parry Maker.", 2)
	end

	local function getAutoParryTargetDebugType(model)
		if not model or not model:IsA("Model") then
			return "unknown"
		end

		local ownerPlayer = Players:GetPlayerFromCharacter(model)
		local hasAnimationController = model:FindFirstChildWhichIsA("AnimationController", true) ~= nil
		local hasAiConfigurations = model:FindFirstChild("AI_Configurations", true) ~= nil
		local hasAnimator = model:FindFirstChildWhichIsA("Animator", true) ~= nil
		local hasHumanoid = model:FindFirstChildOfClass("Humanoid") ~= nil
		local hasBone = model:FindFirstChildWhichIsA("Bone", true) ~= nil
		local hasMotor6D = model:FindFirstChildWhichIsA("Motor6D", true) ~= nil

		if ownerPlayer then
			return "player"
		end

		if hasAnimationController and hasAiConfigurations then
			return "mob"
		end

		if hasAnimationController or hasAnimator or hasHumanoid or hasBone or hasMotor6D then
			return "mob"
		end

		return "unknown"
	end

	local function isLocalAutoParryCharacter(model)
		local character = LocalPlayer and LocalPlayer.Character
		if not model or not model:IsA("Model") or not character then
			return false
		end

		if model == character then
			return true
		end

		local ownerPlayer = Players:GetPlayerFromCharacter(model)
		if ownerPlayer == LocalPlayer then
			return true
		end

		return model:IsDescendantOf(character) or character:IsDescendantOf(model)
	end

	local function resolveAutoParryTargetType(model)
		if isLocalAutoParryCharacter(model) then
			return nil
		end

		local debugType = getAutoParryTargetDebugType(model)
		if debugType == "mob" or debugType == "player" then
			return debugType
		end
	end

	local function ensureAutoParryVisualizer()
		local part = autoParryState.visualizer.part
		if part and part.Parent then
			return part
		end

		part = Instance.new("Part")
		part.Name = "HuajHubAutoParryRange"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Transparency = 0.72
		part.Shape = Enum.PartType.Ball
		part.Material = Enum.Material.ForceField
		part.Color = Color3.fromRGB(0, 170, 255)
		part.Size = Vector3.new(1, 1, 1)
		part.Parent = workspace

		autoParryState.visualizer.part = part
		return part
	end

	local function updateAutoParryVisualizer()
		local character = LocalPlayer and LocalPlayer.Character
		local root = getCharacterRoot(character)
		local part = autoParryState.visualizer.part
		local visualizerToggle = Toggles.AutoParryVisualizer
		local distanceOption = Options.AutoParryDistance

		if not visualizerToggle or not visualizerToggle.Value or not root then
			if part then
				part.Transparency = 1
			end
			return
		end

		part = ensureAutoParryVisualizer()
		local distance = (distanceOption and distanceOption.Value) or 18
		local diameter = math.max(distance * 2, 1)
		part.Transparency = 0.72
		part.Size = Vector3.new(diameter, diameter, diameter)
		part.CFrame = CFrame.new(root.Position)
	end

	local function classifyParryTarget(model, maxDistance)
		local character = LocalPlayer and LocalPlayer.Character
		local root = getCharacterRoot(character)
		if not root or not model or not model:IsA("Model") or isLocalAutoParryCharacter(model) then
			return nil
		end

		local targetRoot = getCharacterRoot(model)
		if not targetRoot then
			return nil
		end

		local mode = Options.AutoParryMode.Value or "Mobs+Players"
		local allowPlayers = mode == "Mobs+Players" or mode == "Players"
		local allowMobs = mode == "Mobs+Players" or mode == "Mobs"
		local whitelist = Options.AutoParryWhitelist.Value
		local ownerPlayer = Players:GetPlayerFromCharacter(model)
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local targetType = resolveAutoParryTargetType(model)
		local isMob = targetType == "mob"
		local isPlayer = targetType == "player"
		local isWhitelisted = ownerPlayer and type(whitelist) == "table" and whitelist[ownerPlayer.Name] == true

		if isWhitelisted then
			return nil
		end

		if isPlayer and not allowPlayers then
			return nil
		end

		if isMob and not allowMobs then
			return nil
		end

		if not isMob and not isPlayer then
			return nil
		end

		if humanoid and humanoid.Health <= 0 then
			return nil
		end

		local distance = getHorizontalEdgeDistance(character, model)
		if distance > maxDistance then
			return nil
		end

		return {
			character = model,
			root = targetRoot,
			distance = distance,
			targetType = targetType,
		}
	end

	local function getAnimationConfig(targetType, animationId)
		local normalized = normalizeAnimationId(animationId)
		local animationTable = targetType == "player" and AUTO_PARRY_ANIMATION_TABLE.Players or AUTO_PARRY_ANIMATION_TABLE.Mobs
		if type(animationTable) ~= "table" then
			return nil
		end

		return animationTable[animationId]
			or animationTable[normalized]
			or animationTable["rbxassetid://" .. normalized]
	end

	normalizeMoveConfig = function(moveConfig, candidateDistance)
		return AutoParryConfigUtils.normalizeMoveConfig(moveConfig, candidateDistance, selectBestMoveConfig)
	end

	local getTrackPriorityScore

	local function getTrackTimePosition(track)
		if not track then
			return nil
		end

		local ok, timePosition = pcall(function()
			return track.TimePosition
		end)

		if ok and type(timePosition) == "number" then
			return math.max(timePosition, 0)
		end
	end

	local function getMinimumAutoParryPriorityScore(moveConfig)
		if moveConfig and (moveConfig.dash == true or moveConfig.block == true or moveConfig.jump == true) then
			return 3
		end

		return 4
	end

	local function isTrackUsableForAutoParry(track, moveConfig, currentTrackTimePosition)
		if not track then
			return false, "missing track"
		end

		local ok, isPlaying = pcall(function()
			return track.IsPlaying
		end)
		if not ok or not isPlaying then
			return false, "stopped"
		end

		local trackPriorityScore = getTrackPriorityScore(track)
		local minimumPriorityScore = getMinimumAutoParryPriorityScore(moveConfig)
		local currentTime = math.max(tonumber(currentTrackTimePosition) or getTrackTimePosition(track) or 0, 0)
		local configuredTiming = resolveConfiguredTiming(moveConfig)

		if trackPriorityScore < minimumPriorityScore then
			local lowPriorityFreshLimit = configuredTiming and math.max(configuredTiming * 0.5, 0.12) or 0.12
			if currentTime > lowPriorityFreshLimit then
				return false, "low priority"
			end
		end

		if configuredTiming and currentTime > math.max(configuredTiming + 0.16, configuredTiming * 1.35) then
			return false, "late track"
		end

		if currentTime > 1.75 and not configuredTiming then
			return false, "stale track"
		end

		return true, nil
	end

	local function getMoveConfigRange(moveConfig)
		return AutoParryConfigUtils.getMoveConfigRange(moveConfig, Options.AutoParryDistance.Value or 18)
	end

	local function getMoveConfigDelaySeconds(moveConfig)
		return AutoParryConfigUtils.getMoveConfigDelaySeconds(moveConfig)
	end

	local function getMoveConfigRepeatDelaySeconds(moveConfig)
		return AutoParryConfigUtils.getMoveConfigRepeatDelaySeconds(moveConfig)
	end

	local function formatAutoParryTrackingText(action, distance, now)
		if not action then
			return "waiting for a detected move in range."
		end

		local trackTimePosition = getTrackTimePosition(action.track) or math.max(now - (action.detectedAt or now), 0)
		local timeUntilTrigger = math.max((action.triggerAt or now) - now, 0)

		return string.format(
			"tracking %s anim %s at %.2fs | trigger %.2fs | %.1f studs",
			action.target and action.target.Name or "unknown",
			action.animationId or "?",
			trackTimePosition,
			timeUntilTrigger,
			tonumber(distance) or 0
		)
	end

	local function cleanupHandledAttackTracks()
		for track in pairs(autoParryState.handledTracks) do
			local ok, isPlaying = pcall(function()
				return track.IsPlaying
			end)

			if not ok or not isPlaying then
				autoParryState.handledTracks[track] = nil
			end
		end
	end

	local function removeQueuedMoveActionForTrack(track)
		for index = #autoParryState.queuedMoveActions, 1, -1 do
			if autoParryState.queuedMoveActions[index].track == track then
				table.remove(autoParryState.queuedMoveActions, index)
			end
		end

		if track then
			autoParryState.queuedTracks[track] = nil
		end
	end

	local function queueAutoParryTrack(targetCharacter, track)
		if not targetCharacter or not track or autoParryState.handledTracks[track] or autoParryState.queuedTracks[track] then
			return false
		end

		if isLocalAutoParryCharacter(targetCharacter) then
			return false
		end

		local animation = track.Animation
		local animationId = animation and animation.AnimationId
		if not animationId or animationId == "" then
			setAutoParryDebugText(string.format("%s has a track without an animation id.", targetCharacter.Name))
			return false
		end

		local normalizedAnimationId = normalizeAnimationId(animationId)
		local debugType = getAutoParryTargetDebugType(targetCharacter)

		local baseDistance = Options.AutoParryDistance.Value or 18
		local candidate = classifyParryTarget(targetCharacter, baseDistance)
		if not candidate then
			setAutoParryDebugText(string.format("%s %s anim %s skipped by range/filter.", debugType, targetCharacter.Name, normalizedAnimationId))
			return false
		end

		local rawConfig = getAnimationConfig(candidate.targetType, animationId)
		local moveConfig = normalizeMoveConfig(rawConfig, candidate.distance)
		if not moveConfig then
			setAutoParryDebugText(string.format("%s %s anim %s not in table.", candidate.targetType, targetCharacter.Name, normalizedAnimationId))
			return false
		end

		local configDistance = getMoveConfigRange(moveConfig)
		if candidate.distance > configDistance then
			setAutoParryDebugText(string.format("%s %s anim %s is outside config range.", candidate.targetType, targetCharacter.Name, normalizedAnimationId))
			return false
		end

		local configuredTiming = resolveConfiguredTiming(moveConfig) or 0
		local sourceKey = getMakerSourceKey(candidate.targetType)
		local timingOffsetMs = getAdaptiveTimingOffsetMs(sourceKey, normalizedAnimationId, moveConfig, candidate.distance)
		local timingOffset = timingOffsetMs / 1000
		local currentTrackTimePosition = getTrackTimePosition(track) or 0
		local isTrackUsable, unusableReason = isTrackUsableForAutoParry(track, moveConfig, currentTrackTimePosition)
		if not isTrackUsable then
			setAutoParryDebugText(string.format(
				"%s %s anim %s ignored (%s).",
				candidate.targetType,
				targetCharacter.Name,
				normalizedAnimationId,
				unusableReason or "filtered"
			))
			return false
		end

		registerDetectedAnimation(
			candidate.targetType,
			targetCharacter.Name,
			normalizedAnimationId,
			currentTrackTimePosition,
			candidate.distance,
			resolveDetectedAnimationName(normalizedAnimationId, track, targetCharacter.Name)
		)

		autoParryState.queuedTracks[track] = true
		table.insert(autoParryState.queuedMoveActions, {
			target = candidate.character,
			targetType = candidate.targetType,
			sourceKey = sourceKey,
			track = track,
			animationId = normalizedAnimationId,
			config = moveConfig,
			detectedAt = os.clock(),
			triggerAt = os.clock() + math.max(configuredTiming + timingOffset + getMoveConfigDelaySeconds(moveConfig), 0),
			timingOffsetMs = timingOffsetMs,
			repeatsRemaining = math.max(1, math.floor(tonumber(moveConfig.repeatAmount) or 1)),
			queuedTrackTimePosition = currentTrackTimePosition,
		})

		local stoppedConnection
		stoppedConnection = track.Stopped:Connect(function()
			if stoppedConnection then
				stoppedConnection:Disconnect()
				stoppedConnection = nil
			end

			if not autoParryState.handledTracks[track] then
				removeQueuedMoveActionForTrack(track)
			end
		end)

		return true
	end

	local function scanAnimatorTracksForAutoParry(targetCharacter, animator)
		if not targetCharacter or not animator then
			return
		end

		local ok, tracks = pcall(function()
			return animator:GetPlayingAnimationTracks()
		end)

		if not ok or type(tracks) ~= "table" then
			return
		end

		for _, track in ipairs(tracks) do
			queueAutoParryTrack(targetCharacter, track)
		end
	end

	local function getQueuedAutoParryActionCandidate(action)
		if not action or not action.track or autoParryState.handledTracks[action.track] then
			return nil, nil
		end

		local actionRange = getMoveConfigRange(action.config)
		local candidate = classifyParryTarget(action.target, actionRange)
		if not candidate then
			return nil, nil
		end

		local currentTrackTimePosition = getTrackTimePosition(action.track) or 0
		if not isTrackUsableForAutoParry(action.track, action.config, currentTrackTimePosition) then
			return nil, nil
		end

		return candidate, currentTrackTimePosition
	end

	local function getSelectedAutoParryTrackFailureReason(action, now)
		if not action then
			return "invalid action"
		end

		local trackTimePosition = getTrackTimePosition(action.track) or math.max(now - (action.detectedAt or now), 0)
		local isTrackUsable, reason = isTrackUsableForAutoParry(action.track, action.config, trackTimePosition)
		if isTrackUsable then
			return nil, trackTimePosition
		end

		return reason or "invalid track", trackTimePosition
	end

	function autoParryRuntime.completeOrRepeatAutoParryAction(selectedAction, activeMoveConfig, animationTrack, now)
		local repeatsRemaining = math.max(math.floor(tonumber(selectedAction.repeatsRemaining) or 1), 1) - 1
		if repeatsRemaining <= 0 then
			autoParryState.handledTracks[animationTrack] = true
			removeQueuedMoveActionForTrack(animationTrack)
			return
		end

		selectedAction.repeatsRemaining = repeatsRemaining
		selectedAction.detectedAt = now
		selectedAction.triggerAt = now + getMoveConfigRepeatDelaySeconds(activeMoveConfig) + getMoveConfigDelaySeconds(activeMoveConfig)
	end

	function autoParryRuntime.executeSelectedAutoParryAction(selectedAction, selectedDistance, remote, now)
		local targetCharacter = selectedAction.target
		local targetType = selectedAction.targetType
		local animationTrack = selectedAction.track
		local animationId = selectedAction.animationId
		local activeMoveConfig = selectedAction.config
		local actionRange = getMoveConfigRange(activeMoveConfig)
		local selectedTrackReason, parryTimingSeconds = getSelectedAutoParryTrackFailureReason(selectedAction, now)
		if selectedTrackReason then
			setAutoParryDebugText(string.format(
				"skipped %s anim %s (%s).",
				targetCharacter and targetCharacter.Name or "unknown",
				animationId or "?",
				selectedTrackReason
			))
			removeQueuedMoveActionForTrack(animationTrack)
			return
		end

		if activeMoveConfig and type(activeMoveConfig.handler) == "function" then
			pcall(function()
				activeMoveConfig.handler({
					target = targetCharacter,
					targetType = targetType,
					track = animationTrack,
					animationId = animationId,
					remote = remote,
					requestModule = remote,
					setBlocking = fireBlockingStateRemote,
					pressDashKey = autoParryRuntime.pressDashKey,
					pressJumpKey = autoParryRuntime.pressJumpKey,
					distance = selectedDistance,
					maxDistance = actionRange,
					now = now,
				})
			end)

			if Toggles.AutoParryBlockInputs.Value then
				autoParryState.inputBlockUntil = now + AUTO_PARRY_BLOCK_DURATION
				autoParryRuntime.setAutoParryInputBlocking(true)
			end

			setAutoParryDebugText(string.format(
				"custom %s anim %s at %.2fs",
				targetCharacter.Name,
				animationId,
				parryTimingSeconds
			))
			autoParryRuntime.completeOrRepeatAutoParryAction(selectedAction, activeMoveConfig, animationTrack, now)
			return
		end

		local usedDash = false
		if activeMoveConfig and activeMoveConfig.dash == true
			and not (Toggles.AutoParryDontBlatantDashPlayers.Value and targetType == "player")
			and now - autoParryState.lastBlatantDashAt >= blatantDashCooldown then
			autoParryState.lastBlatantDashAt = now
			if Toggles.AutoParryBlatantDash.Value then
				usedDash = autoParryRuntime.fireAutoParryDashRemote(remote) == true
			else
				autoParryRuntime.pressDashKey()
				usedDash = true
			end
		end

		if activeMoveConfig and activeMoveConfig.actionType == "Jump" then
			autoParryRuntime.pressJumpKey()
			setAutoParryDebugText(string.format(
				"jump %s anim %s at %.2fs",
				targetCharacter.Name,
				animationId,
				parryTimingSeconds
			))
			autoParryState.pendingParryFailCheck = nil
			autoParryState.handledTracks[animationTrack] = true
			autoParryRuntime.completeOrRepeatAutoParryAction(selectedAction, activeMoveConfig, animationTrack, now)
		elseif activeMoveConfig and activeMoveConfig.actionType == "Dash" then
			setAutoParryDebugText(string.format(
				"%sdash %s anim %s at %.2fs",
				usedDash and "" or "attempted ",
				targetCharacter.Name,
				animationId,
				parryTimingSeconds
			))
			autoParryState.pendingParryFailCheck = nil
			autoParryState.handledTracks[animationTrack] = true
			autoParryRuntime.completeOrRepeatAutoParryAction(selectedAction, activeMoveConfig, animationTrack, now)
		elseif activeMoveConfig and activeMoveConfig.block == true then
			if fireBlockingStateRemote(true) then
				autoParryState.pendingBlockReleaseAt = now + autoParryBlockHoldDuration
				setAutoParryDebugText(string.format(
					"%sblock %s anim %s at %.2fs",
					usedDash and "dash + " or "",
					targetCharacter.Name,
					animationId,
					parryTimingSeconds
				))
			else
				setAutoParryDebugText(string.format(
					"%sblock failed %s anim %s at %.2fs",
					usedDash and "dash + " or "",
					targetCharacter.Name,
					animationId,
					parryTimingSeconds
				))
			end
			autoParryState.pendingParryFailCheck = nil
			autoParryRuntime.completeOrRepeatAutoParryAction(selectedAction, activeMoveConfig, animationTrack, now)
		else
			autoParryRuntime.fireAutoParryParryRemote(remote)
			setAutoParryDebugText(string.format(
				"%sparry %s anim %s at %.2fs",
				usedDash and "dash + " or "",
				targetCharacter.Name,
				animationId,
				parryTimingSeconds
			))
			autoParryState.handledTracks[animationTrack] = true

			if Toggles.AutoParryDashOnFail.Value then
				autoParryState.pendingParryFailCheck = {
					target = targetCharacter,
					distance = actionRange,
					checkAt = now + 0.18,
					sourceKey = selectedAction.sourceKey,
					animationId = animationId,
					actionType = activeMoveConfig.actionType or "Parry",
				}
			else
				autoParryState.pendingParryFailCheck = nil
			end

			autoParryRuntime.completeOrRepeatAutoParryAction(selectedAction, activeMoveConfig, animationTrack, now)
		end

		if Toggles.AutoParryBlockInputs.Value then
			autoParryState.inputBlockUntil = now + AUTO_PARRY_BLOCK_DURATION
			autoParryRuntime.setAutoParryInputBlocking(true)
		end
	end

	function autoParryRuntime.processAutoParryHeartbeat()
		updateAutoParryVisualizer()

		if autoParryState.pendingManualParryDebugMessage and manualParryTimingLabel and type(manualParryTimingLabel.SetText) == "function" then
			manualParryTimingLabel:SetText(autoParryState.pendingManualParryDebugMessage)
			autoParryState.pendingManualParryDebugMessage = nil
		end

		if autoParryState.pendingManualDashDebugMessage and manualDashTimingLabel and type(manualDashTimingLabel.SetText) == "function" then
			manualDashTimingLabel:SetText(autoParryState.pendingManualDashDebugMessage)
			autoParryState.pendingManualDashDebugMessage = nil
		end

		local now = os.clock()
		cleanupHandledAttackTracks()

		if Toggles.AutoParryAdaptiveTiming.Value and now - autoParryState.lastAdaptiveTimingUpdateAt >= adaptiveTimingUpdateInterval then
			autoParryState.lastAdaptiveTimingUpdateAt = now
			updateAdaptiveTimingOffset(false)
		end

		if autoParryState.inputBlockActive and os.clock() >= autoParryState.inputBlockUntil then
			autoParryRuntime.setAutoParryInputBlocking(false)
		end

		if autoParryState.pendingBlockReleaseAt > 0 and now >= autoParryState.pendingBlockReleaseAt then
			autoParryState.pendingBlockReleaseAt = 0
			fireBlockingStateRemote(false)
		end

		if autoParryState.pendingParryFailCheck and now >= autoParryState.pendingParryFailCheck.checkAt then
			local targetCharacter = autoParryState.pendingParryFailCheck.target
			local maxDistance = autoParryState.pendingParryFailCheck.distance or (Options.AutoParryDistance.Value or 18)
			local localCharacter = LocalPlayer and LocalPlayer.Character
			local localRoot = getCharacterRoot(localCharacter)
			local targetRoot = getCharacterRoot(targetCharacter)
			local humanoid = getCharacterHumanoid(targetCharacter)

			if Toggles.AutoParryDashOnFail.Value
				and localRoot
				and targetRoot
				and humanoid
				and humanoid.Health > 0
				and (targetRoot.Position - localRoot.Position).Magnitude <= maxDistance
				and now - autoParryState.lastDashOnFailAt >= dashOnFailCooldown then
				updateLearnedAdaptiveOffset(
					autoParryState.pendingParryFailCheck.sourceKey,
					autoParryState.pendingParryFailCheck.animationId,
					autoParryState.pendingParryFailCheck.actionType,
					-12,
					0.25
				)
				autoParryState.lastDashOnFailAt = now
				autoParryRuntime.pressDashKey()
			end

			autoParryState.pendingParryFailCheck = nil
		end

		if not isAutoParryEnabled() then
			autoParryState.pendingParryFailCheck = nil
			table.clear(autoParryState.queuedMoveActions)
			table.clear(autoParryState.queuedTracks)
			setAutoParryTrackingText("disabled.")
			return
		end

		local remote = getRequestModuleRemote()
		autoParryState.manualActionRequestRemote = remote or autoParryState.manualActionRequestRemote
		if not remote then
			autoParryState.pendingParryFailCheck = nil
			table.clear(autoParryState.queuedMoveActions)
			table.clear(autoParryState.queuedTracks)
			setAutoParryTrackingText("remote not found.")
			if not autoParryState.lastState.remoteMissing then
				autoParryState.lastState.remoteMissing = true
				Library:Notify("Auto Parry remote was not found.", 2)
			end
			return
		end

		autoParryState.lastState.remoteMissing = false

		if now - autoParryState.lastTrackSweepAt >= autoParryTrackSweepInterval then
			autoParryState.lastTrackSweepAt = now
			autoParryRuntime.refreshTrackedAutoParryTargets()
			for model, trackedTarget in pairs(autoParryState.trackedTargets) do
				if not model.Parent then
					autoParryRuntime.disconnectTrackedAutoParryTarget(model)
				else
					for animator in pairs(trackedTarget.animators) do
						scanAnimatorTracksForAutoParry(model, animator)
					end
				end
			end
		end

		local selectedAction
		local trackedAction
		local selectedDistance
		local trackedDistance

		for index = #autoParryState.queuedMoveActions, 1, -1 do
			local action = autoParryState.queuedMoveActions[index]
			local track = action.track
			local candidate, currentTrackTimePosition = getQueuedAutoParryActionCandidate(action)

			if not action
				or not track
				or not candidate
				or not track.IsPlaying then
				removeQueuedMoveActionForTrack(track)
			else
				action.targetType = candidate.targetType
				action.target = candidate.character
				action.lastTrackTimePosition = currentTrackTimePosition

				if not trackedAction
					or action.triggerAt < trackedAction.triggerAt
					or (action.triggerAt == trackedAction.triggerAt and candidate.distance < (trackedDistance or math.huge)) then
					trackedAction = action
					trackedDistance = candidate.distance
				end

				if now >= action.triggerAt and (not selectedAction or action.triggerAt < selectedAction.triggerAt) then
					selectedAction = action
					selectedDistance = candidate.distance
				end
			end
		end

		setAutoParryTrackingText(formatAutoParryTrackingText(trackedAction, trackedDistance, now))

		if not selectedAction or now - autoParryState.lastParryAt < autoParryCooldown then
			return
		end

		autoParryState.lastParryAt = now
		autoParryRuntime.executeSelectedAutoParryAction(selectedAction, selectedDistance, remote, now)
	end

	getTrackPriorityScore = function(track)
		local ok, priority = pcall(function()
			return track and track.Priority
		end)
		if not ok or priority == nil then
			return 0
		end

		if priority == Enum.AnimationPriority.Action4 then
			return 7
		end
		if priority == Enum.AnimationPriority.Action3 then
			return 6
		end
		if priority == Enum.AnimationPriority.Action2 then
			return 5
		end
		if priority == Enum.AnimationPriority.Action then
			return 4
		end
		if priority == Enum.AnimationPriority.Movement then
			return 3
		end
		if priority == Enum.AnimationPriority.Idle then
			return 2
		end
		if priority == Enum.AnimationPriority.Core then
			return 1
		end

		return 0
	end

	local function isBetterManualDebugTrack(candidateTrack, currentBest)
		if not candidateTrack then
			return false
		end

		if not currentBest then
			return true
		end

		local candidatePriority = tonumber(candidateTrack.priorityScore) or 0
		local bestPriority = tonumber(currentBest.priorityScore) or 0
		if candidatePriority ~= bestPriority then
			return candidatePriority > bestPriority
		end

		local candidateTime = tonumber(candidateTrack.timePosition) or math.huge
		local bestTime = tonumber(currentBest.timePosition) or math.huge
		if math.abs(candidateTime - bestTime) > 0.03 then
			return candidateTime < bestTime
		end

		if candidateTrack.matched ~= currentBest.matched then
			return candidateTrack.matched == true
		end

		return false
	end

	local function getManualCaptureCompensationSeconds(captureRequestedAt)
		local captureLatency = math.max(os.clock() - (tonumber(captureRequestedAt) or os.clock()), 0)
		if captureLatency <= (1 / 60) then
			return 0
		end

		return math.min(captureLatency * 0.35, 0.035)
	end

	local function getManualDebugTrackForTarget(targetCharacter, targetType, captureRequestedAt)
		local bestTrack
		local captureCompensation = getManualCaptureCompensationSeconds(captureRequestedAt)

		for _, animator in ipairs(getTargetAnimators(targetCharacter)) do
			local ok, tracks = pcall(function()
				return animator:GetPlayingAnimationTracks()
			end)

			if ok and type(tracks) == "table" then
				for _, track in ipairs(tracks) do
					local animation = track and track.Animation
					local animationId = animation and animation.AnimationId
					if animationId and animationId ~= "" then
						local rawTimePosition = getTrackTimePosition(track) or 0
						local candidateTrack = {
							animationId = normalizeAnimationId(animationId),
							animationName = resolveDetectedAnimationName(animationId, track, targetCharacter.Name),
							timePosition = math.max(rawTimePosition - captureCompensation, 0),
							matched = getAnimationConfig(targetType, animationId) ~= nil,
							priorityScore = getTrackPriorityScore(track),
						}
						if isBetterManualDebugTrack(candidateTrack, bestTrack) then
							bestTrack = candidateTrack
						end
					end
				end
			end
		end

		if bestTrack then
			return bestTrack.animationId, bestTrack.animationName, bestTrack.matched, bestTrack.timePosition, bestTrack.priorityScore
		end
	end

	local function isBetterManualDebugCandidate(candidateInfo, currentBest, preferMatched)
		if not candidateInfo then
			return false
		end

		if not currentBest then
			return true
		end

		local candidatePriority = tonumber(candidateInfo.priorityScore) or 0
		local bestPriority = tonumber(currentBest.priorityScore) or 0
		if candidatePriority ~= bestPriority then
			return candidatePriority > bestPriority
		end

		if preferMatched and candidateInfo.matched ~= currentBest.matched then
			return candidateInfo.matched == true
		end

		local candidateTime = tonumber(candidateInfo.timePosition) or math.huge
		local bestTime = tonumber(currentBest.timePosition) or math.huge
		if math.abs(candidateTime - bestTime) > 0.03 then
			return candidateTime < bestTime
		end

		return (tonumber(candidateInfo.distance) or math.huge) < (tonumber(currentBest.distance) or math.huge)
	end

	local function findManualDebugCandidate(maxDistance, captureRequestedAt)
		local liveFolder = autoParryRuntime.refreshTrackedAutoParryTargets()
		if not liveFolder then
			return nil
		end

		local matchedCandidate
		local fallbackCandidate

		for _, model in ipairs(liveFolder:GetChildren()) do
			if isLocalAutoParryCharacter(model) then
				continue
			end

			local candidate = classifyParryTarget(model, maxDistance)
			if candidate then
				local animationId, animationName, isMatched, timePosition, priorityScore = getManualDebugTrackForTarget(candidate.character, candidate.targetType, captureRequestedAt)
				if animationId then
					local candidateInfo = {
						targetName = candidate.character.Name,
						targetType = candidate.targetType,
						animationId = animationId,
						animationName = animationName,
						timePosition = timePosition or 0,
						priorityScore = priorityScore or 0,
						distance = candidate.distance,
						matched = isMatched,
					}

					if isMatched then
						if isBetterManualDebugCandidate(candidateInfo, matchedCandidate, false) then
							matchedCandidate = candidateInfo
						end
					elseif isBetterManualDebugCandidate(candidateInfo, fallbackCandidate, false) then
						fallbackCandidate = candidateInfo
					end
				end
			end
		end

		return matchedCandidate or fallbackCandidate
	end

	local function reportManualActionDebug(actionKind, captureRequestedAt)
		local maxDistance = Options.AutoParryDistance.Value or 18
		local candidate = findManualDebugCandidate(maxDistance, captureRequestedAt)
		local isDashAction = actionKind == "manual dash"
		local isJumpAction = actionKind == "manual jump"
		local actionType = isDashAction and "Dash" or (isJumpAction and "Jump" or "Parry")
		local setDebugText = isDashAction and setManualDashDebugText or setManualParryDebugText
		local setLastAnimationId = isDashAction and setLastManualDashAnimationId or setLastManualParryAnimationId
		if not candidate then
			setLastAnimationId(nil)
			setDebugText(string.format("%s -> no nearby tracked animation found.", actionKind))
			return
		end

		registerDetectedAnimation(candidate.targetType, candidate.targetName, candidate.animationId, candidate.timePosition, candidate.distance, candidate.animationName)
		setLastAnimationId(candidate.animationId)
		local latestCapture = {
			actionKind = actionKind,
			sourceKey = getMakerSourceKey(candidate.targetType),
			animationId = candidate.animationId,
			wait = candidate.timePosition or 0,
			nickname = candidate.animationName or candidate.targetName,
			range = math.max(1, math.floor(candidate.distance or 16)),
			capturedAt = os.clock(),
		}
		if isDashAction then
			lastManualDashCapture = latestCapture
		elseif isJumpAction then
			lastManualJumpCapture = latestCapture
		else
			lastManualParryCapture = latestCapture
		end

		local savedConfig = findMakerConfigByAnimationId(latestCapture.sourceKey, latestCapture.animationId)
		if savedConfig then
			local savedTiming = tonumber(savedConfig.wait)
			if savedTiming then
				updateLearnedAdaptiveOffset(latestCapture.sourceKey, latestCapture.animationId, actionType, ((latestCapture.wait or 0) - savedTiming) * 1000, 0.35)
			end
		end
		applyBuilderConfigData({
			configId = nil,
			sourceKey = latestCapture.sourceKey,
			animationId = latestCapture.animationId,
			repeatAmount = 1,
			repeatDelay = 0,
			wait = latestCapture.wait or 0,
			nickname = latestCapture.nickname or "",
			actionType = actionType,
			delay = false,
			delayRange = 0,
			range = latestCapture.range or 16,
		})
		setDebugText(string.format(
			"%s -> %s %s anim %s at %.2fs%s",
			actionKind,
			candidate.targetType,
			candidate.targetName,
			candidate.animationId,
			candidate.timePosition or 0,
			candidate.matched and " (in table)" or " (not in table)"
		))
	end

	local function isManualActionRequestRemote(instance)
		if instance == nil or typeof(instance) ~= "Instance" or instance.ClassName ~= "RemoteEvent" then
			return false
		end

		if instance == autoParryState.manualActionRequestRemote then
			return true
		end

		if instance.Name ~= "RequestModule" then
			return false
		end

		local parent = instance.Parent
		return parent ~= nil
			and parent.Name == "Remotes"
			and instance:IsDescendantOf(ReplicatedStorage)
	end

	local function withSuppressedManualActionDebug(callback)
		GLOBAL_ENV[HUAJ_HUB_MANUAL_ACTION_SUPPRESS_KEY] = (tonumber(GLOBAL_ENV[HUAJ_HUB_MANUAL_ACTION_SUPPRESS_KEY]) or 0) + 1

		local ok, result = pcall(callback)

		GLOBAL_ENV[HUAJ_HUB_MANUAL_ACTION_SUPPRESS_KEY] = math.max((tonumber(GLOBAL_ENV[HUAJ_HUB_MANUAL_ACTION_SUPPRESS_KEY]) or 1) - 1, 0)

		if not ok then
			return false, result
		end

		return true, result
	end

	local function shouldBlockFallDamageRequest(instance, args)
		return Toggles.AntiFallDamageEnabled
			and Toggles.AntiFallDamageEnabled.Value
			and isManualActionRequestRemote(instance)
			and args[1] == "Misc"
			and args[2] == "FallDamage"
	end

	function autoParryRuntime.installManualActionDebugHook()
		GLOBAL_ENV[HUAJ_HUB_MANUAL_ACTION_CALLBACK_KEY] = reportManualActionDebug

		if GLOBAL_ENV[HUAJ_HUB_MANUAL_ACTION_HOOK_KEY] then
			return true
		end

		if type(hookmetamethod) ~= "function" or type(newcclosure) ~= "function" then
			setManualParryDebugText("remote hook unavailable in this executor.")
			setManualDashDebugText("remote hook unavailable in this executor.")
			return false
		end

		local previousNamecall
		previousNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			local args = {...}
			local method = getnamecallmethod and getnamecallmethod()

			if method == "FireServer" and isManualActionRequestRemote(self) then
				local isFallDamageRequest = args[1] == "Misc" and args[2] == "FallDamage"
				if isFallDamageRequest then
					beginFallDebugWindow("RequestModule FallDamage", 3)
				end

				if shouldLogFallDebug() then
					local payloadSummary = ""
					if type(args[4]) == "table" then
						local encoded = encodeDebugPayload(args[4])
						payloadSummary = encoded ~= "" and (" payload=" .. tostring(encoded)) or ""
					end

					logFallDebug(string.format(
						"RequestModule FireServer: %s | %s%s",
						tostring(args[1]),
						tostring(args[2]),
						payloadSummary
					))
				end
			end

			if method == "FireServer" and shouldBlockFallDamageRequest(self, args) then
				return nil
			end

			if method == "FireServer" and (tonumber(GLOBAL_ENV[HUAJ_HUB_MANUAL_ACTION_SUPPRESS_KEY]) or 0) <= 0 then
				local callback = GLOBAL_ENV[HUAJ_HUB_MANUAL_ACTION_CALLBACK_KEY]
				if type(callback) == "function" and isManualActionRequestRemote(self) then
					if args[1] == "Misc" and args[2] == "Parry" then
						autoParryState.manualParryInputSuppressUntil = os.clock() + 0.2
						local captureRequestedAt = os.clock()
						task.defer(function()
							pcall(callback, "manual parry", captureRequestedAt)
						end)
					end
				end
			end

			return previousNamecall(self, ...)
		end))

		if not GLOBAL_ENV[HUAJ_HUB_REQUEST_MODULE_FIRESERVER_HOOK_KEY] and type(hookfunction) == "function" then
			local requestModule = getRequestModuleRemote()
			if requestModule then
				local originalFireServer
				local ok = pcall(function()
					originalFireServer = hookfunction(requestModule.FireServer, newcclosure(function(self, ...)
						local args = {...}
						if isManualActionRequestRemote(self) then
							local isFallDamageRequest = args[1] == "Misc" and args[2] == "FallDamage"
							if isFallDamageRequest then
								beginFallDebugWindow("Direct RequestModule FallDamage", 3)
							end

							if shouldLogFallDebug() then
								local payloadSummary = ""
								if type(args[4]) == "table" then
									local payloadOk, encoded = pcall(function()
										return HttpService:JSONEncode(args[4])
									end)
									payloadSummary = payloadOk and (" payload=" .. tostring(encoded)) or ""
								end

								logFallDebug(string.format(
									"Direct FireServer: %s | %s%s",
									tostring(args[1]),
									tostring(args[2]),
									payloadSummary
								))
							end
						end

						if shouldBlockFallDamageRequest(self, args) then
							return nil
						end

						return originalFireServer(self, ...)
					end))
				end)

				if ok and originalFireServer then
					GLOBAL_ENV[HUAJ_HUB_REQUEST_MODULE_FIRESERVER_HOOK_KEY] = true
				end
			end
		end

		GLOBAL_ENV[HUAJ_HUB_MANUAL_ACTION_HOOK_KEY] = true
		return true
	end

	function autoParryRuntime.fireAutoParryDashRemote(remote)
		return withSuppressedManualActionDebug(function()
			remote:FireServer("Misc", "Dash", "GroundForward", {
				DashCooldown = 2,
			})
		end)
	end

	function autoParryRuntime.fireAutoParryParryRemote(remote)
		return withSuppressedManualActionDebug(function()
			remote:FireServer("Misc", "Parry")
		end)
	end

	local trackedAnimatorRegistry = TrackedAnimatorRegistry.new({
		getAnimators = getTargetAnimators,
		shouldTrackModel = function(model)
			return not isLocalAutoParryCharacter(model)
		end,
		onAnimatorTrack = function(model, _, track)
			if not isAutoParryEnabled() then
				return
			end

			queueAutoParryTrack(model, track)
		end,
		onAnimatorReady = function(model, animator)
			scanAnimatorTracksForAutoParry(model, animator)
		end,
	})

	autoParryState.trackedTargets = trackedAnimatorRegistry.targets

	function autoParryRuntime.disconnectTrackedAutoParryTarget(model)
		trackedAnimatorRegistry:disconnectTarget(model)
	end

	function autoParryRuntime.ensureTrackedAnimator(model, animator)
		trackedAnimatorRegistry:ensureAnimator(model, animator)
	end

	function autoParryRuntime.trackAutoParryTarget(model)
		trackedAnimatorRegistry:trackTarget(model)
	end

	autoParryRuntime.refreshTrackedAutoParryTargets = function()
		local liveFolder = workspace:FindFirstChild("Live")
		if not liveFolder then
			return nil
		end

		return trackedAnimatorRegistry:refresh(liveFolder)
	end

	function autoParryRuntime.setAutoParryInputBlocking(active)
		if autoParryState.inputBlockActive == active then
			return
		end

		autoParryState.inputBlockActive = active

		if active then
			ContextActionService:BindActionAtPriority(
				AUTO_PARRY_BLOCK_ACTION,
				function()
					return Enum.ContextActionResult.Sink
				end,
				false,
				Enum.ContextActionPriority.High.Value + 1000,
				unpack(AUTO_PARRY_BLOCK_INPUTS)
			)
		else
			ContextActionService:UnbindAction(AUTO_PARRY_BLOCK_ACTION)
		end
	end

	function autoParryRuntime.pressDashKey()
		autoParryState.manualDashInputSuppressUntil = os.clock() + 0.2
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
		end)
	end

	function autoParryRuntime.pressJumpKey()
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
		end)

		local character = LocalPlayer and LocalPlayer.Character
		local humanoid = getCharacterHumanoid(character)
		if humanoid then
			pcall(function()
				humanoid.Jump = true
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end)
		end
	end

	Toggles.AutoParryVisualizer:OnChanged(function()
		updateAutoParryVisualizer()
	end)

	Toggles.AutoParryBlockInputs:OnChanged(function()
		if not Toggles.AutoParryBlockInputs.Value then
			autoParryState.inputBlockUntil = 0
			autoParryRuntime.setAutoParryInputBlocking(false)
		end
	end)

	Options.AutoParryDistance:OnChanged(function()
		updateAutoParryVisualizer()
	end)

	function autoParryRuntime.refreshAutoParryWhitelist()
		local values = getOtherPlayerNames()
		local currentSelection = {}

		if Options.AutoParryWhitelist and type(Options.AutoParryWhitelist.Value) == "table" then
			for playerName, selected in pairs(Options.AutoParryWhitelist.Value) do
				if selected then
					currentSelection[playerName] = true
				end
			end
		end

		Options.AutoParryWhitelist:SetValues(values)
		Options.AutoParryWhitelist:SetValue(currentSelection)
	end

	maid:GiveTask(Players.PlayerAdded:Connect(function()
		autoParryRuntime.refreshAutoParryWhitelist()
	end))

	maid:GiveTask(Players.PlayerRemoving:Connect(function()
		autoParryRuntime.refreshAutoParryWhitelist()
	end))

	Options.AutoParryMakerDetectedAnimation:OnChanged(function(selectedLabel)
		local detectedEntryRef = detectedAnimationLabelMap[selectedLabel]
		if not detectedEntryRef then
			return
		end

		local detectedEntry = detectedAnimationEntries[detectedEntryRef.sourceKey][detectedEntryRef.animationId]
		if not detectedEntry then
			return
		end

		applyDetectedEntryToBuilder(detectedEntry)
	end)

	Options.AutoParryMakerSavedConfig:OnChanged(function(selectedLabel)
		local configRef = builderConfigLabelMap[selectedLabel]
		if not configRef then
			return
		end

		local configData = findMakerConfigById(configRef.sourceKey, configRef.configId)
		if configData then
			applyBuilderConfigData(configData)
		end
	end)

	autoParryRuntime.refreshAutoParryWhitelist()
	ensureAutoParryMakerConfigFile()
	loadAutoParryMakerConfigsFromFile()
	syncAutoParryBuilderConfigsToRuntime()
	refreshSavedConfigDropdown("(none)")
	refreshDetectedAnimationDropdown("(none)")
	autoParryRuntime.installManualActionDebugHook()
	maid:GiveTask(UserInputService.InputBegan:Connect(function(inputObject)
		if inputObject.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		if UserInputService:GetFocusedTextBox() then
			return
		end

		if inputObject.KeyCode == Enum.KeyCode.F then
			if os.clock() < autoParryState.manualParryInputSuppressUntil then
				return
			end

			local captureRequestedAt = os.clock()
			task.defer(function()
				pcall(reportManualActionDebug, "manual parry", captureRequestedAt)
			end)
			return
		end

		if inputObject.KeyCode == Enum.KeyCode.Space then
			local captureRequestedAt = os.clock()
			task.delay(0.05, function()
				pcall(reportManualActionDebug, "manual jump", captureRequestedAt)
			end)
			return
		end

		if inputObject.KeyCode ~= Enum.KeyCode.Q then
			return
		end

		if os.clock() < autoParryState.manualDashInputSuppressUntil then
			return
		end

		local captureRequestedAt = os.clock()
		task.defer(function()
			pcall(reportManualActionDebug, "manual dash", captureRequestedAt)
		end)
	end))

	local liveFolder = autoParryRuntime.refreshTrackedAutoParryTargets()
	if liveFolder then
		maid:GiveTask(liveFolder.ChildAdded:Connect(function(child)
			autoParryRuntime.trackAutoParryTarget(child)
		end))

		maid:GiveTask(liveFolder.ChildRemoved:Connect(function(child)
			autoParryRuntime.disconnectTrackedAutoParryTarget(child)
		end))
	end

	maid:GiveTask(workspace.ChildAdded:Connect(function(child)
		if child.Name == "Live" then
			autoParryRuntime.refreshTrackedAutoParryTargets()
			maid:GiveTask(child.ChildAdded:Connect(function(grandChild)
				autoParryRuntime.trackAutoParryTarget(grandChild)
			end))
			maid:GiveTask(child.ChildRemoved:Connect(function(grandChild)
				autoParryRuntime.disconnectTrackedAutoParryTarget(grandChild)
			end))
		end
	end))

	maid:GiveTask(RunService.Heartbeat:Connect(autoParryRuntime.processAutoParryHeartbeat))

	registerLibraryUnloadCallback(function()
		autoParryRuntime.setAutoParryInputBlocking(false)
		autoParryState.pendingParryFailCheck = nil
		GLOBAL_ENV[HUAJ_HUB_MASHLE_INIT_KEY] = nil
		GLOBAL_ENV[HUAJ_HUB_MASHLE_LIBRARY_KEY] = nil
		maid:DoCleaning()
		table.clear(autoParryState.queuedMoveActions)
		table.clear(autoParryState.queuedTracks)
		trackedAnimatorRegistry:destroy()
		if autoParryState.visualizer.part then
			autoParryState.visualizer.part:Destroy()
			autoParryState.visualizer.part = nil
		end
	end)
end
setupAutoParryTab()

local function setupMiscTab()
	local miscTab = Tabs["Misc"]

	local miscGroup = miscTab:AddLeftGroupbox("Misc")
	miscGroup:AddLabel("Core misc features go here.")
	miscGroup:AddLabel("Scaffold ready.")

	local alertsGroup = miscTab:AddLeftGroupbox("Alerts")
	alertsGroup:AddLabel("Alerts section placeholder.")
	alertsGroup:AddLabel("Features will be added later.")

	local visualsGroup = miscTab:AddLeftGroupbox("Visuals")
	visualsGroup:AddLabel("Visuals section placeholder.")
	visualsGroup:AddLabel("Features will be added later.")

	local lootGroup = miscTab:AddRightGroupbox("Auto Loot")
	lootGroup:AddLabel("Auto Loot section placeholder.")
	lootGroup:AddLabel("Features will be added later.")

	local inventoryGroup = miscTab:AddRightGroupbox("Inventory")
	inventoryGroup:AddLabel("Inventory section placeholder.")
	inventoryGroup:AddLabel("Features will be added later.")

	local farmsGroup = miscTab:AddRightGroupbox("Farms")
	farmsGroup:AddLabel("Farms section placeholder.")
	farmsGroup:AddLabel("Features will be added later.")
end
setupMiscTab()

local function setupSettingsTab()
	local settingsTab = Tabs["Settings"]
	local menuGroup = settingsTab:AddRightGroupbox("Menu")

	menuGroup:AddButton("Unload", function()
		Library:Unload()
	end)

	menuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
		Default = "RightShift",
		NoUI = true,
		Text = "Menu keybind",
	})

	Library.ToggleKeybind = Options.MenuKeybind
end
setupSettingsTab()

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})

	ThemeManager:SetFolder("HuajHub")
	SaveManager:SetFolder("HuajHub/" .. GAME_KEY)

SaveManager:BuildConfigSection(Tabs["Settings"])
ThemeManager:ApplyToTab(Tabs["Settings"])
SaveManager:LoadAutoloadConfig()

task.defer(function()
	local holder = Window and Window.Holder
	if holder and holder.Visible == false and type(Library.Toggle) == "function" then
		warn("[HuajHub] Forcing window visible")
		pcall(function()
			Library:Toggle()
		end)
	end
end)

end

return MashleAcademy
