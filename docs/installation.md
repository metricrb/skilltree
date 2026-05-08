---
sidebar_position: 2
---

# Installation

## Wally (recommended)

Add to `wally.toml` (the package is **server** realm; [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) comes in as a server dependency):

```toml
[server-dependencies]
SkillTree = "metricrb/skilltree@1.0.0"
```

Run **`wally install`**, then map **`ServerPackages`** under **`ServerScriptService`** like any other Wally server dep.

:::caution Registry tarball

Published tarballs include **`src/`** plus transitive server deps — **not** the Fusion demo under `example/` (excluded in `wally.toml`).

:::

## GitHub Releases

Each [release](https://github.com/metricrb/skilltree/releases) can attach **`SkillTree.rbxm`** built with this repo’s **`default.project.json`** (full Rojo tree including optional dev/demo paths if present in the project file).

Import the model in Studio or merge via Rojo as you prefer.

## Optional: Rojo alias

To shorten requires from server scripts:

```luau
_G.SkillTree = require(script:WaitForChild("ServerPackages"):WaitForChild("_Index"):WaitForChild("metricrb_skilltree"):WaitForChild("SkillTree"))
```

Use **`SkillTree.SkillTree.new`** for the server class and **`SkillTree.Types`** for shared types.
