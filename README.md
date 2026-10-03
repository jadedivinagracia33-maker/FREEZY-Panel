# FREEZY Panel

A focused Roblox Lua panel for detecting existing eggs, filtering and targeting them, visualizing targets, and coordinating an Auto-Pickup workflow through existing `ProximityPrompt` interactions.

> **Scope:** This repository contains the panel/controller and its server bridge only. It does **not** create a map, spawn eggs, create rewards, or add unrelated game systems.

## Repository structure

```text
FREEZY-Panel/
├── FREEZY/
│   ├── FREEZY.lua
│   └── FREEZYServer.lua
├── README.md
└── LICENSE
```

## Components

### `FREEZY/FREEZY.lua`

Client-side panel and controller. It provides:

- Draggable, resizable, animated UI
- Close/reopen launcher
- UI scaling and touch support
- Egg scanning and verification
- Rarity, mutation, and size filters
- Nearest, rarity, largest, and mutation targeting
- Maximum-distance filtering
- Egg ESP, target ESP, and distance labels
- One-shot, continuous, and queued Auto-Pickup modes
- Pickup verification and return-to-start controls
- STOP ALL / cancellation controls
- Session statistics and activity logs
- FPS/session status display

### `FREEZY/FREEZYServer.lua`

Server-side bridge used by the panel. It creates the `FREEZYRemotes` folder and validates supported actions and egg targets before carrying out the controller workflow.

## Egg recognition

FREEZY can recognize an existing object as an egg when it exposes one of the supported identifiers, such as:

- `CollectionService` tag: `Egg`
- Attribute: `IsEgg = true`
- Attribute: `EggId`

It reads available metadata from the existing object, including rarity, mutation, size, availability, position, and `ProximityPrompt` state.

## Auto-Pickup workflow

The controller is designed around an existing game's egg interaction path:

```text
Scan
  ↓
Filter
  ↓
Select target
  ↓
Validate target
  ↓
Move near target
  ↓
Use existing ProximityPrompt
  ↓
Verify observable pickup state
  ↓
Return to starting position
```

The package does **not** invent or grant rewards. The target game remains responsible for its own underlying pickup/reward behavior.

## Targeting modes

- **NEAREST** — selects the nearest valid target.
- **RARITY** — prioritizes recognized rarity levels, then uses distance as a tie-breaker.
- **LARGEST** — compares recognized size tiers or numeric size values.
- **MUTATION** — prioritizes mutation targets, with distance used as a tie-breaker.

Filters are applied before target selection.

## Requirements / integration boundary

The target experience must already provide the relevant egg objects and, for Auto-Pickup, an enabled `ProximityPrompt` or compatible existing interaction path. FREEZY is not a standalone game or egg/reward generator.

Because Roblox experiences can implement their own custom interaction and validation logic, compatibility depends on how the target experience exposes its egg objects and prompts.

## Installation

1. Add `FREEZYServer.lua` to the server-side location used by the target experience.
2. Add `FREEZY.lua` as the client-side LocalScript in the appropriate player/client location.
3. Start the experience and open the FREEZY panel.
4. Run an egg scan and configure the desired filters/target mode.

Use only in experiences and environments where you have permission to run or modify the code.

## No bundled game content

This repository intentionally excludes:

- Maps
- Egg spawning systems
- Currency/reward systems
- Inventory systems
- Pet systems
- Shops
- Progression systems
- Unrelated game mechanics

## Status

The repository is intended as a focused panel/controller package rather than a complete game.
