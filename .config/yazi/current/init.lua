-- yazi-current (id 1001): re-emits local hover/cd to yazi-preview (1002)
-- with custom kinds. This lets yazi-preview filter and react ONLY to this
-- sender, ignoring yazi-neotree (id 1003).

local fifo = os.getenv("GRS_CWD_FIFO")
local tag = os.getenv("GRS_DDS_TAG") or "default"
local hover_kind = "grs-hover-" .. tag
local cd_kind = "grs-cd-" .. tag

ps.sub("hover", function(_)
    local h = cx.active.current.hovered
    if h and h.url then
        ps.pub_to(1002, hover_kind, { url = tostring(h.url) })
    end
end)

ps.sub("cd", function(_)
    local cwd = cx.active.current.cwd
    if cwd then
        local url = tostring(cwd)
        ps.pub_to(1002, cd_kind, { url = url })
        if fifo and #fifo > 0 then
            os.execute(string.format("printf '%%s\\n' %q >> %q &", url, fifo))
        end
    end
end)
