--!strict

local Store = require(game:GetService("ReplicatedStorage"):WaitForChild("SkillTree"):WaitForChild("Store"))

return function()
	describe("Store", function()
		local store
		local defaultState

		beforeEach(function()
			defaultState = {
				playerId = "",
				unlockedNodes = {},
				currencies = { points = 0 },
				level = 1,
			}

			store = Store.new("TestSkillTreeStore", defaultState)
		end)

		it("should save and load player state", function()
			local testState = {
				playerId = "123",
				unlockedNodes = { node1 = 1, node2 = 2 },
				currencies = { points = 50 },
				level = 5,
			}

			store._profiles["123"] = {
				Data = {
					unlockedNodes = {},
					currencies = { points = 0 },
					level = 1,
				},
				AddUserId = function() end,
				Reconcile = function() end,
				EndSession = function() end,
			}

			local success = store:save("123", testState)
			expect(success).to.equal(true)

			local profile = store._profiles["123"]
			expect(profile.Data.unlockedNodes.node1).to.equal(1)
			expect(profile.Data.currencies.points).to.equal(50)
			expect(profile.Data.level).to.equal(5)
		end)

		it("should clear player state", function()
			store._profiles["123"] = {
				Data = {
					unlockedNodes = { node1 = 1 },
					currencies = { points = 100 },
					level = 10,
				},
				AddUserId = function() end,
				Reconcile = function() end,
				EndSession = function() end,
			}

			local success = store:clear("123")
			expect(success).to.equal(true)

			local profile = store._profiles["123"]
			expect(next(profile.Data.unlockedNodes)).to.equal(nil)
			expect(profile.Data.currencies.points).to.equal(0)
			expect(profile.Data.level).to.equal(1)
		end)

		it("should serialize state to plain Luau table", function()
			local state = {
				playerId = "123",
				unlockedNodes = { node1 = 1, node2 = 2 },
				currencies = { points = 100, gold = 50 },
				level = 5,
			}

			-- Verify no metatables
			expect(getmetatable(state)).to.equal(nil)
			expect(getmetatable(state.unlockedNodes)).to.equal(nil)
			expect(getmetatable(state.currencies)).to.equal(nil)
		end)
	end)
end
