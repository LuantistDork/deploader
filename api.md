# Directory structure
By default, `depload.load_depends` loads dependency scripts in `/depends/mods` and `/depends/games`.

```
/my_mod/depends
├── mods
│   ├── some_mod
│   └── another_mod
└── games
    ├── some_game
    └── another_game
```

Each folder must contain an `init.lua` file for deploader to recognize it.
<br><br>
If you want, you can add a folder for the current mod into your `/depends/mods` like so:

```
my_mod/depends/mods
├── my_mod
└── ...
```

You won't get an error from deploader, as deploader treats every mod like they silently depend on themselves, and therefore you don't need to add the mod name to `mod.conf` in this case.

# 'deploader' namespace reference

* `deploader.load_depends([params])`: loads scripts for satisfied optional dependencies.
    * `params`: a deploader table:
        * `mods_path`: the directory containing the mod dependency scripts, by default this is set to `/depends/mods`
        * `games_path`: the directory containing the game dependency scripts, by default this is set to `/depends/games`
            * you can set `mods_path` and `games_path` to the same directory but this may cause naming conflicts if a game and mod share the same technical name.
    * raises an error when it tries to load a satiated mod dependency without it being included in the `mod.conf`

## Dependency exclusive

All members listed here are exclusive to dependencies in your dependency folders.

* `deploader.current_path`: the path of the `/depends/...` folder for the current dependency script, this is provided in case you want to use `dofile` without manual path management.