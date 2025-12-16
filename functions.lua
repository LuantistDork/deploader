
-- util function for checking if file exists
local function file_exists(name)
    local f = io.open(name,"r")
    
    if f == nil then return false end

    io.close(f)
    return true
end

local function load_mods(path)
    local this_mod = core.get_current_modname()
    for _, mod_name in ipairs(core.get_modnames()) do
        local init_path = path .. "/" .. mod_name .. "/init.lua"

        if file_exists(src) then
            core.log("info", string.format("[%s] loading optional dependency script for %s", this_mod, mod_name))
            optional_depends.current_path = path .. "/" .. mod_name
            dofile(init_path)
        end
    end

    optional_depends.current_path = nil
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
        mods_path = "/optional_dependencies",
        games_path = "/game_specific"
    }

    for key, value in pairs(params) do temp[key] = value end

    return temp
end

function optional_depends.include(params)
    local mod_name = core.get_current_modname()
    local mod_path = core.get_modpath(mod_name)
    local params = handle_params_table(params)

    load_mods(mod_path .. params.mods_path)
    load_game(mod_path .. params.games_path)
end