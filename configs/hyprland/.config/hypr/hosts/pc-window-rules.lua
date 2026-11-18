hl.window_rule({
    name = "zen-no-auto-group",
    match = { class = "^zen$" },
    group = "barred",
})

hl.window_rule({
    name = "legcord-workspace",
    match = { class = "^legcord$" },
    workspace = "2 silent",
    group = "barred",
})

hl.window_rule({
    name = "rdr2-fullscreen",
    match = {
        class = "^(steam_app_1174180|RDR2\\.exe)$",
        title = "^Red Dead Redemption 2$",
    },
    fullscreen = true,
})
