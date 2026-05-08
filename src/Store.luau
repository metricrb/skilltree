--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ProfileStore = require(ServerScriptService:WaitForChild("ServerPackages"):WaitForChild("ProfileStore"))
local Types = require(script.Parent.Types)

type PlayerSkillState = Types.PlayerSkillState

--- @class Store
--- Handles Mad Studio ProfileStore integration for skill tree player state persistence.
local Store = {}
Store.__index = Store

type Store = {
	_profileStore: any,
	_profiles: { [string]: any },
	_defaultData: PlayerSkillState,
	load: (self: Store, playerId: string) -> PlayerSkillState?,
	save: (self: Store, playerId: string, state: PlayerSkillState) -> boolean,
	clear: (self: Store, playerId: string) -> boolean,
	release: (self: Store, playerId: string) -> (),
}

--- Creates a new Store instance.
--- @param storeName string -- DataStore name for ProfileStore
--- @param defaultState PlayerSkillState -- Default state for new players (serializable fields only)
--- @return Store
function Store.new(storeName: string, defaultState: PlayerSkillState): Store
	local self = setmetatable({}, Store) :: any
	local template = {
		unlockedNodes = defaultState.unlockedNodes,
		currencies = defaultState.currencies,
		level = defaultState.level,
	}
	self._profileStore = ProfileStore.New(storeName, template)
	self._profiles = {}
	self._defaultData = defaultState
	return self
end

--- Loads a player's skill tree state from ProfileStore.
--- @param playerId string -- The UserId as a string
--- @return PlayerSkillState? -- The player's state, or nil if load failed
function Store:load(playerId: string): PlayerSkillState?
	local profile = self._profileStore:StartSessionAsync(playerId)
	if not profile then
		return nil
	end

	local numericId = tonumber(playerId)
	if numericId then
		profile:AddUserId(numericId)
	end
	profile:Reconcile()

	self._profiles[playerId] = profile

	local data = profile.Data
	return {
		playerId = playerId,
		unlockedNodes = data.unlockedNodes or {},
		currencies = data.currencies or {},
		level = data.level or 1,
	}
end

--- Saves a player's skill tree state to ProfileStore.
--- @param playerId string -- The UserId as a string
--- @param state PlayerSkillState -- The state to save
--- @return boolean -- True if save succeeded
function Store:save(playerId: string, state: PlayerSkillState): boolean
	local profile = self._profiles[playerId]
	if not profile then
		return false
	end

	profile.Data.unlockedNodes = state.unlockedNodes
	profile.Data.currencies = state.currencies
	profile.Data.level = state.level

	return true
end

--- Clears all data for a player and resets to default state.
--- @param playerId string -- The UserId as a string
--- @return boolean -- True if clear succeeded
function Store:clear(playerId: string): boolean
	local profile = self._profiles[playerId]
	if not profile then
		return false
	end

	local template = self._defaultData
	profile.Data.unlockedNodes = {}
	profile.Data.currencies = table.clone(template.currencies)
	profile.Data.level = template.level

	return true
end

--- Ends the profile session after the server is done with this player's data (e.g. player left).
--- @param playerId string -- The UserId as a string
function Store:release(playerId: string)
	local profile = self._profiles[playerId]
	if profile then
		profile:EndSession()
		self._profiles[playerId] = nil
	end
end

return Store
