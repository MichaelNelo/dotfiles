-- yazi-preview (id 1002): sigue SOLO los eventos de yazi-current (id 1001),
-- vía kinds custom tagueados con GRS_DDS_TAG (zellij session). yazi-neotree
-- (1003) no re-emite estos kinds, así que no nos afecta cuando el usuario
-- está en la tab edit. El tag aísla además sesiones zellij distintas que
-- comparten el broker yazi-dds per-user.

local tag = os.getenv("GRS_DDS_TAG") or "default"

ps.sub_remote("grs-hover-" .. tag, function(body)
    if body and body.url then
        ya.emit("reveal", { body.url })
    end
end)

ps.sub_remote("grs-cd-" .. tag, function(body)
    if body and body.url then
        ya.emit("cd", { body.url })
    end
end)
