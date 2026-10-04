-- iPhone 16. Keep the selected orientation across Hyprland config reloads.
local orientation = "sideways"
local runtimeDir = os.getenv("XDG_RUNTIME_DIR")
local state = runtimeDir and io.open(runtimeDir .. "/iphone-screen.orientation", "r")
if state then
    orientation = state:read("*l") or orientation
    state:close()
end

hl.monitor({
    output = "IPHONE",
    mode = orientation == "portrait" and "1179x2556@60" or "2556x1179@60",
    position = "6300x0",
    scale = 3,
    -- Sunshine streams the unrotated 2556x1179 buffer, while Hyprland arranges
    -- windows on a portrait desktop. This works with landscape-only Moonlight.
    transform = orientation == "sideways" and 1 or 0,
})

hl.workspace_rule({
    workspace = "6",
    monitor = "IPHONE",
    default = true,
    layout = "scrolling",
    gaps_in = 0,
    gaps_out = 0,
    border_size = 0,
    decorate = false,
})
