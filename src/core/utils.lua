local Utils = {}

function Utils.getPlaceId()
    return game.PlaceId
end

function Utils.safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    return ok, result
end

return Utils
