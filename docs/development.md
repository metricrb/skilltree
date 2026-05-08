---
sidebar_position: 5
---

# Clone & demo

Everything in this section is for **this git repository** — not shipped in the Wally tarball.

## Layout (Rojo)

After **`wally install`**, `default.project.json` maps roughly to:

- **`ReplicatedStorage.SkillTree`** → library `src/`
- **`ReplicatedStorage.SkillTreeDemo`**, **`SkillTreeDemoServer`**, **`SkillTreeDemoClient`** → `example/` (Fusion UI + server driver)
- **`ReplicatedStorage.DevPackages`** → Fusion (`[dev-dependencies]`)
- **`ServerScriptService.ServerPackages`** → ProfileStore & co.

## Fusion example

Under **`example/`**:

| Piece | Role |
|-------|------|
| `Example.server.luau` | Builds **`SkillTree.new`**, remotes, **`loadPlayer`** / **`unloadPlayer`** |
| `ExampleConfig.luau` | Shared config for server + client |
| `ClientDemo.client.luau` | Fusion HUD wiring **`SkillTreeClient`** |
| `Components/*` | Radial + branch canvas, tooltips, detail panel |

Enable **Studio API access** for ProfileStore. Hit **Play** only after **`Example`** has created remotes so the client does not race.

## Testing

Tests under **`tests/`** assume **`ReplicatedStorage.SkillTree`** (this repo’s Rojo tree). Run with your TestEZ harness while **`rojo serve`** is synced.

## Standards

- **`--!strict`** everywhere
- Types centralized in **`Types`**
- **Signals** — lightweight internal events (no GoodSignal dependency in the library)
