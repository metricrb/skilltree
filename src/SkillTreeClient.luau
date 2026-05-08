--!strict

local Types = require(script.Parent.Types)
local Signal = require(script.Parent.Signal)

type PlayerSkillState = Types.PlayerSkillState
type RemoteConfig = Types.RemoteConfig

--- @class SkillTreeClient
--- Client-side skill tree instance. Manages state and communicates with server.
local SkillTreeClient = {}
SkillTreeClient.__index = SkillTreeClient

type SkillTreeClient = {
	_remotes: RemoteConfig,
	_state: PlayerSkillState,
	StateUpdated: Signal,
	new: (remotes: RemoteConfig) -> SkillTreeClient,
	requestUnlock: (self: SkillTreeClient, nodeId: string) -> (),
	requestUpgrade: (self: SkillTreeClient, nodeId: string) -> (),
	getState: (self: SkillTreeClient) -> PlayerSkillState,
	_onStateUpdated: (self: SkillTreeClient, state: PlayerSkillState) -> (),
}

--- @prop StateUpdated Signal<PlayerSkillState>
--- @within SkillTreeClient
--- Fired when server sends a state update. Argument: state

--- Creates a new SkillTreeClient instance.
--- @param remotes RemoteConfig -- Remote events from server
--- @return SkillTreeClient
function SkillTreeClient.new(remotes: RemoteConfig): SkillTreeClient
	local self = setmetatable({}, SkillTreeClient) :: any
	self._remotes = remotes
	self._state = {
		playerId = "",
		unlockedNodes = {},
		currencies = {},
		level = 1,
	}
	self.StateUpdated = Signal.new()

	-- Listen for state updates from server
	self._remotes.stateUpdated.OnClientEvent:Connect(function(state: PlayerSkillState)
		self:_onStateUpdated(state)
	end)

	return self
end

--- Requests to unlock a node on the server.
--- @param nodeId string -- The node identifier
function SkillTreeClient:requestUnlock(nodeId: string)
	self._remotes.unlockRequest:FireServer(nodeId)
end

--- Requests to upgrade a multi-rank node on the server.
--- @param nodeId string -- The node identifier
function SkillTreeClient:requestUpgrade(nodeId: string)
	self._remotes.upgradeRequest:FireServer(nodeId)
end

--- Returns the current client state.
--- @return PlayerSkillState -- The current state
function SkillTreeClient:getState(): PlayerSkillState
	return self._state
end

--- @private
function SkillTreeClient:_onStateUpdated(state: PlayerSkillState)
	self._state = state
	self.StateUpdated:fire(state)
end

return SkillTreeClient
