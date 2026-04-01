# HuajHub

Multi-game Roblox hub.

## Structure

- `loader/init.lua`: entry script users execute
- `src/core/registry.lua`: maps `PlaceId` and `GameId` to a game key
- `src/core/loader.lua`: resolves the current game and loads its module
- `src/core/bootstrap.lua`: starts the resolved game module
- `src/games/<game_name>/init.lua`: self-contained script for that game

Each game script owns its own features.
That includes movement, ESP, auto parry, remotes, UI, and config paths.

## Current games

- `universal`
- `mashle_academy`
- `deepwoken` placeholder

## Adding a game

1. Create `src/games/<game_name>/init.lua`
2. Add its `PlaceId` or `GameId` to `src/core/registry.lua`
3. Keep that game's logic inside its own script instead of shared feature folders
