# HuajHub

Multi-game Roblox hub with shared systems and per-game modules.

## Layout

- `loader/init.lua`: entry script
- `src/core`: bootstrap and shared runtime
- `src/shared`: shared UI/helpers
- `src/features`: reusable features
- `src/games`: game-specific modules

## Adding a game

Create `src/games/<game_name>/init.lua` and register its `PlaceId` in `src/core/registry.lua`.
