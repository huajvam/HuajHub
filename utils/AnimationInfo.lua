local Services = sharedRequire("@utils/Services.lua")

local MarketplaceService = Services:Get("MarketplaceService")

local AnimationInfo = {}
local animationNameCache = {}

function AnimationInfo.extractNumericId(value)
	return tostring(value or ""):match("%d+")
end

function AnimationInfo.normalizeId(animationId)
	if type(animationId) ~= "string" then
		animationId = tostring(animationId or "")
	end

	local digits = animationId:match("%d+")
	return digits or animationId
end

function AnimationInfo.getTrackName(track)
	if not track then
		return nil
	end

	local animation = track.Animation
	if animation and type(animation.Name) == "string" and animation.Name ~= "" and animation.Name ~= "Animation" then
		return animation.Name
	end

	if type(track.Name) == "string" and track.Name ~= "" and track.Name ~= "Animation" then
		return track.Name
	end

	return nil
end

function AnimationInfo.getAssetName(animationId)
	local normalizedAnimationId = AnimationInfo.extractNumericId(animationId)
	if not normalizedAnimationId then
		return nil
	end

	if animationNameCache[normalizedAnimationId] ~= nil then
		return animationNameCache[normalizedAnimationId] or nil
	end

	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(tonumber(normalizedAnimationId))
	end)

	if ok and type(info) == "table" and type(info.Name) == "string" then
		local resolvedName = info.Name:gsub("^%s+", ""):gsub("%s+$", "")
		if resolvedName ~= "" then
			animationNameCache[normalizedAnimationId] = resolvedName
			return resolvedName
		end
	end

	animationNameCache[normalizedAnimationId] = false
	return nil
end

function AnimationInfo.resolveDetectedName(animationId, track, fallbackName)
	return AnimationInfo.getAssetName(animationId)
		or AnimationInfo.getTrackName(track)
		or fallbackName
end

return AnimationInfo
