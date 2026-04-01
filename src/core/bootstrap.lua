return function()
    local Registry = loadfile("src/core/registry.lua")()
    local Utils = loadfile("src/core/utils.lua")()

    local Bootstrap = {}

    local function requireModule(path)
        return loadfile(path)()
    end

    local function resolveGameKey()
        return Registry.Places[Utils.getPlaceId()] or Registry.DefaultGame
    end

    function Bootstrap.start()
        local gameKey = resolveGameKey()

        local SharedUI = requireModule("src/shared/ui.lua")
        local Notifications = requireModule("src/shared/notifications.lua")

        local AutoParry = requireModule("src/features/autoparry/init.lua")
        local ESP = requireModule("src/features/esp/init.lua")
        local Movement = requireModule("src/features/movement/init.lua")

        local GameModule = requireModule(("src/games/%s/init.lua"):format(gameKey))

        local context = {
            gameKey = gameKey,
            ui = SharedUI,
            notify = Notifications,
            features = {
                autoparry = AutoParry,
                esp = ESP,
                movement = Movement,
            },
        }

        if type(GameModule.init) == "function" then
            GameModule.init(context)
        end

        Notifications.info("Loaded game module: " .. gameKey)
    end

    return Bootstrap
end
