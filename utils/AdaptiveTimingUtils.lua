local AdaptiveTimingUtils = {}

function AdaptiveTimingUtils.getAdaptiveAnimationKey(normalizeAnimationId, sourceKey, animationId, actionType)
	local normalizedAnimationId = type(normalizeAnimationId) == "function" and normalizeAnimationId(animationId) or animationId
	return string.format(
		"%s:%s:%s",
		tostring(sourceKey or "?"),
		tostring(normalizedAnimationId or animationId or "?"),
		tostring(actionType or "Parry")
	)
end

function AdaptiveTimingUtils.updateLearnedOffset(learnedOffsets, normalizeAnimationId, sourceKey, animationId, actionType, deltaMs, weight)
	local key = AdaptiveTimingUtils.getAdaptiveAnimationKey(normalizeAnimationId, sourceKey, animationId, actionType)
	local previous = tonumber(learnedOffsets[key]) or 0
	local appliedWeight = math.clamp(tonumber(weight) or 0.25, 0.05, 1)
	local clampedDeltaMs = math.clamp(tonumber(deltaMs) or 0, -120, 120)
	learnedOffsets[key] = math.clamp(previous + ((clampedDeltaMs - previous) * appliedWeight), -120, 120)
	return learnedOffsets[key]
end

function AdaptiveTimingUtils.getTimingOffsetMs(options)
	local manualOffsetMs = tonumber(options and options.manualOffsetMs) or 0
	if options and options.adaptiveEnabled ~= true then
		return math.clamp(manualOffsetMs, -120, 250)
	end

	local actionType = (options and options.actionType) or "Parry"
	local pingCorrectionMs = tonumber(options and options.pingCorrectionMs) or 0
	local actionBiasMs = tonumber(options and options.actionBiasMs) or 0
	local learnedOffsetMs = tonumber(options and options.learnedOffsetMs) or 0
	local distanceBiasMs = math.clamp(((tonumber(options and options.distance) or 0) - 8) * 1.5, -8, 18)

	return math.clamp(manualOffsetMs + pingCorrectionMs + actionBiasMs + learnedOffsetMs + distanceBiasMs, -120, 250)
end

return AdaptiveTimingUtils
