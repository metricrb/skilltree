--!strict
-- Runs on the server: loads the SkillTree package from ReplicatedStorage and mirrors the Fusion demo wiring.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkillTree = require(ReplicatedStorage:WaitForChild("SkillTree"):WaitForChild("SkillTree"))
local ExampleConfig = require(ReplicatedStorage:WaitForChild("SkillTreeDemo"):WaitForChild("ExampleConfig"))

local tree = SkillTree.new(ExampleConfig)

print("[SkillTree demo] Server Example script running — SkillTree + RemoteEvents initialized.")

tree.NodeUnlocked:connect(function(playerId: string, nodeId: string, rank: number)
	print("[SkillTree demo]", "Player", playerId, "→", nodeId, "rank", rank)
end)

Players.PlayerAdded:Connect(function(player)
	local playerId = tostring(player.UserId)
	if tree:loadPlayer(playerId) then
		tree:addPoints(playerId, "points", 100)
		print("[SkillTree demo] Loaded skill tree state for", player.Name, "(" .. playerId .. "); +100 points")
	else
		warn(
			"[SkillTree demo] loadPlayer failed for "
				.. player.Name
				.. " — enable Studio **Game Settings › Security › Enable Studio Access to API Services** and use a published place File ▸ Settings if DataStores stay blocked."
		)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	tree:unloadPlayer(tostring(player.UserId))
end)
