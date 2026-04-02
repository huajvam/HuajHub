local Services = {}
local cachedVirtualInputManager = getvirtualinputmanager and getvirtualinputmanager()

function Services:Get(...)
	local resolved = {}

	for _, serviceName in ipairs({...}) do
		table.insert(resolved, self[serviceName])
	end

	return table.unpack(resolved)
end

setmetatable(Services, {
	__index = function(self, key)
		if key == "VirtualInputManager" and cachedVirtualInputManager then
			rawset(self, key, cachedVirtualInputManager)
			return cachedVirtualInputManager
		end

		local service = game:GetService(key)
		rawset(self, key, service)
		return service
	end,
})

return Services
