--!strict
-- Edge-to-edge line between skill nodes (GuiObject rotation uses AnchorPoint as pivot).

local Fusion = require(game:GetService("ReplicatedStorage"):WaitForChild("DevPackages"):WaitForChild("Fusion"))
local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("SkillTree"):WaitForChild("Types"))

type Scope = Fusion.Scope
type State = Fusion.State
type NodePosition = Types.NodePosition

type ConnectionLineProps = {
	fromPos: NodePosition,
	toPos: NodePosition,
	fromNodeId: string,
	toNodeId: string,
	state: State,
	nodeSizePx: number?,
	thicknessPx: number?,
}

local function ConnectionLine(scope: Scope, props: ConnectionLineProps): Instance
	local fromPos = props.fromPos
	local toPos = props.toPos
	local state = props.state
	local cell = props.nodeSizePx or 80
	local half = cell / 2
	local thick = props.thicknessPx or 2.5

	local fromCx = fromPos.x + half
	local fromCy = fromPos.y + half
	local toCx = toPos.x + half
	local toCy = toPos.y + half
	local dx = toCx - fromCx
	local dy = toCy - fromCy
	local distCenters = math.sqrt(dx * dx + dy * dy)
	if distCenters < 1 then
		distCenters = 1
	end

	local ux = dx / distCenters
	local uy = dy / distCenters

	-- Visible segment sits between the two squares (edges meet node borders).
	local lineLen = math.max(distCenters - cell, 1)
	local sx = fromCx + ux * half
	local sy = fromCy + uy * half

	local fromOn = scope:Computed(function(use)
		return (use(state).unlockedNodes[props.fromNodeId] or 0) > 0
	end)

	local toOn = scope:Computed(function(use)
		return (use(state).unlockedNodes[props.toNodeId] or 0) > 0
	end)

	local lineColor = scope:Computed(function(use)
		local parentLit = use(fromOn)
		local childLit = use(toOn)
		if parentLit and childLit then
			return Color3.fromRGB(120, 245, 255)
		elseif parentLit then
			return Color3.fromRGB(78, 200, 218)
		else
			return Color3.fromRGB(36, 70, 94)
		end
	end)

	local lineTransparency = scope:Computed(function(use)
		if use(fromOn) then
			return 0.1
		else
			return 0.48
		end
	end)

	local rotationDeg = math.deg(math.atan2(dy, dx))

	local line = scope:New("Frame")({
		Name = "Connection",
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(lineLen, thick),
		Position = UDim2.fromOffset(sx, sy),
		Rotation = rotationDeg,
		BackgroundColor3 = lineColor,
		BackgroundTransparency = lineTransparency,
		BorderSizePixel = 0,
		ZIndex = 0,
	})

	scope:New("UICorner")({
		Parent = line,
		CornerRadius = UDim.new(0, math.max(1, math.floor(thick / 2 + 0.5))),
	})

	return line
end

return ConnectionLine
