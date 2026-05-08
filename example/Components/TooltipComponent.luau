--!strict

local Fusion = require(game:GetService("ReplicatedStorage"):WaitForChild("DevPackages"):WaitForChild("Fusion"))
local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("SkillTree"):WaitForChild("Types"))

type Scope = Fusion.Scope
type State = Fusion.State
type NodeConfig = Types.NodeConfig

type TooltipProps = {
	hoveredNodeId: State,
	nodes: { [string]: NodeConfig },
	state: State,
	parentSize: State,
}

local function TooltipComponent(scope: Scope, props: TooltipProps): Instance
	local hoveredNodeId = props.hoveredNodeId
	local nodes = props.nodes
	local state = props.state

	local isVisible = scope:Computed(function(use)
		return use(hoveredNodeId) ~= nil
	end)

	local tooltipText = scope:Computed(function(use)
		local nodeId = use(hoveredNodeId)
		if not nodeId then
			return ""
		end

		local node = nodes[nodeId]
		if not node then
			return ""
		end

		local text = node.name .. " (" .. node.type .. ")\n"

		if node.maxRank > 1 then
			local st = use(state)
			local rank = st.unlockedNodes[nodeId] or 0
			text = text .. "Rank: " .. tostring(rank) .. "/" .. tostring(node.maxRank) .. "\n"
		end

		text = text .. "Cost: "
		for currency, cost in pairs(node.cost) do
			text = text .. cost .. " " .. currency .. " "
		end

		if node.description then
			text = text .. "\n" .. node.description
		end

		return text
	end)

	local container = scope:New("Frame")({
		Name = "Tooltip",
		Size = UDim2.new(0, 250, 0, 100),
		BackgroundColor3 = Color3.fromRGB(40, 40, 50),
		BorderSizePixel = 1,
		BorderColor3 = Color3.fromRGB(100, 150, 200),
		Visible = isVisible,
	})

	scope:New("TextLabel")({
		Name = "Content",
		Parent = container,
		Size = UDim2.new(1, -10, 1, -10),
		Position = UDim2.new(0, 5, 0, 5),
		BackgroundTransparency = 1,
		Text = tooltipText,
		TextColor3 = Color3.fromRGB(200, 220, 255),
		TextSize = 11,
		Font = Enum.Font.Gotham,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})

	return container
end

return TooltipComponent
