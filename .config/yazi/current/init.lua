-- yazi-current (id 1001): re-emite local hover/cd hacia yazi-preview (1002)
-- con kinds custom. Esto permite a yazi-preview filtrar y reaccionar SOLO
-- a este sender, ignorando a yazi-neotree (id 1003).
--
-- Why not just sub_remote("hover") in preview?
-- Porque sub_remote no recibe el sender en el callback (sólo body), y los
-- yazi-current/neotree comparten config; ambos emiten 'hover' al bus.
-- Forwardeamos con kind custom para tener un canal exclusivo.
--
-- Why GRS_DDS_TAG en el kind?
-- El broker yazi-dds es per-user (un solo socket en $XDG_RUNTIME_DIR), así
-- que dos zellij sessions con grs comparten bus y los kinds globales se
-- cruzarían. Tagging con la sesión zellij aísla cada layout.
--
-- Why read from cx instead of body.url?
-- EmberHover::owned y EmberCd::owned (yazi-dds/src/ember/) descartan la
-- URL cuando el evento se entrega LOCAL. Lives::scope inyecta `cx` como
-- global durante accept_payload, así que cx.active.current.{hovered,cwd}
-- nos da la URL real.

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
