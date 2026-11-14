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
