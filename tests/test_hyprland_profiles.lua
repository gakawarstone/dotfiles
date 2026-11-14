local root = "configs/hyprland/.config/hypr/"
local file = assert(io.open(root .. "hyprland.lua"))
local source = file:read("*a")
file:close()
local selection = assert(source:match('^(.-)hl.env%("XCURSOR_SIZE"'))

for _, case in ipairs({
    { "archlinux", "hosts.pc" },
    { "gklaptop", "hosts.laptop" },
    { "unknown", false },
}) do
    local required = {}
    local env = setmetatable({
        io = { open = function()
            return { read = function() return case[1] end, close = function() end }
        end },
        require = function(name)
            required[#required + 1] = name
            return {}
        end,
    }, { __index = _G })
    assert(load(selection, "hyprland", "t", env))()
    assert(required[3] == (case[2] or nil), case[1])
    assert(#required == (case[2] and 3 or 2), case[1])
end

local required = {}
local env = setmetatable({
    hl = { monitor = function() end, device = function() end },
    require = function(name) required[name] = true end,
}, { __index = _G })
assert(loadfile(root .. "hosts/pc.lua", "t", env))()
assert(required.autostart and required.workspaces and required.ipad and required.iphone)
required = {}
assert(loadfile(root .. "hosts/laptop.lua", "t", env))()
assert(next(required) == nil, "laptop profile must not load autostart")
print("Hyprland profile tests passed")
