# SkillTree Architecture

## Design Principles

1. **Declarative Config**: Tree structure is a plain data table, not imperative API calls
2. **Server-Authoritative**: All unlock logic runs server-side; client is UI-only
3. **Type-Safe**: Strict Luau throughout; types defined in single module
4. **Composable**: Small focused modules with clear interfaces
5. **Reusable**: No game-specific logic; core can be vendored as-is
6. **Flexible**: Supports multiple tree topologies via config
7. **Persistent**: [Mad Studio ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) integration; survives server restart

## Module Responsibilities

### Types
Defines all type interfaces as exported types. No logic. Imported by all other modules.

```
Types.luau
├── NodeConfig
├── CategoryConfig
├── SkillTreeConfig
├── PlayerSkillState
├── Prerequisites (and variants)
├── UnlockResult
└── ...
```

### Signal
Lightweight event system. No dependencies.

```
Signal
├── new() -> Signal
├── connect(callback) -> Connection
├── fire(...args)
└── destroyAllConnections()
```

### Validator
Pure prerequisite evaluation logic. Stateless.

Input: (playerId, nodeConfig, playerState, allNodes)
Output: UnlockResult with reason

No side effects; can be unit tested in isolation.

### Store
ProfileStore-backed wrapper (`ProfileStore.New` + session lifecycle). Handles persistence layer.

```
Store
├── load(playerId) -> PlayerSkillState?
├── save(playerId, state) -> boolean
└── release(playerId)
```

State is plain Luau table (no metatables) for clean serialization.

### EffectHandler
Decoupled effect application. Games register callbacks per node.

```
EffectHandler
├── register(nodeId, callback)
└── apply(playerId, nodeId, rank, effectData)
```

Callbacks run async (task.spawn) to avoid blocking.

### Network
Sets up RemoteEvents for client ↔ server communication.

```
Network
├── create() -> RemoteConfig
├── sendStateUpdate(playerId, state)
├── connectUnlockRequest(callback)
└── connectUpgradeRequest(callback)
```

Server is authoritative; network is transport only.

### SkillTree (Server)
Main server-side class. Orchestrates:
1. Prerequisite validation (via Validator)
2. Currency spending and refunds
3. State persistence (via Store)
4. Effect application (via EffectHandler)
5. Network distribution (via Network)

```
SkillTree
├── new(config) -> SkillTree
├── loadPlayer(playerId) -> boolean
├── addPoints(playerId, currency, amount) -> boolean
├── unlock(playerId, nodeId) -> UnlockResult
├── upgrade(playerId, nodeId) -> UnlockResult
├── respec(playerId) -> boolean
└── Signal: NodeUnlocked
```

All unlock logic flows through `unlock()`:
1. Validate player loaded
2. Validate node exists
3. Validate prerequisites (Validator)
4. Validate affordability
5. Deduct currency
6. Update state
7. Apply effect (EffectHandler)
8. Save (Store)
9. Fire signal
10. Broadcast state (Network)

### SkillTreeClient (Client)
Thin client wrapper for UX. No logic.

```
SkillTreeClient
├── new(remoteConfig) -> SkillTreeClient
├── requestUnlock(nodeId)
├── requestUpgrade(nodeId)
└── Signal: StateUpdated
```

Listens to server state updates; stores in-memory cache. UI reads this cache.

## Data Flow

### Unlock Request

```
Client UI
  ↓ (click node)
SkillTreeClient:requestUnlock()
  ↓ (RemoteEvent)
SkillTree:unlock() [SERVER]
  ├─ Validator.canUnlock()
  ├─ EffectHandler:apply()
  ├─ Store:save()
  ├─ Signal: NodeUnlocked
  └─ Network:sendStateUpdate()
  ↓ (RemoteEvent)
SkillTreeClient.StateUpdated
  ↓
Client UI updates
```

### Player Join

```
Player joins
  ↓
SkillTree:loadPlayer()
  ├─ Store:load()
  └─ _playerStates[playerId] = state
  ↓
tree:addPoints() [game gives initial points]
  ├─ Update _playerStates[playerId].currencies
  ├─ Store:save()
  └─ Network:sendStateUpdate()
  ↓
Client receives state via StateUpdated
  ↓
UI renders
```

### Respec

```
Client requests respec
  ↓
SkillTree:respec()
  ├─ Calculate total refund from all unlocked nodes
  ├─ Clear unlockedNodes
  ├─ Add refund to currencies
  ├─ Store:save()
  └─ Network:sendStateUpdate()
  ↓
Client receives updated state
  ↓
UI re-renders with no nodes unlocked
```

## Configuration Structure

```
SkillTreeConfig
├── currencies: ["points", "gold"]
├── layout: "branching" | "radial" | "web" | "linear"
└── categories OR nodes
    ├── id
    ├── name
    ├── position (x, y)
    └── nodes[]
        ├── id
        ├── type: "passive" | "active" | "multirank" | "exclusive"
        ├── maxRank: number
        ├── cost: { currency → amount }
        ├── prerequisites
        │   ├── level: { minLevel }
        │   ├── parents: [{ nodeId }]
        │   ├── dependencies: [{ nodeIds: [] }]
        │   └── custom: [{ predicate(playerId, state) }]
        ├── position (x, y)
        ├── effectData: { any }
        └── exclusiveGroup: string?
```

## State Shape

```
PlayerSkillState
├── playerId: string
├── unlockedNodes: { [nodeId]: rank }
│   └── rank = 1 for single-rank, 1-N for multi-rank
├── currencies: { [currencyName]: balance }
└── level: number
```

State is serializable (no metatables, no functions). Stored under `profile.Data` in ProfileStore.

## Exclusive Nodes

Exclusive choice nodes work via two mechanisms:

1. **Prerequisite validation** (Validator.checkExclusivity):
   - If node has `exclusiveGroup = "group_a"` and another node in that group is unlocked, reject unlock

2. **Capstone pattern** (Validator.checkCapstone):
   - A capstone node with `type = "exclusive"` and all-parent prerequisites ensures prior tier is locked

Example:
```
Tier 1: [Spell A, Spell B]  (normal, mutually available)
  ↓
Tier 2: [Capstone A, Capstone B]  (exclusive, each requires its parent)
```

If Spell A is unlocked, you can't unlock Spell B. Once Capstone A is unlocked (requires Spell A), you can never unlock Capstone B (requires Spell B).

## Currency Design

Currencies are identified by string name. No built-in currency types.

Games define:
- Currency names in config
- How points are earned (via tree:addPoints API)
- How points are displayed (in UI)

Tree tracks balance per currency per player. No assumptions about source.

## Effect Handlers

Effects are decoupled from unlock logic via a callback registry.

Game provides:
```luau
tree._effectHandler:register("fireball", function(playerId, nodeId, rank, effectData)
  -- Apply Fireball ability to player
  -- Award damage bonus, grant item, play animation, etc.
end)
```

Handler receives full state snapshot. Can do anything (award items, trigger quests, etc.).

Handlers run async (task.spawn) to avoid blocking the unlock transaction.

## Testing Strategy

All modules are unit-testable in isolation via TestEZ:

- **Validator**: Mock player state; test prerequisite logic
- **SkillTree**: Mock Store and EffectHandler; test unlock flow
- **Store**: Mock ProfileStore profiles; test save/load round-trip
- **Currency**: Test spend and refund math

No server/client split in tests; all run server-side.

