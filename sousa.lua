--==============================================================
-- SOUZA AIM + ESP
-- LocalScript -> StarterPlayer > StarterPlayerScripts
--==============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==============================================================
-- CONFIG
--==============================================================

local Settings = {
	Aimbot = false,

	ESP = false,
	ESPNames = true,

	ShowFOV = true,

	TeamCheck = false,
	WallCheck = false,

	FOV = 220,
	Smoothness = 0.22,

	AimPart = "Head"
}

--==============================================================
-- CORES
--==============================================================

local COLORS = {
	Background = Color3.fromRGB(14, 15, 20),
	Panel = Color3.fromRGB(20, 22, 29),
	Card = Color3.fromRGB(29, 32, 41),

	CardHover = Color3.fromRGB(34, 38, 49),

	Text = Color3.fromRGB(245, 245, 250),
	SubText = Color3.fromRGB(145, 150, 165),

	Accent = Color3.fromRGB(115, 85, 255),
	Accent2 = Color3.fromRGB(160, 100, 255),

	Enabled = Color3.fromRGB(70, 210, 125),
	Disabled = Color3.fromRGB(90, 94, 105),

	ESP = Color3.fromRGB(255, 75, 90)
}

--==============================================================
-- SCREEN GUI
--==============================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "SouzaAimESP"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

--==============================================================
-- FOV
--==============================================================

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Size = UDim2.fromOffset(
	Settings.FOV * 2,
	Settings.FOV * 2
)
FOVCircle.ZIndex = 1
FOVCircle.Parent = Gui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = COLORS.Accent
FOVStroke.Thickness = 1.5
FOVStroke.Transparency = 0.25
FOVStroke.Parent = FOVCircle

--==============================================================
-- MAIN PANEL
--==============================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(330, 475)
Main.Position = UDim2.new(
	0.5,
	-165,
	0.5,
	-237
)

Main.BackgroundColor3 = COLORS.Panel
Main.BorderSizePixel = 0
Main.ZIndex = 10
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 18)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(53, 56, 70)
MainStroke.Thickness = 1
MainStroke.Transparency = 0.15
MainStroke.Parent = Main

--==============================================================
-- TOP BAR
--==============================================================

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 62)
TopBar.BackgroundTransparency = 1
TopBar.Active = true
TopBar.ZIndex = 11
TopBar.Parent = Main

local Logo = Instance.new("Frame")
Logo.Size = UDim2.fromOffset(38, 38)
Logo.Position = UDim2.fromOffset(14, 12)
Logo.BackgroundColor3 = COLORS.Accent
Logo.BorderSizePixel = 0
Logo.ZIndex = 12
Logo.Parent = TopBar

Instance.new(
	"UICorner",
	Logo
).CornerRadius = UDim.new(0, 11)

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.fromScale(1, 1)
LogoText.BackgroundTransparency = 1
LogoText.Text = "S"
LogoText.Font = Enum.Font.GothamBold
LogoText.TextSize = 20
LogoText.TextColor3 = Color3.new(1, 1, 1)
LogoText.ZIndex = 13
LogoText.Parent = Logo

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -115, 0, 24)
Title.Position = UDim2.fromOffset(62, 10)
Title.BackgroundTransparency = 1

Title.Text = "SOUZA AIM"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.TextColor3 = COLORS.Text
Title.TextXAlignment = Enum.TextXAlignment.Left

Title.ZIndex = 12
Title.Parent = TopBar

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -115, 0, 18)
Subtitle.Position = UDim2.fromOffset(62, 32)
Subtitle.BackgroundTransparency = 1

Subtitle.Text = "ESP • AIMBOT"
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextSize = 11
Subtitle.TextColor3 = COLORS.SubText
Subtitle.TextXAlignment = Enum.TextXAlignment.Left

Subtitle.ZIndex = 12
Subtitle.Parent = TopBar

--==============================================================
-- MINIMIZE
--==============================================================

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(38, 38)
Minimize.Position = UDim2.new(1, -50, 0, 12)

Minimize.BackgroundColor3 = COLORS.Card
Minimize.BorderSizePixel = 0

Minimize.Text = "—"
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 20
Minimize.TextColor3 = COLORS.Text

Minimize.AutoButtonColor = false

