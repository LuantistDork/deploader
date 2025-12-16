-- gets the hard and soft dependencies from mod.conf
---@param mod_name string the name of the mod
---@return table the hard dependencies of the mod (depends in the mod.conf)
---@return table the soft dependencies of the mod (optional_depends in the mod.conf)
local function get_dependencies(mod_name)
    local file = io.open(core.get_modpath(mod_name) .. "/mod.conf", "r")

    local depends = {}
    local optional_depends = {}

    optional_depends[mod_name] = true

    if not file then return depends, optional_depends end

    local content = file:read("*all")
    io.close(file)

    local dep_line = string.match(content, "depends%s=[^\n]*")
    dep_line = string.gsub(dep_line, "depends%s=", "")

    for dependency in string.gmatch(dep_line, "[a-z0-9_]+") do
        depends[dependency] = true
    end

    local optdep_line = string.match(content, "optional_depends%s=[^\n]*")
    optdep_line = string.gsub(optdep_line, "optional_depends%s=", "")

    for dependency in string.gmatch(optdep_line, "[a-z0-9_]+") do
        optional_depends[dependency] = true
    end

    return depends, optional_depends
end

--- loads dependencies at the provided path
---@param path string the mods_path directory
local function load_mods(path)
    local this_mod = core.get_current_modname()
    local depends, optional_depends = get_dependencies(this_mod)
    local undocumented_depends = {}

    for _, mod_name in ipairs(core.get_modnames()) do
        local init_path = path .. "/" .. mod_name .. "/init.lua"

        if io.open(init_path, "r") then
            -- catch when mod.conf doesn't include a dependency
            if not depends[mod_name] and not optional_depends[mod_name] then table.insert(undocumented_depends, mod_name) end

            core.log("info", string.format("[%s] loading optional dependency script for %s", this_mod, mod_name))
            deploader.current_path = path .. "/" .. mod_name
            dofile(init_path)
        end
    end

    deploader.current_path = nil

    -- if an optional dependency goes unused, then warn
    for mod_name, _ in ipairs(optional_depends) do
        local init_path = path .. "/" .. mod_name .. "/init.lua"
        if not file_exists(init_path) then
            core.log("warning", string.format("[%s] unused optional dependency: %s (consider removing from your mod.conf)", this_mod, mod_name))
        end
    end

    -- if dependency is given a script without being documented, then throw an error
    if #undocumented_depends > 0 then
        error(string.format("add %s to the optional_depends in your mod.conf", table.concat(undocumented_depends, ", ")))
    end
end

--- loads the game specific script
---@param path string the games_path directory
local function load_game(path)
    local this_mod = core.get_current_modname()
    local game_info = core.get_game_info()

    if game_info.id then
        local init_path = path .. "/" .. game_info.id .. "/init.lua"

        if io.open(init_path, "r") then
            core.log("info", string.format("[%s] loading game specific script for %s", this_mod, game_info.id))
            deploader.current_path = path .. "/" .. game_info.id
            dofile(init_path)
        end
    end

    deploader.current_path = nil
end

local function handle_params_table(params)
    return {
        mods_path = params.mods_path or "/depends/mods",
        games_path = params.mods_path or "/depends/games"
    }
end

--- handles dependency loading
---@param params table table specifies the `mods_path` and `games_path`, the target directories to be loaded
function deploader.load_depends(params)
    local mod_name = core.get_current_modname()
    local path = deploader.current_path or core.get_modpath(mod_name)
    local params = handle_params_table(params or {})

    load_mods(path .. params.mods_path)
    load_game(path .. params.games_path)
end