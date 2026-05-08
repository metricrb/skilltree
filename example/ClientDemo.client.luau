--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--- Avoid infinite yield when optional demo deps (`DevPackages`/Fusion, remotes) are missing.
local function waitChild(parent: Instance, name: string, timeoutSeconds: number): Instance?
	local found = parent:FindFirstChild(name)
	if found then
		return found
	end
	local deadline = os.clock() + timeoutSeconds
	while os.clock() < deadline do
		found = parent:FindFirstChild(name)
		if found then
			return found
		end
		task.wait(0.1)
	end
	return nil
end

local devPackages = waitChild(ReplicatedStorage, "DevPackages", 15)
if not devPackages then
	warn(
		"[SkillTree demo] ReplicatedStorage.DevPackages missing after 15s. "
			.. "Run `wally install` (Fusion is listed under [dev-dependencies] in wally.toml), then Rojo-sync `DevPackages` (see default.project.json)."
	)
	return
end

local fusionLoader = waitChild(devPackages, "Fusion", 10)
if not fusionLoader then
	warn("[SkillTree demo] DevPackages.Fusion missing. Re-run `wally install`.")
	return
end

local Fusion = require(fusionLoader :: any)

local SkillTreeClient = require(ReplicatedStorage:WaitForChild("SkillTree"):WaitForChild("SkillTreeClient"))
local Types = require(ReplicatedStorage:WaitForChild("SkillTree"):WaitForChild("Types"))
local ExampleConfig = require(ReplicatedStorage:WaitForChild("SkillTreeDemo"):WaitForChild("ExampleConfig"))

local function resolveComponentsFolder(): Folder?
	local parentFolder = script.Parent
	local sibling = waitChild(parentFolder, "Components", 12)
	if sibling and sibling:IsA("Folder") then
		return sibling
	end
	local underScript = waitChild(script, "Components", 2)
	if underScript and underScript:IsA("Folder") then
		return underScript
	end
	warn(
		"[SkillTree demo] Components folder missing. Expected `StarterPlayerScripts.SkillTreeDemoClient.Components` as a sibling of ClientDemo "
			.. "(fix Rojo `default.project.json` or re-sync)."
	)
	return nil
end

local componentsFolder = resolveComponentsFolder()
if not componentsFolder then
	return
end

local HUDComponent = require(componentsFolder:WaitForChild("HUDComponent"))
local RadialCategoryPanel = require(componentsFolder:WaitForChild("RadialCategoryPanel"))
local BranchCanvas = require(componentsFolder:WaitForChild("BranchCanvas"))
local SkillDetailPanel = require(componentsFolder:WaitForChild("SkillDetailPanel"))
local TooltipComponent = require(componentsFolder:WaitForChild("TooltipComponent"))

type SkillTreeConfig = Types.SkillTreeConfig
type NodeConfig = Types.NodeConfig

local exampleConfig: SkillTreeConfig = ExampleConfig

local function buildAllNodesById(cfg: SkillTreeConfig): { [string]: NodeConfig }
	local map: { [string]: NodeConfig } = {}
	if cfg.categories then
		for _, cat in ipairs(cfg.categories) do
			for _, node in ipairs(cat.nodes) do
				map[node.id] = node
			end
		end
	end
	return map
end

local allNodesById = buildAllNodesById(exampleConfig)

local HEADER_H = 40
local FOOTER_H = 76
local LEFT_PANEL_W = 200

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkillTreeUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local root = Fusion.scoped(Fusion)

-- Wait for remotes — Example.server creates them when SkillTree.new runs on the server (bounded wait)
local unlockRequest = waitChild(ReplicatedStorage, "SkillTreeUnlockRequest", 30)
local upgradeRequest = waitChild(ReplicatedStorage, "SkillTreeUpgradeRequest", 30)
local stateUpdated = waitChild(ReplicatedStorage, "SkillTreeStateUpdated", 30)

if not unlockRequest or not unlockRequest:IsA("RemoteEvent") then
	warn("[SkillTree demo] RemoteEvents missing after 30s. Ensure ServerScriptService.SkillTreeDemoServer.Example runs (creates SkillTree + remotes).")
	return
end
if not upgradeRequest or not upgradeRequest:IsA("RemoteEvent") or not stateUpdated or not stateUpdated:IsA("RemoteEvent") then
	warn("[SkillTree demo] Upgrade/state remotes missing. Check Example server script.")
	return
end

local remoteConfig = {
	unlockRequest = unlockRequest,
	upgradeRequest = upgradeRequest,
	stateUpdated = stateUpdated,
}

local client = SkillTreeClient.new(remoteConfig)

print("[SkillTree demo] ClientDemo started — awaiting server state (ProfileStore API must be enabled in Studio).")

-- Reactive state
local state = root:Value(client:getState())

-- Listen for state updates from server
local didAnnounceState = false
client.StateUpdated:connect(function(newState)
	state:set(newState)
	if not didAnnounceState and next(newState.currencies) ~= nil then
		didAnnounceState = true
		print(
			"[SkillTree demo] Server state synced (points in bottom bar). Select a node to open the detail card; use Acquire to unlock or upgrade."
		)
	end
end)

