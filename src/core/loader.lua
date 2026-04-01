local Registry = loadfile("src/core/registry.lua")()

local Loader = {}

function Loader.resolveGameKey()
	if Registry.Places[game.PlaceId] then
		return Registry.Places[game.PlaceId]
	end

	if Registry.GameIds[game.GameId] then
		return Registry.GameIds[game.GameId]
	end

	return Registry.DefaultGame
end

function Loader.loadGameModule()
	local gameKey = Loader.resolveGameKey()
	local path = ("src/games/%s/init.lua"):format(gameKey)

	local chunk, loadError = loadfile(path)
	if not chunk then
		error(("Failed to load %s: %s"):format(path, tostring(loadError)))
	end

	local ok, result = pcall(chunk)
	if not ok then
		error(("Error while loading %s: %s"):format(path, tostring(result)))
	end

	return gameKey, result
end

return Loader
