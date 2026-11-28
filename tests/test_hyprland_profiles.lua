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
local monitor_count = 0
local workspace_rules = {}
local env = setmetatable({
    hl = {
        monitor = function() monitor_count = monitor_count + 1 end,
        device = function() end,
        workspace_rule = function(rule) workspace_rules[#workspace_rules + 1] = rule end,
    },
    require = function(name) required[name] = true end,
}, { __index = _G })
assert(loadfile(root .. "hosts/pc.lua", "t", env))()
assert(required.autostart and required.workspaces and required.ipad and required.iphone)
assert(required["hosts.pc-window-rules"])
required = {}
monitor_count = 0
workspace_rules = {}
assert(loadfile(root .. "hosts/laptop.lua", "t", env))()
assert(next(required) == nil, "laptop profile must not load autostart")
assert(monitor_count == 0, "laptop profile must not configure external monitors")
assert(#workspace_rules == 2, "laptop profile must define two workspace rules")
local scrolling_workspaces = {}
for _, rule in ipairs(workspace_rules) do
    assert(rule.layout == "scrolling", "laptop workspace must use scrolling")
    assert(rule.monitor == nil, "laptop workspace must not be assigned to a monitor")
    scrolling_workspaces[rule.workspace] = true
end
assert(scrolling_workspaces["3"] and scrolling_workspaces["4"], "laptop workspaces 3 and 4 must use scrolling")

for _, case in ipairs({ { "archlinux", 6 }, { "gklaptop", 100 } }) do
    local groupbar
    local group_env = setmetatable({
        io = { open = function()
            return { read = function() return case[1] end, close = function() end }
        end },
        require = function() return {} end,
        hl = {
            config = function(config) groupbar = config.group.groupbar end,
            bind = function() end,
            dsp = {
                group = { toggle = function() end, next = function() end, prev = function() end, lock_active = function() end },
                window = { move = function() end },
            },
        },
    }, { __index = _G })
    assert(loadfile(root .. "groups.lua", "t", group_env))()
    assert(groupbar.priority == case[2], case[1])
end

local rules = {}
local rules_env = setmetatable({
    hl = { window_rule = function(rule) rules[rule.name] = rule end },
}, { __index = _G })
assert(loadfile(root .. "hosts/pc-window-rules.lua", "t", rules_env))()
assert(rules["rdr2-fullscreen"].fullscreen)
assert(source:find('hl.bind%("CTRL %+ SHIFT %+ 2"'))
print("Hyprland profile tests passed")
