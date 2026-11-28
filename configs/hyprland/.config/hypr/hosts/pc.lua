hl.monitor({
    output = "HDMI-A-1",
    mode = "2560x1440@75",
    position = "2560x0",
    scale = 1,
})

hl.monitor({
    output = "DP-1",
    mode = "2560x1440@165",
    position = "0x0",
    scale = 1,
})

hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })
require("autostart")
require("workspaces")
require("ipad")
require("iphone")
require("hosts.pc-window-rules")
