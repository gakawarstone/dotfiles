hl.config({
    scrolling = {
        column_width = 0.5,
        direction = "right",
        explicit_column_widths = "0.5, 0.6, 1.0",
    },
})

local mainMod = "SUPER"

hl.bind(mainMod .. " + L", hl.dsp.layout("focus r"))
hl.bind(mainMod .. " + H", hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + Tab", hl.dsp.layout("focus r"))

hl.bind(mainMod .. " + SHIFT + L", hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.layout("swapcol l"))

hl.bind(mainMod .. " + R", hl.dsp.layout("colresize +conf"))
