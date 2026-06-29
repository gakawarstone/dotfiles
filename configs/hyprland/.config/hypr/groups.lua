local theme = require("theme")
local mainMod = "SUPER"

hl.config({
    group = {
        col = {
            border_active = { colors = { theme.mauve, theme.blue }, angle = 45 },
            border_inactive = theme.surface1,
        },

        groupbar = {
            enabled = true,
            font_family = "MonaspiceKr Nerd Font",
            font_size = 12,
            gradients = true,
            height = 24,
            priority = 100,
            render_titles = true,
            gradient_rounding = 10,
            scrolling = true,
            text_color = theme.text,
            text_padding = 10,
            indicator_height = 0,
            gaps_in = 4,
            gaps_out = 5,
            keep_upper_gap = false,
            round_only_edges = false,

            col = {
                active = theme.surface2,
                inactive = theme.surface0,
                locked_active = theme.surface2,
                locked_inactive = theme.surface0,
            },
        },
    },
})

hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.window.move({ out_of_group = true }))

hl.bind("ALT + Tab", hl.dsp.group.next())
hl.bind("ALT + SHIFT + Tab", hl.dsp.group.prev())

hl.bind(mainMod .. " + I", hl.dsp.group.lock_active({ action = "toggle" }))
