local EntityESP = {}
EntityESP.__index = EntityESP

local function safeRemoveDrawing(object)
	if not object then
		return
	end

	pcall(function()
		object.Visible = false
	end)

	pcall(function()
		if type(object.Remove) == "function" then
			object:Remove()
			return
		end
	end)

	pcall(function()
		if type(object.Destroy) == "function" then
			object:Destroy()
		end
	end)
end

function EntityESP.createDrawing(registry, className, properties, shuttingDownFlag)
	if shuttingDownFlag and shuttingDownFlag() then
		return nil
	end

	local object = Drawing.new(className)
	for key, value in pairs(properties or {}) do
		object[key] = value
	end

	table.insert(registry, object)
	return object
end

function EntityESP.new(registry, accentColor, shuttingDownFlag)
	local self = setmetatable({
		objects = {},
		boxLines = {},
		skeletonLines = {},
	}, EntityESP)

	for index = 1, 4 do
		self.boxLines[index] = EntityESP.createDrawing(registry, "Line", {
			Thickness = 1.5,
			Transparency = 1,
			Color = accentColor,
			Visible = false,
		}, shuttingDownFlag)
		table.insert(self.objects, self.boxLines[index])
	end

	self.healthBarOutline = EntityESP.createDrawing(registry, "Square", {
		Filled = false,
		Thickness = 1,
		Transparency = 1,
		Color = Color3.fromRGB(20, 20, 20),
		Visible = false,
	}, shuttingDownFlag)
	table.insert(self.objects, self.healthBarOutline)

	self.healthBarFill = EntityESP.createDrawing(registry, "Square", {
		Filled = true,
		Thickness = 1,
		Transparency = 1,
		Color = Color3.fromRGB(80, 255, 120),
		Visible = false,
	}, shuttingDownFlag)
	table.insert(self.objects, self.healthBarFill)

	self.nameText = EntityESP.createDrawing(registry, "Text", {
		Center = true,
		Outline = true,
		Size = 13,
		Font = 2,
		Transparency = 1,
		Color = Color3.fromRGB(255, 255, 255),
		Visible = false,
	}, shuttingDownFlag)
	table.insert(self.objects, self.nameText)

	self.distanceText = EntityESP.createDrawing(registry, "Text", {
		Center = true,
		Outline = true,
		Size = 13,
		Font = 2,
		Transparency = 1,
		Color = Color3.fromRGB(205, 205, 205),
		Visible = false,
	}, shuttingDownFlag)
	table.insert(self.objects, self.distanceText)

	self.healthText = EntityESP.createDrawing(registry, "Text", {
		Center = true,
		Outline = true,
		Size = 13,
		Font = 2,
		Transparency = 1,
		Color = Color3.fromRGB(150, 255, 150),
		Visible = false,
	}, shuttingDownFlag)
	table.insert(self.objects, self.healthText)

	self.tracerLine = EntityESP.createDrawing(registry, "Line", {
		Thickness = 1.25,
		Transparency = 1,
		Color = accentColor,
		Visible = false,
	}, shuttingDownFlag)
	table.insert(self.objects, self.tracerLine)

	for index = 1, 20 do
		self.skeletonLines[index] = EntityESP.createDrawing(registry, "Line", {
			Thickness = 1,
			Transparency = 1,
			Color = accentColor,
			Visible = false,
		}, shuttingDownFlag)
		table.insert(self.objects, self.skeletonLines[index])
	end

	return self
end

function EntityESP:setAccentColor(accentColor)
	for _, line in ipairs(self.boxLines) do
		if line then
			line.Color = accentColor
		end
	end

	for _, line in ipairs(self.skeletonLines) do
		if line then
			line.Color = accentColor
		end
	end

	if self.tracerLine then
		self.tracerLine.Color = accentColor
	end
end

function EntityESP:hide()
	for _, line in ipairs(self.boxLines) do
		if line then
			line.Visible = false
		end
	end
	for _, line in ipairs(self.skeletonLines) do
		if line then
			line.Visible = false
		end
	end
	if self.healthBarOutline then
		self.healthBarOutline.Visible = false
	end
	if self.healthBarFill then
		self.healthBarFill.Visible = false
	end
	if self.nameText then
		self.nameText.Visible = false
	end
	if self.distanceText then
		self.distanceText.Visible = false
	end
	if self.healthText then
		self.healthText.Visible = false
	end
	if self.tracerLine then
		self.tracerLine.Visible = false
	end
end

function EntityESP:Destroy()
	self:hide()

	for _, object in ipairs(self.objects) do
		safeRemoveDrawing(object)
	end
end

return EntityESP
