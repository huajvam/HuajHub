local MashleAcademy = {}
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

local Players, ContextActionService, HttpService, Lighting, MarketplaceService, ReplicatedStorage, RunService, Stats, TeleportService, UserInputService, VirtualInputManager = Services:Get(
	"Players",
	"ContextActionService",
	"HttpService",
	"Lighting",
	"MarketplaceService",
	"ReplicatedStorage",
	"RunService",
	"Stats",
	"TeleportService",
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
local HUAJ_HUB_FALL_DAMAGE_BLOCK_CALLBACK_KEY = "__huaj_hub_fall_damage_block_callback_v1"
local HUAJ_HUB_FALL_DAMAGE_BLOCK_HOOK_KEY = "__huaj_hub_fall_damage_block_hook_v1"
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

local Library = sharedRequire("ui/Linoria/Library.lua")
local ThemeManager = sharedRequire("ui/Linoria/addons/ThemeManager.lua")
local SaveManager = sharedRequire("ui/Linoria/addons/SaveManager.lua")
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
		name = "Wildwood Waypoint",
		cframe = CFrame.new(-2737.0459, -170.828079, 2341.62231, 0.964204669, -7.07022139e-08, -0.265159041, 8.38839469e-08, 1, 3.8388567e-08, 0.265159041, -5.92570224e-08, 0.964204669),
	},
	{
		name = "FoxRoot Waypoint",
		cframe = CFrame.new(1093.70618, 148.240448, -681.392212, 0.99993062, 2.08667288e-08, -0.0117770443, -2.14097966e-08, 1, -4.5986333e-08, 0.0117770443, 4.62352894e-08, 0.99993062),
	},
	{
		name = "Amberdune Waypoint",
		cframe = CFrame.new(3071.53589, -324.125854, 899.911987, 1, -3.00653085e-08, 2.76935033e-14, 3.00653085e-08, 1, -1.02304945e-07, -2.46176726e-14, 1.02304945e-07, 1),
	},
	{
		name = "Iceveil Waypoint",
		cframe = CFrame.new(4026.97412, 452.833557, -799.645996, 1, -1.13955378e-08, 4.58303736e-15, 1.13955378e-08, 1, -3.87762853e-08, -4.1411606e-15, 3.87762853e-08, 1),
	},
	{
		name = "Hell Waypoint",
		cframe = CFrame.new(-3214.24609, 599.277405, -4055.79907, 1, -2.68896461e-08, 1.24301695e-14, 2.68896461e-08, 1, -9.14988902e-08, -9.96979632e-15, 9.14988902e-08, 1),
	},
	{
		name = "Monarch",
		cframe = CFrame.new(733.030396, 749.907593, -10329.5664, 0.979425311, 7.31646352e-08, 0.201807097, -8.02046856e-08, 1, 2.67080047e-08, -0.201807097, -4.23443716e-08, 0.979425311),
	},
	{
		name = "Phoenix's Warmth",
		cframe = CFrame.new(4350.98291, 446.019592, -1581.35376, 0.987107038, -3.27994059e-08, -0.160061657, 2.61109161e-08, 1, -4.38901857e-08, 0.160061657, 3.91449539e-08, 0.987107038),
	},
	{
		name = "Phoenix's Warmth",
		cframe = CFrame.new(4350.98291, 446.019592, -1581.35376, 0.987107038, -3.27994059e-08, -0.160061657, 2.61109161e-08, 1, -4.38901857e-08, 0.160061657, 3.91449539e-08, 0.987107038),
	},
	{
		name = "Golem Boss",
		cframe = CFrame.new(5098.49072, -257.10025, 2690.97607, -0.816534698, -2.81613701e-08, -0.577296376, 2.08560795e-08, 1, -7.82805571e-08, 0.577296376, -7.59589298e-08, -0.816534698),
	},
	{
		name = "Rocky Wasteland",
		cframe = CFrame.new(4118.82031, -34.5353432, 2671.44702, 0.0668392107, -4.89053136e-08, -0.997763753, -1.01583858e-07, 1, -5.58199247e-08, 0.997763753, 1.05087651e-07, 0.0668392107),
	},
	{
		name = "Lightning trainer",
		cframe = CFrame.new(2114.12622, 233.599701, -4.08441305, 0.535777152, 5.18457419e-08, -0.844359457, -8.86734952e-08, 1, 5.13585841e-09, 0.844359457, 7.21206277e-08, 0.535777152),
	},
	{
		name = "Darkness trainer",
		cframe = CFrame.new(2343.64746, 336.893616, 1097.67017, 0.990223587, -3.98804509e-08, 0.139489248, 2.74498451e-08, 1, 9.10390341e-08, -0.139489248, -8.63200427e-08, 0.990223587),
	},
	{
		name = "Wind trainer",
		cframe = CFrame.new(-1543.85535, 172.433594, 2467.42822, 0.936020434, -5.70699266e-09, 0.351945639, 5.29027666e-09, 1, 2.14574536e-09, -0.351945639, -1.4657163e-10, 0.936020434),
	},
	{
		name = "Rock trainer",
		cframe = CFrame.new(-2195.04224, -526.410889, 769.722839, -0.37383762, 3.8120838e-08, -0.927494168, -6.31155643e-08, 1, 6.65403732e-08, 0.927494168, 8.34146121e-08, -0.37383762),
	},
	{
		name = "Water trainer",
		cframe = CFrame.new(427.878235, -583.534241, 300.343933, -0.362585038, 6.9538475e-10, 0.931950688, 9.47962633e-08, 1, 3.61353045e-08, -0.931950688, 1.01447561e-07, -0.362585038),
	},
	{
		name = "Charm trainer",
		cframe = CFrame.new(680.588074, 114.594231, 1798.10364, -0.348678589, 8.59627178e-08, 0.937242329, -4.62264182e-09, 1, -9.34385156e-08, -0.937242329, -3.69125459e-08, -0.348678589),
	},
	{
		name = "Fire trainer",
		cframe = CFrame.new(846.60968, 273.999969, 1120.53345, 0.402919024, -4.20336121e-09, -0.915235639, -9.05761937e-08, 1, -4.4467491e-08, 0.915235639, 1.00815356e-07, 0.402919024),
	},
	{
		name = "Gravity trainer",
		cframe = CFrame.new(1337.01135, -242.068863, -1507.9856, -0.608169496, 2.94269803e-10, 0.793807209, -4.00048084e-09, 1, -3.43564577e-09, -0.793807209, -5.26506572e-09, -0.608169496),
	},
	{
		name = "Space trainer",
		cframe = CFrame.new(-899.295288, -257.800507, -1764.98584, 0.151669085, -6.96571831e-08, -0.988431334, 7.46957056e-08, 1, -5.90108336e-08, 0.988431334, -6.48814549e-08, 0.151669085),
	},
	{
		name = "Sound trainer",
		cframe = CFrame.new(3387.08398, 293.94751, 2100.4978, 0.0187702365, -4.81636775e-09, 0.999823809, -5.48707995e-08, 1, 5.8473355e-09, -0.999823809, -5.49708865e-08, 0.0187702365),
	},
	{
		name = "Partisan trainer",
		cframe = CFrame.new(3803.45459, 128.813904, 2572.55908, 0.383655548, 5.01024733e-09, -0.923476279, -8.89659049e-08, 1, -3.15352082e-08, 0.923476279, 9.42565563e-08, 0.383655548),
	},
	{
		name = "Ice trainer",
		cframe = CFrame.new(4074.54199, 464.226288, -631.305969, -0.999495029, -2.63436402e-08, -0.0317748189, -2.37301361e-08, 1, -8.26279134e-08, 0.0317748189, -8.18321695e-08, -0.999495029),
	},
	{
		name = "Muscle trainer",
		cframe = CFrame.new(3507.59814, 317.500275, -657.695374, -0.957502961, -6.03253669e-10, 0.288423389, 4.16879109e-09, 1, 1.5931036e-08, -0.288423389, 1.64563918e-08, -0.957502961),
	},
	{
		name = "Sand trainer",
		cframe = CFrame.new(3524.19458, 107.499878, 253.549484, -0.767369151, -6.61880932e-08, 0.641205549, -4.63483971e-08, 1, 4.77565436e-08, -0.641205549, 6.92805013e-09, -0.767369151),
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

local function installFallDamageBlockHook()
	if GLOBAL_ENV[HUAJ_HUB_FALL_DAMAGE_BLOCK_HOOK_KEY] then
		return true
	end

	if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
		return false
	end

	local hookWrapper = newcclosure or function(callback)
		return callback
	end

	local originalNamecall
	originalNamecall = hookmetamethod(game, "__namecall", hookWrapper(function(self, ...)
		local args = table.pack(...)
		local callback = GLOBAL_ENV[HUAJ_HUB_FALL_DAMAGE_BLOCK_CALLBACK_KEY]
		local isCallerCheckAvailable = type(checkcaller) == "function"

		if (not isCallerCheckAvailable or not checkcaller())
			and getnamecallmethod() == "FireServer"
		then
			if type(callback) == "function" then
				local ok, shouldBlock = pcall(callback, self, args)
				if ok and shouldBlock == true then
					return nil
				end
			end
		end

		return originalNamecall(self, ...)
	end))

	GLOBAL_ENV[HUAJ_HUB_FALL_DAMAGE_BLOCK_HOOK_KEY] = true
	return true
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
	GLOBAL_ENV[HUAJ_HUB_FALL_DAMAGE_BLOCK_CALLBACK_KEY] = nil

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
	local playersList = Players and Players.GetPlayers and Players:GetPlayers()
	if type(playersList) ~= "table" then
		return names
	end

	for _, player in ipairs(playersList) do
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

local function getToggleValue(name, default)
	if Toggles and Toggles[name] then
		return Toggles[name].Value == true
	end

	return default == true
end

local function getOptionValue(name, default)
	if Options and Options[name] then
		local value = Options[name].Value
		if value ~= nil then
			return value
		end
	end

	return default
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

Library:Notify("Huaj Hub Loaded", 3, Color3.fromRGB(80, 255, 120))

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
	local godModeHeartbeatConnection = nil
	local godModeCharacterConnection = nil
	local godModeLoopToken = 0
	local noStunHeartbeatConnection = nil
	local noStunCharacterConnection = nil
	local noStunStateAddedConnection = nil
	local noStunHumanoidConnection = nil
	local noStunNeutralizedStates = {}
	local knockedOwnershipCharacterConnection = nil
	local knockedOwnershipStateAddedConnection = nil
	local knockedOwnershipStateRemovedConnection = nil
	local speedHackVelocity = nil
	local flyVelocity = nil
	local antiFallState = nil
	local GOD_MODE_FALL_DAMAGE_PAYLOAD = {
		FallDamageValueTotal = -math.huge,
		FallDamage = -math.huge,
	}
	local GOD_MODE_REMOTE_INTERVAL = 0.05
	local GOD_MODE_REMOTE_BURST = 3
	local GOD_MODE_INFINITE_HEALTH_THRESHOLD = 1e12
	local godModeActive = false
	local godModeSavedHealth = nil
	local godModeSavedMaxHealth = nil
	local antiFallProtectedUntil = 0
	local teleportAntiFallUntil = 0
	local knockedOwnershipLoopToken = 0
	local noStunWalkSpeed = 16
	local noStunJumpPower = 50
	local noStunJumpHeight = 7.2
	local teleportLocations = {}
	local teleportLabels = {"(none)"}
	local triggerAntiFallBypass
	local ensureAntiFallState
	local applyTeleportAntiFallProtection
	local NO_STUN_STATE_NAMES = {
		NoMove = true,
		NoMoveFake = true,
		NoRoate = true,
		NoRotate = true,
		NoJump = true,
		NoAct = true,
		Action = true,
		Stunned = true,
		NotParryableStun = true,
	}

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
		local character = LocalPlayer and LocalPlayer.Character
		local root = getCharacterRoot(character)
		if not character or not root then
			Library:Notify("Character root is unavailable.", 2)
			return
		end

		local targetCFrame
		local targetLabel

		local selection = Options.TeleportDestination.Value
		local destination = selection and teleportLocations[selection]
		if not destination then
			Library:Notify("No teleport destination selected.", 2)
			return
		end

		targetCFrame = destination.cframe
		targetLabel = selection

		if typeof(targetCFrame) ~= "CFrame" then
			Library:Notify("Selected destination is unavailable.", 2)
			return
		end

		applyTeleportAntiFallProtection(character, 2)
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = targetCFrame
		Library:Notify("Teleported to " .. tostring(targetLabel) .. ".", 2)
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

	local function isNoStunActive()
		return Toggles and Toggles.NoStunEnabled and Toggles.NoStunEnabled.Value == true
	end

	local function clearNoStunValue(valueObject)
		if not valueObject or not valueObject.Parent then
			return
		end

		if not valueObject:IsA("BoolValue") then
			return
		end

		if not NO_STUN_STATE_NAMES[valueObject.Name] then
			return
		end

		pcall(function()
			if not noStunNeutralizedStates[valueObject] then
				noStunNeutralizedStates[valueObject] = {
					name = valueObject.Name,
					value = valueObject.Value,
				}
			end

			valueObject.Value = false
			valueObject.Name = "__HuajHubBlocked_" .. tostring(noStunNeutralizedStates[valueObject].name)
		end)
	end

	local function restoreNoStunValues()
		for valueObject, state in pairs(noStunNeutralizedStates) do
			if valueObject and valueObject.Parent and type(state) == "table" then
				pcall(function()
					valueObject.Name = state.name or valueObject.Name
					if state.value ~= nil then
						valueObject.Value = state.value
					end
				end)
			end
		end

		table.clear(noStunNeutralizedStates)
	end

	local function stopNoStun()
		if noStunHeartbeatConnection then
			noStunHeartbeatConnection:Disconnect()
			noStunHeartbeatConnection = nil
		end
		if noStunCharacterConnection then
			noStunCharacterConnection:Disconnect()
			noStunCharacterConnection = nil
		end
		if noStunStateAddedConnection then
			noStunStateAddedConnection:Disconnect()
			noStunStateAddedConnection = nil
		end
		if noStunHumanoidConnection then
			noStunHumanoidConnection:Disconnect()
			noStunHumanoidConnection = nil
		end

		restoreNoStunValues()
	end

	local function isAntiFallActive()
		return Toggles and Toggles.AntiFallDamageEnabled and Toggles.AntiFallDamageEnabled.Value == true
	end

	local function isTeleportAntiFallActive()
		return os.clock() <= teleportAntiFallUntil
	end

	local function shouldUseAntiFallProtection()
		return isAntiFallActive() or isTeleportAntiFallActive()
	end

	local function shouldBlockTeleportFallDamageRequest(instance, args)
		if not shouldUseAntiFallProtection() then
			return false
		end

		if instance == nil or typeof(instance) ~= "Instance" or not instance:IsA("RemoteEvent") then
			return false
		end

		if instance.Name ~= "RequestModule" then
			return false
		end

		local parent = instance.Parent
		if parent == nil or parent.Name ~= "Remotes" or not instance:IsDescendantOf(ReplicatedStorage) then
			return false
		end

		return args[1] == "Misc" and args[2] == "FallDamage"
	end

	local function shouldMaintainLocalAntiFallState()
		return isAntiFallActive() and os.clock() <= antiFallProtectedUntil
	end

	local function shouldMaintainAntiFallState()
		return shouldUseAntiFallProtection() and os.clock() <= antiFallProtectedUntil
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

	local function getNilInstance(name, className)
		if type(getnilinstances) ~= "function" then
			return nil
		end

		for _, instance in next, getnilinstances() do
			if instance
				and instance.Name == name
				and instance.ClassName == className then
				return instance
			end
		end

		return nil
	end

	local function clearCharacterNoStunStates(character)
		local characterState = getCharacterStateFolder(character)
		if not characterState then
			return nil
		end

		for _, child in ipairs(characterState:GetChildren()) do
			clearNoStunValue(child)
		end

		return characterState
	end

	local function captureNoStunDefaults(humanoid)
		if not humanoid then
			return
		end

		if humanoid.WalkSpeed and humanoid.WalkSpeed > 0 then
			noStunWalkSpeed = humanoid.WalkSpeed
		end

		if humanoid.UseJumpPower then
			if humanoid.JumpPower and humanoid.JumpPower > 0 then
				noStunJumpPower = humanoid.JumpPower
			end
		elseif humanoid.JumpHeight and humanoid.JumpHeight > 0 then
			noStunJumpHeight = humanoid.JumpHeight
		end
	end

	local function enforceNoStunHumanoid(humanoid)
		if not humanoid then
			return
		end

		captureNoStunDefaults(humanoid)

		pcall(function()
			humanoid.AutoRotate = true
		end)

		pcall(function()
			if humanoid.WalkSpeed <= 0 then
				humanoid.WalkSpeed = noStunWalkSpeed
			end
		end)

		pcall(function()
			if humanoid.UseJumpPower then
				if humanoid.JumpPower <= 0 then
					humanoid.JumpPower = noStunJumpPower
				end
			elseif humanoid.JumpHeight <= 0 then
				humanoid.JumpHeight = noStunJumpHeight
			end
		end)
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
		if not shouldMaintainLocalAntiFallState() or not character then
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
		teleportAntiFallUntil = 0
		removeAntiFallState()
	end

	local function removeGodModeState()
		local humanoid = getCharacterHumanoid(LocalPlayer and LocalPlayer.Character)
		if not humanoid then
			godModeSavedHealth = nil
			godModeSavedMaxHealth = nil
			return
		end

		local restoredMaxHealth = godModeSavedMaxHealth
		local restoredHealth = godModeSavedHealth

		godModeSavedHealth = nil
		godModeSavedMaxHealth = nil

		if restoredMaxHealth and restoredMaxHealth > 0 then
			pcall(function()
				humanoid.MaxHealth = restoredMaxHealth
			end)
		end

		if restoredHealth and restoredHealth > 0 then
			pcall(function()
				local maxHealth = humanoid.MaxHealth
				humanoid.Health = math.clamp(restoredHealth, 0, maxHealth > 0 and maxHealth or restoredHealth)
			end)
		end
	end

	local function isHumanoidHealthInfinite(humanoid)
		if not humanoid then
			return false
		end

		local health = humanoid.Health
		local maxHealth = humanoid.MaxHealth
		if health == math.huge or maxHealth == math.huge then
			return true
		end

		if health >= GOD_MODE_INFINITE_HEALTH_THRESHOLD or maxHealth >= GOD_MODE_INFINITE_HEALTH_THRESHOLD then
			return true
		end

		return false
	end

	local function updateGodModeSavedHealth(humanoid)
		if not humanoid then
			return
		end

		if godModeSavedHealth == nil and godModeSavedMaxHealth == nil and not isHumanoidHealthInfinite(humanoid) then
			godModeSavedHealth = humanoid.Health
			godModeSavedMaxHealth = humanoid.MaxHealth
		end
	end

	local function fireGodModeFallDamageRemote()
		local requestModule = getRequestModuleRemote()
		if not requestModule then
			return
		end

		pcall(function()
			requestModule:FireServer("Misc", "FallDamage", nil, {
				FallDamageValueTotal = GOD_MODE_FALL_DAMAGE_PAYLOAD.FallDamageValueTotal,
				FallDamage = GOD_MODE_FALL_DAMAGE_PAYLOAD.FallDamage,
			})
		end)
	end

	local function ensureGodModeState(character)
		if not godModeActive then
			return
		end

		if not character then
			return
		end

		local humanoid = getCharacterHumanoid(character)
		if humanoid then
			updateGodModeSavedHealth(humanoid)
			if isHumanoidHealthInfinite(humanoid) then
				return
			end
		end

		fireGodModeFallDamageRemote()
	end

	local function stopGodMode()
		godModeActive = false
		godModeLoopToken += 1
		if godModeHeartbeatConnection then
			godModeHeartbeatConnection:Disconnect()
			godModeHeartbeatConnection = nil
		end
		if godModeCharacterConnection then
			godModeCharacterConnection:Disconnect()
			godModeCharacterConnection = nil
		end

		removeGodModeState()
	end

	local function startGodMode()
		stopGodMode()
		godModeActive = true
		godModeLoopToken += 1
		godModeSavedHealth = nil
		godModeSavedMaxHealth = nil
		local loopToken = godModeLoopToken

		local function hookCharacter(character)
			local humanoid = getCharacterHumanoid(character)
			if humanoid then
				godModeSavedHealth = humanoid.Health
				godModeSavedMaxHealth = humanoid.MaxHealth
			end
			ensureGodModeState(character)
		end

		local currentCharacter = LocalPlayer and LocalPlayer.Character
		if currentCharacter then
			hookCharacter(currentCharacter)
		end

		godModeCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
			task.defer(function()
				if godModeActive then
					hookCharacter(character)
				end
			end)
		end)

		godModeHeartbeatConnection = RunService.Heartbeat:Connect(function()
			local character = LocalPlayer and LocalPlayer.Character
			if character then
				ensureGodModeState(character)
			end
		end)

		task.spawn(function()
			while loopToken == godModeLoopToken do
				if not godModeActive then
					break
				end

				local humanoid = getCharacterHumanoid(LocalPlayer and LocalPlayer.Character)
				if humanoid then
					updateGodModeSavedHealth(humanoid)
					if isHumanoidHealthInfinite(humanoid) then
						godModeActive = false
						break
					end
				end

				for _ = 1, GOD_MODE_REMOTE_BURST do
					fireGodModeFallDamageRemote()
				end

				task.wait(GOD_MODE_REMOTE_INTERVAL)
			end
		end)
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

	local function isBringableMob(model)
		if not model or not model:IsA("Model") then
			return false
		end

		if LocalPlayer and LocalPlayer.Character == model then
			return false
		end

		if Players:GetPlayerFromCharacter(model) then
			return false
		end

		if not getCharacterHumanoid(model) or not getCharacterRoot(model) then
			return false
		end

		return true
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

	triggerAntiFallBypass = function(character, duration, preserveRemoteBypass)
		local now = os.clock()
		local appliedDuration = math.max(duration or 1.5, 0.25)
		local expiresAt = now + appliedDuration
		antiFallProtectedUntil = math.max(antiFallProtectedUntil, expiresAt)
		if preserveRemoteBypass then
			teleportAntiFallUntil = math.max(teleportAntiFallUntil, expiresAt)
		end
		if isAntiFallActive() then
			ensureAntiFallState(character)
		end
		task.delay(appliedDuration + 0.1, function()
			if not shouldMaintainLocalAntiFallState() then
				removeAntiFallState()
			end
		end)
	end

	applyTeleportAntiFallProtection = function(character, duration)
		triggerAntiFallBypass(character, duration, true)
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

			if shouldMaintainLocalAntiFallState() then
				local character = LocalPlayer and LocalPlayer.Character
				ensureAntiFallState(character)
			elseif antiFallState then
				removeAntiFallState()
			end
		end)
	end

	local function startNoStun()
		stopNoStun()

		local function hookCharacter(character)
			if noStunStateAddedConnection then
				noStunStateAddedConnection:Disconnect()
				noStunStateAddedConnection = nil
			end
			if noStunHumanoidConnection then
				noStunHumanoidConnection:Disconnect()
				noStunHumanoidConnection = nil
			end

			local characterState = clearCharacterNoStunStates(character)
			local humanoid = getCharacterHumanoid(character)
			if humanoid then
				captureNoStunDefaults(humanoid)
				enforceNoStunHumanoid(humanoid)
				noStunHumanoidConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
					if isNoStunActive() then
						enforceNoStunHumanoid(humanoid)
					end
				end)
			end

			if not characterState then
				return
			end

			noStunStateAddedConnection = characterState.ChildAdded:Connect(function(child)
				if not isNoStunActive() then
					return
				end

				clearNoStunValue(child)
			end)
		end

		local currentCharacter = LocalPlayer and LocalPlayer.Character
		if currentCharacter then
			hookCharacter(currentCharacter)
		end

		noStunCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
			task.defer(function()
				if isNoStunActive() then
					hookCharacter(character)
				end
			end)
		end)

		noStunHeartbeatConnection = RunService.Heartbeat:Connect(function()
			if not isNoStunActive() then
				return
			end

			local character = LocalPlayer and LocalPlayer.Character
			clearCharacterNoStunStates(character)
			enforceNoStunHumanoid(getCharacterHumanoid(character))
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

	combatGroup:AddToggle("NoStunEnabled", {
		Text = "No Stun",
		Default = false,
	})

	combatGroup:AddToggle("KnockedOwnershipEnabled", {
		Text = "Knocked Ownership",
		Default = false,
	})

	combatGroup:AddButton("God Mode", function()
		startGodMode()
	end)

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

	installFallDamageBlockHook()
	GLOBAL_ENV[HUAJ_HUB_FALL_DAMAGE_BLOCK_CALLBACK_KEY] = shouldBlockTeleportFallDamageRequest
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

	Toggles.NoStunEnabled:OnChanged(function()
		if Toggles.NoStunEnabled.Value then
			startNoStun()
		else
			stopNoStun()
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
		stopGodMode()
		stopNoStun()
		stopKnockedOwnership()
		GLOBAL_ENV[HUAJ_HUB_FALL_DAMAGE_BLOCK_CALLBACK_KEY] = nil
	end)

	stopSpeedHack()
	stopFly()
	stopNoclip()
	stopAntiFall()
	stopGodMode()
	stopNoStun()
	stopKnockedOwnership()
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

	local function ensureEntryStaminaBar(entry)
		if not entry or not drawingAvailable then
			return
		end

		if not entry.staminaBarOutline then
			entry.staminaBarOutline = EntityESP.createDrawing(globalEspDrawings, "Square", {
				Filled = false,
				Thickness = 1,
				Transparency = 1,
				Color = Color3.fromRGB(20, 20, 20),
				Visible = false,
			}, function()
				return espShuttingDown
			end)
			table.insert(entry.objects, entry.staminaBarOutline)
		end

		if not entry.staminaBarFill then
			entry.staminaBarFill = EntityESP.createDrawing(globalEspDrawings, "Square", {
				Filled = true,
				Thickness = 1,
				Transparency = 1,
				Color = Color3.fromRGB(240, 200, 60),
				Visible = false,
			}, function()
				return espShuttingDown
			end)
			table.insert(entry.objects, entry.staminaBarFill)
		end
	end

	local function setEntryStaminaBar(entry, position, size, fillPosition, fillSize, fillColor, visible)
		if not entry then
			return
		end

		ensureEntryStaminaBar(entry)

		if entry.staminaBarOutline then
			entry.staminaBarOutline.Position = position
			entry.staminaBarOutline.Size = size
			entry.staminaBarOutline.Visible = visible == true
		end

		if entry.staminaBarFill then
			entry.staminaBarFill.Position = fillPosition
			entry.staminaBarFill.Size = fillSize
			entry.staminaBarFill.Color = fillColor or entry.staminaBarFill.Color
			entry.staminaBarFill.Visible = visible == true
		end
	end

	local function getPlayerAcademyName(model)
		local ownerPlayer = Players:GetPlayerFromCharacter(model)
		if not ownerPlayer then
			return nil
		end

		local dataFolder = ownerPlayer:FindFirstChild("Data")
		local academyValue = dataFolder and dataFolder:FindFirstChild("Academy")
		if academyValue and academyValue:IsA("StringValue") then
			local academyName = tostring(academyValue.Value or "")
			if academyName ~= "" then
				return academyName
			end
		end

		return nil
	end

	local function isAcademyEspEnabled(academyName)
		local normalizedName = string.lower(tostring(academyName or ""))
		if normalizedName == "walkis" then
			return getToggleValue("EspShowWalkisAcademy", true)
		end
		if normalizedName == "saint ars" then
			return getToggleValue("EspShowSaintArsAcademy", true)
		end
		if normalizedName == "easton" then
			return getToggleValue("EspShowEastonAcademy", true)
		end

		return false
	end

	local function getPlayerEspAccentColor(model)
		local normalizedName = string.lower(tostring(getPlayerAcademyName(model) or ""))
		if normalizedName == "walkis" then
			return Color3.fromRGB(255, 70, 70)
		end
		if normalizedName == "saint ars" then
			return Color3.fromRGB(80, 255, 120)
		end
		if normalizedName == "easton" then
			return Color3.fromRGB(40, 170, 255)
		end

		return Color3.fromRGB(190, 190, 190)
	end

	local function getPlayerMagicMarksValue(model)
		local ownerPlayer = Players:GetPlayerFromCharacter(model)
		if not ownerPlayer then
			return nil
		end

		local dataFolder = ownerPlayer:FindFirstChild("Data")
		local magicMarksValue = dataFolder and dataFolder:FindFirstChild("MagicMarks")
		if magicMarksValue and magicMarksValue:IsA("NumberValue") then
			local value = tonumber(magicMarksValue.Value)
			if value then
				return math.floor(value + 0.5)
			end
		end

		return nil
	end

	local function getPlayerRankValue(model)
		local ownerPlayer = Players:GetPlayerFromCharacter(model)
		if not ownerPlayer then
			return nil
		end

		local dataFolder = ownerPlayer:FindFirstChild("Data")
		local statsFolder = dataFolder and dataFolder:FindFirstChild("Stats")
		local rankValue = statsFolder and statsFolder:FindFirstChild("LevelRank")
		if rankValue and rankValue:IsA("StringValue") then
			local value = tostring(rankValue.Value or "")
			if value ~= "" then
				return value
			end
		end

		return nil
	end

	local function getEspStaminaState(model)
		if not model or not model:IsA("Model") then
			return nil, nil
		end

		local characterState = model:FindFirstChild("CharacterState")
		local staminaValue = characterState and characterState:FindFirstChild("Stamina")
		if not staminaValue or not staminaValue:IsA("NumberValue") then
			return nil, nil
		end

		local currentValue = tonumber(staminaValue.Value)
		if not currentValue then
			return nil, nil
		end

		local staminaMaxValue = characterState and characterState:FindFirstChild("StaminaMax")
		local maxValue = tonumber(staminaMaxValue and staminaMaxValue:IsA("NumberValue") and staminaMaxValue.Value)
			or tonumber(staminaValue:GetAttribute("MaxValue"))
			or tonumber(staminaValue:GetAttribute("Max"))
			or tonumber(staminaValue:GetAttribute("Maximum"))
			or tonumber(staminaValue:GetAttribute("Base"))
			or 3

		if maxValue <= 0 then
			maxValue = math.max(currentValue, 3)
		end

		return math.clamp(currentValue, 0, maxValue), maxValue
	end

	local function shouldShowPlayerEsp(model)
		local targetType = getEspTargetType(model)
		if targetType ~= "player" then
			return false
		end

		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil and humanoid.Health <= 0 then
			return false
		end

		local academyName = getPlayerAcademyName(model)
		return isAcademyEspEnabled(academyName)
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

		if targetType == "player" and not getToggleValue("PlayerEspEnabled", false) then
			return false
		end

		if targetType == "mob" and not getToggleValue("MobEspEnabled", false) then
			return false
		end

		local maxDistance = tonumber(getOptionValue("EspRenderDistance", 150)) or 150
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

	local function hideDrawingObject(object)
		if not object then
			return
		end

		pcall(function()
			object.Visible = false
		end)
	end

	local function hideEspEntry(entry)
		if not entry then
			return
		end

		if entry.boxLines then
			for _, line in ipairs(entry.boxLines) do
				hideDrawingObject(line)
			end
		end

		if entry.skeletonLines then
			for _, line in ipairs(entry.skeletonLines) do
				hideDrawingObject(line)
			end
		end

		hideDrawingObject(entry.healthBarOutline)
		hideDrawingObject(entry.healthBarFill)
		hideDrawingObject(entry.staminaBarOutline)
		hideDrawingObject(entry.staminaBarFill)
		hideDrawingObject(entry.nameText)
		hideDrawingObject(entry.distanceText)
		hideDrawingObject(entry.healthText)
		hideDrawingObject(entry.staminaText)
		hideDrawingObject(entry.magicMarksText)
		hideDrawingObject(entry.rankText)
		hideDrawingObject(entry.tracerLine)
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

		local showBox = getToggleValue("EspShowBox", true)
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
			getToggleValue("EspShowHealthBar", true) and humanoid ~= nil
		)

		local staminaValue, staminaMax = getEspStaminaState(model)
		local staminaRatio = (staminaValue and staminaMax and staminaMax > 0) and math.clamp(staminaValue / staminaMax, 0, 1) or 0
		local staminaBarX = box.right + 3
		setEntryStaminaBar(
			entry,
			Vector2.new(staminaBarX, box.top),
			Vector2.new(barWidth, barHeight),
			Vector2.new(staminaBarX + 1, box.bottom - ((barHeight - 2) * staminaRatio) - 1),
			Vector2.new(barWidth - 2, math.max((barHeight - 2) * staminaRatio, 1)),
			Color3.fromRGB(240, 200, 60),
			getToggleValue("EspShowStaminaBar", false) and staminaValue ~= nil
		)

		entry:setText(
			entry.nameText,
			getEspDisplayName(model, targetType),
			Vector2.new(box.left + (box.width * 0.5), box.top - 14),
			getToggleValue("EspShowNames", true)
		)

		local magicMarksValue = targetType == "player" and getPlayerMagicMarksValue(model) or nil
		local rankValue = targetType == "player" and getPlayerRankValue(model) or nil
		entry:setText(
			entry.rankText,
			rankValue and string.format("Rank: %s", rankValue) or "",
			Vector2.new(box.left + (box.width * 0.5) + 42, box.top - 27),
			targetType == "player" and rankValue ~= nil and getToggleValue("EspShowRankText", false)
		)

		entry:setText(
			entry.magicMarksText,
			magicMarksValue and string.format("Mark: %d", magicMarksValue) or "",
			Vector2.new(box.left + (box.width * 0.5) + 42, box.top - 14),
			targetType == "player" and magicMarksValue ~= nil and getToggleValue("EspShowMagicMarks", false)
		)

		entry:setText(
			entry.distanceText,
			string.format("%.0f studs", distance),
			Vector2.new(box.left + (box.width * 0.5), box.bottom + 1),
			getToggleValue("EspShowDistance", true)
		)

		entry:setText(
			entry.healthText,
			string.format("%d / %d HP", math.floor(health + 0.5), math.floor(maxHealth + 0.5)),
			Vector2.new(box.left + (box.width * 0.5), box.top - 27),
			getToggleValue("EspShowHealthText", false) and humanoid ~= nil
		)

		entry:setText(
			entry.staminaText,
			staminaValue and string.format("%d / %d ST", math.floor(staminaValue + 0.5), math.floor(staminaMax + 0.5)) or "",
			Vector2.new(box.left + (box.width * 0.5), box.top - 40),
			getToggleValue("EspShowStaminaText", false) and staminaValue ~= nil and staminaMax ~= nil
		)

		entry:setTracer(tracerStart, tracerEnd, accentColor, getToggleValue("EspShowTracers", true))

		if getToggleValue("EspShowSkeleton", false) then
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

		if not getToggleValue("PlayerEspEnabled", false) then
			clearEspCache(playerEspEntries)
			return
		end

		local validModels = {}
		for _, model in ipairs(iterEspCandidateModels()) do
			if shouldShowPlayerEsp(model) and shouldRenderEspModel(model, "player") then
				validModels[model] = true
				local accentColor = getPlayerEspAccentColor(model)
				local entry = ensureEspEntry(
					playerEspEntries,
					model,
					accentColor
				)
				if entry then
					updateEspEntry(entry, model, "player", accentColor)
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

		if not getToggleValue("MobEspEnabled", false) then
			clearEspCache(mobEspEntries)
			return
		end

		local validModels = {}
		for _, model in ipairs(iterEspCandidateModels()) do
			if shouldShowMobEsp(model) and shouldRenderEspModel(model, "mob") then
				validModels[model] = true
				local accentColor = Color3.fromRGB(255, 255, 255)
				local entry = ensureEspEntry(
					mobEspEntries,
					model,
					accentColor
				)
				if entry then
					updateEspEntry(entry, model, "mob", accentColor)
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
		return getToggleValue("PlayerEspEnabled", false)
			or getToggleValue("MobEspEnabled", false)
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

	espGroup:AddToggle("EspShowWalkisAcademy", {
		Text = "Walkis Academy",
		Default = true,
	})

	espGroup:AddToggle("EspShowSaintArsAcademy", {
		Text = "Saint Ars Academy",
		Default = true,
	})

	espGroup:AddToggle("EspShowEastonAcademy", {
		Text = "Easton Academy",
		Default = true,
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
		Default = 500,
		Min = 10,
		Max = 2000,
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
		Default = false,
	})

	espVisualGroup:AddToggle("EspShowStaminaText", {
		Text = "Stamina Text",
		Default = false,
	})

	espVisualGroup:AddToggle("EspShowMagicMarks", {
		Text = "Magic Marks",
		Default = false,
	})

	espVisualGroup:AddToggle("EspShowRankText", {
		Text = "Rank Esp",
		Default = false,
	})

	espVisualGroup:AddToggle("EspShowHealthBar", {
		Text = "Health Bar",
		Default = true,
	})

	espVisualGroup:AddToggle("EspShowStaminaBar", {
		Text = "Stamina Bar",
		Default = false,
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

	Toggles.PlayerEspEnabled:OnChanged(function()
		if not getToggleValue("PlayerEspEnabled", false) and not getToggleValue("MobEspEnabled", false) then
			forceClearEsp()
			return
		end
		updatePlayerEsp()
	end)

	Toggles.EspShowWalkisAcademy:OnChanged(function()
		updatePlayerEsp()
	end)

	Toggles.EspShowSaintArsAcademy:OnChanged(function()
		updatePlayerEsp()
	end)

	Toggles.EspShowEastonAcademy:OnChanged(function()
		updatePlayerEsp()
	end)

	Toggles.MobEspEnabled:OnChanged(function()
		if not getToggleValue("PlayerEspEnabled", false) and not getToggleValue("MobEspEnabled", false) then
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

	Toggles.EspShowStaminaText:OnChanged(function()
		refreshEsp()
	end)

	Toggles.EspShowMagicMarks:OnChanged(function()
		refreshEsp()
	end)

	Toggles.EspShowRankText:OnChanged(function()
		refreshEsp()
	end)

	Toggles.EspShowHealthBar:OnChanged(function()
		refreshEsp()
	end)

	Toggles.EspShowStaminaBar:OnChanged(function()
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
	Enum.KeyCode.Up,
	Enum.KeyCode.Down,
	Enum.KeyCode.Left,
	Enum.KeyCode.Right,
	Enum.KeyCode.Space,
	Enum.KeyCode.LeftControl,
	Enum.KeyCode.RightControl,
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
	pcall(function()
		ContextActionService:UnbindAction(AUTO_PARRY_BLOCK_ACTION)
	end)
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
		lastHeartbeatErrorMessage = nil,
		lastHeartbeatErrorAt = 0,
		heartbeatDisabled = false,
		visualizer = {
			part = nil,
		},
		manualActionRequestRemote = getRequestModuleRemote(),
		trackedTargets = {},
		handledTracks = {},
		queuedTracks = {},
		recentAnimationActions = {},
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
		manualBlockCaptureStartedAt = 0,
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
		if getToggleValue("AutoParryAdaptiveTiming", false) then
			autoParryState.lastAdaptiveTimingUpdateAt = 0
			updateAdaptiveTimingOffset(true)
		end
	end)

	Toggles.AutoParryEnabled:OnChanged(function()
		if getToggleValue("AutoParryEnabled", false) then
			autoParryState.heartbeatDisabled = false
			autoParryState.lastHeartbeatErrorMessage = nil
			autoParryState.lastHeartbeatErrorAt = 0
			return
		end

		autoParryState.pendingParryFailCheck = nil
		table.clear(autoParryState.queuedMoveActions)
		table.clear(autoParryState.queuedTracks)
		if autoParryRuntime and type(autoParryRuntime.setAutoParryInputBlocking) == "function" then
			autoParryRuntime.setAutoParryInputBlocking(false)
		end
		fireBlockingStateRemote(false)
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
	local makerBlockHoldInput = autoParryMakerGroup:AddInput("AutoParryMakerBlockHold", {
		Text = "Block Hold",
		Default = "0.35",
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
			manualOffsetMs = tonumber(getOptionValue("AutoParryTimingOffset", 0)) or 0,
			adaptiveEnabled = getToggleValue("AutoParryAdaptiveTiming", false),
			actionType = actionType,
			pingCorrectionMs = tonumber(autoParryState.adaptiveTiming.lastComputedOffsetMs) or 0,
			actionBiasMs = tonumber(autoParryState.adaptiveTiming.actionBiasMs[actionType]) or 0,
			learnedOffsetMs = tonumber(autoParryState.adaptiveTiming.learnedOffsets[key]) or 0,
			distance = distance,
		})
	end

	local function getBuilderConfigData()
		local animationId = normalizeBuilderAnimationId(getOptionValue("AutoParryMakerAnimationId", ""))
		local sourceKey = getOptionValue("AutoParryMakerSource", "Players") or "Players"
		local actionType = getOptionValue("AutoParryMakerActionType", "Parry") or "Parry"

		if not animationId or animationId == "" then
			return nil
		end

		return {
			configId = autoParryState.currentBuilderConfigId,
			sourceKey = sourceKey,
			animationId = animationId,
			nickname = tostring(getOptionValue("AutoParryMakerNickname", "") or ""),
			wait = tonumber(getOptionValue("AutoParryMakerWait", 0)) or 0,
			repeatAmount = math.max(1, math.floor(tonumber(getOptionValue("AutoParryMakerRepeatAmount", 1)) or 1)),
			repeatDelay = tonumber(getOptionValue("AutoParryMakerRepeatDelay", 0)) or 0,
			actionType = actionType,
			delay = getOptionValue("AutoParryMakerDelay", "Off") == "On",
			delayRange = tonumber(getOptionValue("AutoParryMakerDelayRange", 0)) or 0,
			blockHold = tonumber(getOptionValue("AutoParryMakerBlockHold", autoParryBlockHoldDuration)) or autoParryBlockHoldDuration,
			range = tonumber(getOptionValue("AutoParryMakerRange", 16)) or 16,
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
		Options.AutoParryMakerBlockHold:SetValue(tostring(configData.blockHold or autoParryBlockHoldDuration))
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

		if not getToggleValue("AutoParryVisualizer", false) or not root then
			if part then
				part.Transparency = 1
			end
			return
		end

		part = ensureAutoParryVisualizer()
		local distance = tonumber(getOptionValue("AutoParryDistance", 18)) or 18
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

		local mode = getOptionValue("AutoParryMode", "Mobs+Players") or "Mobs+Players"
		local allowPlayers = mode == "Mobs+Players" or mode == "Players"
		local allowMobs = mode == "Mobs+Players" or mode == "Mobs"
		local whitelist = getOptionValue("AutoParryWhitelist", nil)
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
		return AutoParryConfigUtils.getMoveConfigRange(moveConfig, tonumber(getOptionValue("AutoParryDistance", 18)) or 18)
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

		local now = os.clock()
		for recentKey, recentTimestamp in pairs(autoParryState.recentAnimationActions) do
			if now - (tonumber(recentTimestamp) or 0) >= 0.45 then
				autoParryState.recentAnimationActions[recentKey] = nil
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

	local function hasQueuedMoveActionForAnimation(targetCharacter, animationId)
		local normalizedAnimationId = normalizeAnimationId(animationId)
		if not targetCharacter or not normalizedAnimationId or normalizedAnimationId == "" then
			return false
		end

		for _, queuedAction in ipairs(autoParryState.queuedMoveActions) do
			if queuedAction
				and queuedAction.target == targetCharacter
				and normalizeAnimationId(queuedAction.animationId) == normalizedAnimationId
			then
				return true
			end
		end

		return false
	end

	local function getRecentAnimationActionKey(targetCharacter, animationId)
		local normalizedAnimationId = normalizeAnimationId(animationId)
		if not targetCharacter or not normalizedAnimationId or normalizedAnimationId == "" then
			return nil
		end

		local targetDebugId = targetCharacter:GetDebugId()
		if not targetDebugId or targetDebugId == "" then
			targetDebugId = tostring(targetCharacter)
		end

		return string.format("%s::%s", targetDebugId, normalizedAnimationId)
	end

	local function wasAnimationRecentlyHandled(targetCharacter, animationId)
		local recentKey = getRecentAnimationActionKey(targetCharacter, animationId)
		if not recentKey then
			return false
		end

		local recentState = autoParryState.recentAnimationActions[recentKey]
		if not recentState then
			return false
		end

		local expiresAt
		if type(recentState) == "table" then
			expiresAt = tonumber(recentState.expiresAt)
		else
			expiresAt = (tonumber(recentState) or 0) + 0.45
		end

		if os.clock() < (expiresAt or 0) then
			return true
		end

		autoParryState.recentAnimationActions[recentKey] = nil
		return false
	end

	local function markAnimationRecentlyHandled(targetCharacter, animationId, durationSeconds)
		local recentKey = getRecentAnimationActionKey(targetCharacter, animationId)
		if recentKey then
			local duration = math.clamp(tonumber(durationSeconds) or 0.9, 0.45, 3)
			autoParryState.recentAnimationActions[recentKey] = {
				recordedAt = os.clock(),
				expiresAt = os.clock() + duration,
			}
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

		if hasQueuedMoveActionForAnimation(targetCharacter, normalizedAnimationId) then
			return false
		end

		if wasAnimationRecentlyHandled(targetCharacter, normalizedAnimationId) then
			return false
		end

		local baseDistance = tonumber(getOptionValue("AutoParryDistance", 18)) or 18
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

			if getToggleValue("AutoParryBlockInputs", false) then
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

		local handledDuration = math.max(
			resolveConfiguredTiming(activeMoveConfig) or 0,
			getMoveConfigDelaySeconds(activeMoveConfig),
			getMoveConfigRepeatDelaySeconds(activeMoveConfig)
		) + 0.75
		markAnimationRecentlyHandled(targetCharacter, animationId, handledDuration)

		local usedDash = false
		if activeMoveConfig and activeMoveConfig.dash == true
			and not (getToggleValue("AutoParryDontBlatantDashPlayers", false) and targetType == "player")
			and now - autoParryState.lastBlatantDashAt >= blatantDashCooldown then
			autoParryState.lastBlatantDashAt = now
			if getToggleValue("AutoParryBlatantDash", false) then
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
				autoParryState.pendingBlockReleaseAt = now + (tonumber(activeMoveConfig.blockHold) or autoParryBlockHoldDuration)
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

			if getToggleValue("AutoParryDashOnFail", false) then
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

		if getToggleValue("AutoParryBlockInputs", false) then
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
		local localCharacter = LocalPlayer and LocalPlayer.Character
		local localHumanoid = getCharacterHumanoid(localCharacter)
		cleanupHandledAttackTracks()

		if getToggleValue("AutoParryAdaptiveTiming", false) and now - autoParryState.lastAdaptiveTimingUpdateAt >= adaptiveTimingUpdateInterval then
			autoParryState.lastAdaptiveTimingUpdateAt = now
			updateAdaptiveTimingOffset(false)
		end

		if autoParryState.inputBlockActive and os.clock() >= autoParryState.inputBlockUntil then
			autoParryRuntime.setAutoParryInputBlocking(false)
		end

		if autoParryState.inputBlockActive and localHumanoid then
			pcall(function()
				localHumanoid:Move(Vector3.zero, false)
				localHumanoid.Jump = false
			end)
		end

		if autoParryState.pendingBlockReleaseAt > 0 and now >= autoParryState.pendingBlockReleaseAt then
			autoParryState.pendingBlockReleaseAt = 0
			fireBlockingStateRemote(false)
		end

		if autoParryState.pendingParryFailCheck and now >= autoParryState.pendingParryFailCheck.checkAt then
			local targetCharacter = autoParryState.pendingParryFailCheck.target
			local maxDistance = autoParryState.pendingParryFailCheck.distance or (tonumber(getOptionValue("AutoParryDistance", 18)) or 18)
			local localRoot = getCharacterRoot(localCharacter)
			local targetRoot = getCharacterRoot(targetCharacter)
			local humanoid = getCharacterHumanoid(targetCharacter)

			if getToggleValue("AutoParryDashOnFail", false)
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
			table.clear(autoParryState.recentAnimationActions)
			setAutoParryTrackingText("disabled.")
			return
		end

		local remote = getRequestModuleRemote()
		autoParryState.manualActionRequestRemote = remote or autoParryState.manualActionRequestRemote
		if not remote then
			autoParryState.pendingParryFailCheck = nil
			table.clear(autoParryState.queuedMoveActions)
			table.clear(autoParryState.queuedTracks)
			table.clear(autoParryState.recentAnimationActions)
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
		local maxDistance = tonumber(getOptionValue("AutoParryDistance", 18)) or 18
		local candidate = findManualDebugCandidate(maxDistance, captureRequestedAt)
		local isDashAction = actionKind == "manual dash"
		local isJumpAction = actionKind == "manual jump"
		local isBlockAction = actionKind == "manual block"
		local actionType = isDashAction and "Dash" or (isJumpAction and "Jump" or (isBlockAction and "Block" or "Parry"))
		local setDebugText = isDashAction and setManualDashDebugText or setManualParryDebugText
		local setLastAnimationId = isDashAction and setLastManualDashAnimationId or setLastManualParryAnimationId
		local manualBlockHold = tonumber(autoParryState.manualBlockCaptureHold) or autoParryBlockHoldDuration
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
			blockHold = manualBlockHold,
			range = latestCapture.range or 16,
		})
		setDebugText(string.format(
			"%s -> %s %s anim %s at %.2fs%s%s",
			actionKind,
			candidate.targetType,
			candidate.targetName,
			candidate.animationId,
			candidate.timePosition or 0,
			candidate.matched and " (in table)" or " (not in table)",
			isBlockAction and string.format(" | hold %.2fs", manualBlockHold) or ""
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
		return shouldUseAntiFallProtection()
			and isManualActionRequestRemote(instance)
			and args[1] == "Misc"
			and args[2] == "FallDamage"
	end

	function autoParryRuntime.installManualActionDebugHook()
		GLOBAL_ENV[HUAJ_HUB_MANUAL_ACTION_CALLBACK_KEY] = reportManualActionDebug

		setManualParryDebugText("remote hook disabled; use F/Q/Space/RMB capture.")
		setManualDashDebugText("remote hook disabled; use F/Q/Space capture.")
		return false
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
		if not getToggleValue("AutoParryBlockInputs", false) then
			autoParryState.inputBlockUntil = 0
			autoParryRuntime.setAutoParryInputBlocking(false)
		end
	end)

	Options.AutoParryDistance:OnChanged(function()
		updateAutoParryVisualizer()
	end)

	function autoParryRuntime.refreshAutoParryWhitelist()
		if not Options or not Options.AutoParryWhitelist then
			return
		end

		local values = getOtherPlayerNames()
		local currentSelection = {}

		local whitelistSelection = getOptionValue("AutoParryWhitelist", {})
		if type(whitelistSelection) == "table" then
			for playerName, selected in pairs(whitelistSelection) do
				if selected then
					currentSelection[playerName] = true
				end
			end
		end

		pcall(function()
			Options.AutoParryWhitelist:SetValues(values)
		end)
		pcall(function()
			Options.AutoParryWhitelist:SetValue(currentSelection)
		end)
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
			if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
				autoParryState.manualBlockCaptureStartedAt = os.clock()
			end
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

	maid:GiveTask(UserInputService.InputEnded:Connect(function(inputObject)
		if inputObject.UserInputType ~= Enum.UserInputType.MouseButton2 then
			return
		end

		local startedAt = tonumber(autoParryState.manualBlockCaptureStartedAt) or 0
		autoParryState.manualBlockCaptureStartedAt = 0
		if startedAt <= 0 then
			return
		end

		local heldFor = math.max(os.clock() - startedAt, 0.03)
		autoParryState.manualBlockCaptureHold = math.min(heldFor, 3)
		local captureRequestedAt = startedAt
		task.defer(function()
			pcall(reportManualActionDebug, "manual block", captureRequestedAt)
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

	maid:GiveTask(RunService.Heartbeat:Connect(function()
		if autoParryState.heartbeatDisabled then
			return
		end

		local ok, err = pcall(autoParryRuntime.processAutoParryHeartbeat)
		if ok then
			return
		end

		local errorMessage = tostring(err)
		local now = os.clock()
		if errorMessage ~= autoParryState.lastHeartbeatErrorMessage or (now - autoParryState.lastHeartbeatErrorAt) >= 2 then
			autoParryState.lastHeartbeatErrorMessage = errorMessage
			autoParryState.lastHeartbeatErrorAt = now
			autoParryState.heartbeatDisabled = true
			autoParryState.pendingParryFailCheck = nil
			table.clear(autoParryState.queuedMoveActions)
			table.clear(autoParryState.queuedTracks)
			autoParryRuntime.setAutoParryInputBlocking(false)
			fireBlockingStateRemote(false)
			if Toggles and Toggles.AutoParryEnabled and type(Toggles.AutoParryEnabled.SetValue) == "function" then
				pcall(function()
					Toggles.AutoParryEnabled:SetValue(false)
				end)
			end
			warn("[HuajHub] Auto Parry heartbeat error: " .. errorMessage)
			Library:Notify("Auto Parry was disabled after a runtime error. Re-enable it after uploading the fixed file.", 4)
		end
	end))

	registerLibraryUnloadCallback(function()
		autoParryRuntime.setAutoParryInputBlocking(false)
		fireBlockingStateRemote(false)
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
	local function safeRead(propertyGetter, fallback)
		local ok, value = pcall(propertyGetter)
		if ok and value ~= nil then
			return value
		end
		return fallback
	end

	local originalVisualSettings = {
		globalShadows = safeRead(function()
			return Lighting.GlobalShadows
		end, true),
		brightness = safeRead(function()
			return Lighting.Brightness
		end, 2),
		environmentDiffuseScale = safeRead(function()
			return Lighting.EnvironmentDiffuseScale
		end, 1),
		environmentSpecularScale = safeRead(function()
			return Lighting.EnvironmentSpecularScale
		end, 1),
		fogEnd = safeRead(function()
			return Lighting.FogEnd
		end, 100000),
		streamingMinRadius = safeRead(function()
			return workspace.StreamingMinRadius
		end, 64),
		streamingTargetRadius = safeRead(function()
			return workspace.StreamingTargetRadius
		end, 128),
	}
	local fpsBoostTextureStates = {}
	local fpsBoostMaterialStates = {}
	local fpsBoostStudsPerTileStates = {}
	local fpsBoostMeshTextureStates = {}
	local blurEffectStates = {}
	local effectEnabledStates = {}
	local staffDetectorPlayerAddedConnection = nil
	local staffDetectorTriggered = false
	local STAFF_GROUP_ID = 32643289

	local function setBlurEffectsEnabled(enabled)
		for _, descendant in ipairs(Lighting:GetDescendants()) do
			if descendant:IsA("BlurEffect") then
				if blurEffectStates[descendant] == nil then
					blurEffectStates[descendant] = {
						enabled = descendant.Enabled,
						size = descendant.Size,
					}
				end

				pcall(function()
					descendant.Enabled = enabled and blurEffectStates[descendant].enabled or false
				end)
				pcall(function()
					descendant.Size = enabled and blurEffectStates[descendant].size or 0
				end)
			end
		end
	end

	local function restoreFpsBoostVisuals()
		for instance, transparency in pairs(fpsBoostTextureStates) do
			if instance and instance.Parent then
				pcall(function()
					instance.Transparency = transparency
				end)
			end
		end
		table.clear(fpsBoostTextureStates)

		for instance, material in pairs(fpsBoostMaterialStates) do
			if instance and instance.Parent then
				pcall(function()
					instance.Material = material
				end)
			end
		end
		table.clear(fpsBoostMaterialStates)

		for instance, state in pairs(fpsBoostStudsPerTileStates) do
			if instance and instance.Parent then
				pcall(function()
					instance.StudsPerTileU = state.u
					instance.StudsPerTileV = state.v
				end)
			end
		end
		table.clear(fpsBoostStudsPerTileStates)

		for instance, textureId in pairs(fpsBoostMeshTextureStates) do
			if instance and instance.Parent then
				pcall(function()
					instance.TextureID = textureId
				end)
			end
		end
		table.clear(fpsBoostMeshTextureStates)
	end

	local function applyFpsBoostVisuals()
		restoreFpsBoostVisuals()

		for _, descendant in ipairs(workspace:GetDescendants()) do
			if descendant:IsA("Texture") or descendant:IsA("Decal") then
				fpsBoostTextureStates[descendant] = descendant.Transparency
				pcall(function()
					descendant.Transparency = 1
				end)
			elseif descendant:IsA("BasePart") then
				fpsBoostMaterialStates[descendant] = descendant.Material
				pcall(function()
					descendant.Material = Enum.Material.SmoothPlastic
				end)
				if descendant:IsA("MeshPart") then
					fpsBoostMeshTextureStates[descendant] = descendant.TextureID
					pcall(function()
						descendant.TextureID = ""
					end)
				end
			elseif descendant:IsA("Terrain") then
				fpsBoostStudsPerTileStates[descendant] = {
					u = descendant.StudsPerTileU,
					v = descendant.StudsPerTileV,
				}
				pcall(function()
					descendant.StudsPerTileU = 64
					descendant.StudsPerTileV = 64
				end)
			end
		end
	end

	local function setEffectsEnabled(enabled)
		for _, descendant in ipairs(Lighting:GetDescendants()) do
			if descendant:IsA("PostEffect") and not descendant:IsA("BlurEffect") then
				if effectEnabledStates[descendant] == nil then
					effectEnabledStates[descendant] = descendant.Enabled
				end

				pcall(function()
					descendant.Enabled = enabled and effectEnabledStates[descendant] or false
				end)
			elseif descendant:IsA("Atmosphere") then
				if effectEnabledStates[descendant] == nil then
					effectEnabledStates[descendant] = {
						Density = descendant.Density,
						Haze = descendant.Haze,
						Glare = descendant.Glare,
					}
				end

				pcall(function()
					local state = effectEnabledStates[descendant]
					if enabled and type(state) == "table" then
						descendant.Density = state.Density
						descendant.Haze = state.Haze
						descendant.Glare = state.Glare
					else
						descendant.Density = 0
						descendant.Haze = 0
						descendant.Glare = 0
					end
				end)
			elseif descendant:IsA("Sky") or descendant:IsA("Clouds") then
				if effectEnabledStates[descendant] == nil then
					effectEnabledStates[descendant] = descendant.Parent
				end

				pcall(function()
					descendant.Parent = enabled and Lighting or nil
				end)
			end
		end
	end

	local function applyVisualSettings()
		local fpsBoostEnabled = getToggleValue("MiscFpsBoostEnabled", false)
		local disableShadowsEnabled = getToggleValue("MiscDisableShadowsEnabled", false)
		local chunkLoaderEnabled = getToggleValue("MiscChunkLoaderEnabled", false)
		local renderDistance = tonumber(getOptionValue("MiscRenderDistance", 11)) or 11

		pcall(function()
			Lighting.GlobalShadows = not disableShadowsEnabled
		end)

		if fpsBoostEnabled then
			pcall(function()
				Lighting.Brightness = 1
			end)
			pcall(function()
				Lighting.EnvironmentDiffuseScale = 0
			end)
			pcall(function()
				Lighting.EnvironmentSpecularScale = 0
			end)
			setEffectsEnabled(false)
			applyFpsBoostVisuals()
		else
			pcall(function()
				Lighting.Brightness = originalVisualSettings.brightness
			end)
			pcall(function()
				Lighting.EnvironmentDiffuseScale = originalVisualSettings.environmentDiffuseScale
			end)
			pcall(function()
				Lighting.EnvironmentSpecularScale = originalVisualSettings.environmentSpecularScale
			end)
			setEffectsEnabled(true)
			restoreFpsBoostVisuals()
		end

		pcall(function()
			Lighting.FogEnd = originalVisualSettings.fogEnd
		end)

		pcall(function()
			local radius = math.max(math.floor(renderDistance), 1) * 64
			workspace.StreamingMinRadius = chunkLoaderEnabled and radius or originalVisualSettings.streamingMinRadius
		end)
		pcall(function()
			local radius = math.max(math.floor(renderDistance), 1) * 64
			workspace.StreamingTargetRadius = chunkLoaderEnabled and radius or originalVisualSettings.streamingTargetRadius
		end)
	end

	local function fetchServerPage(placeId, cursor)
		local requestUrl = string.format(
			"https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true%s",
			placeId,
			cursor and ("&cursor=" .. HttpService:UrlEncode(cursor)) or ""
		)

		local responseBody
		local ok, response = pcall(function()
			return game:HttpGet(requestUrl)
		end)
		if ok and type(response) == "string" and response ~= "" then
			responseBody = response
		elseif type(request) == "function" then
			local requestOk, requestResponse = pcall(function()
				return request({
					Url = requestUrl,
					Method = "GET",
				})
			end)
			if requestOk and type(requestResponse) == "table" and requestResponse.Success and type(requestResponse.Body) == "string" then
				responseBody = requestResponse.Body
			end
		elseif type(http_request) == "function" then
			local requestOk, requestResponse = pcall(function()
				return http_request({
					Url = requestUrl,
					Method = "GET",
				})
			end)
			if requestOk and type(requestResponse) == "table" and requestResponse.Success and type(requestResponse.Body) == "string" then
				responseBody = requestResponse.Body
			end
		end

		if type(responseBody) ~= "string" or responseBody == "" then
			return nil, "Unable to fetch server list."
		end

		local decodeOk, decoded = pcall(function()
			return HttpService:JSONDecode(responseBody)
		end)
		if not decodeOk or type(decoded) ~= "table" then
			return nil, "Unable to decode server list."
		end

		return decoded, nil
	end

	local function hopToLowestPopulationServer()
		local placeId = game.PlaceId
		local currentJobId = game.JobId
		local bestServer = nil
		local cursor = nil
		local pagesChecked = 0

		repeat
			local payload, errorMessage = fetchServerPage(placeId, cursor)
			if not payload then
				Library:Notify(errorMessage or "Failed to fetch servers.", 3)
				return
			end

			for _, server in ipairs(payload.data or {}) do
				local serverId = server.id
				local playing = tonumber(server.playing) or math.huge
				local maxPlayers = tonumber(server.maxPlayers) or 0
				if serverId and serverId ~= currentJobId and playing < maxPlayers then
					if not bestServer or playing < (tonumber(bestServer.playing) or math.huge) then
						bestServer = server
					end
				end
			end

			cursor = payload.nextPageCursor
			pagesChecked += 1
		until bestServer or not cursor or pagesChecked >= 5

		if not bestServer or not bestServer.id then
			Library:Notify("No lower-population server was found.", 3)
			return
		end

		Library:Notify(string.format("Hopping to server with %s players...", tostring(bestServer.playing)), 3)
		TeleportService:TeleportToPlaceInstance(placeId, bestServer.id, LocalPlayer)
	end

	local function hopToHighestPopulationServer()
		local placeId = game.PlaceId
		local currentJobId = game.JobId
		local bestServer = nil
		local bestScore = -1
		local cursor = nil
		local pagesChecked = 0

		repeat
			local payload, errorMessage = fetchServerPage(placeId, cursor)
			if not payload then
				Library:Notify(errorMessage or "Failed to fetch servers.", 3)
				return
			end

			for _, server in ipairs(payload.data or {}) do
				local serverId = server.id
				local playing = tonumber(server.playing) or -1
				local maxPlayers = tonumber(server.maxPlayers) or 0
				local openSlots = maxPlayers - playing
				if serverId and serverId ~= currentJobId and openSlots > 0 then
					local fillRatio = maxPlayers > 0 and (playing / maxPlayers) or 0
					local preferredOpenSlotPenalty = math.abs(openSlots - 1) * 0.05
					local score = fillRatio - preferredOpenSlotPenalty
					if score > bestScore then
						bestServer = server
						bestScore = score
					end
				end
			end

			cursor = payload.nextPageCursor
			pagesChecked += 1
		until not cursor or pagesChecked >= 5

		if not bestServer or not bestServer.id then
			Library:Notify("No higher-population server was found.", 3)
			return
		end

		Library:Notify(string.format("Hopping to server with %s players...", tostring(bestServer.playing)), 3)
		TeleportService:TeleportToPlaceInstance(placeId, bestServer.id, LocalPlayer)
	end

	local function stopStaffDetector()
		if staffDetectorPlayerAddedConnection then
			staffDetectorPlayerAddedConnection:Disconnect()
			staffDetectorPlayerAddedConnection = nil
		end
		staffDetectorTriggered = false
	end

	local function getStaffDetectionReason(player)
		if not player or player == LocalPlayer then
			return nil
		end

		local rankOk, rank = pcall(function()
			return player:GetRankInGroup(STAFF_GROUP_ID)
		end)
		if not rankOk or tonumber(rank) == nil or rank <= 0 then
			return nil
		end

		local role = "Unknown"
		pcall(function()
			role = player:GetRoleInGroup(STAFF_GROUP_ID)
		end)

		return string.format("group rank %s (%s)", tostring(rank), tostring(role))
	end

	local function handleDetectedStaffPlayer(player)
		if staffDetectorTriggered then
			return
		end

		local reason = getStaffDetectionReason(player)
		if not reason then
			return
		end

		staffDetectorTriggered = true
		Library:Notify(string.format("Staff detected: %s [%s]", player.Name, reason), 4)
		task.delay(0.2, function()
			pcall(function()
				LocalPlayer:Kick(string.format("Staff detected: %s [%s]", player.Name, reason))
			end)
		end)
	end

	local function startStaffDetector()
		stopStaffDetector()

		for _, player in ipairs(Players:GetPlayers()) do
			handleDetectedStaffPlayer(player)
			if staffDetectorTriggered then
				return
			end
		end

		staffDetectorPlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
			handleDetectedStaffPlayer(player)
		end)
	end

	local inventoryPlayerMap = {}
	local inventoryPlayerLabels = {"(none)"}
	local inventoryListLabel

	local function buildInventoryPlayerLabels()
		table.clear(inventoryPlayerMap)
		inventoryPlayerLabels = {"(none)"}

		local playersList = {}
		local ok, livePlayers = pcall(function()
			return Players:GetPlayers()
		end)
		if ok and type(livePlayers) == "table" then
			playersList = livePlayers
		end

		if #playersList == 0 then
			local childrenOk, children = pcall(function()
				return game:GetService("Players"):GetChildren()
			end)
			if childrenOk and type(children) == "table" then
				for _, child in ipairs(children) do
					if child and type(child.Name) == "string" and child.Name ~= "" then
						table.insert(playersList, child)
					end
				end
			end
		end

		table.sort(playersList, function(left, right)
			return left.Name:lower() < right.Name:lower()
		end)

		for _, player in ipairs(playersList) do
			local label = player.Name
			inventoryPlayerMap[label] = player
			table.insert(inventoryPlayerLabels, label)
		end
	end

	local function setInventoryViewerText(text)
		if inventoryListLabel and type(inventoryListLabel.SetText) == "function" then
			inventoryListLabel:SetText(text)
		end
	end

	local function renderSelectedInventory()
		local selectedName = Options.InventoryViewerPlayer and Options.InventoryViewerPlayer.Value
		local selectedPlayer = selectedName and inventoryPlayerMap[selectedName]
		if not selectedPlayer then
			setInventoryViewerText("Select a player to view inventory folders.")
			return
		end

		local dataFolder = selectedPlayer:FindFirstChild("Data")
		local inventoryFolder = dataFolder and dataFolder:FindFirstChild("Inventory")
		if not inventoryFolder or not inventoryFolder:IsA("Folder") then
			setInventoryViewerText(string.format("%s has no readable Data.Inventory folder.", selectedPlayer.Name))
			return
		end

		local folderNames = {}
		for _, child in ipairs(inventoryFolder:GetChildren()) do
			if child:IsA("Folder") then
				table.insert(folderNames, child.Name)
			end
		end
		table.sort(folderNames, function(left, right)
			return left:lower() < right:lower()
		end)

		if #folderNames == 0 then
			setInventoryViewerText(string.format("%s inventory has no folders.", selectedPlayer.Name))
			return
		end

		setInventoryViewerText(string.format(
			"%s Inventory:\n%s",
			selectedPlayer.Name,
			table.concat(folderNames, "\n")
		))
	end

	local function refreshInventoryViewerDropdown(preferredSelection)
		buildInventoryPlayerLabels()

		if Options.InventoryViewerPlayer then
			pcall(function()
				Options.InventoryViewerPlayer:SetValues(inventoryPlayerLabels)
			end)
			local currentSelection = preferredSelection or Options.InventoryViewerPlayer.Value or "(none)"
			if not inventoryPlayerMap[currentSelection] then
				currentSelection = "(none)"
			end
			pcall(function()
				Options.InventoryViewerPlayer:SetValue(currentSelection)
			end)
		end

		renderSelectedInventory()
	end

	buildInventoryPlayerLabels()

	local miscGroup = miscTab:AddLeftGroupbox("Misc")
	miscGroup:AddButton("Hop to Low Server", function()
		hopToLowestPopulationServer()
	end)
	miscGroup:AddButton("Hop to High Server", function()
		hopToHighestPopulationServer()
	end)

	local alertsGroup = miscTab:AddLeftGroupbox("Alerts")
	alertsGroup:AddToggle("StaffDetectorEnabled", {
		Text = "Mod/Admin Detector",
		Default = false,
	})

	local visualsGroup = miscTab:AddLeftGroupbox("Visuals")
	visualsGroup:AddToggle("MiscFpsBoostEnabled", {
		Text = "FPS Boost",
		Default = false,
	})

	visualsGroup:AddToggle("MiscChunkLoaderEnabled", {
		Text = "Chunk Loader",
		Default = false,
	})

	visualsGroup:AddToggle("MiscDisableShadowsEnabled", {
		Text = "Disable Shadows",
		Default = false,
	})

	visualsGroup:AddSlider("MiscRenderDistance", {
		Text = "Render Distance",
		Default = 11,
		Min = 1,
		Max = 30,
		Rounding = 0,
	})

	local lootGroup = miscTab:AddRightGroupbox("Auto Loot")
	lootGroup:AddLabel("Auto Loot section placeholder.")
	lootGroup:AddLabel("Features will be added later.")

	local inventoryGroup = miscTab:AddRightGroupbox("Inventory")
	inventoryGroup:AddDropdown("InventoryViewerPlayer", {
		Text = "Player",
		Values = inventoryPlayerLabels,
		Default = 1,
		Multi = false,
	})
	inventoryGroup:AddButton("Refresh Player List", function()
		refreshInventoryViewerDropdown()
	end)
	inventoryListLabel = inventoryGroup:AddLabel("Select a player to view inventory folders.", true)

	local farmsGroup = miscTab:AddRightGroupbox("Farms")
	farmsGroup:AddLabel("Farms section placeholder.")
	farmsGroup:AddLabel("Features will be added later.")

	Toggles.MiscFpsBoostEnabled:OnChanged(applyVisualSettings)
	Toggles.MiscChunkLoaderEnabled:OnChanged(applyVisualSettings)
	Toggles.MiscDisableShadowsEnabled:OnChanged(applyVisualSettings)
	Options.MiscRenderDistance:OnChanged(applyVisualSettings)
	Toggles.StaffDetectorEnabled:OnChanged(function()
		if Toggles.StaffDetectorEnabled.Value then
			startStaffDetector()
		else
			stopStaffDetector()
		end
	end)
	Options.InventoryViewerPlayer:OnChanged(function()
		renderSelectedInventory()
	end)
	maid:GiveTask(Players.PlayerAdded:Connect(function(player)
		refreshInventoryViewerDropdown("(none)")
	end))
	maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
		local currentSelection = Options.InventoryViewerPlayer and Options.InventoryViewerPlayer.Value
		local preferredSelection = currentSelection ~= player.Name and currentSelection or "(none)"
		refreshInventoryViewerDropdown(preferredSelection)
	end))
	refreshInventoryViewerDropdown("(none)")

	registerLibraryUnloadCallback(function()
		stopStaffDetector()
		pcall(function()
			Lighting.GlobalShadows = originalVisualSettings.globalShadows
		end)
		pcall(function()
			Lighting.Brightness = originalVisualSettings.brightness
		end)
		pcall(function()
			Lighting.EnvironmentDiffuseScale = originalVisualSettings.environmentDiffuseScale
		end)
		pcall(function()
			Lighting.EnvironmentSpecularScale = originalVisualSettings.environmentSpecularScale
		end)
		pcall(function()
			Lighting.FogEnd = originalVisualSettings.fogEnd
		end)
		pcall(function()
			workspace.StreamingMinRadius = originalVisualSettings.streamingMinRadius
		end)
		pcall(function()
			workspace.StreamingTargetRadius = originalVisualSettings.streamingTargetRadius
		end)
		setEffectsEnabled(true)
		restoreFpsBoostVisuals()
		setBlurEffectsEnabled(true)
	end)
end
local miscSetupOk = pcall(setupMiscTab)
if not miscSetupOk then
	local miscFallback = Tabs["Misc"]:AddLeftGroupbox("Misc")
	miscFallback:AddLabel("Misc failed to build.")
	miscFallback:AddLabel("Using fallback view.")
end

local function setupSettingsTab()
	local settingsTab = Tabs["Settings"]
	local menuGroup = settingsTab:AddLeftGroupbox("Menu")

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
local settingsSetupOk = pcall(setupSettingsTab)
if not settingsSetupOk then
	local settingsFallback = Tabs["Settings"]:AddLeftGroupbox("Menu")
	settingsFallback:AddLabel("Settings failed to build.")
end

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})

ThemeManager:SetFolder("HuajHub")
SaveManager:SetFolder("HuajHub/" .. GAME_KEY)
local saveManagerOk, saveManagerErr = pcall(function()
	SaveManager:BuildConfigSection(Tabs["Settings"])
end)

local themeManagerOk, themeManagerErr = pcall(function()
	ThemeManager:ApplyToTab(Tabs["Settings"])
end)

if not saveManagerOk or not themeManagerOk then
	local diagnosticsGroup = Tabs["Settings"]:AddRightGroupbox("Settings Status")
	diagnosticsGroup:AddLabel("Some settings sections failed to load.")
	if not saveManagerOk then
		diagnosticsGroup:AddLabel("Config section failed.")
	end
	if not themeManagerOk then
		diagnosticsGroup:AddLabel("Theme section failed.")
	end
end
pcall(function()
	ContextActionService:UnbindAction("HuajHubAutoParryInputBlock")
end)
pcall(function()
	fireBlockingStateRemote(false)
end)

task.defer(function()
	local holder = Window and Window.Holder
	if holder and holder.Visible == false and type(Library.Toggle) == "function" then
		pcall(function()
			Library:Toggle()
		end)
	end
end)

end

return MashleAcademy
