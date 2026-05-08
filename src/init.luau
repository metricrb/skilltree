--!strict

--- @class SkillTreePackage
--- Main package export for the skill tree system.

return {
	Types = require(script:WaitForChild("Types")),
	Signal = require(script:WaitForChild("Signal")),
	Validator = require(script:WaitForChild("Validator")),
	Store = require(script:WaitForChild("Store")),
	EffectHandler = require(script:WaitForChild("EffectHandler")),
	Network = require(script:WaitForChild("Network")),
	SkillTree = require(script:WaitForChild("SkillTree")),
	SkillTreeClient = require(script:WaitForChild("SkillTreeClient")),
}
