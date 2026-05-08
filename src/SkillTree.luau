--!strict

local Types = require(script.Parent.Types)
local Signal = require(script.Parent.Signal)
local Validator = require(script.Parent.Validator)
local EffectHandler = require(script.Parent.EffectHandler)
local Store = require(script.Parent.Store)
local Network = require(script.Parent.Network)

type SkillTreeConfig = Types.SkillTreeConfig
type NodeConfig = Types.NodeConfig
type PlayerSkillState = Types.PlayerSkillState
type UnlockResult = Types.UnlockResult
type RemoteConfig = Types.RemoteConfig
type CostMap = Types.CostMap

--- @class SkillTree
--- The server-side skill tree instance. Manages unlock logic, currency, and player state.
local SkillTree = {}
SkillTree.__index = SkillTree

type SkillTree = {
	config: SkillTreeConfig,
	_allNodes: { [string]: NodeConfig },
	_playerStates: { [string]: PlayerSkillState },
	_store: Store,
	_effectHandler: EffectHandler,
	_network: Network,
	_remoteConfig: RemoteConfig,
	NodeUnlocked: Signal,
	new: (config: SkillTreeConfig) -> SkillTree,
	addPoints: (self: SkillTree, playerId: string, currency: string, amount: number) -> boolean,
	unlock: (self: SkillTree, playerId: string, nodeId: string) -> UnlockResult,
	upgrade: (self: SkillTree, playerId: string, nodeId: string) -> UnlockResult,
	getState: (self: SkillTree, playerId: string) -> PlayerSkillState?,
	getNode: (self: SkillTree, nodeId: string) -> NodeConfig?,
	respec: (self: SkillTree, playerId: string) -> boolean,
	loadPlayer: (self: SkillTree, playerId: string) -> boolean,
	savePlayer: (self: SkillTree, playerId: string) -> boolean,
	unloadPlayer: (self: SkillTree, playerId: string) -> (),
	_buildNodeMap: (config: SkillTreeConfig) -> { [string]: NodeConfig },
	_getRank: (state: PlayerSkillState, nodeId: string) -> number,
	_canAfford: (state: PlayerSkillState, cost: CostMap) -> boolean,
	_spendPoints: (state: PlayerSkillState, cost: CostMap) -> (),
	_normalizePersistedState: (self: SkillTree, state: PlayerSkillState) -> (),
	_isConfiguredCurrency: (self: SkillTree, currency: string) -> boolean,
}

--- @prop NodeUnlocked Signal<string, string, number>
--- @within SkillTree
--- Fired when a node is successfully unlocked or upgraded. Arguments: playerId, nodeId, rank.

--- Creates a new SkillTree instance.
--- @param config SkillTreeConfig -- The skill tree configuration
--- @return SkillTree
function SkillTree.new(config: SkillTreeConfig): SkillTree
	local self = setmetatable({}, SkillTree) :: any
	self.config = config
	self._allNodes = SkillTree._buildNodeMap(config)
	self._playerStates = {}
	self.NodeUnlocked = Signal.new()

	local defaultState: PlayerSkillState = {
		playerId = "",
		unlockedNodes = {},
		currencies = {},
		level = 1,
	}

	-- Initialize currency balances to 0
	for _, currency in ipairs(config.currencies) do
		defaultState.currencies[currency] = 0
	end

	self._store = Store.new("SkillTreeStore", defaultState)
	self._effectHandler = EffectHandler.new()
	self._network = Network.new()
	self._remoteConfig = self._network:create()

	-- Set up network listeners
	self._network:connectUnlockRequest(function(player: Player, nodeId: string)
		local result = self:unlock(tostring(player.UserId), nodeId)
		if result.success then
			local state = self._playerStates[tostring(player.UserId)]
			if state then
				self._network:sendStateUpdate(tostring(player.UserId), state)
			end
		end
	end)

	self._network:connectUpgradeRequest(function(player: Player, nodeId: string)
		local result = self:upgrade(tostring(player.UserId), nodeId)
		if result.success then
			local state = self._playerStates[tostring(player.UserId)]
			if state then
				self._network:sendStateUpdate(tostring(player.UserId), state)
			end
		end
	end)

	return self
end

