-- yazi-current (id 1001): user-driven navigator in grs-explore.
-- Hover → publish to preview (1002) for cursor tracking.
-- cd    → fan out via yazi-cd-sync.sh (ya emit-to siblings + kak + lazygit).

local tag = os.getenv("GRS_DDS_TAG") or "default"
local hover_kind = "grs-hover-" .. tag

ps.sub("hover", function(_)
    local h = cx.active.current.hovered
    if h and h.url then
        ps.pub_to(1002, hover_kind, { url = tostring(h.url) })
    end
end)

ps.sub("cd", function(_)
    local cwd = cx.active.current.cwd
    if not cwd then return end
    os.execute(string.format(
        "bash ~/.config/zellij/scripts/yazi-cd-sync.sh %q 1001 &",
        tostring(cwd)))
end)
