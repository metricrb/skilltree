--!strict

--- @class Types
--- Shared Luau type definitions for skill trees, configuration, and server state.

--- @interface NodePosition
--- @within Types
--- .x number
--- .y number
---
--- Canvas position for a node.
export type NodePosition = {
	x: number,
	y: number,
}

--- @type CostMap { [string]: number }
--- @within Types
--- Currency-to-amount mapping for unlock costs.
export type CostMap = { [string]: number }

--- @interface PrerequisiteLevel
--- @within Types
--- .minLevel number
---
--- Minimum player level requirement.
export type PrerequisiteLevel = {
	minLevel: number,
}

--- @interface PrerequisiteNode
--- @within Types
--- .nodeId string
---
--- Parent node that must be unlocked.
export type PrerequisiteNode = {
	nodeId: string,
}

--- @interface PrerequisiteDependency
--- @within Types
--- .nodeIds { string }
---
--- Set of specific nodes that must all be unlocked.
export type PrerequisiteDependency = {
	nodeIds: { string },
}

--- @interface PrerequisiteCustom
--- @within Types
--- .predicate (playerId: string, state: PlayerSkillState) -> boolean
---
--- Custom validation function.
export type PrerequisiteCustom = {
	predicate: (playerId: string, state: PlayerSkillState) -> boolean,
}

--- @interface Prerequisites
--- @within Types
--- .level PrerequisiteLevel?
--- .parents { PrerequisiteNode }?
--- .dependencies { PrerequisiteDependency }?
--- .custom { PrerequisiteCustom }?
---
--- Union of prerequisite constraints. Any number of these can be combined.
export type Prerequisites = {
	level: PrerequisiteLevel?,
	parents: { PrerequisiteNode }?,
	dependencies: { PrerequisiteDependency }?,
	custom: { PrerequisiteCustom }?,
}

--- @type EffectData { [string]: any }
--- @within Types
--- Effect payload passed to EffectHandler.
export type EffectData = { [string]: any }

--- @interface NodeConfig
--- @within Types
--- .id string
--- .type "passive" | "active" | "multirank" | "exclusive"
--- .name string
--- .description string?
--- .icon string?
--- .maxRank number
--- .cost CostMap
--- .prerequisites Prerequisites?
--- .position NodePosition
--- .effectData EffectData?
--- .category string?
--- .exclusiveGroup string?
---
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
--- .id string
--- .name string
--- .icon string?
--- .description string?
--- .position NodePosition
--- .nodes { NodeConfig }
---
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
--- .categories { CategoryConfig }?
--- .nodes { NodeConfig }?
--- .layout "linear" | "branching" | "web" | "radial"?
--- .currencies { string }
---
--- Full skill tree configuration supporting multiple layout topologies.
export type SkillTreeConfig = {
	categories: { CategoryConfig }?,
	nodes: { NodeConfig }?,
	layout: "linear" | "branching" | "web" | "radial"?,
	currencies: { string },
}

--- @interface PlayerSkillState
--- @within Types
--- .playerId string
--- .unlockedNodes { [string]: number }
--- .currencies { [string]: number }
--- .level number
---
--- Player-specific skill tree state, serializable for storage.
export type PlayerSkillState = {
	playerId: string,
	unlockedNodes: { [string]: number },
	currencies: { [string]: number },
	level: number,
}

--- @interface UnlockResult
--- @within Types
--- .success boolean
--- .reason string
---
--- Result of an unlock or upgrade attempt.
export type UnlockResult = {
	success: boolean,
	reason: string,
}

--- @interface RemoteConfig
--- @within Types
--- .unlockRequest RemoteEvent
--- .upgradeRequest RemoteEvent
--- .stateUpdated RemoteEvent
---
--- Configuration for client-server RemoteEvent communication.
export type RemoteConfig = {
	unlockRequest: RemoteEvent,
	upgradeRequest: RemoteEvent,
	stateUpdated: RemoteEvent,
}

return {}
