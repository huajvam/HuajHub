local TrackedAnimatorRegistry = {}
TrackedAnimatorRegistry.__index = TrackedAnimatorRegistry

function TrackedAnimatorRegistry.new(options)
	return setmetatable({
		targets = {},
		getAnimators = options and options.getAnimators,
		shouldTrackModel = options and options.shouldTrackModel,
		onAnimatorTrack = options and options.onAnimatorTrack,
		onAnimatorReady = options and options.onAnimatorReady,
	}, TrackedAnimatorRegistry)
end

function TrackedAnimatorRegistry:disconnectTarget(model)
	local trackedTarget = self.targets[model]
	if not trackedTarget then
		return
	end

	for _, connection in ipairs(trackedTarget.connections) do
		connection:Disconnect()
	end

	self.targets[model] = nil
end

function TrackedAnimatorRegistry:ensureAnimator(model, animator)
	local trackedTarget = self.targets[model]
	if not trackedTarget or not animator or trackedTarget.animators[animator] then
		return
	end

	trackedTarget.animators[animator] = true

	table.insert(trackedTarget.connections, animator.AnimationPlayed:Connect(function(track)
		if type(self.onAnimatorTrack) == "function" then
			self.onAnimatorTrack(model, animator, track)
		end
	end))

	if type(self.onAnimatorReady) == "function" then
		self.onAnimatorReady(model, animator)
	end
end

function TrackedAnimatorRegistry:trackTarget(model)
	if not model or not model:IsA("Model") or self.targets[model] then
		return
	end

	if type(self.shouldTrackModel) == "function" and not self.shouldTrackModel(model) then
		return
	end

	local trackedTarget = {
		model = model,
		animators = {},
		connections = {},
	}

	self.targets[model] = trackedTarget

	local getAnimators = self.getAnimators
	if type(getAnimators) == "function" then
		for _, animator in ipairs(getAnimators(model)) do
			self:ensureAnimator(model, animator)
		end
	end

	table.insert(trackedTarget.connections, model.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Animator") then
			self:ensureAnimator(model, descendant)
			return
		end

		if descendant:IsA("AnimationController") or descendant:IsA("Humanoid") then
			if type(getAnimators) == "function" then
				for _, animator in ipairs(getAnimators(model)) do
					self:ensureAnimator(model, animator)
				end
			end
		end
	end))

	table.insert(trackedTarget.connections, model.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			self:disconnectTarget(model)
		end
	end))
end

function TrackedAnimatorRegistry:refresh(liveFolder)
	if not liveFolder then
		return nil
	end

	for _, model in ipairs(liveFolder:GetChildren()) do
		self:trackTarget(model)
	end

	return liveFolder
end

function TrackedAnimatorRegistry:destroy()
	for model in pairs(self.targets) do
		self:disconnectTarget(model)
	end
end

return TrackedAnimatorRegistry
