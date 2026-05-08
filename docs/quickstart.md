---
sidebar_position: 3
---

# Quick start

Minimal patterns for a game that already has **`SkillTree`** on the server and **`ReplicatedStorage`** wiring for the client (adjust paths to your Rojo tree).

## Server

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

See **[SkillTree](/api/SkillTree)** for `unlock`, `upgrade`, `respec`, persistence, and effects.

## Client

The published artifact is **server-first**; replicate **`SkillTreeClient`** + **`Types`** (or your own thin layer) under **`ReplicatedStorage`** in your game’s Rojo layout.

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

See **[SkillTreeClient](/api/SkillTreeClient)** for the full surface.