Minimize.ZIndex = 13
Minimize.Parent = TopBar

Instance.new(
	"UICorner",
	Minimize
).CornerRadius = UDim.new(0, 11)

--==============================================================
-- CONTENT
--==============================================================

local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"

Content.Size = UDim2.new(1, -20, 1, -75)
Content.Position = UDim2.fromOffset(10, 65)

Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0

Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = COLORS.Accent

Content.CanvasSize = UDim2.fromOffset(0, 550)

Content.ZIndex = 11
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 8)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content

--==============================================================
-- SECTION TITLE
--==============================================================

local function CreateSection(text)

	local Label = Instance.new("TextLabel")

	Label.Size = UDim2.new(1, -10, 0, 26)
	Label.BackgroundTransparency = 1

	Label.Text = string.upper(text)

	Label.Font = Enum.Font.GothamBold
	Label.TextSize = 11
	Label.TextColor3 = COLORS.SubText

	Label.TextXAlignment =
		Enum.TextXAlignment.Left

	Label.Parent = Content

	return Label
end

--==============================================================
-- TOGGLE
--==============================================================

local function CreateToggle(name, description, callback)

	local Card = Instance.new("TextButton")

	Card.Size = UDim2.new(1, -4, 0, 62)
	Card.BackgroundColor3 = COLORS.Card
	Card.BorderSizePixel = 0
	Card.Text = ""
	Card.AutoButtonColor = false
	Card.Parent = Content

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 13)
	Corner.Parent = Card

	local Name = Instance.new("TextLabel")

	Name.Size = UDim2.new(1, -85, 0, 22)
	Name.Position = UDim2.fromOffset(14, 9)

	Name.BackgroundTransparency = 1

	Name.Text = name
	Name.Font = Enum.Font.GothamSemibold
	Name.TextSize = 14
	Name.TextColor3 = COLORS.Text

	Name.TextXAlignment =
		Enum.TextXAlignment.Left

	Name.Parent = Card

	local Desc = Instance.new("TextLabel")

	Desc.Size = UDim2.new(1, -85, 0, 19)
	Desc.Position = UDim2.fromOffset(14, 32)

	Desc.BackgroundTransparency = 1

	Desc.Text = description
	Desc.Font = Enum.Font.Gotham
	Desc.TextSize = 10
	Desc.TextColor3 = COLORS.SubText

	Desc.TextXAlignment =
		Enum.TextXAlignment.Left

	Desc.Parent = Card

	local Switch = Instance.new("Frame")

	Switch.Size = UDim2.fromOffset(46, 25)
	Switch.Position = UDim2.new(
		1,
		-59,
		0.5,
		-12
	)

	Switch.BackgroundColor3 = COLORS.Disabled
	Switch.BorderSizePixel = 0
	Switch.Parent = Card

	Instance.new(
		"UICorner",
		Switch
	).CornerRadius = UDim.new(1, 0)

	local Circle = Instance.new("Frame")

	Circle.Size = UDim2.fromOffset(19, 19)
	Circle.Position = UDim2.fromOffset(3, 3)

	Circle.BackgroundColor3 =
		Color3.new(1, 1, 1)

	Circle.BorderSizePixel = 0
	Circle.Parent = Switch

	Instance.new(
		"UICorner",
		Circle
	).CornerRadius = UDim.new(1, 0)

	local enabled = false

	local function SetState(state)

		enabled = state

		TweenService:Create(
			Switch,
			TweenInfo.new(0.18),
			{
				BackgroundColor3 =
					state
					and COLORS.Enabled
					or COLORS.Disabled
			}
		):Play()

		TweenService:Create(
			Circle,
			TweenInfo.new(0.18),
			{
				Position =
					state
					and UDim2.fromOffset(24, 3)
					or UDim2.fromOffset(3, 3)
			}
		):Play()

		callback(state)
	end

	Card.MouseButton1Click:Connect(function()
		SetState(not enabled)
	end)

	Card.MouseEnter:Connect(function()

		TweenService:Create(
			Card,
			TweenInfo.new(0.12),
			{
				BackgroundColor3 =
					COLORS.CardHover
			}
		):Play()

	end)

	Card.MouseLeave:Connect(function()

		TweenService:Create(
			Card,
			TweenInfo.new(0.12),
			{
				BackgroundColor3 =
					COLORS.Card
			}
		):Play()

	end)

	return {
		Set = SetState
	}
