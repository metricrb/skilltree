---
sidebar_position: 4
---

# Configuration reference

The canonical type shapes are **[documented in the API](/api/Types)** (generated from `Types.luau`). Below is a compact reminder.

## SkillTreeConfig

- **`currencies`** — Array of currency names tracked per player.
- **`layout`** — `"linear"` \| `"branching"` \| `"web"` \| `"radial"` (optional).
- **`nodes`** — Flat list of **NodeConfig** nodes (see API) **or**
- **`categories`** — For radial-style UIs, **CategoryConfig** groups with nested nodes.

## NodeConfig (essentials)

| Field | Role |
|-------|------|
| `id`, `name`, `type` | Identity; `type` is passive / active / multirank / exclusive |
| `maxRank` | Ranks for multi-rank skills |
| `cost` | `[string]: number` map of currency → price |
| `prerequisites` | Optional prerequisites block (see **Types**) |
| `position` | UI canvas `{ x, y }` |
| `effectData` | Opaque payload for your **EffectHandler** |
| `category` / `exclusiveGroup` | Grouping and mutex rules |

## Prerequisites

Union-style table with optional **level**, **parents**, **dependencies**, and **custom** blocks — see **[Types](/api/Types)** for field-level detail.

## Validation

Runtime checks live in **[Validator](/api/Validator)**; the server **[SkillTree](/api/SkillTree)** delegates to them before unlock/upgrade.
