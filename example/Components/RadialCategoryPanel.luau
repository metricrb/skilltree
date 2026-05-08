--!strict

local Fusion = require(game:GetService("ReplicatedStorage"):WaitForChild("DevPackages"):WaitForChild("Fusion"))
local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("SkillTree"):WaitForChild("Types"))

type Scope = Fusion.Scope
type State = Fusion.State
type CategoryConfig = Types.CategoryConfig
type SkillTreeConfig = Types.SkillTreeConfig

type RadialCategoryPanelProps = {
	config: SkillTreeConfig,
	activeCategory: State,
	onCategorySelect: (categoryId: string) -> (),
	state: State,
	topInsetPx: number?,
	bottomInsetPx: number?,
}

local function RadialCategoryPanel(scope: Scope, props: RadialCategoryPanelProps): Instance
	local config = props.config
	local activeCategory = props.activeCategory
	local onCategorySelect = props.onCategorySelect

	local topIn = props.topInsetPx or 40
	local bottomIn = props.bottomInsetPx or 76

	local container = scope:New("Frame")({
		Name = "RadialCategoryPanel",
		Size = UDim2.new(0, 200, 1, -(topIn + bottomIn)),
		Position = UDim2.new(0, 0, 0, topIn),
		BackgroundColor3 = Color3.fromRGB(14, 20, 32),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ZIndex = 2,
	})

	scope:New("Frame")({
		Name = "RightEdgeGlow",
		Parent = container,
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.new(0, 1, 1, -12),
		Position = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = Color3.fromRGB(72, 200, 220),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
	})

	if config.categories then
		local numCategories = #config.categories
		local angle = (math.pi * 2) / numCategories
		local radius = 70

		for i, category in ipairs(config.categories) do
			local theta = angle * (i - 1)
			local x = 100 + math.cos(theta) * radius - 40
			local y = 100 + math.sin(theta) * radius - 40

			local isActive = scope:Computed(function(use)
				return use(activeCategory) == category.id
			end)

			local bgColor = scope:Computed(function(use)
				if use(isActive) then
					return Color3.fromRGB(100, 150, 200)
				else
					return Color3.fromRGB(60, 70, 90)
				end
			end)

			local categoryButton = scope:New("Frame")({
				Name = category.id,
				Size = UDim2.new(0, 80, 0, 80),
				Position = UDim2.new(0, x, 0, y),
				BackgroundColor3 = bgColor,
				BorderSizePixel = 1,
				BorderColor3 = Color3.fromRGB(100, 120, 150),
				Parent = container,
			})

			scope:New("TextLabel")({
				Parent = categoryButton,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = category.name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				Font = Enum.Font.GothamSemibold,
			})

			local clickDetector = scope:New("TextButton")({
				Parent = categoryButton,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "",
			})

			clickDetector.MouseButton1Click:Connect(function()
				onCategorySelect(category.id)
			end)
		end
	end

	return container
end

return RadialCategoryPanel
