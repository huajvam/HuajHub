local AutoParryConfigUtils = {}

function AutoParryConfigUtils.getConfigActionType(configData)
	if type(configData) ~= "table" then
		return "Parry"
	end

	if configData.actionType == "Dash" or configData.actionType == "Block" or configData.actionType == "Parry" or configData.actionType == "Jump" then
		return configData.actionType
	end

	if configData.block == true then
		return "Block"
	end

	if configData.jump == true then
		return "Jump"
	end

	if configData.roll == true or configData.dash == true then
		return "Dash"
	end

	return "Parry"
end

function AutoParryConfigUtils.buildRuntimeMoveConfig(configData, getConfigActionType)
	local resolveActionType = type(getConfigActionType) == "function" and getConfigActionType or AutoParryConfigUtils.getConfigActionType
	local actionType = resolveActionType(configData)

	return {
		timing = tonumber(configData.wait) or 0,
		dash = actionType == "Dash",
		block = actionType == "Block",
		jump = actionType == "Jump",
		repeatAmount = math.max(1, math.floor(tonumber(configData.repeatAmount) or 1)),
		repeatDelay = tonumber(configData.repeatDelay) or 0,
		delay = configData.delay == true,
		delayRange = tonumber(configData.delayRange) or 0,
		range = tonumber(configData.range) or 16,
		nickname = configData.nickname or "",
		actionType = actionType,
	}
end

function AutoParryConfigUtils.normalizeMoveConfig(moveConfig, candidateDistance, selectBestMoveConfig)
	if type(moveConfig) == "number" then
		return {
			timing = moveConfig,
			dash = false,
			block = false,
			handler = nil,
			repeatAmount = 1,
			repeatDelay = 0,
			delay = false,
			delayRange = 0,
			range = nil,
		}
	end

	if type(moveConfig) == "function" then
		return {
			timing = nil,
			dash = false,
			block = false,
			handler = moveConfig,
			repeatAmount = 1,
			repeatDelay = 0,
			delay = false,
			delayRange = 0,
			range = nil,
		}
	end

	if type(moveConfig) == "table" then
		if type(moveConfig.entries) == "table" then
			if type(selectBestMoveConfig) ~= "function" then
				return nil
			end

			return selectBestMoveConfig(moveConfig.entries, tonumber(candidateDistance) or math.huge)
		end

		return {
			timing = moveConfig.timing,
			dash = moveConfig.dash == true,
			block = moveConfig.block == true,
			jump = moveConfig.jump == true,
			handler = type(moveConfig.handler) == "function" and moveConfig.handler or nil,
			repeatAmount = math.max(1, math.floor(tonumber(moveConfig.repeatAmount) or 1)),
			repeatDelay = tonumber(moveConfig.repeatDelay) or 0,
			delay = moveConfig.delay == true,
			delayRange = tonumber(moveConfig.delayRange) or 0,
			range = tonumber(moveConfig.range) or nil,
			nickname = moveConfig.nickname or "",
			actionType = moveConfig.actionType,
		}
	end

	return nil
end

function AutoParryConfigUtils.resolveConfiguredTiming(moveConfig)
	local numericTiming = tonumber(moveConfig and moveConfig.timing)
	if not numericTiming then
		return nil
	end

	if numericTiming > 10 then
		return numericTiming / 1000
	end

	return numericTiming
end

function AutoParryConfigUtils.getMoveConfigRange(moveConfig, defaultRange)
	local configRange = tonumber(moveConfig and moveConfig.range)
	if configRange and configRange > 0 then
		return configRange
	end

	return defaultRange or 18
end

function AutoParryConfigUtils.getMoveConfigDelaySeconds(moveConfig)
	local shouldDelay = moveConfig and moveConfig.delay == true
	if not shouldDelay then
		return 0
	end

	local delayRange = math.max(tonumber(moveConfig.delayRange) or 0, 0)
	if delayRange <= 0 then
		return 0
	end

	if delayRange > 10 then
		delayRange = delayRange / 1000
	end

	return math.random() * delayRange
end

function AutoParryConfigUtils.getMoveConfigRepeatDelaySeconds(moveConfig)
	local repeatDelay = math.max(tonumber(moveConfig and moveConfig.repeatDelay) or 0, 0)
	if repeatDelay > 10 then
		return repeatDelay / 1000
	end

	return repeatDelay
end

return AutoParryConfigUtils
