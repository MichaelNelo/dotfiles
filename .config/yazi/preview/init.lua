-- yazi-preview (id 1002): cursor tracks yazi-current via DDS hover.
-- Directory sync happens via `ya emit-to 1002 cd …` from yazi-cd-sync.sh —
-- the local cd fires but there's no local `cd` sub, so no rebroadcast.

local tag = os.getenv("GRS_DDS_TAG") or "default"

ps.sub_remote("grs-hover-" .. tag, function(body)
    if body and body.url then
        ya.emit("reveal", { body.url })
    end
end)
