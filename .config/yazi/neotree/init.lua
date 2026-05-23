-- yazi-neotree (id 1003): sidebar en la tab edit.
--
-- No emite eventos custom (yazi-preview sólo sigue a yazi-current vía
-- grs-{hover,cd}-<tag>), pero sí escucha grs-reveal-<tag>: el opener de
-- yazi-current publica el archivo que acaba de mandar a nvr, y nosotros
-- lo revelamos acá para que el sidebar quede sincronizado con el buffer
-- abierto. El tag (GRS_DDS_TAG) aísla este canal entre sesiones zellij.

local tag = os.getenv("GRS_DDS_TAG") or "default"

ps.sub_remote("grs-reveal-" .. tag, function(body)
    if type(body) == "string" and #body > 0 then
        ya.emit("reveal", { body })
    end
end)
