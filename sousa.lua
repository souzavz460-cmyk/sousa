--====================================================
-- PAINEL LOCAL - 1 ÚNICO LOCALSCRIPT
-- StarterPlayer > StarterPlayerScripts
--====================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

------------------------------------------------------
-- CONFIG
------------------------------------------------------

local GREEN = Color3.fromRGB(55, 255, 85)
local DARK_GREEN = Color3.fromRGB(5, 55, 22)
local CARD_GREEN = Color3.fromRGB(5, 45, 19)
local BACKGROUND = Color3.fromRGB(3, 7, 5)

local Settings = {
	ESP = false,
	Names = false,
	Distance = false,

	Aimbot = false,
	Silent = false,

	AutoReload = false,

	FireSpeed = 1,
}

------------------------------------------------------
-- REMOVE GUI ANTIGA
------------------------------------------------------

local old = PlayerGui:FindFirstChild("LocalFunctionsPanel")

if old then
	old:Destroy()
end

------------------------------------------------------
-- GUI
------------------------------------------------------

local Gui = Instance.new("ScreenGui")
Gui.Name = "LocalFunctionsPanel"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0.82, 0, 0.7, 0)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = BACKGROUND
Main.BorderSizePixel = 0
Main.Parent = Gui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 28)

local Size = Instance.new("UISizeConstraint")
Size.MinSize = Vector2.new(350, 300)
Size.MaxSize = Vector2.new(730, 470)
Size.Parent = Main

------------------------------------------------------
-- SIDEBAR
------------------------------------------------------

local Side = Instance.new("Frame")
Side.Size = UDim2.new(0, 75, 1, 0)
Side.BackgroundTransparency = 1
Side.Parent = Main

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 14)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.Parent = Side

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0, 23)
SidePadding.Parent = Side

local function sideButton(text)

	local b = Instance.new("TextButton")

	b.Size = UDim2.fromOffset(55, 55)

	b.BackgroundColor3 = DARK_GREEN

	b.Text = text
	b.TextSize = 25
	b.TextColor3 = Color3.fromRGB(220,255,220)

	b.Font = Enum.Font.GothamBold

	b.BorderSizePixel = 0

	b.Parent = Side

	Instance.new("UICorner", b).CornerRadius =
		UDim.new(1,0)

	return b

end

local AimTab = sideButton("⌖")
local EspTab = sideButton("◉")
local GunTab = sideButton("🎮")
local ToolTab = sideButton("⚙")

------------------------------------------------------
-- TOPBAR
------------------------------------------------------

local Top = Instance.new("Frame")

Top.Position = UDim2.new(0, 87, 0, 15)
Top.Size = UDim2.new(1, -105, 0, 60)

Top.BackgroundTransparency = 1
Top.Parent = Main

local Title = Instance.new("TextLabel")

Title.Size = UDim2.new(0, 270, 1, 0)

Title.BackgroundColor3 = DARK_GREEN

Title.Text = "  ⌖  FUNÇÕES"

Title.TextColor3 = GREEN

Title.TextSize = 26

Title.Font = Enum.Font.GothamBold

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.BorderSizePixel = 0

Title.Parent = Top

Instance.new("UICorner", Title).CornerRadius =
	UDim.new(0,25)

------------------------------------------------------

local Close = Instance.new("TextButton")

Close.Size = UDim2.fromOffset(55,55)

Close.Position = UDim2.new(1,-55,0,2)

Close.BackgroundColor3 = DARK_GREEN

Close.Text = "×"

Close.TextColor3 = GREEN

Close.TextSize = 38

Close.Font = Enum.Font.Gotham

Close.BorderSizePixel = 0

Close.Parent = Top

Instance.new("UICorner", Close).CornerRadius =
	UDim.new(1,0)

------------------------------------------------------
-- CONTAINER
------------------------------------------------------

local Container =
	Instance.new("ScrollingFrame")

Container.Position =
	UDim2.new(0,87,0,88)

Container.Size =
	UDim2.new(1,-105,1,-105)

Container.BackgroundTransparency = 1

Container.BorderSizePixel = 0

Container.ScrollBarThickness = 3

Container.ScrollBarImageColor3 = GREEN

Container.AutomaticCanvasSize =
	Enum.AutomaticSize.Y

Container.CanvasSize = UDim2.new()

Container.Parent = Main

local List = Instance.new("UIListLayout")

List.Padding = UDim.new(0,11)

List.Parent = Container

------------------------------------------------------
-- CLEAR TAB
------------------------------------------------------

local function clear()

	for _,v in ipairs(Container:GetChildren()) do

		if not v:IsA("UIListLayout") then
			v:Destroy()
		end

	end

end

------------------------------------------------------
-- TOGGLE
------------------------------------------------------