end

--==============================================================
-- VALUE SELECTOR
--==============================================================

local function CreateSelector(
	name,
	getText,
	leftCallback,
	rightCallback
)

	local Card = Instance.new("Frame")

	Card.Size = UDim2.new(1, -4, 0, 58)
	Card.BackgroundColor3 = COLORS.Card
	Card.BorderSizePixel = 0
	Card.Parent = Content

	Instance.new(
		"UICorner",
		Card
	).CornerRadius = UDim.new(0, 13)

	local Name = Instance.new("TextLabel")

	Name.Size = UDim2.new(0.45, 0, 1, 0)
	Name.Position = UDim2.fromOffset(14, 0)

	Name.BackgroundTransparency = 1

	Name.Text = name
	Name.Font = Enum.Font.GothamSemibold
	Name.TextSize = 13
	Name.TextColor3 = COLORS.Text

	Name.TextXAlignment =
		Enum.TextXAlignment.Left

	Name.Parent = Card

	local Minus = Instance.new("TextButton")

	Minus.Size = UDim2.fromOffset(36, 36)

	Minus.Position =
		UDim2.new(
			1,
			-132,
			0.5,
			-18
		)

	Minus.BackgroundColor3 =
		Color3.fromRGB(38, 41, 52)

	Minus.BorderSizePixel = 0

	Minus.Text = "−"
	Minus.Font = Enum.Font.GothamBold
	Minus.TextSize = 18
	Minus.TextColor3 = COLORS.Text

	Minus.Parent = Card

	Instance.new(
		"UICorner",
		Minus
	).CornerRadius = UDim.new(0, 9)

	local Value = Instance.new("TextLabel")

	Value.Size = UDim2.fromOffset(50, 36)

	Value.Position =
		UDim2.new(
			1,
			-91,
			0.5,
			-18
		)

	Value.BackgroundTransparency = 1

	Value.Text = getText()

	Value.Font = Enum.Font.GothamBold
	Value.TextSize = 12
	Value.TextColor3 = COLORS.Accent2

	Value.Parent = Card

	local Plus = Instance.new("TextButton")

	Plus.Size = UDim2.fromOffset(36, 36)

	Plus.Position =
		UDim2.new(
			1,
			-43,
			0.5,
			-18
		)

	Plus.BackgroundColor3 =
		Color3.fromRGB(38, 41, 52)

	Plus.BorderSizePixel = 0

	Plus.Text = "+"
	Plus.Font = Enum.Font.GothamBold
	Plus.TextSize = 18
	Plus.TextColor3 = COLORS.Text

	Plus.Parent = Card

	Instance.new(
		"UICorner",
		Plus
	).CornerRadius = UDim.new(0, 9)

	local function Refresh()
		Value.Text = getText()
	end

	Minus.MouseButton1Click:Connect(function()

		leftCallback()
		Refresh()

	end)

	Plus.MouseButton1Click:Connect(function()

		rightCallback()
		Refresh()

	end)

	return Refresh
end

--==============================================================
-- UI OPTIONS
--==============================================================

CreateSection("Combat")

CreateToggle(
	"Aimbot",
	"Mira automaticamente no alvo",
	function(state)
		Settings.Aimbot = state
	end
)

CreateToggle(
	"Wall Check",
	"Ignora jogadores atrás da parede",
	function(state)
		Settings.WallCheck = state
	end
)

CreateToggle(
	"Team Check",
	"Ignora jogadores do seu time",
	function(state)
		Settings.TeamCheck = state
	end
)

CreateSection("Visual")

CreateToggle(
	"ESP",
	"Highlight através das paredes",
	function(state)
		Settings.ESP = state
	end
)

CreateToggle(
	"Nome + distância",
	"Mostra informações acima do jogador",
	function(state)
		Settings.ESPNames = state
	end
)

CreateToggle(
	"FOV",
	"Mostra a área de alcance do Aimbot",
	function(state)
		Settings.ShowFOV = state
	end
)

CreateSection("Configuração")

