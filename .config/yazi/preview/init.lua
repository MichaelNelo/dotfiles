-- yazi-preview (id 1002): follows ONLY events from yazi-current (id 1001),
-- via custom kinds tagged with GRS_DDS_TAG (zellij session).

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
