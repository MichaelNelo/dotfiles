-- yazi-neotree (id 1003): sync bidireccional con current (1001) + listener
-- de grs-reveal-<tag> (el opener de current lo usa para hovear el archivo
-- abierto). Echo guard URL-match igual que current.

local tag = os.getenv("GRS_DDS_TAG") or "default"
local hover_kind = "grs-hover-" .. tag
local cd_kind = "grs-cd-" .. tag

local skip_hover_url = nil
local skip_cd_url = nil

ps.sub_remote("grs-reveal-" .. tag, function(body)
    if type(body) == "string" and #body > 0 then
        -- reveal dispara cd al dirname + hover al file: guardamos ambos.
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