local function createToggle(name, description, callback)

	local holder = Instance.new("Frame")

	holder.Size = UDim2.new(1,-5,0,94)

	holder.BackgroundTransparency = 1

	holder.Parent = Container

	----------------------------------------------

	local button = Instance.new("TextButton")

	button.Size = UDim2.new(1,0,0,66)

	button.BackgroundColor3 = CARD_GREEN

	button.Text = ""

	button.BorderSizePixel = 0

	button.AutoButtonColor = false

	button.Parent = holder

	Instance.new("UICorner",button).CornerRadius =
		UDim.new(0,24)

	----------------------------------------------

	local text = Instance.new("TextLabel")

	text.Position = UDim2.new(0,25,0,0)

	text.Size = UDim2.new(1,-110,1,0)

	text.BackgroundTransparency = 1

	text.Text = name

	text.TextColor3 = Color3.new(1,1,1)

	text.TextSize = 23

	text.Font = Enum.Font.GothamBold

	text.TextXAlignment =
		Enum.TextXAlignment.Left

	text.Parent = button

	----------------------------------------------

	local circle = Instance.new("Frame")

	circle.AnchorPoint = Vector2.new(1,0.5)

	circle.Position = UDim2.new(1,-17,0.5,0)

	circle.Size = UDim2.fromOffset(42,42)

	circle.BackgroundColor3 =
		Color3.fromRGB(75,75,75)

	circle.BorderSizePixel = 0

	circle.Parent = button

	Instance.new("UICorner",circle).CornerRadius =
		UDim.new(1,0)

	----------------------------------------------

	local info = Instance.new("TextLabel")

	info.Position = UDim2.new(0,20,0,67)

	info.Size = UDim2.new(1,-30,0,23)

	info.BackgroundTransparency = 1

	info.Text = description or ""

	info.TextColor3 =
		Color3.fromRGB(145,145,145)

	info.TextSize = 15

	info.Font = Enum.Font.GothamMedium

	info.TextXAlignment =
		Enum.TextXAlignment.Left

	info.Parent = holder

	----------------------------------------------

	local enabled = false

	button.MouseButton1Click:Connect(function()

		enabled = not enabled

		circle.BackgroundColor3 =
			enabled and GREEN
			or Color3.fromRGB(75,75,75)

		TweenService:Create(
			button,
			TweenInfo.new(.12),
			{
				BackgroundColor3 =
					enabled
					and Color3.fromRGB(7,60,25)
					or CARD_GREEN
			}
		):Play()

		callback(enabled)

	end)

end

------------------------------------------------------
-- SLIDER / LEVEL
------------------------------------------------------

local function createLevels(name, values, callback)

	local index = 1

	local button = Instance.new("TextButton")

	button.Size = UDim2.new(1,-5,0,68)

	button.BackgroundColor3 = CARD_GREEN

	button.BorderSizePixel = 0

	button.Text = ""

	button.Parent = Container

	Instance.new("UICorner",button).CornerRadius =
		UDim.new(0,24)

	local title = Instance.new("TextLabel")

	title.Position = UDim2.new(0,25,0,0)

	title.Size = UDim2.new(.7,0,1,0)

	title.BackgroundTransparency = 1

	title.Text = name

	title.Font = Enum.Font.GothamBold

	title.TextSize = 21

	title.TextColor3 = Color3.new(1,1,1)

	title.TextXAlignment =
		Enum.TextXAlignment.Left

	title.Parent = button

	local value = Instance.new("TextLabel")

	value.Position = UDim2.new(.7,0,0,0)

	value.Size = UDim2.new(.25,0,1,0)

	value.BackgroundTransparency = 1

	value.Text = tostring(values[index])

	value.Font = Enum.Font.GothamBold

	value.TextSize = 20

	value.TextColor3 = GREEN

	value.Parent = button

	button.MouseButton1Click:Connect(function()

		index += 1

		if index > #values then
			index = 1
		end

		value.Text = tostring(values[index])

		callback(values[index])

	end)

end

------------------------------------------------------
-- ESP
------------------------------------------------------

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ClientESP"
ESPFolder.Parent = Gui

local function clearESP()

	for _,v in ipairs(ESPFolder:GetChildren()) do
		v:Destroy()
	end

	for _,plr in ipairs(Players:GetPlayers()) do

		if plr.Character then

			local h =
				plr.Character:
				FindFirstChild("ClientHighlight")

			if h then
				h:Destroy()
			end

		end

	end

end

