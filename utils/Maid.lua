local Maid = {}
Maid.ClassName = "Maid"
Maid.__index = Maid

function Maid.new()
	return setmetatable({
		_tasks = {},
	}, Maid)
end

function Maid.isMaid(value)
	return type(value) == "table" and value.ClassName == "Maid"
end

function Maid:__newindex(index, newTask)
	if Maid[index] ~= nil then
		rawset(self, index, newTask)
		return
	end

	local tasks = rawget(self, "_tasks")
	local oldTask = tasks[index]

	if oldTask == newTask then
		return
	end

	tasks[index] = newTask

	if oldTask then
		if type(oldTask) == "function" then
			oldTask()
		elseif typeof(oldTask) == "RBXScriptConnection" then
			oldTask:Disconnect()
		elseif typeof(oldTask) == "thread" then
			task.cancel(oldTask)
		elseif type(oldTask) == "table" and type(oldTask.Remove) == "function" then
			oldTask:Remove()
		elseif type(oldTask) == "table" and type(oldTask.Destroy) == "function" then
			oldTask:Destroy()
		end
	end
end

function Maid:GiveTask(taskToTrack)
	if taskToTrack == nil then
		error("Task cannot be nil", 2)
	end

	local taskId = #self._tasks + 1
	self[taskId] = taskToTrack
	return taskId
end

function Maid:DoCleaning()
	local tasks = self._tasks

	for index, taskToCleanup in pairs(tasks) do
		tasks[index] = nil

		if typeof(taskToCleanup) == "RBXScriptConnection" then
			taskToCleanup:Disconnect()
		elseif typeof(taskToCleanup) == "thread" then
			task.cancel(taskToCleanup)
		elseif type(taskToCleanup) == "function" then
			taskToCleanup()
		elseif type(taskToCleanup) == "table" and type(taskToCleanup.Remove) == "function" then
			taskToCleanup:Remove()
		elseif type(taskToCleanup) == "table" and type(taskToCleanup.Destroy) == "function" then
			taskToCleanup:Destroy()
		end
	end
end

Maid.Destroy = Maid.DoCleaning

return Maid