local activeCategory = root:Value(exampleConfig.categories and exampleConfig.categories[1].id or nil)
local hoveredNodeId = root:Value(nil :: string?)
local selectedNodeId = root:Value(nil :: string?)

-- Get current category object
local currentCategory = root:Computed(function(use)
	local catId = use(activeCategory)
	if exampleConfig.categories then
		for _, cat in ipairs(exampleConfig.categories) do
			if cat.id == catId then
				return cat
			end
		end
	end
	return nil
end)

-- Main layout
local mainContainer = root:New("Frame")({
	Parent = screenGui,
	Name = "MainLayout",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
})

local stellarBackdrop = root:New("Frame")({
	Name = "StellarBackdrop",
	Parent = mainContainer,
	ZIndex = 0,
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(4, 10, 28),
	BorderSizePixel = 0,
})

root:New("UIGradient")({
	Parent = stellarBackdrop,
	Rotation = 115,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 40, 68)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(10, 18, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 8, 22)),
	}),
	Transparency = NumberSequence.new(0.06),
})

local headerBar = root:New("Frame")({
	Name = "DemoHeader",
	Parent = mainContainer,
	ZIndex = 4,
	Size = UDim2.new(1, 0, 0, HEADER_H),
	Position = UDim2.new(0, 0, 0, 0),
	BorderSizePixel = 0,
	BackgroundColor3 = Color3.fromRGB(12, 20, 36),
	BackgroundTransparency = 0.12,
})

root:New("TextLabel")({
	Name = "HeaderTitle",
	Parent = headerBar,
	Size = UDim2.new(1, -32, 1, -8),
	Position = UDim2.new(0, 18, 0, 4),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "Skills",
	TextColor3 = Color3.fromRGB(210, 230, 240),
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
})

local hud = HUDComponent(root, {
	state = state,
	footerHeightPx = FOOTER_H,
	primaryCurrency = "points",
})
hud.Parent = mainContainer

local categoryPanel = RadialCategoryPanel(root, {
	config = exampleConfig,
	activeCategory = activeCategory,
	onCategorySelect = function(catId: string)
		activeCategory:set(catId)
	end,
	state = state,
	topInsetPx = HEADER_H,
	bottomInsetPx = FOOTER_H,
})
categoryPanel.Parent = mainContainer

local tooltip = TooltipComponent(root, {
	hoveredNodeId = hoveredNodeId,
	nodes = allNodesById,
	state = state,
	parentSize = root:Value(Vector2.new(1920, 1080)),
})
tooltip.ZIndex = 7
tooltip.Position = UDim2.new(0, 16, 0, HEADER_H + 6)
tooltip.Parent = mainContainer

SkillDetailPanel(root, {
	selectedNodeId = selectedNodeId,
	allNodesById = allNodesById,
	state = state,
	topInsetPx = HEADER_H,
	bottomGuardPx = FOOTER_H,
	onAcquire = function(nodeId: string)
		local st = Fusion.peek(state)
		if (st.unlockedNodes[nodeId] or 0) > 0 then
			client:requestUpgrade(nodeId)
		else
			client:requestUnlock(nodeId)
		end
	end,
	onClose = function()
		selectedNodeId:set(nil)
	end,
}).Parent = mainContainer

local branchCanvas: GuiObject?

local function mountBranchCanvas(categoryObj: Types.CategoryConfig?)
	if branchCanvas and branchCanvas.Parent then
		branchCanvas:Destroy()
		branchCanvas = nil
	end

	local canvas = BranchCanvas(root, {
		category = categoryObj,
		state = state,
		topInsetPx = HEADER_H,
		leftInsetPx = LEFT_PANEL_W,
		bottomInsetPx = FOOTER_H,
		onHover = function(nodeId: string?, isHovering: boolean)
			hoveredNodeId:set(isHovering and nodeId or nil)
		end,
		onSelect = function(nodeId: string)
			selectedNodeId:set(nodeId)
		end,
	})
	canvas.Parent = mainContainer
	branchCanvas = canvas
end

-- Fusion 0.3: Observer replaces deprecated Computed:onSubscribe patterns
Fusion.Observer(root, currentCategory):onBind(function()
	mountBranchCanvas(Fusion.peek(currentCategory))
	selectedNodeId:set(nil)
end)

print("[SkillTree demo] Skill tree UI visible — bottom HUD, constellation canvas, categories left.")

-- `game:BindToClose` is server-only; cleanup when the demo UI goes away / local player leaves.
local fusionCleanedUp = false
local function cleanupFusionScope()
	if fusionCleanedUp then
		return
	end
	fusionCleanedUp = true
	Fusion.doCleanup(root)
end

screenGui.Destroying:Connect(cleanupFusionScope)

local localPlayer = Players.LocalPlayer
if localPlayer then
	localPlayer.Destroying:Connect(cleanupFusionScope)
end
