--!strict

local Types = require(script.Parent.Types)

type EffectData = Types.EffectData

--- @class EffectHandler
--- Manages the application of skill effects when nodes are unlocked.
local EffectHandler = {}
EffectHandler.__index = EffectHandler

type EffectCallback = (playerId: string, nodeId: string, rank: number, effectData: EffectData) -> ()

type EffectHandler = {
	_callbacks: { [string]: EffectCallback },
	register: (self: EffectHandler, nodeId: string, callback: EffectCallback) -> (),
	apply: (self: EffectHandler, playerId: string, nodeId: string, rank: number, effectData: EffectData?) -> (),
}

--- Creates a new EffectHandler instance.
--- @return EffectHandler
function EffectHandler.new(): EffectHandler
	local self = setmetatable({}, EffectHandler) :: any
	self._callbacks = {}
	return self
end

--- Registers an effect callback for a specific node.
--- @param nodeId string -- The node identifier
--- @param callback function -- Callback(playerId, nodeId, rank, effectData)
function EffectHandler:register(nodeId: string, callback: EffectCallback)
	self._callbacks[nodeId] = callback
end

--- Applies an effect for a node unlock or upgrade.
--- @param playerId string -- The UserId as a string
--- @param nodeId string -- The node identifier
--- @param rank number -- The current rank of the node
--- @param effectData EffectData? -- Effect payload from the node config
function EffectHandler:apply(playerId: string, nodeId: string, rank: number, effectData: EffectData?)
	local callback = self._callbacks[nodeId]
	if callback then
		task.spawn(callback, playerId, nodeId, rank, effectData or {})
	end
end

return EffectHandler
