--!strict

--- @interface NodePosition
--- @within Types
--- Canvas position for a node.
export type NodePosition = {
	x: number,
	y: number,
}

--- @interface CostMap
--- @within Types
--- Currency-to-amount mapping for unlock costs.
export type CostMap = { [string]: number }

--- @interface PrerequisiteLevel
--- @within Types
--- Minimum player level requirement.
export type PrerequisiteLevel = {
	minLevel: number,
}

--- @interface PrerequisiteNode
--- @within Types
--- Parent node that must be unlocked.
export type PrerequisiteNode = {
	nodeId: string,
}

--- @interface PrerequisiteDependency
--- @within Types
--- Set of specific nodes that must all be unlocked.
export type PrerequisiteDependency = {
	nodeIds: { string },
}

--- @interface PrerequisiteCustom
--- @within Types
--- Custom validation function.
export type PrerequisiteCustom = {
	predicate: (playerId: string, state: PlayerSkillState) -> boolean,
}

--- @type Prerequisites
--- @within Types
--- Union of prerequisite constraints. Any number of these can be combined.
export type Prerequisites = {
	level: PrerequisiteLevel?,
	parents: { PrerequisiteNode }?,
	dependencies: { PrerequisiteDependency }?,
	custom: { PrerequisiteCustom }?,
}

--- @interface EffectData
--- @within Types
--- Effect payload passed to EffectHandler.
export type EffectData = { [string]: any }

--- @interface NodeConfig
--- @within Types
--- Declarative definition of a skill tree node.
export type NodeConfig = {
	id: string,
	type: "passive" | "active" | "multirank" | "exclusive",
	name: string,
	description: string?,
	icon: string?,
	maxRank: number,
	cost: CostMap,
	prerequisites: Prerequisites?,
	position: NodePosition,
	effectData: EffectData?,
	category: string?,
	exclusiveGroup: string?,
}

--- @interface CategoryConfig
--- @within Types
--- Top-level category definition for radial layout.
export type CategoryConfig = {
	id: string,
	name: string,
	icon: string?,
	description: string?,
	position: NodePosition,
	nodes: { NodeConfig },
}

--- @interface SkillTreeConfig
--- @within Types
--- Full skill tree configuration supporting multiple layout topologies.
export type SkillTreeConfig = {
	categories: { CategoryConfig }?,
	nodes: { NodeConfig }?,
	layout: "linear" | "branching" | "web" | "radial"?,
	currencies: { string },
}

--- @interface PlayerSkillState
--- @within Types
--- Player-specific skill tree state, serializable for storage.
export type PlayerSkillState = {
	playerId: string,
	unlockedNodes: { [string]: number },
	currencies: { [string]: number },
	level: number,
}

--- @interface UnlockResult
--- @within Types
--- Result of an unlock or upgrade attempt.
export type UnlockResult = {
	success: boolean,
	reason: string,
}

--- @interface RemoteConfig
--- @within Types
--- Configuration for client-server RemoteEvent communication.
export type RemoteConfig = {
	unlockRequest: RemoteEvent,
	upgradeRequest: RemoteEvent,
	stateUpdated: RemoteEvent,
}

return {}
