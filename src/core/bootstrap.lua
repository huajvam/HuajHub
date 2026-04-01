return function()
	local Loader = loadfile("src/core/loader.lua")()

	local Bootstrap = {}

	function Bootstrap.start()
		local gameKey, GameModule = Loader.loadGameModule()

		if type(GameModule.init) == "function" then
			GameModule.init({
				gameKey = gameKey,
			})
		else
			warn(("HuajHub module '%s' is missing init(context)"):format(gameKey))
		end
	end

	return Bootstrap
end
