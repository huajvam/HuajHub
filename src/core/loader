local Registry = loadfile("src/core/registry.lua")()

local Loader = {}

function Loader.resolveGameKey()
	local placeId = game.PlaceId
	local gameId = game.GameId

	if Registry.Places[placeId] then
		return Registry.Places[placeId]
	end

	if Registry.GameIds[gameId] then
		return Registry.GameIds[gameId]
	end

	return Registry.DefaultGame
end

function Loader.loadGameModule()
	local gameKey = Loader.resolveGameKey()
	local path = ("src/games/%s/init.lua"):format(gameKey)

	local chunk, loadError = loadfile(path)
	if not chunk then
		error(("Failed to load game module '%s' from %s: %s"):format(gameKey, path, tostring(loadError)))
	end

	local ok, result = pcall(chunk)
	if not ok then
		error(("Game module '%s' errored during load: %s"):format(gameKey, tostring(result)))
	end

	return gameKey, result
end

return Loader
