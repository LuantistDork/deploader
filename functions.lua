
-- util function for checking if file exists
local function file_exists(name)
    local f = io.open(name, "r")
    
    if f == nil then return false end

    io.close(f)
    return true
end

local function get_optonal_depends(mod_name)
    local file = io.open(core.get_modpath(mod_name) .. "/mod.conf", "r")

    local dependencies = {}

    dependencies[mod_name] = true

    if not file then return dependencies end

    local content = file:read("*all")
    io.close(file)

    local line = string.match(content, "optional_depends%s=[^\n]*")
    line = string.gsub(line, "optional_depends%s=", "")

    for dependency in string.gmatch(line, "[a-z0-9_]+") do
        dependencies[dependency] = true
    end

    return dependencies
end

local function load_mods(path)
    local this_mod = core.get_current_modname()
    local this_optional_depends = get_optonal_depends(this_mod)
    local undocumented_depends = {}

    for _, mod_name in ipairs(core.get_modnames()) do
        local init_path = path .. "/" .. mod_name .. "/init.lua"

        if file_exists(init_path) then
            -- catch when mod.conf doesn't include an optional dependency
            if not this_optional_depends[mod_name] then table.insert(undocumented_depends, mod_name) end

            core.log("info", string.format("[%s] loading optional dependency script for %s", this_mod, mod_name))
            optional_depends.current_path = path .. "/" .. mod_name
            dofile(init_path)
        end
    end

    optional_depends.current_path = nil

    for mod_name, _ in ipairs(this_optional_depends) do
        local init_path = path .. "/" .. mod_name .. "/init.lua"
        if not file_exists(init_path) then
            core.log("warning", string.format("[%s] unused optional dependency: %s (consider removing from your mod.conf)", this_mod, mod_name))
        end
    end

    if #undocumented_depends > 0 then
        error(string.format("add %s to the optional_depends in your mod.conf", table.concat(undocumented_depends, ", ")))
    end
end

local function load_game(path)
    local this_mod = core.get_current_modname()
    local game_info = core.get_game_info()

    if game_info.id then
        local init_path = path .. "/" .. game_info.id .. "/init.lua"

        if file_exists(init_path) then
            core.log("info", string.format("[%s] loading game specific script for %s", this_mod, game_info.id))
            optional_depends.current_path = path .. "/" .. game_info.id
            dofile(init_path)
        end
    end

    optional_depends.current_path = nil
end

local function handle_params_table(params)
    local temp = {
        mods_path = "/optional_depends",
        games_path = "/game_specific"
    }

    if not params then return temp end

    for key, value in pairs(params) do temp[key] = value end

    return temp
end

function optional_depends.include(params)
    local mod_name = core.get_current_modname()
    local path = optional_depends.current_path or core.get_modpath(mod_name)
    local params = handle_params_table(params)

    load_mods(path .. params.mods_path)
    load_game(path .. params.games_path)
end