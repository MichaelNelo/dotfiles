-- yazi-preview (id 1002): sigue SOLO los eventos de yazi-current (id 1001),
-- vía kinds custom. yazi-neotree (1003) no re-emite estos kinds, así que
-- no nos afecta cuando el usuario está en la tab edit.

ps.sub_remote("grs-hover-from-1001", function(body)
    if body and body.url then
        ya.emit("reveal", { body.url })
    end
end)

ps.sub_remote("grs-cd-from-1001", function(body)
    if body and body.url then
        ya.emit("cd", { body.url })
    end
end)
