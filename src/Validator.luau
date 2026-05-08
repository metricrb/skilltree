--!strict

local Types = require(script.Parent.Types)

type NodeConfig = Types.NodeConfig
type Prerequisites = Types.Prerequisites
type PlayerSkillState = Types.PlayerSkillState
type UnlockResult = Types.UnlockResult
type CostMap = Types.CostMap

--- @class Validator
--- Evaluates prerequisites and unlock conditions.
local Validator = {}

--- Ensures node cost keys are allowed currencies with finite nonnegative amounts (server authoritative).
--- @param cost CostMap -- Per-currency spends from node config
--- @param configuredCurrencies { string } -- `SkillTreeConfig.currencies`
--- @return UnlockResult

function Validator.validateCostAgainstConfig(cost: CostMap, configuredCurrencies: { string }): UnlockResult
	local allowed: { [string]: boolean } = {}
	for _, c in ipairs(configuredCurrencies) do
		allowed[c] = true
	end

	for currency, rawAmount in pairs(cost) do
		if not allowed[currency] then
			return {
				success = false,
				reason = `Cost uses unrecognized currency '${currency}'`,
			}
		end
		if typeof(rawAmount) ~= "number" or rawAmount ~= rawAmount or math.abs(rawAmount) == math.huge then
			return { success = false, reason = "Invalid cost amount" }
		end
		if rawAmount < 0 then
			return { success = false, reason = `Negative cost amount for '${currency}'` }
		end
	end

	return { success = true, reason = "" }
end

--- Rejects malformed configs where prerequisites reference unknown node ids.
--- @param node NodeConfig
--- @param allNodes { [string]: NodeConfig }
--- @return UnlockResult

function Validator.validateReferencedNodeIds(node: NodeConfig, allNodes: { [string]: NodeConfig }): UnlockResult
	local prereqs = node.prerequisites
	if not prereqs then
		return { success = true, reason = "" }
	end

	if prereqs.parents then
		for _, parentReq in ipairs(prereqs.parents) do
			if not allNodes[parentReq.nodeId] then
				return {
					success = false,
					reason = `Unknown prerequisite node id '${parentReq.nodeId}'`,
				}
			end
		end
	end

	if prereqs.dependencies then
		for _, dep in ipairs(prereqs.dependencies) do
			for _, depNodeId in ipairs(dep.nodeIds) do
				if not allNodes[depNodeId] then
					return {
						success = false,
						reason = `Unknown prerequisite node id '${depNodeId}'`,
					}
				end
			end
		end
	end

	return { success = true, reason = "" }
end

--- Validates if a player can unlock a node.
--- @param playerId string -- The UserId as a string
--- @param node NodeConfig -- The node being evaluated
--- @param state PlayerSkillState -- The player's current state
--- @param allNodes { [string]: NodeConfig } -- All nodes in the tree
--- @return UnlockResult

function Validator.canUnlock(
	playerId: string,
	node: NodeConfig,
	state: PlayerSkillState,
	allNodes: { [string]: NodeConfig }
): UnlockResult
	if not node.prerequisites then
		return { success = true, reason = "" }
	end

	local prereqs = node.prerequisites

	-- Check level requirement
	if prereqs.level then
		if state.level < prereqs.level.minLevel then
			return {
				success = false,
				reason = "Requires level " .. tostring(prereqs.level.minLevel),
			}
		end
	end

	-- Check parent nodes
	if prereqs.parents then
		for _, parentReq in ipairs(prereqs.parents) do
			if not state.unlockedNodes[parentReq.nodeId] then
				return {
					success = false,
					reason = "Requires parent node: " .. parentReq.nodeId,
				}
			end
		end
	end

	-- Check explicit dependencies
	if prereqs.dependencies then
		for _, dep in ipairs(prereqs.dependencies) do
			for _, depNodeId in ipairs(dep.nodeIds) do
				if not state.unlockedNodes[depNodeId] then
					return {
						success = false,
						reason = "Requires node: " .. depNodeId,
					}
				end
			end
		end
	end

	-- Check custom predicates
	if prereqs.custom then
		for _, customReq in ipairs(prereqs.custom) do
			local passed = customReq.predicate(playerId, state)
			if not passed then
				return {
					success = false,
					reason = "Custom prerequisite not met",
				}
			end
		end
	end

	return { success = true, reason = "" }
end

--- Checks if a node is in an exclusive group and if so, if any siblings are unlocked.
--- @param node NodeConfig -- The node being evaluated
--- @param state PlayerSkillState -- The player's current state
--- @param allNodes { [string]: NodeConfig } -- All nodes in the tree
--- @return UnlockResult
function Validator.checkExclusivity(
	node: NodeConfig,
	state: PlayerSkillState,
	allNodes: { [string]: NodeConfig }
): UnlockResult
	if node.type ~= "exclusive" then
		return { success = true, reason = "" }
	end

	if not node.exclusiveGroup then
		return { success = true, reason = "" }
	end

	-- Find all siblings in the same exclusive group
	for _, otherNode in pairs(allNodes) do
		if otherNode.exclusiveGroup == node.exclusiveGroup and otherNode.id ~= node.id then
			if state.unlockedNodes[otherNode.id] then
				return {
					success = false,
					reason = "Exclusive choice already made in this group",
				}
			end
		end
	end

	return { success = true, reason = "" }
end

--- Checks if a node is a capstone and if all prior tier nodes are unlocked.
--- @param node NodeConfig -- The node being evaluated
--- @param state PlayerSkillState -- The player's current state
--- @param allNodes { [string]: NodeConfig } -- All nodes in the tree
--- @return UnlockResult
function Validator.checkCapstone(
	node: NodeConfig,
	state: PlayerSkillState,
	allNodes: { [string]: NodeConfig }
): UnlockResult
	-- A capstone is identified by having all nodes in its prerequisites
	-- This is a simple implementation; capstones require all parents to be unlocked
	if not node.prerequisites or not node.prerequisites.parents then
		return { success = true, reason = "" }
	end

	for _, parentReq in ipairs(node.prerequisites.parents) do
		if not state.unlockedNodes[parentReq.nodeId] then
			return {
				success = false,
				reason = "Capstone requires all parent nodes to be unlocked",
			}
		end
	end

	return { success = true, reason = "" }
end

return Validator
