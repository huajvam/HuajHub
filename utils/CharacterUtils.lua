local CharacterUtils = {}

function CharacterUtils.getRoot(character)
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
end

function CharacterUtils.getHumanoid(character)
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

function CharacterUtils.getHorizontalModelRadius(model)
	if not model or not model:IsA("Model") then
		return 0
	end

	local ok, size = pcall(function()
		return model:GetExtentsSize()
	end)

	if ok and typeof(size) == "Vector3" then
		return math.max(size.X, size.Z) * 0.5
	end

	local root = CharacterUtils.getRoot(model)
	if root and root:IsA("BasePart") then
		return math.max(root.Size.X, root.Size.Z) * 0.5
	end

	return 0
end

function CharacterUtils.getHorizontalEdgeDistance(sourceCharacter, targetCharacter)
	local sourceRoot = CharacterUtils.getRoot(sourceCharacter)
	local targetRoot = CharacterUtils.getRoot(targetCharacter)
	if not sourceRoot or not targetRoot then
		return math.huge
	end

	local sourcePosition = Vector2.new(sourceRoot.Position.X, sourceRoot.Position.Z)
	local targetPosition = Vector2.new(targetRoot.Position.X, targetRoot.Position.Z)
	local centerDistance = (targetPosition - sourcePosition).Magnitude
	local sourceRadius = CharacterUtils.getHorizontalModelRadius(sourceCharacter)
	local targetRadius = CharacterUtils.getHorizontalModelRadius(targetCharacter)

	return math.max(centerDistance - sourceRadius - targetRadius, 0)
end

function CharacterUtils.getLiveFolder()
	return workspace:FindFirstChild("Live")
end

return CharacterUtils
