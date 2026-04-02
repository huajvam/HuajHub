local GLOBAL_ENV = getgenv and getgenv() or _G

local REPO_OWNER = GLOBAL_ENV.HuajHubRepoOwner or "huajvam"
local REPO_NAME = GLOBAL_ENV.HuajHubRepoName or "HuajHub"
local REPO_BRANCH = GLOBAL_ENV.HuajHubRepoBranch or "main"
local RAW_BASE_URL = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(REPO_OWNER, REPO_NAME, REPO_BRANCH)

GLOBAL_ENV.HuajHubRawBaseUrl = RAW_BASE_URL

local function compileChunk(source, chunkName)
	local chunk, compileError = loadstring(source, chunkName)
	if not chunk then
		error(("HuajHub compile failed for %s: %s"):format(chunkName, tostring(compileError)))
	end

	return chunk
end

local function executeChunk(source, chunkName)
	local chunk = compileChunk(source, chunkName)
	local ok, result = pcall(chunk)
	if not ok then
		error(("HuajHub runtime failed for %s: %s"):format(chunkName, tostring(result)))
	end

	return result
end

local function canReadLocalFile(path)
	return type(isfile) == "function" and type(readfile) == "function" and isfile(path)
end

local function readModuleSource(path)
	if canReadLocalFile(path) then
		warn("[HuajHub] Loading local module: " .. path)
		return readfile(path), "local"
	end

	local url = RAW_BASE_URL .. path
	warn("[HuajHub] Fetching module: " .. url)
	return game:HttpGet(url), url
end

local function requireModule(path)
	local source, sourceName = readModuleSource(path)
	return executeChunk(source, sourceName)
end

local function normalizeModulePath(path)
	if type(path) ~= "string" then
		error("HuajHub sharedRequire expected string path")
	end

	local normalized = path:gsub("\\", "/")
	if normalized:sub(1, 1) == "@" then
		normalized = normalized:sub(2)
	end

	return normalized
end

GLOBAL_ENV.sharedRequire = function(path)
	return requireModule(normalizeModulePath(path))
end

local function resolveGameKey(gameMap)
	if type(gameMap) ~= "table" then
		error("HuajHub expected a game map table")
	end

	local placeMatch = gameMap.Places and gameMap.Places[game.PlaceId]
	if placeMatch then
		return placeMatch
	end

	local gameMatch = gameMap.GameIds and gameMap.GameIds[game.GameId]
	if gameMatch then
		return gameMatch
	end

	return gameMap.DefaultGame or "Universal"
end

local gameMap = sharedRequire("games/gameList.lua")
local gameKey = resolveGameKey(gameMap)

warn(("[HuajHub] Resolved game key: %s (PlaceId=%s GameId=%s)"):format(
	tostring(gameKey),
	tostring(game.PlaceId),
	tostring(game.GameId)
))

if gameKey == "MashleAcademy" then
	GLOBAL_ENV.__huaj_hub_mashle_initialized_v1 = nil
	GLOBAL_ENV.__huaj_hub_mashle_library_v1 = nil
end

local gameModule = sharedRequire(("games/%s.lua"):format(gameKey))

if type(gameModule) ~= "table" or type(gameModule.init) ~= "function" then
	error(("HuajHub game module '%s' is missing init(context)"):format(tostring(gameKey)))
end

local ok, initError = pcall(gameModule.init, {
	gameKey = gameKey,
	repoOwner = REPO_OWNER,
	repoName = REPO_NAME,
	repoBranch = REPO_BRANCH,
	rawBaseUrl = RAW_BASE_URL,
})

if not ok then
	error(("[HuajHub] Failed to initialize '%s': %s"):format(tostring(gameKey), tostring(initError)))
end

warn("[HuajHub] Initialization complete: " .. tostring(gameKey))