--- Adds points to a player's currency balance.
--- @param playerId string -- The UserId as a string
--- @param currency string -- The currency name
--- @param amount number -- Amount to add
--- @return boolean -- True if successful
function SkillTree:addPoints(playerId: string, currency: string, amount: number): boolean
	local state = self._playerStates[playerId]
	if not state then
		return false
	end

	if not self:_isConfiguredCurrency(currency) then
		return false
	end

	if typeof(amount) ~= "number" or amount ~= amount or math.abs(amount) == math.huge then
		return false
	end

	local bal = state.currencies[currency]
	if typeof(bal) ~= "number" or bal ~= bal then
		bal = 0
	end

	if bal + amount < 0 then
		return false
	end

	state.currencies[currency] = bal + amount

	self._store:save(playerId, state)
	self._network:sendStateUpdate(playerId, state)

	return true
end

--- Attempts to unlock a node for the given player.
--- @param playerId string -- The UserId as a string
--- @param nodeId string -- The node identifier from SkillTreeConfig
--- @return UnlockResult -- { success: boolean, reason: string }
function SkillTree:unlock(playerId: string, nodeId: string): UnlockResult
	local state = self._playerStates[playerId]
	if not state then
		return { success = false, reason = "Player not loaded" }
	end

	local node = self._allNodes[nodeId]
	if not node then
		return { success = false, reason = "Node not found" }
	end

	-- Check if already unlocked
	if state.unlockedNodes[nodeId] then
		return { success = false, reason = "Node already unlocked" }
	end

	local refResult = Validator.validateReferencedNodeIds(node, self._allNodes)
	if not refResult.success then
		return refResult
	end

	local costValidity = Validator.validateCostAgainstConfig(node.cost, self.config.currencies)
	if not costValidity.success then
		return costValidity
	end

	-- Validate prerequisites
	local prereqResult = Validator.canUnlock(playerId, node, state, self._allNodes)
	if not prereqResult.success then
		return prereqResult
	end

	-- Check exclusivity
	local exclusResult = Validator.checkExclusivity(node, state, self._allNodes)
	if not exclusResult.success then
		return exclusResult
	end

	-- Check affordability
	if not self:_canAfford(state, node.cost) then
		return { success = false, reason = "Insufficient points" }
	end

	-- Spend points
	self:_spendPoints(state, node.cost)

	-- Mark as unlocked (rank 1 for non-multirank)
	state.unlockedNodes[nodeId] = 1

	-- Apply effect
	self._effectHandler:apply(playerId, nodeId, 1, node.effectData)

	-- Save and notify
	self._store:save(playerId, state)
	self.NodeUnlocked:fire(playerId, nodeId, 1)

	return { success = true, reason = "" }
end

--- Upgrades a multi-rank node for the given player.
--- @param playerId string -- The UserId as a string
--- @param nodeId string -- The node identifier
--- @return UnlockResult -- { success: boolean, reason: string }
function SkillTree:upgrade(playerId: string, nodeId: string): UnlockResult
	local state = self._playerStates[playerId]
	if not state then
		return { success = false, reason = "Player not loaded" }
	end

	local node = self._allNodes[nodeId]
	if not node then
		return { success = false, reason = "Node not found" }
	end

	if node.type == "multirank" or node.maxRank > 1 then
		local currentRank = self:_getRank(state, nodeId) or 0

		if currentRank == 0 then
			return { success = false, reason = "Node not unlocked" }
		end

		if currentRank >= node.maxRank then
			return { success = false, reason = "Node at max rank" }
		end

		local upgradeCostValidity = Validator.validateCostAgainstConfig(node.cost, self.config.currencies)
		if not upgradeCostValidity.success then
			return upgradeCostValidity
		end

		if not self:_canAfford(state, node.cost) then
			return { success = false, reason = "Insufficient points" }
		end

		self:_spendPoints(state, node.cost)
		state.unlockedNodes[nodeId] = currentRank + 1

		self._effectHandler:apply(playerId, nodeId, currentRank + 1, node.effectData)
		self._store:save(playerId, state)
		self.NodeUnlocked:fire(playerId, nodeId, currentRank + 1)

		return { success = true, reason = "" }
	else
		return { success = false, reason = "Node is not multi-rank" }
	end
end

--- Retrieves the current state for a player.
--- @param playerId string -- The UserId as a string
--- @return PlayerSkillState? -- The player's state, or nil if not loaded
function SkillTree:getState(playerId: string): PlayerSkillState?
	return self._playerStates[playerId]
