local function config_dir()
    local source = debug.getinfo(1, "S").source
    if source:sub(1, 1) == "@" then
        return source:sub(2):match("(.*/)")
    end
    return os.getenv("HOME") .. "/.config/hypr/"
end

local function active_theme()
    local handle = io.popen("readlink " .. config_dir() .. "theme.conf 2>/dev/null")
    if not handle then
        return "latte"
    end

    local target = handle:read("*l") or ""
    handle:close()

    if target:find("mocha", 1, true) then
        return "mocha"
    end

    return "latte"
end

return require(active_theme())
