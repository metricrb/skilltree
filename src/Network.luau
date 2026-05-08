--!strict

local Types = require(script.Parent.Types)
local Signal = require(script.Parent.Signal)

type PlayerSkillState = Types.PlayerSkillState
type RemoteConfig = Types.RemoteConfig

--- @class Network
--- Manages client-server communication via RemoteEvents.
local Network = {}
Network.__index = Network

type Network = {
	_replicatedStorage: Instance,
	_unlockRequest: RemoteEvent,
	_upgradeRequest: RemoteEvent,
	_stateUpdated: RemoteEvent,
	create: (self: Network) -> RemoteConfig,
	sendStateUpdate: (self: Network, playerId: string, state: PlayerSkillState) -> (),
	connectUnlockRequest: (self: Network, callback: (player: Player, nodeId: string) -> ()) -> (),
	connectUpgradeRequest: (self: Network, callback: (player: Player, nodeId: string) -> ()) -> (),
}

--- Creates a new Network instance and sets up RemoteEvents.
--- @return Network
function Network.new(): Network
	local self = setmetatable({}, Network) :: any
	self._replicatedStorage = game:GetService("ReplicatedStorage")
	return self
end

--- Creates RemoteEvents if they don't exist and returns RemoteConfig.
--- @return RemoteConfig
function Network:create(): RemoteConfig
	local unlockRequest = self._replicatedStorage:FindFirstChild("SkillTreeUnlockRequest")
	if not unlockRequest then
		unlockRequest = Instance.new("RemoteEvent")
		unlockRequest.Name = "SkillTreeUnlockRequest"
		unlockRequest.Parent = self._replicatedStorage
	end
	self._unlockRequest = unlockRequest :: RemoteEvent

	local upgradeRequest = self._replicatedStorage:FindFirstChild("SkillTreeUpgradeRequest")
	if not upgradeRequest then
		upgradeRequest = Instance.new("RemoteEvent")
		upgradeRequest.Name = "SkillTreeUpgradeRequest"
		upgradeRequest.Parent = self._replicatedStorage
	end
	self._upgradeRequest = upgradeRequest :: RemoteEvent

	local stateUpdated = self._replicatedStorage:FindFirstChild("SkillTreeStateUpdated")
	if not stateUpdated then
		stateUpdated = Instance.new("RemoteEvent")
		stateUpdated.Name = "SkillTreeStateUpdated"
		stateUpdated.Parent = self._replicatedStorage
	end
	self._stateUpdated = stateUpdated :: RemoteEvent

	return {
		unlockRequest = self._unlockRequest,
		upgradeRequest = self._upgradeRequest,
		stateUpdated = self._stateUpdated,
	}
end

--- Sends state update to a specific player.
--- @param playerId string -- The UserId as a string
--- @param state PlayerSkillState -- The updated state
function Network:sendStateUpdate(playerId: string, state: PlayerSkillState)
	local userId = tonumber(playerId)
	if not userId then
		return
	end
	local player = game:GetService("Players"):GetPlayerByUserId(userId)
	if player then
		self._stateUpdated:FireClient(player, state)
	end
end

--- Connects to unlock requests from clients.
--- @param callback function -- Callback(player, nodeId)
function Network:connectUnlockRequest(callback: (player: Player, nodeId: string) -> ())
	self._unlockRequest.OnServerEvent:Connect(callback)
end

--- Connects to upgrade requests from clients.
--- @param callback function -- Callback(player, nodeId)
function Network:connectUpgradeRequest(callback: (player: Player, nodeId: string) -> ())
	self._upgradeRequest.OnServerEvent:Connect(callback)
end

return Network
