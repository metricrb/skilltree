--!strict

local SkillTree = require(game:GetService("ReplicatedStorage"):WaitForChild("SkillTree"):WaitForChild("SkillTree"))

return function()
	describe("SkillTree", function()
		local tree
		local config

		beforeEach(function()
			config = {
				currencies = { "points" },
				categories = nil,
				nodes = {
					{
						id = "basic_attack",
						type = "passive",
						name = "Basic Attack",
						maxRank = 1,
						cost = { points = 10 },
						prerequisites = nil,
						position = { x = 0, y = 0 },
						effectData = nil,
					},
					{
						id = "power_attack",
						type = "active",
						name = "Power Attack",
						maxRank = 1,
						cost = { points = 20 },
						prerequisites = {
							parents = { { nodeId = "basic_attack" } },
						},
						position = { x = 100, y = 0 },
						effectData = nil,
					},
					{
						id = "strength_boost",
						type = "multirank",
						name = "Strength Boost",
						maxRank = 5,
						cost = { points = 15 },
						prerequisites = nil,
						position = { x = 0, y = 100 },
						effectData = nil,
					},
				},
			}

			tree = SkillTree.new(config)
		end)

		it("should reject addPoints for currency not in config", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = {},
				currencies = { points = 50 },
				level = 1,
			}

			expect(tree:addPoints("123", "gems", 10)).to.equal(false)
			expect(tree._playerStates["123"].currencies.points).to.equal(50)
		end)

		it("should reject addPoints that would make balance negative", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = {},
				currencies = { points = 5 },
				level = 1,
			}

			expect(tree:addPoints("123", "points", -10)).to.equal(false)
			expect(tree._playerStates["123"].currencies.points).to.equal(5)
		end)

		it("should reject unlock when node cost references unconfigured currency", function()
			local invalidCostConfig = {
				currencies = { "points" },
				categories = nil,
				nodes = {
					{
						id = "bad_currency",
						type = "passive",
						name = "Bad",
						maxRank = 1,
						cost = { gold = 1 },
						prerequisites = nil,
						position = { x = 0, y = 0 },
						effectData = nil,
					},
				},
			}
			local t2 = SkillTree.new(invalidCostConfig)
			t2._playerStates["999"] = {
				playerId = "999",
				unlockedNodes = {},
				currencies = { points = 100 },
				level = 1,
			}
			local result = t2:unlock("999", "bad_currency")
			expect(result.success).to.equal(false)
			expect(result.reason:match("unrecognized")).to.be.ok()
		end)

		it("should initialize with empty player states", function()
			expect(tree._playerStates).to.be.ok()
			expect(next(tree._playerStates)).to.equal(nil)
		end)

		it("should add points to player currency", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = {},
				currencies = { points = 0 },
				level = 1,
			}

			local success = tree:addPoints("123", "points", 50)
			expect(success).to.equal(true)
			expect(tree._playerStates["123"].currencies.points).to.equal(50)
		end)

		it("should unlock a node with sufficient points", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = {},
				currencies = { points = 100 },
				level = 1,
			}

			local result = tree:unlock("123", "basic_attack")
			expect(result.success).to.equal(true)
			expect(tree._playerStates["123"].unlockedNodes.basic_attack).to.equal(1)
			expect(tree._playerStates["123"].currencies.points).to.equal(90)
		end)

		it("should reject unlock with insufficient points", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = {},
				currencies = { points = 5 },
				level = 1,
			}

			local result = tree:unlock("123", "basic_attack")
			expect(result.success).to.equal(false)
			expect(result.reason:match("Insufficient")).to.be.ok()
		end)

		it("should reject unlock if prerequisites not met", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = {},
				currencies = { points = 100 },
				level = 1,
			}

			local result = tree:unlock("123", "power_attack")
			expect(result.success).to.equal(false)
			expect(result.reason:match("parent")).to.be.ok()
		end)

		it("should upgrade multi-rank nodes", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = { strength_boost = 1 },
				currencies = { points = 100 },
				level = 1,
			}

			local result = tree:upgrade("123", "strength_boost")
			expect(result.success).to.equal(true)
			expect(tree._playerStates["123"].unlockedNodes.strength_boost).to.equal(2)
		end)

		it("should reject upgrade at max rank", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = { strength_boost = 5 },
				currencies = { points = 100 },
				level = 1,
			}

			local result = tree:upgrade("123", "strength_boost")
			expect(result.success).to.equal(false)
			expect(result.reason:match("max")).to.be.ok()
		end)

		it("should respec and refund all points", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = { basic_attack = 1, strength_boost = 3 },
				currencies = { points = 0 },
				level = 1,
			}

			local success = tree:respec("123")
			expect(success).to.equal(true)
			expect(next(tree._playerStates["123"].unlockedNodes)).to.equal(nil)
			expect(tree._playerStates["123"].currencies.points).to.equal(10 + (15 * 3))
		end)

		it("should return node configuration", function()
			local node = tree:getNode("basic_attack")
			expect(node).to.be.ok()
			expect(node.id).to.equal("basic_attack")
			expect(node.cost.points).to.equal(10)
		end)

		it("should emit NodeUnlocked signal on successful unlock", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = {},
				currencies = { points = 100 },
				level = 1,
			}

			local fired = false
			local connection = tree.NodeUnlocked:connect(function(playerId, nodeId, rank)
				if playerId == "123" and nodeId == "basic_attack" and rank == 1 then
					fired = true
				end
			end)

			tree:unlock("123", "basic_attack")
			expect(fired).to.equal(true)

			connection:disconnect()
		end)
	end)
end
