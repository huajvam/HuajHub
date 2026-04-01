local Notifications = {}

function Notifications.info(message)
    warn("[HuajHub] " .. tostring(message))
end

return Notifications
