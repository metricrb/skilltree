--!strict

local Validator = require(game:GetService("ReplicatedStorage"):WaitForChild("SkillTree"):WaitForChild("Validator"))

return function()
	describe("Validator", function()
		local mockNode
		local mockState

		beforeEach(function()
			mockNode = {
				id = "test_node",
				type = "passive",
				maxRank = 1,
				cost = { points = 10 },
				prerequisites = nil,
			}

			mockState = {
				playerId = "123",
				unlockedNodes = {},
				currencies = { points = 100 },
				level = 1,
			}
		end)

		it("should reject invalid cost currency keys", function()
			local result = Validator.validateCostAgainstConfig({ gold = 10 }, { "points" })
			expect(result.success).to.equal(false)
		end)

		it("should reject invalid cost amounts", function()
			expect(Validator.validateCostAgainstConfig({ points = math.huge }, { "points" }).success).to.equal(false)
			expect(Validator.validateCostAgainstConfig({ points = -1 }, { "points" }).success).to.equal(false)
		end)

		it("should reject unknown prerequisite node ids", function()
			mockNode.prerequisites = {
				parents = { { nodeId = "missing_parent" } },
			}
			local result = Validator.validateReferencedNodeIds(mockNode, {})
			expect(result.success).to.equal(false)
		end)

		it("should allow unlock with no prerequisites", function()
			local result = Validator.canUnlock("123", mockNode, mockState, {})
			expect(result.success).to.equal(true)
		end)

		it("should reject unlock when level too low", function()
			mockNode.prerequisites = {
				level = { minLevel = 10 },
			}

			local result = Validator.canUnlock("123", mockNode, mockState, {})
			expect(result.success).to.equal(false)
			expect(result.reason:match("level")).to.be.ok()
		end)

		it("should allow unlock when level sufficient", function()
			mockState.level = 10
			mockNode.prerequisites = {
				level = { minLevel = 10 },
			}

			local result = Validator.canUnlock("123", mockNode, mockState, {})
			expect(result.success).to.equal(true)
		end)

		it("should reject unlock when parent node not unlocked", function()
			mockNode.prerequisites = {
				parents = {
					{ nodeId = "parent_node" },
				},
			}

			local result = Validator.canUnlock("123", mockNode, mockState, {})
			expect(result.success).to.equal(false)
			expect(result.reason:match("parent")).to.be.ok()
		end)

		it("should allow unlock when parent node unlocked", function()
			mockState.unlockedNodes["parent_node"] = 1
			mockNode.prerequisites = {
				parents = {
					{ nodeId = "parent_node" },
				},
			}

			local result = Validator.canUnlock("123", mockNode, mockState, {})
			expect(result.success).to.equal(true)
		end)

		it("should reject unlock when dependency not met", function()
			mockNode.prerequisites = {
				dependencies = {
					{
						nodeIds = { "dep_1", "dep_2" },
					},
				},
			}

			local result = Validator.canUnlock("123", mockNode, mockState, {})
			expect(result.success).to.equal(false)
			expect(result.reason:match("requires")).to.be.ok()
		end)

		it("should allow unlock when all dependencies met", function()
			mockState.unlockedNodes["dep_1"] = 1
			mockState.unlockedNodes["dep_2"] = 1
			mockNode.prerequisites = {
				dependencies = {
					{
						nodeIds = { "dep_1", "dep_2" },
					},
				},
			}

			local result = Validator.canUnlock("123", mockNode, mockState, {})
			expect(result.success).to.equal(true)
		end)

		it("should evaluate custom predicates", function()
			mockNode.prerequisites = {
				custom = {
					{
						predicate = function(_playerId: string, _state: any)
							return false
						end,
					},
				},
			}

			local result = Validator.canUnlock("123", mockNode, mockState, {})
			expect(result.success).to.equal(false)
			expect(result.reason:match("Custom")).to.be.ok()
		end)

		it("should reject exclusive node if sibling unlocked", function()
			mockNode.type = "exclusive"
			mockNode.exclusiveGroup = "choice_group"
			mockState.unlockedNodes["sibling_node"] = 1

			local allNodes = {
				test_node = mockNode,
				sibling_node = {
					id = "sibling_node",
					type = "exclusive",
					exclusiveGroup = "choice_group",
				},
			}

			local result = Validator.checkExclusivity(mockNode, mockState, allNodes)
			expect(result.success).to.equal(false)
		end)

		it("should allow exclusive node if no siblings unlocked", function()
			mockNode.type = "exclusive"
			mockNode.exclusiveGroup = "choice_group"

			local allNodes = {
				test_node = mockNode,
				sibling_node = {
					id = "sibling_node",
					type = "exclusive",
					exclusiveGroup = "choice_group",
				},
			}

			local result = Validator.checkExclusivity(mockNode, mockState, allNodes)
			expect(result.success).to.equal(true)
		end)
	end)
end
