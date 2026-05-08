# SkillTree

A reusable, declarative skill tree system for Roblox games written in strict Luau. Fully typed, server-authoritative, and designed for multi-currency support and complex tree topologies.

## Installation

Add to your project's `wally.toml` (this package is **server realm**; it pulls in [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) transitively):

```toml
[server-dependencies]
SkillTree = "metricrb/skilltree@1.0.0"
```

Then run **`wally install`**. Server deps from **`[server-dependencies]`** (ProfileStore) install under **`ServerPackages/`**. In **this cloned repository**, **`[dev-dependencies]`** installs **`elttob/fusion@0.3.0`** under **`DevPackages/`** for the Fusion example — **`default.project.json`** maps **`SkillTree`** + **`DevPackages`** into **`ReplicatedStorage`** and **`ServerPackages`** into **`ServerScriptService`**.

**Registry contents:** Only the library (`src/`) is published. Paths **`example/`** and **`tests/`** are listed under **`exclude`** in this repo’s `wally.toml`, so **they never ship with `wally install`**—they are only for cloning the repo (Rojo + Studio).

For your game, map `ServerPackages` under `ServerScriptService` like your Rojo/Wally defaults; **ProfileStore** resolves as `ServerScriptService.ServerPackages.ProfileStore`.

**Tip:** To simplify imports, create a helper alias under `ServerScriptService`:
```luau
_G.SkillTree = require(script:WaitForChild("ServerPackages"):WaitForChild("_Index"):WaitForChild("metricrb_skilltree"):WaitForChild("SkillTree"))
```

Then use `_G.SkillTree.SkillTree.new()` throughout your game.

## Repo layout (Rojo + Fusion demo — **clone only**)

This section is for **developers working in this repository**. It is **not** part of the Wally package (see **Installation** above).

In **this git repository**, Rojo maps the whole package to **`ReplicatedStorage.SkillTree`** (the `src/` folder), so server and client can `require` the same ModuleScripts:

- **`ReplicatedStorage.SkillTreeDemo.ExampleConfig`** — shared demo `SkillTreeConfig`
- **`ReplicatedStorage.DevPackages`** — **`wally`** dev-deps (**`Fusion`**) pulled by **`wally install`**, required for **`example/`**
- **`ServerScriptService.SkillTreeDemoServer.Example`** — server script (`SkillTree.new`, `PlayerAdded`: `loadPlayer`, `addPoints`, `unloadPlayer`)
- **`StarterPlayer.StarterPlayerScripts.SkillTreeDemoClient.ClientDemo`** — Fusion UI locally

Studio **API access must be enabled** for ProfileStore. After **`wally install`**, use **`require(ReplicatedStorage.DevPackages.Fusion)`** in the demo (**`ClientDemo`** and **`Components`**).

Consuming **`metricrb/skilltree` from the Registry** yields **`src/`** + **ProfileStore** transitively — not **Fusion**, which is **`[dev-dependencies]`** here only (`example/` is excluded from the published package anyway).

## Quick Start

### Server Setup

Import from the installed Wally package:

```luau
local SkillTreePackage = require(game:GetService("ServerScriptService"):WaitForChild("ServerPackages"):WaitForChild("_Index"):WaitForChild("metricrb_skilltree"):WaitForChild("SkillTree"))
local SkillTree = SkillTreePackage.SkillTree

local config = {
  currencies = { "points", "gold" },
  layout = "branching",
  nodes = {
    {
      id = "fireball",
      type = "active",
      name = "Fireball",
      maxRank = 1,
      cost = { points = 20 },
      prerequisites = nil,
      position = { x = 0, y = 0 },
      effectData = { damage = 50 },
    },
  },
}

local tree = SkillTree.new(config)

game:GetService("Players").PlayerAdded:Connect(function(player)
  local userId = tostring(player.UserId)
  tree:loadPlayer(userId)
  tree:addPoints(userId, "points", 100)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
  tree:unloadPlayer(tostring(player.UserId))
end)

tree.NodeUnlocked:connect(function(playerId, nodeId, rank)
  print(playerId .. " unlocked " .. nodeId .. " at rank " .. rank)
end)
```

### Client Usage

The published Wally artifact is **server realm**; `SkillTreeClient` and `Types` must be available to the client from **ReplicatedStorage** (or another replicated container) in your own Rojo layout. The example below assumes you map them under `ReplicatedStorage.SkillTree`.

```luau
local SkillTreeClient = require(game:GetService("ReplicatedStorage"):WaitForChild("SkillTree"):WaitForChild("SkillTreeClient"))

local remotes = {
  unlockRequest = game:GetService("ReplicatedStorage"):WaitForChild("SkillTreeUnlockRequest"),
  upgradeRequest = game:GetService("ReplicatedStorage"):WaitForChild("SkillTreeUpgradeRequest"),
  stateUpdated = game:GetService("ReplicatedStorage"):WaitForChild("SkillTreeStateUpdated"),
}

local client = SkillTreeClient.new(remotes)

client:requestUnlock("fireball")
client.StateUpdated:connect(function(state)
  print("State updated:", state)
end)
```

## SkillTreeConfig Reference

