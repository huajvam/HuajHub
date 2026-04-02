# HuajHub

Multi-game Roblox hub.

## Structure

- `source.lua`: main loader users execute
- `games/gameList.lua`: maps `PlaceId` and `GameId` to a game script
- `games/<GameName>.lua`: self-contained script for that game
- `classes/`: shared class-style modules
- `utils/`: shared utility modules

This now follows the same top-level shape as the Aztup Hub files:
- one root entry script
- one root `games` folder
- optional root `classes` and `utils` folders

## Current games

- `MashleAcademy`
- `DeepWoken` placeholder
- `Universal`

## Current loadstring

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/huajvam/HuajHub/main/source.lua"))()
```
