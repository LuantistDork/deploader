Simple mod API that automates optional dependencies using a folder-heavy approach in Luanti.

# How to use?
put `deploader` in your `mod.conf`'s dependencies list, add the following line to your `init.lua`:

```lua
deploader.load_dependencies()
```

...and now you can manage your optional dependencies using folders like so:

```
/depends/mods/modname/init.lua
/depends/mods/other_mod/init.lua
/depends/mods/...
```

for game specific stuff, use:

```
/depends/games/game_id/init.lua
/depends/games/other_game/init.lua
/depends/games/...
```

yes you need to use a `(dependency name)/init.lua` pattern,
but say you're not feeling the directory names, you can use:

```lua
deploader.load_depends {
    mods_path = "/directory_for_mods",
    games_path = "/directory_for_games",
}
```

you can set `games_path` and `mods_path` to the same folder but be warned this would cause issues if a mod and a game share a name.
<br>

dependency scripts get access to a global variable: `deploader.current_path` which will hold the path of the script's parent directory.

# What is this error? help!

you may get an error like this:

```
add some_mod, other_mod to the optional_depends in your mod.conf
```

this is because you made a script for mods in your dependencies folder without first adding them to your `mod.conf`'s `optional_depends`.
this error occurs because my API can't ensure that your script will load after all optional dependencies have loaded, as load order is determined by the engine.
simply double check your `mod.conf` and make sure you have a line that looks like this:

```conf
optional_depends = bombulator, airsword, some_other_mod, other_mod, blahblah, ...
```

note that this error doesn't show up unless the depended mod is enabled.