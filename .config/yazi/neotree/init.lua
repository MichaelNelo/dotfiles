-- yazi-neotree (id 1003): sidebar in grs-edit.
-- Reveals files that yazi-current just opened, and mirrors user
-- navigation via yazi-cd-sync.sh (broadcasts cd to siblings + kak + lazygit).

local tag = os.getenv("GRS_DDS_TAG") or "default"

ps.sub_remote("grs-reveal-" .. tag, function(body)
    if type(body) == "string" and #body > 0 then
        ya.emit("reveal", { body })
    end
end)

ps.sub("cd", function(_)
    local cwd = cx.active.current.cwd
    if not cwd then return end
    os.execute(string.format(
        "bash ~/.config/zellij/scripts/yazi-cd-sync.sh %q 1003 &",
        tostring(cwd)))
end)
