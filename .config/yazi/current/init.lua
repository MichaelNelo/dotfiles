-- yazi-current (id 1001): publica hover/cd a preview (1002) y neotree (1003);
-- aplica los hover/cd que recibe de neotree (sync bidireccional).
-- Echo guard URL-match: descarta el primer local que matchee el remote aplicado.

local fifo = os.getenv("GRS_CWD_FIFO")
local tag = os.getenv("GRS_DDS_TAG") or "default"
local hover_kind = "grs-hover-" .. tag
local cd_kind = "grs-cd-" .. tag

local skip_hover_url = nil
local skip_cd_url = nil

-- cx.active.current.hovered (no body.url): EmberHover::owned descarta la URL
-- cuando el evento se entrega LOCAL.
ps.sub("hover", function(_)
    local h = cx.active.current.hovered
    if h and h.url then
        local u = tostring(h.url)
        if u == skip_hover_url then
            skip_hover_url = nil
            return
        end
        ps.pub_to(1002, hover_kind, { url = u })
        ps.pub_to(1003, hover_kind, { url = u })
    end
end)

ps.sub("cd", function(_)
    local cwd = cx.active.current.cwd
    if cwd then
        local url = tostring(cwd)
        -- lazygit fifo: write SIEMPRE, también para cds que vienen de neotree.
        if fifo and #fifo > 0 then
            os.execute(string.format("printf '%%s\\n' %q >> %q &", url, fifo))
        end
        if url == skip_cd_url then
            skip_cd_url = nil
            return
        end
        ps.pub_to(1002, cd_kind, { url = url })
        ps.pub_to(1003, cd_kind, { url = url })
    end
end)

ps.sub_remote(hover_kind, function(body)
    if body and body.url then
        skip_hover_url = tostring(body.url)
        ya.emit("reveal", { body.url })
    end
end)

ps.sub_remote(cd_kind, function(body)
    if body and body.url then
        skip_cd_url = tostring(body.url)
        ya.emit("cd", { body.url })
    end
end)
