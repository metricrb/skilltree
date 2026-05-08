--!strict

local SkillTree = require(game:GetService("ReplicatedStorage"):WaitForChild("SkillTree"):WaitForChild("SkillTree"))

return function()
	describe("Currency", function()
		local tree
		local config

		beforeEach(function()
			config = {
				currencies = { "points", "gold" },
				categories = nil,
				nodes = {
					{
						id = "expensive_node",
						type = "passive",
						name = "Expensive Node",
						maxRank = 1,
						cost = { points = 10, gold = 5 },
						prerequisites = nil,
						position = { x = 0, y = 0 },
						effectData = nil,
					},
				},
			}

			tree = SkillTree.new(config)
		end)

		it("should track multiple currencies per player", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = {},
				currencies = { points = 100, gold = 50 },
				level = 1,
			}

			expect(tree._playerStates["123"].currencies.points).to.equal(100)
			expect(tree._playerStates["123"].currencies.gold).to.equal(50)
		end)

		it("should add points to specific currency", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = {},
				currencies = { points = 0, gold = 0 },
				level = 1,
			}

			tree:addPoints("123", "points", 50)
			tree:addPoints("123", "gold", 25)

			expect(tree._playerStates["123"].currencies.points).to.equal(50)
			expect(tree._playerStates["123"].currencies.gold).to.equal(25)
		end)

		it("should require sufficient balance in all required currencies", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = {},
				currencies = { points = 20, gold = 2 },
				level = 1,
			}

			local result = tree:unlock("123", "expensive_node")
			expect(result.success).to.equal(false)
			expect(result.reason:match("Insufficient")).to.be.ok()
		end)

		it("should spend from all required currencies", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = {},
				currencies = { points = 100, gold = 50 },
				level = 1,
			}

			local result = tree:unlock("123", "expensive_node")
			expect(result.success).to.equal(true)
			expect(tree._playerStates["123"].currencies.points).to.equal(90)
			expect(tree._playerStates["123"].currencies.gold).to.equal(45)
		end)

		it("should handle currency balance correctly after respec", function()
			tree._playerStates["123"] = {
				playerId = "123",
				unlockedNodes = { expensive_node = 1 },
				currencies = { points = 90, gold = 45 },
				level = 1,
			}

			local success = tree:respec("123")
			expect(success).to.equal(true)
			expect(tree._playerStates["123"].currencies.points).to.equal(100)
			expect(tree._playerStates["123"].currencies.gold).to.equal(50)
		end)
	end)
end