end

--- Retrieves a node configuration by ID.
--- @param nodeId string -- The node identifier
--- @return NodeConfig? -- The node config, or nil if not found
function SkillTree:getNode(nodeId: string): NodeConfig?
	return self._allNodes[nodeId]
end

--- Resets a player's skill tree state, refunding all points.
--- @param playerId string -- The UserId as a string
--- @return boolean -- True if successful
function SkillTree:respec(playerId: string): boolean
	local state = self._playerStates[playerId]
	if not state then
		return false
	end

	self:_normalizePersistedState(state)

	-- Refund only currencies declared in config (validated cost prevents phantom keys from sticking)
	for nodeId, rank in pairs(state.unlockedNodes) do
		local node = self._allNodes[nodeId]
		if node and Validator.validateCostAgainstConfig(node.cost, self.config.currencies).success then
			for currency, cost in pairs(node.cost) do
				state.currencies[currency] += cost * rank
			end
		end
	end

	-- Clear unlocks
	table.clear(state.unlockedNodes)

	self._store:save(playerId, state)
	self._network:sendStateUpdate(playerId, state)

	return true
end

--- Loads a player's skill tree state from storage.
--- @param playerId string -- The UserId as a string
--- @return boolean -- True if successful
function SkillTree:loadPlayer(playerId: string): boolean
	local loaded = self._store:load(playerId)
	if not loaded then
		return false
	end

	self:_normalizePersistedState(loaded)

	self._playerStates[playerId] = loaded
	self._store:save(playerId, loaded)
	self._network:sendStateUpdate(playerId, loaded)
	return true
end

--- Saves a player's skill tree state to storage.
--- @param playerId string -- The UserId as a string
--- @return boolean -- True if successful
function SkillTree:savePlayer(playerId: string): boolean
	return self._store:save(playerId, self._playerStates[playerId])
end

--- Unloads and releases a player's data from memory.
--- @param playerId string -- The UserId as a string
function SkillTree:unloadPlayer(playerId: string)
	self._store:release(playerId)
	self._playerStates[playerId] = nil
end

--- @private
function SkillTree._buildNodeMap(config: SkillTreeConfig): { [string]: NodeConfig }
	local nodes: { [string]: NodeConfig } = {}

	if config.nodes then
		for _, node in ipairs(config.nodes) do
			nodes[node.id] = node
		end
	end

	if config.categories then
		for _, category in ipairs(config.categories) do
			for _, node in ipairs(category.nodes) do
				nodes[node.id] = node
			end
		end
	end

	return nodes
end

--- @private
function SkillTree:_getRank(state: PlayerSkillState, nodeId: string): number
	return state.unlockedNodes[nodeId] or 0
end

--- @private
function SkillTree:_canAfford(state: PlayerSkillState, cost: CostMap): boolean
	for currency, amount in pairs(cost) do
		local balance = state.currencies[currency]
		if typeof(balance) ~= "number" or balance ~= balance then
			balance = 0
		end
		if not self:_isConfiguredCurrency(currency) then
			return false
		end
		if balance < amount then
			return false
		end
	end
	return true
end

--- @private
function SkillTree:_spendPoints(state: PlayerSkillState, cost: CostMap)
	for currency, amount in pairs(cost) do
		local bal = state.currencies[currency]
		if typeof(bal) ~= "number" or bal ~= bal then
			bal = 0
		end
		state.currencies[currency] = bal - amount
	end
end

--- Strips datastore-injected currencies and clamps balances before any economy mutation.
--- @private
function SkillTree:_normalizePersistedState(state: PlayerSkillState)
	local clean: CostMap = {}
	for _, currency in ipairs(self.config.currencies) do
		local v = state.currencies[currency]
		if typeof(v) ~= "number" or v ~= v or math.abs(v) == math.huge then
			clean[currency] = 0
		else
			clean[currency] = math.max(0, v)
		end
	end
	state.currencies = clean

	local lv = state.level
	if typeof(lv) ~= "number" or lv ~= lv or math.abs(lv) == math.huge then
		state.level = 1
	else
		state.level = math.max(1, math.floor(lv))
	end
end

--- @private
function SkillTree:_isConfiguredCurrency(currency: string): boolean
	for _, allowed in ipairs(self.config.currencies) do
		if allowed == currency then
			return true
		end
	end
	return false
end

return SkillTree
