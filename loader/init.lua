local GLOBAL_ENV = getgenv and getgenv() or _G

local REPO_OWNER = GLOBAL_ENV.HuajHubRepoOwner or "huajvam"
local REPO_NAME = GLOBAL_ENV.HuajHubRepoName or "HuajHub"
local REPO_BRANCH = GLOBAL_ENV.HuajHubRepoBranch or "main"
local RAW_BASE_URL = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(REPO_OWNER, REPO_NAME, REPO_BRANCH)

local function compileChunk(source, chunkName)
	local chunk, compileError = loadstring(source, chunkName)
	if not chunk then
		error(("HuajHub loader compile failed for %s: %s"):format(chunkName, tostring(compileError)))
	end

	return chunk
end

local function executeChunk(source, chunkName)
	local chunk = compileChunk(source, chunkName)
	local ok, result = pcall(chunk)
	if not ok then
		error(("HuajHub loader runtime failed for %s: %s"):format(chunkName, tostring(result)))
	end

	return result
end

local function canReadLocalFile(path)
	return type(isfile) == "function" and type(readfile) == "function" and isfile(path)
end

local function readModuleSource(path)
	if canReadLocalFile(path) then
		return readfile(path), "local"
	end

	local url = RAW_BASE_URL .. path
	return game:HttpGet(url), url
end

local function requireModule(path)
	local source, sourceName = readModuleSource(path)
	return executeChunk(source, sourceName)
end

local function resolveGameKey(registry)
	if type(registry) ~= "table" then
		error("HuajHub loader expected registry table")
	end

	local places = type(registry.Places) == "table" and registry.Places or {}
	local gameIds = type(registry.GameIds) == "table" and registry.GameIds or {}

	return places[game.PlaceId] or gameIds[game.GameId] or registry.DefaultGame or "universal"
end

local registry = requireModule("src/core/registry.lua")
local gameKey = resolveGameKey(registry)
local gameModule = requireModule(("src/games/%s/init.lua"):format(gameKey))

if type(gameModule) ~= "table" or type(gameModule.init) ~= "function" then
	error(("HuajHub game module '%s' is missing init(context)"):format(tostring(gameKey)))
end

gameModule.init({
	gameKey = gameKey,
	repoOwner = REPO_OWNER,
	repoName = REPO_NAME,
	repoBranch = REPO_BRANCH,
	rawBaseUrl = RAW_BASE_URL,
})