CreateSelector(
	"FOV",

	function()
		return tostring(Settings.FOV)
	end,

	function()

		Settings.FOV =
			math.max(
				50,
				Settings.FOV - 25
			)

	end,

	function()

		Settings.FOV =
			math.min(
				600,
				Settings.FOV + 25
			)

	end
)

CreateSelector(
	"Suavidade",

	function()

		return string.format(
			"%.2f",
			Settings.Smoothness
		)

	end,

	function()

		Settings.Smoothness =
			math.clamp(
				Settings.Smoothness - 0.05,
				0.05,
				1
			)

	end,

	function()

		Settings.Smoothness =
			math.clamp(
				Settings.Smoothness + 0.05,
				0.05,
				1
			)

	end
)

--==============================================================
-- AIM PART
--==============================================================

CreateSelector(
	"Mira",

	function()

		if Settings.AimPart == "Head" then
			return "HEAD"
		end

		return "BODY"
	end,

	function()

		if Settings.AimPart == "Head" then
			Settings.AimPart =
				"HumanoidRootPart"
		else
			Settings.AimPart =
				"Head"
		end

	end,

	function()

		if Settings.AimPart == "Head" then
			Settings.AimPart =
				"HumanoidRootPart"
		else
			Settings.AimPart =
				"Head"
		end

	end
)

--==============================================================
-- MINIMIZED BUTTON
--==============================================================

local OpenButton = Instance.new("TextButton")

OpenButton.Name = "OpenButton"

OpenButton.Size = UDim2.fromOffset(58, 58)
OpenButton.Position = UDim2.new(
	0,
	20,
	0.5,
	-29
)

OpenButton.BackgroundColor3 = COLORS.Accent
OpenButton.BorderSizePixel = 0

OpenButton.Text = "S"
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = 23
OpenButton.TextColor3 = Color3.new(1, 1, 1)

OpenButton.Visible = false
OpenButton.AutoButtonColor = false

OpenButton.ZIndex = 50
OpenButton.Parent = Gui

Instance.new(
	"UICorner",
	OpenButton
).CornerRadius = UDim.new(1, 0)

local OpenStroke =
	Instance.new("UIStroke")

OpenStroke.Color =
	Color3.fromRGB(200, 190, 255)

OpenStroke.Thickness = 1.5
OpenStroke.Parent = OpenButton

--==============================================================
-- MINIMIZE / OPEN
--==============================================================

Minimize.MouseButton1Click:Connect(function()

	Main.Visible = false
	OpenButton.Visible = true

end)

OpenButton.MouseButton1Click:Connect(function()

	OpenButton.Visible = false
	Main.Visible = true

end)

--==============================================================
-- DRAG
--==============================================================

local function MakeDraggable(handle, object)

	local dragging = false
	local dragInput = nil

	local dragStart = nil
	local startPos = nil

	handle.InputBegan:Connect(function(input)

		if
			input.UserInputType
				== Enum.UserInputType.MouseButton1
			or input.UserInputType
				== Enum.UserInputType.Touch
		then

			dragging = true

			dragStart = input.Position
			startPos = object.Position

			input.Changed:Connect(function()

				if
					input.UserInputState
						== Enum.UserInputState.End
				then
					dragging = false
				end

			end)

		end

	end)

	handle.InputChanged:Connect(function(input)

		if
			input.UserInputType
				== Enum.UserInputType.MouseMovement
			or input.UserInputType
				== Enum.UserInputType.Touch
		then
			dragInput = input
		end

	end)

	UIS.InputChanged:Connect(function(input)

		if
			dragging
			and input == dragInput
		then

			local delta =
				input.Position - dragStart

			object.Position =
				UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset
						+ delta.X,

					startPos.Y.Scale,
					startPos.Y.Offset
						+ delta.Y
				)

		end

	end)

end

MakeDraggable(TopBar, Main)
MakeDraggable(OpenButton, OpenButton)

--==============================================================
-- ESP
--==============================================================

local ESPObjects = {}

local function DestroyESP(player)

	local data = ESPObjects[player]

	if not data then
		return
	end

	if data.Highlight then
		data.Highlight:Destroy()
	end

	if data.Tag then
		data.Tag:Destroy()
	end

	ESPObjects[player] = nil

end

