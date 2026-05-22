-- yazi-neotree (id 1003): sidebar en la tab edit.
--
-- No emite eventos custom (yazi-preview sólo sigue a yazi-current vía
-- grs-{hover,cd}-from-1001), pero sí escucha grs-reveal-from-1001: el
-- opener de yazi-current publica el archivo que acaba de mandar a nvr,
-- y nosotros lo revelamos acá para que el sidebar quede sincronizado
-- con el buffer abierto.

ps.sub_remote("grs-reveal-from-1001", function(body)
    if type(body) == "string" and #body > 0 then
        ya.emit("reveal", { body })
    end
end)
