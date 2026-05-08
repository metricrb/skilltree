--!strict
-- Bottom status bar inspired by constellation-style RPG skill screens (levels + pooled currency).

local Fusion = require(game:GetService("ReplicatedStorage"):WaitForChild("DevPackages"):WaitForChild("Fusion"))

type Scope = Fusion.Scope
type State = Fusion.State

type HUDProps = {
	state: State,
	footerHeightPx: number,
	primaryCurrency: string?,
}

local function HUDComponent(scope: Scope, props: HUDProps): Instance
	local state = props.state
	local footerH = props.footerHeightPx
	local currencyKey = props.primaryCurrency or "points"

	local container = scope:New("Frame")({
		Name = "BottomStatusBar",
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.new(1, 0, 0, footerH),
		Position = UDim2.new(0, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(8, 14, 24),
		BackgroundTransparency = 0.08,
		ZIndex = 3,
	})

	scope:New("UIPadding")({
		Parent = container,
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
	})

	scope:New("Frame")({
		Name = "TopAccent",
		Parent = container,
		Size = UDim2.new(1, 40, 0, 2),
		Position = UDim2.new(0, -20, 0, 0),
		AnchorPoint = Vector2.new(0, 0),
		BackgroundColor3 = Color3.fromRGB(72, 200, 220),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
	})

	scope:New("TextLabel")({
		Name = "PointsLabel",
		Parent = container,
		Size = UDim2.new(0.42, -8, 0, 22),
		Position = UDim2.new(0, 0, 0, 12),
		BackgroundTransparency = 1,
		Text = "SKILL POINTS",
		TextColor3 = Color3.fromRGB(180, 210, 220),
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local pointsValue = scope:Computed(function(use)
		local st = use(state)
		local val = st.currencies[currencyKey]
		if typeof(val) == "number" then
			return tostring(math.floor(val))
		end
		if typeof(val) ~= "nil" then
			return tostring(val)
		end
		return "–"
	end)

	scope:New("TextLabel")({
		Name = "PointsValue",
		Parent = container,
		Size = UDim2.new(0.42, -8, 0, footerH - 36),
		Position = UDim2.new(0, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = pointsValue,
		TextColor3 = Color3.fromRGB(235, 250, 255),
		TextSize = 32,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	scope:New("TextLabel")({
		Name = "PowerLabel",
		Parent = container,
		Size = UDim2.new(0.24, -8, 0, 22),
		Position = UDim2.new(0.5, 0, 0, 12),
		BackgroundTransparency = 1,
		Text = "POWER",
		TextColor3 = Color3.fromRGB(180, 210, 220),
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local powerVal = scope:Computed(function(use)
		return "Lv " .. tostring(use(state).level)
	end)

	scope:New("TextLabel")({
		Name = "PowerValue",
		Parent = container,
		Size = UDim2.new(0.24, -8, 0, footerH - 36),
		Position = UDim2.new(0.5, 0, 0, 28),
		BackgroundTransparency = 1,
		Text = powerVal,
		TextColor3 = Color3.fromRGB(185, 220, 255),
		TextSize = 26,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local currencyStrip = scope:Computed(function(use)
		local st = use(state)
		local segments = {}
		for currency, balance in pairs(st.currencies) do
			table.insert(segments, `{currency}: {tostring(balance)}`)
		end
		table.sort(segments)
		if #segments == 0 then
			return ""
		end
		return table.concat(segments, "   ·   ")
	end)

	scope:New("TextLabel")({
		Name = "CurrenciesSmall",
		Parent = container,
		Size = UDim2.new(0.28, 0, 0, 44),
		Position = UDim2.new(1, -4, 0, 14),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Text = currencyStrip,
		TextColor3 = Color3.fromRGB(130, 160, 178),
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	return container
end

return HUDComponent