```luau
type SkillTreeConfig = {
  categories: { CategoryConfig }?,      -- Top-level categories (radial layout)
  nodes: { NodeConfig }?,               -- Flat node list (alternative to categories)
  layout: "linear" | "branching" | "web" | "radial"?,  -- Layout topology
  currencies: { string },               -- Currency names tracked per player
}

type CategoryConfig = {
  id: string,
  name: string,
  icon: string?,
  description: string?,
  position: { x: number, y: number },  -- Canvas position
  nodes: { NodeConfig },                -- Category's skill nodes
}

type NodeConfig = {
  id: string,
  type: "passive" | "active" | "multirank" | "exclusive",
  name: string,
  description: string?,
  icon: string?,
  maxRank: number,                      -- 1 for non-multirank
  cost: { [string]: number },           -- Currency -> amount
  prerequisites: Prerequisites?,        -- Unlock conditions
  position: { x: number, y: number },   -- UI canvas position
  effectData: { [string]: any }?,       -- Passed to effect handler
  category: string?,                    -- Parent category ID
  exclusiveGroup: string?,              -- For exclusive choice nodes
}

type Prerequisites = {
  level: { minLevel: number }?,
  parents: { { nodeId: string } }?,
  dependencies: { { nodeIds: { string } } }?,
  custom: { { predicate: (playerId: string, state: PlayerSkillState) -> boolean } }?,
}
```

## API Reference

### Server-Side

```luau
-- Create tree from config
local tree = SkillTree.new(config)

-- Load player state from storage
tree:loadPlayer(userId)

-- Add currency points
tree:addPoints(userId, "points", 50) -> boolean

-- Unlock a node
tree:unlock(userId, nodeId) -> { success: boolean, reason: string }

-- Upgrade a multi-rank node
tree:upgrade(userId, nodeId) -> { success: boolean, reason: string }

-- Get player state
tree:getState(userId) -> PlayerSkillState

-- Get node config
tree:getNode(nodeId) -> NodeConfig

-- Full respec (refund all points, clear unlocks)
tree:respec(userId) -> boolean

-- Save and unload
tree:savePlayer(userId) -> boolean
tree:unloadPlayer(userId)

-- Signal: fires when node unlocked
tree.NodeUnlocked:connect(function(playerId, nodeId, rank) end)
```

### Client-Side

```luau
local client = SkillTreeClient.new(remoteConfig)

-- Request unlock from server
client:requestUnlock(nodeId)

-- Request upgrade from server
client:requestUpgrade(nodeId)

-- Get current client state
client:getState() -> PlayerSkillState

-- Listen for state updates from server
client.StateUpdated:connect(function(state) end)
```

## Example UI

**(Repository only — not in the Wally package.)** A Fusion 0.3 demo lives under `example/`:

- **`Example.server.luau`** — `require(ReplicatedStorage.SkillTree.SkillTree)` and drives live saves + remotes (`PlayerAdded`, `unloadPlayer`).
- **`ClientDemo.client.luau`** — LocalScript Fusion UI wiring `SkillTreeClient` + the same **`ExampleConfig`** as the server (`ReplicatedStorage.SkillTreeDemo.ExampleConfig`), so visuals match server rules.
- **`Components/`** — Radial + branch canvas HUD.

Demonstrates:

- **Split-view layout**: Radial category picker (left) + branching canvas (right)
- **Pan and zoom**: Mouse drag for panning, scroll wheel for zoom
- **Node tooltips**: Hover display with cost, rank, and prerequisites
- **Animated unlocks**: Scale pulse and color transition on node unlock
- **Live balance**: HUD showing current currency balance

To run it with Rojo: **`wally install`**, then **`rojo serve`**, sync so **`ReplicatedStorage.DevPackages`** (Fusion) and **`SkillTree`** are present; enable Studio datastore API access, hit Play — **Example** installs remotes **before** the client reads them; edit **`example/ExampleConfig.luau`** to change nodes or currencies once for both halves.

## Testing

Run tests with TestEZ (`tests/` Modules expect **`ReplicatedStorage.SkillTree`** per this repo’s **Rojo** tree):

```bash
rojo serve
# In another terminal, or in-game:
# Load the test suite and run
```

Test coverage includes:

- **Validator**: Prerequisite evaluation (levels, parents, dependencies, custom predicates)
- **Tree**: Unlock flow, multi-rank upgrades, exclusive node locking, respec
- **Store**: Mad Studio ProfileStore integration and state serialization
- **Currency**: Multi-currency balance tracking and spend logic

## Code Standards

- **--!strict** enforced on all modules
- **Types module**: Central type definitions imported by all files
- **Wally deps**: ProfileStore on the server (transitive for consumers). **Fusion** is **`[dev-dependencies]`** in this repo only — pulled into **`DevPackages/`** for the clone-only Fusion demo, not part of the published Registry bundle for games that only need the library.
- **Moonwave docs**: Every public method and type fully documented
- **Signal class**: Lightweight built-in event system (no GoodSignal dependency)

## Moonwave Documentation Build

Generate HTML docs:

```bash
moonwave install
moonwave build
```

Docs will be in the `docs/` directory. See `.moonwave.toml` for config.

## Extending

### Custom Effect Handlers

```luau
local tree = SkillTree.new(config)

tree._effectHandler:register("fireball", function(playerId, nodeId, rank, effectData)
  -- Apply effect: give player ability, boost stat, etc.
  print("Applied effect for " .. nodeId .. " rank " .. rank)
end)
```

### Custom Prerequisites

```luau
local nodeConfig = {
  -- ...
  prerequisites = {
    custom = {
      {
        predicate = function(playerId, state)
          return state.level >= 20
        end,
      },
    },
  },
}
```

### Multiple Currencies

```luau
local config = {
  currencies = { "points", "gold", "essence" },
  -- ...
  nodes = {
    {
      id = "legendary_skill",
      cost = { points = 50, gold = 100, essence = 1 },
      -- ...
    },
  },
}
```

## License

MIT
