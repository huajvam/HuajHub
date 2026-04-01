local MashleAcademy = {}

function MashleAcademy.init(context)
    context.notify.info("Mashle Academy module loaded")

    context.features.autoparry.init(context, MashleAcademy)
    context.features.esp.init(context, MashleAcademy)
    context.features.movement.init(context, MashleAcademy)
end

return MashleAcademy
