hl.window_rule({
    name = "energy-meter-window",
    match = { class = "^org\\.quickshell$", title = "^Energy Meter$" },
    float = true,
    center = true,
    size = { 650, 670 },
    group = "barred",
})

hl.window_rule({
    name = "smart-gaps-borders-tv1",
    match = { workspace = "w[tv1]" },
    border_size = 0,
})

-- Hide the annoying close and minimize buttons in T3 Code.
hl.window_rule({
    name = "t3code-hide-window-controls",
    match = { class = "^t3code$" },
    fullscreen_state = "0 2",
})

hl.window_rule({
    name = "ignore-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "xwayland-nofocus",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
    },
    no_focus = true,
})

hl.window_rule({
    name = "full-width-agent-apps",
    match = { class = "^(herdr|t3code)$" },
    scrolling_width = 1.0,
})
