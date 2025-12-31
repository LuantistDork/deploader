-- gets the hard and soft dependencies from mod.conf
---@param mod_name string the name of the mod
---@return table depends the hard dependencies of the mod (depends in the mod.conf)
---@return table optional_depends the soft dependencies of the mod (optional_depends in the mod.conf)
local function get_dependencies(mod_name)
	local settings = Settings(core.get_modpath(mod_name) .. "/mod.conf")

    local depends = {}
    local optional_depends = {}

    optional_depends[mod_name] = true

    if not settings then return depends, optional_depends end

    local dep_str = settings:get("depends") or ""
    for dependency in string.gmatch(dep_str, "[a-z0-9_]+") do
        depends[dependency] = true
    end

    local optdep_str = settings:get("optional_depends") or ""
    for dependency in string.gmatch(optdep_str, "[a-z0-9_]+") do
        optional_depends[dependency] = true
    end

    return depends, optional_depends
end

--- loads dependency specific scripts at the provided path.
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

    -- warn for unused optional dependencies
    for mod_name, _ in ipairs(optional_depends) do
        local init_path = path .. "/" .. mod_name .. "/init.lua"
        if not io.open(init_path, "r") then
            core.log("warning", string.format("[%s] unused optional dependency: %s (consider removing from your mod.conf)", this_mod, mod_name))
        end
    end

    -- if dependency is given a script without being documented, then throw an error
    if #undocumented_depends > 0 then
		error(string.format("add %s to the optional_depends in your mod.conf", 
			table.concat(undocumented_depends, ", ")
		))
    end
end

-- gets the supported games from mod.conf
---@param mod_name string the name of the mod
---@return table supported_games the games explicitly supported by the mod (supported_games in the mod.conf)
local function get_supported_games(mod_name)
	local settings = Settings(core.get_modpath(mod_name) .. "/mod.conf")

    local supported_games = {}

    if not settings then return supported_games end

    local str = settings:get("supported_games") or ""
    for game_id in string.gmatch(str, "[a-z0-9_]+") do
        supported_games[game_id] = true
    end

    return supported_games
end

--- loads game specific scripts at the provided path.
---@param path string the games_path directory
local function load_game(path)
    local this_mod = core.get_current_modname()
    local supported_games = get_supported_games(this_mod)
    local game_id = core.get_game_info().id
	local init_path = path .. "/" .. game_id .. "/init.lua"

	if io.open(init_path, "r") then
		
		-- if support for this game isn't documented in the mod.conf, then give a warning.
		if not supported_games[game_id] then
			core.log("warning", string.format("[%s] undocumented game support: %s (consider adding it to your mod.conf)", this_mod, game_id))
		end

		core.log("info", string.format("[%s] loading game specific script for %s", this_mod, game_id))
		deploader.current_path = path .. "/" .. game_id
		dofile(init_path)
	end

    deploader.current_path = nil
end

--- automates the loading of dependency specific scripts.
---@param params table table specifies the `mods_path` and `games_path`, the target directories to be loaded
function deploader.load_depends(params)
    local mod_name = core.get_current_modname()
    local path = deploader.current_path or core.get_modpath(mod_name)

	params = params or {}

    local mods_path = params.mods_path or "/depends/mods"
    local games_path = params.games_path or "/depends/games"

    load_mods(path .. mods_path)
    load_game(path .. games_path)
end