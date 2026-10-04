-- iPad Air M2 11-inch, to the right of the two desktop monitors.
hl.monitor({
    output = "IPAD",
    mode = "2360x1640@60",
    position = "5120x0",
    scale = 2,
})

hl.workspace_rule({
    workspace = "5",
    monitor = "IPAD",
    default = true,
    layout = "scrolling",
})
