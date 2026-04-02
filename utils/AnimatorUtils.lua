local CharacterUtils = sharedRequire("@utils/CharacterUtils.lua")

local AnimatorUtils = {}

function AnimatorUtils.getPrimaryAnimator(targetCharacter)
	if not targetCharacter then
		return nil
	end

	local humanoid = CharacterUtils.getHumanoid(targetCharacter)
	if humanoid then
		local humanoidAnimator = humanoid:FindFirstChildOfClass("Animator")
		if humanoidAnimator then
			return humanoidAnimator
		end
	end

	return targetCharacter:FindFirstChildWhichIsA("Animator", true)
end

function AnimatorUtils.getAllAnimators(targetCharacter)
	if not targetCharacter then
		return {}
	end

	local animators = {}
	local seenAnimators = {}

	for _, descendant in ipairs(targetCharacter:GetDescendants()) do
		if descendant:IsA("Animator") and not seenAnimators[descendant] then
			seenAnimators[descendant] = true
			table.insert(animators, descendant)
		end
	end

	return animators
end

return AnimatorUtils
