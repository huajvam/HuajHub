local MashleAcademy = {}

function MashleAcademy.init(context)
	warn("HuajHub loaded: Mashle Academy")

	if context.features.movement and type(context.features.movement.init) == "function" then
		context.features.movement.init(context, MashleAcademy)
	end

	if context.features.esp and type(context.features.esp.init) == "function" then
		context.features.esp.init(context, MashleAcademy)
	end

	if context.features.autoparry and type(context.features.autoparry.init) == "function" then
		context.features.autoparry.init(context, MashleAcademy)
	end
end

return MashleAcademy
