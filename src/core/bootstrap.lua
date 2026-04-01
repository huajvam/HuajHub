return function()
	local Loader = loadfile("src/core/loader.lua")()

	local Bootstrap = {}

	local function requireModule(path)
		local chunk, loadError = loadfile(path)
		if not chunk then
			error(("Failed to load module %s: %s"):format(path, tostring(loadError)))
		end

		local ok, result = pcall(chunk)
		if not ok then
			error(("Module %s errored: %s"):format(path, tostring(result)))
		end

		return result
	end

	function Bootstrap.start()
		local gameKey, GameModule = Loader.loadGameModule()

		local context = {
			gameKey = gameKey,
			features = {
				movement = requireModule("src/features/movement/init.lua"),
				esp = requireModule("src/features/esp/init.lua"),
				autoparry = requireModule("src/features/autoparry/init.lua"),
			},
		}

		if type(GameModule.init) == "function" then
			GameModule.init(context)
		else
			warn(("HuajHub game module '%s' has no init(context) function"):format(gameKey))
		end
	end

	return Bootstrap
end
