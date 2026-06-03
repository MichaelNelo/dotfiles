-- yazi-neotree (id 1003): sidebar in the edit tab.
-- Listens for grs-reveal-<tag>: the opener in yazi-current publishes the
-- file it just sent to kak, and we reveal it here so the sidebar stays
-- in sync with the open buffer.

local tag = os.getenv("GRS_DDS_TAG") or "default"

ps.sub_remote("grs-reveal-" .. tag, function(body)
    if type(body) == "string" and #body > 0 then
        ya.emit("reveal", { body })
    end
end)