local function CreateESP(player)

	if player == LocalPlayer then
		return
	end

	DestroyESP(player)

	local character = player.Character

	if not character then
		return
	end

	local humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	local root =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	local head =
		character:FindFirstChild(
			"Head"
		)

	if
		not humanoid
		or not root
		or not head
	then
		return
	end

	--==============================
	-- CHAMS
	--==============================

	local Highlight =
		Instance.new("Highlight")

	Highlight.Name =
		"ESP_" .. player.Name

	Highlight.Adornee = character

	Highlight.DepthMode =
		Enum.HighlightDepthMode.AlwaysOnTop

	Highlight.FillColor = COLORS.ESP
	Highlight.FillTransparency = 0.62

	Highlight.OutlineColor =
		Color3.fromRGB(255, 255, 255)

	Highlight.OutlineTransparency = 0

	Highlight.Enabled = false

	Highlight.Parent = character

	--==============================
	-- NAME TAG
	--==============================

	local Tag =
		Instance.new("BillboardGui")

	Tag.Name = "ESPTag"

	Tag.Adornee = head

	Tag.Size =
		UDim2.fromOffset(
			200,
			45
		)

	Tag.StudsOffset =
		Vector3.new(
			0,
			2.7,
			0
		)

	Tag.AlwaysOnTop = true

	Tag.Enabled = false

	Tag.Parent = PlayerGui

	local Text =
		Instance.new("TextLabel")

	Text.Name = "Text"

	Text.Size =
		UDim2.fromScale(
			1,
			1
		)

	Text.BackgroundTransparency = 1

	Text.Text =
		player.DisplayName

	Text.Font =
		Enum.Font.GothamBold

	Text.TextSize = 13

	Text.TextColor3 =
		Color3.fromRGB(
			255,
			255,
			255
		)

	Text.TextStrokeTransparency = 0.35

	Text.Parent = Tag

	ESPObjects[player] = {
		Highlight = Highlight,
		Tag = Tag,
		Text = Text
	}

end

--==============================================================
-- PLAYER SETUP
--==============================================================

local function SetupPlayer(player)

	if player == LocalPlayer then
		return
	end

	player.CharacterAdded:Connect(function()

		task.wait(0.5)

		CreateESP(player)

	end)

	player.CharacterRemoving:Connect(function()

		DestroyESP(player)

	end)

	if player.Character then

		task.defer(function()
			CreateESP(player)
		end)

	end

end

for _, player in ipairs(
	Players:GetPlayers()
) do

	SetupPlayer(player)

end

Players.PlayerAdded:Connect(
	SetupPlayer
)

Players.PlayerRemoving:Connect(
	DestroyESP
)

--==============================================================
-- TEAM CHECK
--==============================================================

local function IsTeammate(player)

	if not Settings.TeamCheck then
		return false
	end

	if LocalPlayer.Team == nil then
		return false
	end

	return player.Team == LocalPlayer.Team

end

--==============================================================
-- WALL CHECK
--==============================================================

local RayParams =
	RaycastParams.new()

RayParams.FilterType =
	Enum.RaycastFilterType.Exclude

RayParams.IgnoreWater = true

local function IsVisible(
	character,
	targetPart
)

	if not Settings.WallCheck then
		return true
	end

	local camera =
		workspace.CurrentCamera

	if not camera then
		return false
	end

	local ignore = {}

	if LocalPlayer.Character then

		table.insert(
			ignore,
			LocalPlayer.Character
		)

	end

	RayParams.FilterDescendantsInstances =
		ignore

	local origin =
		camera.CFrame.Position

	local direction =
		targetPart.Position
		- origin

	local result =
		workspace:Raycast(
			origin,
			direction,
			RayParams
		)

	if not result then
		return true
	end

	return
		result.Instance
			:IsDescendantOf(
				character
			)

end

--==============================================================
-- GET TARGET
--==============================================================