local function makeESP(plr)

	if plr == Player then return end
	if not plr.Character then return end

	local char = plr.Character

	----------------------------------------------
	-- HIGHLIGHT
	----------------------------------------------

	if Settings.ESP then

		local old =
			char:FindFirstChild("ClientHighlight")

		if old then
			old:Destroy()
		end

		local h = Instance.new("Highlight")

		h.Name = "ClientHighlight"

		h.Adornee = char

		h.DepthMode =
			Enum.HighlightDepthMode.AlwaysOnTop

		h.FillColor = GREEN

		h.FillTransparency = .78

		h.OutlineColor =
			Color3.new(1,1,1)

		h.OutlineTransparency = .1

		h.Parent = char

	end

	----------------------------------------------
	-- NOME / DISTÂNCIA
	----------------------------------------------

	if Settings.Names or Settings.Distance then

		local head = char:
			FindFirstChild("Head")

		if not head then return end

		local billboard =
			Instance.new("BillboardGui")

		billboard.Name = plr.Name

		billboard.Adornee = head

		billboard.AlwaysOnTop = true

		billboard.Size =
			UDim2.fromOffset(180,38)

		billboard.StudsOffset =
			Vector3.new(0,2.5,0)

		billboard.Parent = ESPFolder

		local label =
			Instance.new("TextLabel")

		label.Size =
			UDim2.fromScale(1,1)

		label.BackgroundTransparency = 1

		label.TextColor3 = GREEN

		label.TextStrokeTransparency = .4

		label.Font =
			Enum.Font.GothamBold

		label.TextSize = 15

		label.Parent = billboard

		RunService.RenderStepped:Connect(function()

			if not billboard.Parent then
				return
			end

			if not char.Parent then
				billboard:Destroy()
				return
			end

			local text = ""

			if Settings.Names then
				text = plr.DisplayName
			end

			if Settings.Distance then

				local root =
					char:
						FindFirstChild(
							"HumanoidRootPart"
						)

				local myRoot =
					Player.Character
					and Player.Character:
						FindFirstChild(
							"HumanoidRootPart"
						)

				if root and myRoot then

					local distance =
						math.floor(
							(root.Position -
							myRoot.Position).Magnitude
						)

					if text ~= "" then
						text ..= " • "
					end

					text ..=
						distance .. "m"

				end

			end

			label.Text = text

		end)

	end

end

local function refreshESP()

	clearESP()

	for _,plr in ipairs(Players:GetPlayers()) do
		makeESP(plr)
	end

end

Players.PlayerAdded:Connect(function(plr)

	plr.CharacterAdded:Connect(function()

		task.wait(.5)

		refreshESP()

	end)

end)

------------------------------------------------------
-- AIMBOT LOCAL
------------------------------------------------------

local function closestTarget()

	local closest
	local distance = math.huge

	local center =
		Vector2.new(
			Camera.ViewportSize.X / 2,
			Camera.ViewportSize.Y / 2
		)

	for _,plr in ipairs(Players:GetPlayers()) do

		if plr ~= Player
			and plr.Character
			and plr.Character:
				FindFirstChild("Head") then

			local head =
				plr.Character.Head

			local pos,visible =
				Camera:
					WorldToViewportPoint(
						head.Position
					)

			if visible then

				local screen =
					Vector2.new(pos.X,pos.Y)

				local diff =
					(screen-center).Magnitude

				if diff < distance then

					distance = diff
					closest = head

				end

			end

		end

	end

	return closest

end

RunService.RenderStepped:Connect(function()

	if Settings.Aimbot then

		local target = closestTarget()

		if target then

			local camPos =
				Camera.CFrame.Position

			local wanted =
				CFrame.new(
					camPos,
					target.Position
				)

			Camera.CFrame =
				Camera.CFrame:Lerp(
					wanted,
					0.13
				)

		end

	end

end)

------------------------------------------------------
-- AUTO RELOAD LOCAL
------------------------------------------------------

RunService.Heartbeat:Connect(function()

	if not Settings.AutoReload then
		return
	end

	local char = Player.Character

	if not char then return end

	local tool =
		char:FindFirstChildOfClass("Tool")

	if not tool then return end

	local ammo =
		tool:FindFirstChild(
			"Ammo",
			true
		)

	local maxAmmo =
		tool:FindFirstChild(
			"MaxAmmo",
			true
		)

	if ammo
		and maxAmmo
		and ammo:IsA("IntValue")
		and maxAmmo:IsA("IntValue")
	then

		if ammo.Value <= 0 then
			ammo.Value = maxAmmo.Value
		end

	end

end)

------------------------------------------------------
-- FIRE SPEED LOCAL
------------------------------------------------------

local function applyFireSpeed()

	local char = Player.Character

	if not char then return end

	local tool =
		char:FindFirstChildOfClass("Tool")

	if not tool then return end

	local possibleNames = {
		"FireRate",
		"Cooldown",
		"FireDelay",
		"ShootDelay"
	}

	for _,name in ipairs(possibleNames) do

		local value =
			tool:FindFirstChild(
				name,
				true
			)

		if value
			and value:IsA("NumberValue")
		then

			if name == "FireRate" then

				value.Value =
					Settings.FireSpeed

			else

				value.Value =
					1 / Settings.FireSpeed

			end

		end

	end

