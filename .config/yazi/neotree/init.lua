-- yazi-neotree (id 1003): sidebar en la tab edit. Bidireccionalmente
-- sincronizado con yazi-current (1001) — forwardea hover/cd locales hacia
-- 1001 y 1002 (preview), y aplica los recibidos desde current. Además
-- conserva el listener original de grs-reveal-<tag>, que el opener de
-- yazi-current usa para que el sidebar haga reveal sobre el archivo abierto
-- (cd al dirname + hover del file).
--
-- Echo guard: idem yazi-current — tras aplicar un evento remoto, descarta el
-- primer evento local que matchee la URL para no rebotar al sender.

local tag = os.getenv("GRS_DDS_TAG") or "default"
local hover_kind = "grs-hover-" .. tag
local cd_kind = "grs-cd-" .. tag

local skip_hover_url = nil
local skip_cd_url = nil

ps.sub_remote("grs-reveal-" .. tag, function(body)
    if type(body) == "string" and #body > 0 then
        -- reveal cd al dirname y hovea el file: guardamos ambos echoes.
        skip_hover_url = body
        skip_cd_url = body:gsub("/[^/]*$", "")
        ya.emit("reveal", { body })
    end
end)

ps.sub("hover", function(_)
    local h = cx.active.current.hovered
    if h and h.url then
        local u = tostring(h.url)
        if u == skip_hover_url then
            skip_hover_url = nil
            return
        end
        ps.pub_to(1001, hover_kind, { url = u })
        ps.pub_to(1002, hover_kind, { url = u })
    end
end)

ps.sub("cd", function(_)
    local cwd = cx.active.current.cwd
    if cwd then
        local url = tostring(cwd)
        if url == skip_cd_url then
            skip_cd_url = nil
            return
        end
        ps.pub_to(1001, cd_kind, { url = url })
        ps.pub_to(1002, cd_kind, { url = url })
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