local function GetClosestTarget()

	local camera =
		workspace.CurrentCamera

	if not camera then
		return nil
	end

	local viewport =
		camera.ViewportSize

	local center =
		Vector2.new(
			viewport.X / 2,
			viewport.Y / 2
		)

	local closestPart = nil
	local closestPlayer = nil

	local closestDistance =
		Settings.FOV

	for _, player in ipairs(
		Players:GetPlayers()
	) do

		if
			player ~= LocalPlayer
			and not IsTeammate(player)
		then

			local character =
				player.Character

			if character then

				local humanoid =
					character:
					FindFirstChildOfClass(
						"Humanoid"
					)

				local targetPart =
					character:
					FindFirstChild(
						Settings.AimPart
					)

				if not targetPart then

					targetPart =
						character:
						FindFirstChild(
							"HumanoidRootPart"
						)

				end

				if
					humanoid
					and humanoid.Health > 0
					and targetPart
					and IsVisible(
						character,
						targetPart
					)
				then

					local position,
						onScreen =
						camera:
						WorldToViewportPoint(
							targetPart.Position
						)

					if
						onScreen
						and position.Z > 0
					then

						local screenPosition =
							Vector2.new(
								position.X,
								position.Y
							)

						local distance =
							(
								screenPosition
								- center
							).Magnitude

						if
							distance
								< closestDistance
						then

							closestDistance =
								distance

							closestPart =
								targetPart

							closestPlayer =
								player

						end

					end

				end

			end

		end

	end

	return
		closestPart,
		closestPlayer

end

--==============================================================
-- ESP UPDATE
--==============================================================

local lastESPUpdate = 0

local function UpdateESP()

	if
		os.clock() - lastESPUpdate
		< 0.08
	then
		return
	end

	lastESPUpdate = os.clock()

	local myCharacter =
		LocalPlayer.Character

	local myRoot =
		myCharacter
		and myCharacter:
			FindFirstChild(
				"HumanoidRootPart"
			)

	for player, data in pairs(
		ESPObjects
	) do

		local character =
			player.Character

		local humanoid =
			character
			and character:
				FindFirstChildOfClass(
					"Humanoid"
				)

		local root =
			character
			and character:
				FindFirstChild(
					"HumanoidRootPart"
				)

		local alive =
			humanoid
			and humanoid.Health > 0
			and root

		local show =
			Settings.ESP
			and alive
			and not IsTeammate(player)

		if data.Highlight then

			data.Highlight.Enabled =
				show

		end

		if data.Tag then

			data.Tag.Enabled =
				show
				and Settings.ESPNames

		end

		if
			show
			and Settings.ESPNames
			and data.Text
			and myRoot
			and root
		then

			local distance =
				(
					myRoot.Position
					- root.Position
				).Magnitude

			data.Text.Text =
				player.DisplayName
				.. "\n"
				.. math.floor(distance)
				.. " studs"

		end

	end

end

--==============================================================
-- AIMBOT
--==============================================================

pcall(function()

	RunService:
		UnbindFromRenderStep(
			"Souza_Aimbot"
		)

end)

RunService:BindToRenderStep(
	"Souza_Aimbot",

	Enum.RenderPriority.Camera.Value
		+ 10,

	function()

		local camera =
			workspace.CurrentCamera

		if not camera then
			return
		end

		--==============================
		-- FOV
		--==============================

		local viewport =
			camera.ViewportSize

		local center =
			Vector2.new(
				viewport.X / 2,
				viewport.Y / 2
			)

		FOVCircle.Position =
			UDim2.fromOffset(
				center.X,
				center.Y
			)

		FOVCircle.Size =
			UDim2.fromOffset(
				Settings.FOV * 2,
				Settings.FOV * 2
			)

		FOVCircle.Visible =
			Settings.ShowFOV

		--==============================
		-- ESP
		--==============================

		UpdateESP()

		--==============================
		-- AIM
		--==============================

		if not Settings.Aimbot then
			return
		end

		local target =
			GetClosestTarget()

		if not target then
			return
		end

		if not target.Parent then
			return
		end

		local cameraPosition =
			camera.CFrame.Position

		local desired =
			CFrame.lookAt(
				cameraPosition,
				target.Position
			)

		local alpha =
			math.clamp(
				Settings.Smoothness,
				0.05,
				1
			)

		camera.CFrame =
			camera.CFrame:Lerp(
				desired,
				alpha
			)

	end
)

--==============================================================
-- RESPAWN
--==============================================================

LocalPlayer.CharacterAdded:Connect(
	function()

		task.wait(0.5)

	end
)

print(
	"[SOUZA AIM] Interface carregada."
)
