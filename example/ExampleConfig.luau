--!strict
-- Demo skill tree definition shared by `Example.server` (server) and `ClientDemo.client` (client UI).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage:WaitForChild("SkillTree"):WaitForChild("Types"))

type SkillTreeConfig = Types.SkillTreeConfig

local config: SkillTreeConfig = {
	currencies = { "points" },
	layout = "radial",
	categories = {
		{
			id = "combat",
			name = "Combat",
			icon = "rbxasset://textures/Cursors/MouseLockedCursor.png",
			description = "Offensive abilities",
			position = { x = 100, y = 100 },
			nodes = {
				{
					id = "basic_attack",
					type = "passive",
					name = "Basic Attack",
					description = "A fundamental melee attack",
					maxRank = 1,
					cost = { points = 10 },
					prerequisites = nil,
					position = { x = 0, y = 0 },
					effectData = { damage = 10 },
				},
				{
					id = "power_strike",
					type = "active",
					name = "Power Strike",
					description = "A devastating charge attack",
					maxRank = 1,
					cost = { points = 25 },
					prerequisites = {
						parents = { { nodeId = "basic_attack" } },
					},
					position = { x = 150, y = 0 },
					effectData = { damage = 50 },
				},
				{
					id = "whirlwind",
					type = "active",
					name = "Whirlwind",
					description = "Spin attack hitting all enemies",
					maxRank = 1,
					cost = { points = 40 },
					prerequisites = {
						parents = { { nodeId = "power_strike" } },
					},
					position = { x = 300, y = 0 },
					effectData = { damage = 75 },
				},
			},
		},
		{
			id = "defense",
			name = "Defense",
			icon = "rbxasset://textures/Cursors/MouseLockedCursor.png",
			description = "Defensive abilities",
			position = { x = 100, y = 100 },
			nodes = {
				{
					id = "shield_bash",
					type = "passive",
					name = "Shield Bash",
					description = "Block and counter attack",
					maxRank = 1,
					cost = { points = 15 },
					prerequisites = nil,
					position = { x = 0, y = 0 },
					effectData = { armor = 5 },
				},
				{
					id = "fortify",
					type = "multirank",
					name = "Fortify",
					description = "Increase armor permanently",
					maxRank = 5,
					cost = { points = 20 },
					prerequisites = {
						parents = { { nodeId = "shield_bash" } },
					},
					position = { x = 150, y = 0 },
					effectData = { armor = 10 },
				},
			},
		},
	},
}

return config
