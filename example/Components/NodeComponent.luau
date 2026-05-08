--!strict

local Fusion = require(game:GetService("ReplicatedStorage"):WaitForChild("DevPackages"):WaitForChild("Fusion"))
local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("SkillTree"):WaitForChild("Types"))

type Scope = Fusion.Scope
type State = Fusion.State
type NodeConfig = Types.NodeConfig
type PlayerSkillState = Types.PlayerSkillState

type NodeComponentProps = {
	node: NodeConfig,
	state: State,
	isUnlocked: State,
	canUnlock: State,
	onSelect: () -> (),
	onHover: (nodeId: string?, isHovering: boolean) -> (),
}

local function NodeComponent(scope: Scope, props: NodeComponentProps): Instance
	local node = props.node
	local isUnlocked = props.isUnlocked
	local canUnlock = props.canUnlock
	local onSelect = props.onSelect
	local onHover = props.onHover

	local bgColor = scope:Computed(function(use)
		if use(isUnlocked) then
			return Color3.fromRGB(100, 200, 100)
		elseif use(canUnlock) then
			return Color3.fromRGB(200, 180, 100)
		else
			return Color3.fromRGB(100, 100, 100)
		end
	end)

	local container = scope:New("Frame")({
		Name = node.id,
		Size = UDim2.new(0, 80, 0, 80),
		Position = UDim2.new(0, node.position.x, 0, node.position.y),
		BackgroundColor3 = bgColor,
		BorderSizePixel = 2,
		BorderColor3 = Color3.fromRGB(42, 90, 110),
		ZIndex = 2,
	})

	local aspectRatio = scope:New("UIAspectRatioConstraint")({
		Parent = container,
		AspectRatio = 1,
	})

	scope:New("TextLabel")({
		Name = "NodeName",
		Parent = container,
		Size = UDim2.new(1, -4, 0.5, -2),
		Position = UDim2.new(0, 2, 0, 2),
		BackgroundTransparency = 1,
		Text = node.name,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 12,
		Font = Enum.Font.GothamSemibold,
		TextWrapped = true,
	})

	local rankDisplay = scope:Computed(function(use)
		if node.maxRank > 1 then
			local st = use(props.state) :: PlayerSkillState
			local rank = st.unlockedNodes[node.id] or 0
			return rank .. "/" .. tostring(node.maxRank)
		else
			return use(isUnlocked) and "✓" or "-"
		end
	end)

	scope:New("TextLabel")({
		Name = "Rank",
		Parent = container,
		Size = UDim2.new(1, -4, 0.5, -2),
		Position = UDim2.new(0, 2, 0.5, 0),
		BackgroundTransparency = 1,
		Text = rankDisplay,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 10,
		Font = Enum.Font.Gotham,
	})

	local button = scope:New("TextButton")({
		Name = "Button",
		Parent = container,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
	})

	button.MouseButton1Click:Connect(function()
		onSelect()
	end)

	button.MouseEnter:Connect(function()
		onHover(node.id, true)
	end)

	button.MouseLeave:Connect(function()
		onHover(node.id, false)
	end)

	return container
end

return NodeComponent
