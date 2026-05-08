--!strict

local Fusion = require(game:GetService("ReplicatedStorage"):WaitForChild("DevPackages"):WaitForChild("Fusion"))
local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("SkillTree"):WaitForChild("Types"))
local NodeComponent = require(script.Parent:WaitForChild("NodeComponent"))
local ConnectionLine = require(script.Parent:WaitForChild("ConnectionLine"))

type Scope = Fusion.Scope
type State = Fusion.State
type CategoryConfig = Types.CategoryConfig
type NodeConfig = Types.NodeConfig

type BranchCanvasProps = {
	category: CategoryConfig?,
	state: State,
	topInsetPx: number?,
	leftInsetPx: number?,
	bottomInsetPx: number?,
	onHover: (nodeId: string?, isHovering: boolean) -> (),
	onSelect: (nodeId: string) -> (),
}

local function BranchCanvas(scope: Scope, props: BranchCanvasProps): Instance
	local category = props.category
	local state = props.state
	local onHover = props.onHover
	local onSelect = props.onSelect
	local topIn = props.topInsetPx or 40
	local leftIn = props.leftInsetPx or 200
	local bottomIn = props.bottomInsetPx or 76

	local scale = scope:Value(1)
	local panX = scope:Value(0)
	local panY = scope:Value(0)

	local container = scope:New("Frame")({
		Name = "BranchCanvas",
		Size = UDim2.new(1, -leftIn, 1, -(topIn + bottomIn)),
		Position = UDim2.new(0, leftIn, 0, topIn),
		BackgroundColor3 = Color3.fromRGB(8, 12, 28),
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		ZIndex = 1,
	})

	local canvas = scope:New("Frame")({
		Name = "Canvas",
		Parent = container,
		Size = UDim2.new(0, 2000, 0, 2000),
		Position = UDim2.new(0, panX, 0, panY),
		BackgroundTransparency = 1,
	})

	if category then
		local idToNode: { [string]: NodeConfig } = {}
		for _, n in ipairs(category.nodes) do
			idToNode[n.id] = n
		end

		for _, node in ipairs(category.nodes) do
			if node.prerequisites and node.prerequisites.parents then
				for _, pref in ipairs(node.prerequisites.parents) do
					local parentNode = idToNode[pref.nodeId]
					if parentNode then
						local line = ConnectionLine(scope, {
							fromPos = parentNode.position,
							toPos = node.position,
							fromNodeId = parentNode.id,
							toNodeId = node.id,
							state = state,
							nodeSizePx = 80,
							thicknessPx = 2.5,
						})
						line.ZIndex = 0
						line.Parent = canvas
					end
				end
			end
		end

		for _, node in ipairs(category.nodes) do
			local isUnlocked = scope:Computed(function(use)
				return (use(state).unlockedNodes[node.id] or 0) > 0
			end)

			local canUnlock = scope:Computed(function(use)
				return (use(state).unlockedNodes[node.id] or 0) == 0
			end)

			local nodeComponent = NodeComponent(scope, {
				node = node,
				state = state,
				isUnlocked = isUnlocked,
				canUnlock = canUnlock,
				onSelect = function()
					onSelect(node.id)
				end,
				onHover = onHover,
			})

			nodeComponent.Parent = canvas
		end
	end

	-- Handle mouse wheel zoom
	local UserInputService = game:GetService("UserInputService")

	UserInputService.InputChanged:Connect(function(input: InputObject, _gameProcessed: boolean)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local currentScale = Fusion.peek(scale)
			local newScale = currentScale + (input.Position.Z * 0.1)
			newScale = math.clamp(newScale, 0.5, 3)
			scale:set(newScale)

			canvas.Size = UDim2.new(0, 2000 * newScale, 0, 2000 * newScale)
		end
	end)

	-- Mouse drag panning
	local isDragging = false
	local lastX, lastY = 0, 0

	container.InputBegan:Connect(function(input: InputObject, _gameProcessed: boolean)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = true
			local mouse = game:GetService("Players").LocalPlayer:GetMouse()
			lastX = mouse.X
			lastY = mouse.Y
		end
	end)

	container.InputEnded:Connect(function(input: InputObject, _gameProcessed: boolean)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = false
		end
	end)

	container.InputChanged:Connect(function(input: InputObject, _gameProcessed: boolean)
		if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mouse = game:GetService("Players").LocalPlayer:GetMouse()
			local dx = mouse.X - lastX
			local dy = mouse.Y - lastY

			panX:set(Fusion.peek(panX) + dx)
			panY:set(Fusion.peek(panY) + dy)
			canvas.Position = UDim2.new(0, Fusion.peek(panX), 0, Fusion.peek(panY))

			lastX = mouse.X
			lastY = mouse.Y
		end
	end)

	return container
end

return BranchCanvas