end

------------------------------------------------------
-- TAB AIM
------------------------------------------------------

local function AimPage()

	clear()

	Title.Text = "  ⌖  FUNÇÕES"

	createToggle(
		"Aimbot",
		"Mira local no jogador mais próximo",
		function(v)

			Settings.Aimbot = v

		end
	)

	createToggle(
		"Silent",
		"Modo de alvo silencioso local",
		function(v)

			Settings.Silent = v

		end
	)

end

------------------------------------------------------
-- TAB ESP
------------------------------------------------------

local function ESPPage()

	clear()

	Title.Text = "  ◉  VISUAL"

	createToggle(
		"ESP",
		"Destaca jogadores através das paredes",
		function(v)

			Settings.ESP = v

			refreshESP()

		end
	)

	createToggle(
		"Nomes",
		"Mostra nome dos jogadores",
		function(v)

			Settings.Names = v

			refreshESP()

		end
	)

	createToggle(
		"Distância",
		"Mostra distância do jogador",
		function(v)

			Settings.Distance = v

			refreshESP()

		end
	)

end

------------------------------------------------------
-- TAB ARMAS
------------------------------------------------------

local function GunPage()

	clear()

	Title.Text = "  🎮  ARMAS"

	createToggle(
		"Auto Recarregar",
		"Recarrega valores Ammo automaticamente",
		function(v)

			Settings.AutoReload = v

		end
	)

	createLevels(
		"Velocidade das Balas",
		{
			1,
			2,
			3,
			5,
			10
		},
		function(v)

			Settings.FireSpeed = v

			applyFireSpeed()

		end
	)

end

------------------------------------------------------
-- TAB CONFIG
------------------------------------------------------

local function SettingsPage()

	clear()

	Title.Text = "  ⚙  CONFIG"

	local reset =
		Instance.new("TextButton")

	reset.Size =
		UDim2.new(1,-5,0,65)

	reset.BackgroundColor3 =
		CARD_GREEN

	reset.Text =
		"RESETAR FUNÇÕES"

	reset.TextColor3 =
		Color3.new(1,1,1)

	reset.TextSize = 19

	reset.Font =
		Enum.Font.GothamBold

	reset.BorderSizePixel = 0

	reset.Parent = Container

	Instance.new(
		"UICorner",
		reset
	).CornerRadius =
		UDim.new(0,22)

	reset.MouseButton1Click:
	Connect(function()

		Settings.ESP = false
		Settings.Names = false
		Settings.Distance = false

		Settings.Aimbot = false
		Settings.Silent = false

		Settings.AutoReload = false

		Settings.FireSpeed = 1

		clearESP()

	end)

end

------------------------------------------------------
-- BUTTONS
------------------------------------------------------

AimTab.MouseButton1Click:Connect(AimPage)
EspTab.MouseButton1Click:Connect(ESPPage)
GunTab.MouseButton1Click:Connect(GunPage)
ToolTab.MouseButton1Click:Connect(SettingsPage)

------------------------------------------------------
-- CLOSE
------------------------------------------------------

Close.MouseButton1Click:Connect(function()

	Main.Visible = false

end)

------------------------------------------------------
-- ABRIR NOVAMENTE
------------------------------------------------------

local Open = Instance.new("TextButton")

Open.Size = UDim2.fromOffset(55,55)

Open.Position =
	UDim2.new(0,15,.5,-27)

Open.BackgroundColor3 =
	DARK_GREEN

Open.Text = "⌖"

Open.TextColor3 = GREEN

Open.TextSize = 28

Open.Font =
	Enum.Font.GothamBold

Open.BorderSizePixel = 0

Open.Parent = Gui

Instance.new("UICorner",Open).CornerRadius =
	UDim.new(1,0)

Open.MouseButton1Click:Connect(function()

	Main.Visible = true

end)

------------------------------------------------------
-- DRAG
------------------------------------------------------

local dragging = false
local dragStart
local startPos

Top.InputBegan:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch
	then

		dragging = true

		dragStart = input.Position

		startPos = Main.Position

	end

end)

UIS.InputChanged:Connect(function(input)

	if not dragging then
		return
	end

	if input.UserInputType ==
		Enum.UserInputType.MouseMovement
		or input.UserInputType ==
		Enum.UserInputType.Touch
	then

		local delta =
			input.Position - dragStart

		Main.Position =
			UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,

				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)

	end

end)

UIS.InputEnded:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch
	then

		dragging = false

	end

end)

------------------------------------------------------
-- PRIMEIRA TELA
------------------------------------------------------

AimPage()
