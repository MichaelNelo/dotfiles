-- yazi-current (id 1001): primary navigator. Forwardea hover/cd hacia
-- yazi-preview (1002) y yazi-neotree (1003), y aplica los hover/cd que
-- recibe desde neotree, manteniendo sync bidireccional.
--
-- Why GRS_DDS_TAG en el kind?
-- El broker yazi-dds es per-user (un solo socket en $XDG_RUNTIME_DIR), así
-- que dos zellij sessions con grs comparten bus y los kinds globales se
-- cruzarían. Tagging con la sesión zellij aísla cada layout.
--
-- Why read from cx instead of body.url?
-- EmberHover::owned y EmberCd::owned descartan la URL cuando el evento se
-- entrega LOCAL. Lives::scope inyecta `cx` como global durante accept_payload,
-- así que cx.active.current.{hovered,cwd} nos da la URL real.
--
-- Echo guard:
-- Tras recibir un hover/cd remoto y aplicarlo con ya.emit, el evento local
-- resultante se publicaría de vuelta al sender y entraríamos en loop.
-- Guardamos la URL aplicada y descartamos el primer evento local que matchee.
-- Si el ya.emit no dispara local (porque ya estábamos ahí), el guard queda
-- stale; a lo sumo perdemos un publish del próximo manual move a esa URL.

local fifo = os.getenv("GRS_CWD_FIFO")
local tag = os.getenv("GRS_DDS_TAG") or "default"
local hover_kind = "grs-hover-" .. tag
local cd_kind = "grs-cd-" .. tag

local skip_hover_url = nil
local skip_cd_url = nil

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
        -- lazygit follow: write to fifo SIEMPRE, así también sigue cds
        -- originados en neotree (que llegan acá vía sub_remote más abajo).
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
