-- gets the hard and soft dependencies from mod.conf
---@param mod_name string the name of the mod
---@return table depends the hard dependencies of the mod (depends in the mod.conf)
---@return table optional_depends the soft dependencies of the mod (optional_depends in the mod.conf)
local function get_dependencies(mod_name)
	local settings = Settings(core.get_modpath(mod_name) .. "/mod.conf")

    local depends = {}
    local optional_depends = {}

    optional_depends[mod_name] = true

    if settings then
		local dep_str = settings:get("depends") or ""
		for dependency in string.gmatch(dep_str, "[a-z0-9_]+") do
			depends[dependency] = true
		end

		local optdep_str = settings:get("optional_depends") or ""
		for dependency in string.gmatch(optdep_str, "[a-z0-9_]+") do
			optional_depends[dependency] = true
		end
	end

    return depends, optional_depends
end

--- loads dependency specific scripts at the provided path.
---@param path string the mods_path directory
---@param aliases table `[original_name] = alias` style table defining mod aliases
local function load_mods(path, aliases)
    local this_mod = core.get_current_modname()
    local depends, optional_depends = get_dependencies(this_mod)
    local undocumented_depends = {}

    for _, actual_mod_name in ipairs(core.get_modnames()) do
		local mod_name = aliases[actual_mod_name] or actual_mod_name
        local init_path = path .. "/" .. mod_name .. "/init.lua"

        if io.open(init_path, "r") then
            -- catch when mod.conf doesn't include a dependency
            if not depends[actual_mod_name] and not optional_depends[actual_mod_name] then
				table.insert(undocumented_depends, actual_mod_name)
			end

            core.log("info", string.format("[%s] loading optional dependency script for %s", this_mod, actual_mod_name))
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
---@return table unsupported_games the games explicitly not supported by the mod (unsupported_games in the mod.conf)
local function get_supported_games(mod_name)
	local settings = Settings(core.get_modpath(mod_name) .. "/mod.conf")

    local supported_games = {}
	local unsupported_games = {}

    if settings then
		local supported_str = settings:get("supported_games") or ""
		for game_id in string.gmatch(supported_str, "[a-z0-9_]+") do
			supported_games[game_id] = true
		end

		local unsupported_str = settings:get("unsupported_games") or ""
		for game_id in string.gmatch(unsupported_str, "[a-z0-9_]+") do
			unsupported_games[game_id] = true
		end
	end

    return supported_games, unsupported_games
end

--- loads game specific scripts at the provided path.
---@param path string the games_path directory
---@param aliases table `[original_name] = alias` style table defining game aliases
local function load_game(path, aliases)
    local this_mod = core.get_current_modname()
    local supported_games, unsupported_games = get_supported_games(this_mod)
    local actual_game_id = core.get_game_info().id
	local game_id = aliases[actual_game_id] or actual_game_id

	-- do not load for unsupported games
	if unsupported_games[actual_game_id] then
		core.log("error", string.format("[%s] unsupported game: %s, consider disabling %s.", this_mod, actual_game_id, this_mod))
		return
	end

	local init_path = path .. "/" .. game_id .. "/init.lua"

	if io.open(init_path, "r") then
		
		-- if support for this game isn't documented in the mod.conf, then give a warning.
		if not supported_games[actual_game_id] then
			core.log("warning", string.format("[%s] undocumented game support: %s (consider adding it to your mod.conf)", this_mod, actual_game_id))
		end

		core.log("info", string.format("[%s] loading game specific script for %s", this_mod, actual_game_id))
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
	local mod_aliases = params.mod_aliases or {}
	local game_aliases = params.game_aliases or {}

    load_mods(path .. mods_path, mod_aliases)
    load_game(path .. games_path, game_aliases)
end