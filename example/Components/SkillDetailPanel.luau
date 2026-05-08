--!strict
-- Slide-style detail card reminiscent of constellation skill UIs — preview stripe, info, Acquire.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage:WaitForChild("DevPackages"):WaitForChild("Fusion"))
local Types = require(ReplicatedStorage:WaitForChild("SkillTree"):WaitForChild("Types"))

type Scope = Fusion.Scope
type State = Fusion.State
type NodeConfig = Types.NodeConfig

type SkillDetailProps = {
	selectedNodeId: State,
	allNodesById: { [string]: NodeConfig },
	state: State,
	topInsetPx: number,
	bottomGuardPx: number,
	onAcquire: (nodeId: string) -> (),
	onClose: () -> (),
}

local function SkillDetailPanel(scope: Scope, props: SkillDetailProps): Instance
	local selectedNodeId = props.selectedNodeId
	local allNodes = props.allNodesById

	local visible = scope:Computed(function(use)
		local id = use(selectedNodeId)
		return typeof(id) == "string" and id ~= ""
	end)

	local wrapper = scope:New("Frame")({
		Name = "SkillDetailPanel",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.new(0, 320, 0.55, -(props.topInsetPx + props.bottomGuardPx)),
		Position = UDim2.new(1, -20, 0, props.topInsetPx + 8),
		BackgroundTransparency = 1,
		Visible = visible,
		ZIndex = 6,
	})

	local bg = scope:New("Frame")({
		Name = "Card",
		Parent = wrapper,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 16, 28),
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		ZIndex = 1,
	})

	scope:New("UICorner")({
		Parent = bg,
		CornerRadius = UDim.new(0, 8),
	})

	scope:New("UIStroke")({
		Parent = bg,
		Thickness = 1,
		Transparency = 0.65,
		Color = Color3.fromRGB(72, 200, 220),
	})

	scope:New("Frame")({
		Name = "PreviewStripe",
		Parent = bg,
		Size = UDim2.new(1, -16, 0, 110),
		Position = UDim2.new(0, 8, 0, 8),
		BackgroundColor3 = Color3.fromRGB(16, 32, 48),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 2,
	})

	local titleLabel = scope:Computed(function(use)
		local id = use(selectedNodeId)
		local node = typeof(id) == "string" and allNodes[id] or nil
		return node and node.name or ""
	end)

	local subtitle = scope:Computed(function(use)
		local id = use(selectedNodeId)
		local node = typeof(id) == "string" and allNodes[id] or nil
		return node and `({node.type})` or ""
	end)

	local body = scope:Computed(function(use)
		local id = use(selectedNodeId)
		local node = typeof(id) == "string" and allNodes[id] or nil
		if not node then
			return ""
		end
		local txt = ""
		if node.description then
			txt = txt .. node.description .. "\n\n"
		end
		txt = txt .. "Cost: "
		for c, amt in pairs(node.cost) do
			txt ..= tostring(amt) .. " " .. c .. "  "
		end
		txt ..= "\nRank cap: " .. tostring(node.maxRank)
		return txt
	end)

	scope:New("TextLabel")({
		Name = "Subtitle",
		Parent = bg,
		Size = UDim2.new(1, -24, 0, 20),
		Position = UDim2.new(0, 14, 0, 128),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = subtitle,
		TextColor3 = Color3.fromRGB(130, 160, 180),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2,
	})

	scope:New("TextLabel")({
		Name = "Title",
		Parent = bg,
		Size = UDim2.new(1, -54, 0, 54),
		Position = UDim2.new(0, 14, 0, 72),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = titleLabel,
		TextColor3 = Color3.fromRGB(238, 245, 255),
		TextSize = 21,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 2,
	})

	scope:New("TextLabel")({
		Name = "Body",
		Parent = bg,
		Size = UDim2.new(1, -28, 1, -(54 + 90 + 50)),
		Position = UDim2.new(0, 14, 0, 156),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = body,
		TextColor3 = Color3.fromRGB(200, 215, 230),
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 2,
	})

	local closeBtn = scope:New("TextButton")({
		Name = "Close",
		Parent = bg,
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.new(1, -44, 0, 12),
		BackgroundColor3 = Color3.fromRGB(25, 40, 54),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Text = "✕",
		TextColor3 = Color3.fromRGB(200, 220, 230),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		AutoButtonColor = false,
		ZIndex = 3,
	})

	scope:New("UICorner")({
		Parent = closeBtn,
		CornerRadius = UDim.new(1, 0),
	})

	closeBtn.MouseButton1Click:Connect(function()
		props.onClose()
	end)

	local acquire = scope:New("TextButton")({
		Name = "Acquire",
		Parent = bg,
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.new(1, -32, 0, 42),
		Position = UDim2.new(0.5, 0, 1, -16),
		BackgroundColor3 = Color3.fromRGB(28, 95, 120),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Text = "",
		ZIndex = 3,
		AutoButtonColor = true,
	})

	scope:New("UICorner")({
		Parent = acquire,
		CornerRadius = UDim.new(0, 8),
	})

	scope:New("TextLabel")({
		Name = "AcquireLabel",
		Parent = acquire,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "ACQUIRE SKILL",
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(230, 250, 255),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 4,
	})

	acquire.MouseButton1Click:Connect(function()
		local id = Fusion.peek(selectedNodeId) :: string?
		if typeof(id) == "string" and id ~= "" then
			props.onAcquire(id)
		end
	end)

	return wrapper
end

return SkillDetailPanel
