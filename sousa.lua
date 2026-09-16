--[[
    ================================================================
    ROBLOX AUTO-DETECTION ENGINE & CLIENT PANEL
    ================================================================
    - Sistema 100% Client-Side para Place Próprio
    - Interface Quadrada Responsiva Mobile/PC (Tema Verde Neon/Escuro)
    - Auto-Detecção de Armas, Valores, Atributos e Estruturas do Jogo
    - Gerenciamento de Conexões e Ciclo de Vida Sem Memory Leak
    ================================================================
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Assets & Configurações de UI
local LOGO_ASSET = "rbxthumb://type=Asset&id=98880379063768&w=420&h=420"
local TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- ================================================================
-- ESTADOS E VARIÁVEIS GLOBAIS
-- ================================================================
local State = {
	-- Aim
	Aimbot = false,
	SilentAim = false,
	AimKill = false,
	IgnoreBots = true,
	IgnoreTeam = true,
	CheckVisibility = false,
	FOV = 120,
	Smoothing = 0.2,
	TargetPart = "Head", -- "Head" ou "HumanoidRootPart"
	ShowFOV = true,

	-- ESP
	ESPMaster = false,
	ESPHighlight = false,
	ESPBox = false,
	ESPName = false,
	ESPDistance = false,
	ESPHealth = false,
	ESPTracer = false,

	-- Armas
	AutoReload = false,
	FireSpeedMultiplier = 1,
	NoRecoil = false,
	NoSpread = false,
	BulletSpeedMultiplier = 1,

	-- Movimento
	WalkSpeed = 16,
	JumpPower = 50,
	FlyKill = false,

	-- UI
	ThemeDark = true,
	ShowLogo = true,
}

-- Mapeamento de nomes comuns para Auto-Detecção
local ALIASES = {
	Ammo = {"Ammo", "CurrentAmmo", "Bullets", "Magazine", "Mag", "Clip", "Munição", "AmmoCount"},
	MaxAmmo = {"MaxAmmo", "MaxClip", "MaxBullets", "Capacity", "MagCapacity"},
	FireRate = {"FireRate", "FireDelay", "ShootDelay", "Cooldown", "RPM", "AttackSpeed", "Cadence"},
	ReloadTime = {"ReloadTime", "ReloadDelay", "ReloadSpeed", "TempoRecarga"},
	BulletSpeed = {"BulletSpeed", "ProjectileSpeed", "Velocity", "Velocidade"},
	Recoil = {"Recoil", "Kickback", "RecoilAmount"},
	Spread = {"Spread", "Inaccuracy", "Accuracy"}
}

-- Estutura do Módulo de Conexões (Gerenciador de Limpeza)
local ConnectionManager = {
	_connections = {},
	_espObjects = {}
}

function ConnectionManager:Add(connection, tag)
	if connection then
		table.insert(self._connections, {conn = connection, tag = tag or "General"})
	end
end

function ConnectionManager:ClearByTag(tag)
	for i = #self._connections, 1, -1 do
		if self._connections[i].tag == tag then
			if self._connections[i].conn then
				self._connections[i].conn:Disconnect()
			end
			table.remove(self._connections, i)
		end
	end
end

function ConnectionManager:ClearAll()
	for _, item in ipairs(self._connections) do
		if item.conn then
			item.conn:Disconnect()
		end
	end
	self._connections = {}

	for player, folder in pairs(self._espObjects) do
		if folder then folder:Destroy() end
	end
	self._espObjects = {}
end

-- ================================================================
-- AUTO-DETECTOR DE ARMAS E PROPRIEDADES
-- ================================================================
local WeaponScanner = {
	CurrentTool = nil,
	CachedProperties = {},
	OriginalValues = {}
}

function WeaponScanner:GetActiveTool()
	local char = LocalPlayer.Character
	if not char then return nil end
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Tool") then
			return child
		end
	end
	return nil
end

function WeaponScanner:FindProperty(tool, aliasList)
	if not tool then return nil end

	-- 1. Verificar Descendants por ValueObjects
	for _, descendant in ipairs(tool:GetDescendants()) do
		for _, alias in ipairs(aliasList) do
			if string.lower(descendant.Name) == string.lower(alias) then
				if descendant:IsA("ValueObject") then
					return {Type = "ValueObject", Object = descendant, Field = "Value"}
				end
			end
		end
	end

	-- 2. Verificar Attributes na Tool e nos Descendants
	for _, alias in ipairs(aliasList) do
		if tool:GetAttribute(alias) ~= nil then
			return {Type = "Attribute", Object = tool, Field = alias}
		end
	end

	for _, descendant in ipairs(tool:GetDescendants()) do
		for _, alias in ipairs(aliasList) do
			if descendant:GetAttribute(alias) ~= nil then
				return {Type = "Attribute", Object = descendant, Field = alias}
			end
		end
	end

	-- 3. Verificar ModuleScripts acessíveis no client
	for _, descendant in ipairs(tool:GetDescendants()) do
		if descendant:IsA("ModuleScript") then
			local success, result = pcall(require, descendant)
			if success and type(result) == "table" then
				for _, alias in ipairs(aliasList) do
					for key, val in pairs(result) do
						if string.lower(tostring(key)) == string.lower(alias) and type(val) == "number" then
							return {Type = "Table", Object = result, Field = key, Script = descendant}
						end
					end
				end
			end
		end
	end

	return nil
end

function WeaponScanner:Scan(tool)
	if not tool then
		self.CurrentTool = nil
		self.CachedProperties = {}
		return
	end

	if self.CurrentTool == tool then return end
	self:RestoreOriginals()

	self.CurrentTool = tool
	self.CachedProperties = {}

	for propName, aliases in pairs(ALIASES) do
		local match = self:FindProperty(tool, aliases)
		if match then
			self.CachedProperties[propName] = match
			-- Salvar valor original
			if match.Type == "ValueObject" then
				self.OriginalValues[propName] = match.Object.Value
			elseif match.Type == "Attribute" then
				self.OriginalValues[propName] = match.Object:GetAttribute(match.Field)
			elseif match.Type == "Table" then
				self.OriginalValues[propName] = match.Object[match.Field]
			end
		end
	end
end

function WeaponScanner:RestoreOriginals()
	if not self.CurrentTool or not self.OriginalValues then return end

	for propName, origVal in pairs(self.OriginalValues) do
		local prop = self.CachedProperties[propName]
		if prop then
			pcall(function()
				if prop.Type == "ValueObject" then
					prop.Object.Value = origVal
				elseif prop.Type == "Attribute" then
					prop.Object:SetAttribute(prop.Field, origVal)
				elseif prop.Type == "Table" then
					prop.Object[prop.Field] = origVal
				end
			end)
		end
	end
	self.OriginalValues = {}
end

function WeaponScanner:ApplyModifiers()
	if not self.CurrentTool then return end

	-- Modificar Fire Rate
	local fireRateProp = self.CachedProperties["FireRate"]
	if fireRateProp and self.OriginalValues["FireRate"] then
		local orig = self.OriginalValues["FireRate"]
		local newVal = orig / State.FireSpeedMultiplier
		pcall(function()
			if fireRateProp.Type == "ValueObject" then fireRateProp.Object.Value = newVal
			elseif fireRateProp.Type == "Attribute" then fireRateProp.Object:SetAttribute(fireRateProp.Field, newVal)
			elseif fireRateProp.Type == "Table" then fireRateProp.Object[fireRateProp.Field] = newVal end
		end)
	end

	-- No Recoil
	local recoilProp = self.CachedProperties["Recoil"]
	if recoilProp then
		local newVal = State.NoRecoil and 0 or (self.OriginalValues["Recoil"] or 1)
		pcall(function()
			if recoilProp.Type == "ValueObject" then recoilProp.Object.Value = newVal
			elseif recoilProp.Type == "Attribute" then recoilProp.Object:SetAttribute(recoilProp.Field, newVal)
			elseif recoilProp.Type == "Table" then recoilProp.Object[recoilProp.Field] = newVal end
		end)
	end

	-- No Spread
	local spreadProp = self.CachedProperties["Spread"]
	if spreadProp then
		local newVal = State.NoSpread and 0 or (self.OriginalValues["Spread"] or 1)
		pcall(function()
			if spreadProp.Type == "ValueObject" then spreadProp.Object.Value = newVal
			elseif spreadProp.Type == "Attribute" then spreadProp.Object:SetAttribute(spreadProp.Field, newVal)
			elseif spreadProp.Type == "Table" then spreadProp.Object[spreadProp.Field] = newVal end
		end)
	end

	-- Auto Reload
	if State.AutoReload then
		local ammoProp = self.CachedProperties["Ammo"]
		local maxAmmoProp = self.CachedProperties["MaxAmmo"]
		if ammoProp and maxAmmoProp then
			local maxVal = (maxAmmoProp.Type == "ValueObject" and maxAmmoProp.Object.Value) 
				or (maxAmmoProp.Type == "Attribute" and maxAmmoProp.Object:GetAttribute(maxAmmoProp.Field))
				or (maxAmmoProp.Type == "Table" and maxAmmoProp.Object[maxAmmoProp.Field])

			if maxVal then
				pcall(function()
					if ammoProp.Type == "ValueObject" then ammoProp.Object.Value = maxVal
					elseif ammoProp.Type == "Attribute" then ammoProp.Object:SetAttribute(ammoProp.Field, maxVal)
					elseif ammoProp.Type == "Table" then ammoProp.Object[ammoProp.Field] = maxVal end
				end)
			end
		end
	end
end

-- ================================================================
-- SISTEMA DE MIRA (AIMBOT)
-- ================================================================
local Targeting = {
	FOVCircle = nil
}

function Targeting:InitFOV()
	local circle = Drawing.new("Circle")
	circle.Thickness = 1.5
	circle.Color = Color3.fromRGB(0, 255, 120)
	circle.Filled = false
	circle.Transparency = 0.8
	circle.NumSides = 32
	circle.Visible = false
	self.FOVCircle = circle
end

function Targeting:GetClosestTarget()
	local closestPlayer = nil
	local shortestDistance = State.FOV

	local mousePos = UserInputService:GetMouseLocation()

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			-- Checagem de Time
			if State.IgnoreTeam and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
				continue
			end

			local char = player.Character
			if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
				local targetPart = char:FindFirstChild(State.TargetPart) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
				if targetPart then
					local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
					if onScreen then
						-- Raycast para visibilidade
						if State.CheckVisibility then
							local rayParams = RaycastParams.new()
							rayParams.FilterType = Enum.RaycastFilterType.Exclude
							rayParams.FilterDescendantsInstances = {LocalPlayer.Character, char}
							local rayResult = Workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, rayParams)
							if rayResult then continue end
						end

						local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
						if dist < shortestDistance then
							shortestDistance = dist
							closestPlayer = targetPart
						end
					end
				end
			end
		end
	end

	return closestPlayer
end

function Targeting:Update()
	if self.FOVCircle then
		self.FOVCircle.Position = UserInputService:GetMouseLocation()
		self.FOVCircle.Radius = State.FOV
		self.FOVCircle.Visible = State.Aimbot and State.ShowFOV
	end

	if State.Aimbot then
		local targetPart = self:GetClosestTarget()
		if targetPart then
			local currentCFrame = Camera.CFrame
			local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
			Camera.CFrame = currentCFrame:Lerp(targetCFrame, math.clamp(State.Smoothing, 0.05, 1))
		end
	end
end

-- ================================================================
-- GERENCIADOR DE ESP CLIENT-SIDE
-- ================================================================
local ESPManager = {}

function ESPManager:CreateESPForPlayer(player)
	if player == LocalPlayer then return end

	local function setupChar(char)
		if not char then return end
		local root = char:WaitForChild("HumanoidRootPart", 3)
		local head = char:WaitForChild("Head", 3)
		local hum = char:WaitForChild("Humanoid", 3)

		if not (root and head and hum) then return end

		-- Highlight
		local hl = Instance.new("Highlight")
		hl.Name = "ESP_Highlight"
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.FillColor = Color3.fromRGB(0, 255, 120)
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = 0.5
		hl.Enabled = State.ESPMaster and State.ESPHighlight
		hl.Parent = char

		-- Billboard Gui para Nome, Distância e Vida
		local bb = Instance.new("BillboardGui")
		bb.Name = "ESP_Billboard"
		bb.Adornee = head
		bb.Size = UDim2.new(0, 150, 0, 50)
		bb.StudsOffset = Vector3.new(0, 2.5, 0)
		bb.AlwaysOnTop = true
		bb.Enabled = State.ESPMaster and (State.ESPName or State.ESPDistance or State.ESPHealth)

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.TextStrokeTransparency = 0.2
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12
		lbl.Parent = bb
		bb.Parent = char

		ConnectionManager._espObjects[player] = {Highlight = hl, Billboard = bb, Label = lbl, Char = char}
	end

	if player.Character then setupChar(player.Character) end
	ConnectionManager:Add(player.CharacterAdded:Connect(setupChar), "ESP")
end

function ESPManager:Update()
	if not State.ESPMaster then
		for _, data in pairs(ConnectionManager._espObjects) do
			if data.Highlight then data.Highlight.Enabled = false end
			if data.Billboard then data.Billboard.Enabled = false end
		end
		return
	end

	for player, data in pairs(ConnectionManager._espObjects) do
		local char = data.Char
		if char and char:Parent() and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
			local hum = char.Humanoid
			local root = char.HumanoidRootPart

			if hum.Health > 0 then
				if data.Highlight then
					data.Highlight.Enabled = State.ESPHighlight
				end

				if data.Billboard and data.Label then
					data.Billboard.Enabled = State.ESPName or State.ESPDistance or State.ESPHealth
					local text = ""
					if State.ESPName then text = text .. player.Name end
					if State.ESPDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
						local dist = math.floor((root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
						text = text .. " [" .. dist .. "m]"
					end
					if State.ESPHealth then
						text = text .. " (" .. math.floor(hum.Health) .. "HP)"
					end
					data.Label.Text = text
				end
			else
				if data.Highlight then data.Highlight.Enabled = false end
				if data.Billboard then data.Billboard.Enabled = false end
			end
		end
	end
end

function ESPManager:Init()
	for _, p in ipairs(Players:GetPlayers()) do
		self:CreateESPForPlayer(p)
	end
	ConnectionManager:Add(Players.PlayerAdded:Connect(function(p)
		self:CreateESPForPlayer(p)
	end), "ESP")

	ConnectionManager:Add(Players.PlayerRemoving:Connect(function(p)
		if ConnectionManager._espObjects[p] then
			ConnectionManager._espObjects[p] = nil
		end
	end), "ESP")
end

-- ================================================================
-- CONSTRUTOR DA INTERFACE GRÁFICA (UI)
-- ================================================================
local UI = {
	ScreenGui = nil,
	MainFrame = nil,
	FloatingBtn = nil,
	Pages = {},
	CurrentPage = nil,
	IncompatibilityNotifs = {}
}

function UI:CreateComponent(className, properties, children)
	local inst = Instance.new(className)
	for k, v in pairs(properties or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

function UI:MakeToggle(parent, titleText, descText, defaultState, callback, isCompatibleCheck)
	local state = defaultState
	local compatible = true

	if isCompatibleCheck then
		compatible = isCompatibleCheck()
	end

	local card = self:CreateComponent("Frame", {
		Size = UDim2.new(1, 0, 0, descText and 65 or 50),
		BackgroundColor3 = Color3.fromRGB(15, 35, 20),
		BorderSizePixel = 0,
		Parent = parent
	}, {
		Instance.new("UICorner", {CornerRadius = UDim.new(0, 12)}),
		Instance.new("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)})
	})

	local title = self:CreateComponent("TextLabel", {
		Size = UDim2.new(0.7, 0, 0, 24),
		Position = UDim2.new(0, 0, 0, descText and 8 or 13),
		BackgroundTransparency = 1,
		Text = titleText,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		Parent = card
	})

	if descText then
		self:CreateComponent("TextLabel", {
			Size = UDim2.new(0.7, 0, 0, 18),
			Position = UDim2.new(0, 0, 0, 32),
			BackgroundTransparency = 1,
			Text = compatible and descText or "Não compatível com este sistema de armas",
			TextColor3 = compatible and Color3.fromRGB(160, 180, 165) or Color3.fromRGB(255, 80, 80),
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			Parent = card
		})
	end

	local toggleBtn = self:CreateComponent("TextButton", {
		Size = UDim2.new(0, 44, 0, 24),
		Position = UDim2.new(1, -44, 0.5, -12),
		BackgroundColor3 = (state and compatible) and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(40, 50, 45),
		AutoButtonColor = false,
		Text = "",
		Parent = card
	}, {
		Instance.new("UICorner", {CornerRadius = UDim.new(1, 0)})
	})

	local circle = self:CreateComponent("Frame", {
		Size = UDim2.new(0, 18, 0, 18),
		Position = (state and compatible) and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = toggleBtn
	}, {
		Instance.new("UICorner", {CornerRadius = UDim.new(1, 0)})
	})

	local function toggle()
		if not compatible then return end
		state = not state
		TweenService:Create(toggleBtn, TWEEN_INFO, {
			BackgroundColor3 = state and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(40, 50, 45)
		}):Play()
		TweenService:Create(circle, TWEEN_INFO, {
			Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
		}):Play()
		callback(state)
	end

	toggleBtn.MouseButton1Click:Connect(toggle)
	return card
end

function UI:MakeSelector(parent, titleText, options, defaultIdx, callback)
	local card = self:CreateComponent("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = Color3.fromRGB(15, 35, 20),
		BorderSizePixel = 0,
		Parent = parent
	}, {
		Instance.new("UICorner", {CornerRadius = UDim.new(0, 12)}),
		Instance.new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)})
	})

	self:CreateComponent("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 6),
		BackgroundTransparency = 1,
		Text = titleText,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Parent = card
	})

	local container = self:CreateComponent("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.new(0, 0, 0, 28),
		BackgroundTransparency = 1,
		Parent = card
	}, {
		Instance.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Left
		})
	})

	for idx, optName in ipairs(options) do
		local btn = self:CreateComponent("TextButton", {
			Size = UDim2.new(1 / #options, -5, 1, 0),
			BackgroundColor3 = (idx == defaultIdx) and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(25, 45, 30),
			Text = tostring(optName),
			TextColor3 = (idx == defaultIdx) and Color3.fromRGB(5, 20, 10) or Color3.fromRGB(200, 220, 205),
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			Parent = container
		}, {
			Instance.new("UICorner", {CornerRadius = UDim.new(0, 6)})
		})

		btn.MouseButton1Click:Connect(function()
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = Color3.fromRGB(25, 45, 30)
					child.TextColor3 = Color3.fromRGB(200, 220, 205)
				end
			end
			btn.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
			btn.TextColor3 = Color3.fromRGB(5, 20, 10)
			callback(optName, idx)
		end)
	end
end

function UI:Build()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	if playerGui:FindFirstChild("RobloxCustomPanel") then
		playerGui.RobloxCustomPanel:Destroy()
	end

	self.ScreenGui = Instance.new("ScreenGui")
	self.ScreenGui.Name = "RobloxCustomPanel"
	self.ScreenGui.ResetOnSpawn = false
	self.ScreenGui.Parent = playerGui

	-- UI Scale para Adaptabilidade Mobile
	local uiScale = Instance.new("UIScale", self.ScreenGui)
	local function updateScale()
		local vp = Camera.ViewportSize
		if vp.X < 600 or vp.Y < 600 then
			uiScale.Scale = math.min(vp.X / 620, vp.Y / 650)
		else
			uiScale.Scale = 1
		end
	end
	updateScale()
	ConnectionManager:Add(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale), "UI")

	-- Painel Principal (Formato Aproximadamente Quadrado 560x580)
	local main = self:CreateComponent("Frame", {
		Name = "MainFrame",
		Size = UDim2.new(0, 560, 0, 580),
		Position = UDim2.new(0.5, -280, 0.5, -290),
		BackgroundColor3 = Color3.fromRGB(10, 12, 10),
		ClipsDescendants = true,
		Parent = self.ScreenGui
	}, {
		Instance.new("UICorner", {CornerRadius = UDim.new(0, 24)}),
		Instance.new("UIStroke", {Color = Color3.fromRGB(25, 45, 30), Thickness = 2})
	})
	self.MainFrame = main

	-- Topbar (Arrastável)
	local topbar = self:CreateComponent("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundTransparency = 1,
		Parent = main
	})

	-- Arraste Mobile / PC
	local dragging, dragStart, startPos
	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	-- Logo e Título
	local logoImg = self:CreateComponent("ImageLabel", {
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(0, 20, 0, 12),
		BackgroundTransparency = 1,
		Image = LOGO_ASSET,
		Parent = topbar
	}, {
		Instance.new("UICorner", {CornerRadius = UDim.new(1, 0)})
	})

	local headerPill = self:CreateComponent("Frame", {
		Size = UDim2.new(0, 180, 0, 38),
		Position = UDim2.new(0, 68, 0, 11),
		BackgroundColor3 = Color3.fromRGB(15, 45, 20),
		Parent = topbar
	}, {
		Instance.new("UICorner", {CornerRadius = UDim.new(1, 0)})
	})

	local titleLabel = self:CreateComponent("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "⚡ FUNÇÕES",
		TextColor3 = Color3.fromRGB(0, 255, 120),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		Parent = headerPill
	})

	-- Botão Fechar
	local closeBtn = self:CreateComponent("TextButton", {
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(1, -50, 0, 12),
		BackgroundColor3 = Color3.fromRGB(20, 35, 25),
		Text = "✕",
		TextColor3 = Color3.fromRGB(0, 255, 120),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		Parent = topbar
	}, {
		Instance.new("UICorner", {CornerRadius = UDim.new(1, 0)})
	})

	-- Botão Flutuante (para reabrir)
	local floatBtn = self:CreateComponent("ImageButton", {
		Size = UDim2.new(0, 50, 0, 50),
		Position = UDim2.new(0, 15, 0.5, -25),
		BackgroundColor3 = Color3.fromRGB(10, 20, 12),
		Image = LOGO_ASSET,
		Visible = false,
		Parent = self.ScreenGui
	}, {
		Instance.new("UICorner", {CornerRadius = UDim.new(1, 0)}),
		Instance.new("UIStroke", {Color = Color3.fromRGB(0, 255, 120), Thickness = 2})
	})
	self.FloatingBtn = floatBtn

	closeBtn.MouseButton1Click:Connect(function()
		TweenService:Create(main, TWEEN_INFO, {Size = UDim2.new(0, 0, 0, 0), Position = main.Position + UDim2.new(0, 280, 0, 290)}):Play()
		task.wait(0.25)
		main.Visible = false
		floatBtn.Visible = true
	end)

	floatBtn.MouseButton1Click:Connect(function()
		floatBtn.Visible = false
		main.Visible = true
		main.Size = UDim2.new(0, 0, 0, 0)
		main.Position = UDim2.new(0.5, 0, 0.5, 0)
		TweenService:Create(main, TWEEN_INFO, {Size = UDim2.new(0, 560, 0, 580), Position = UDim2.new(0.5, -280, 0.5, -290)}):Play()
	end)

	-- Sidebar Lateral Esquerda (Abas)
	local sidebar = self:CreateComponent("Frame", {
		Size = UDim2.new(0, 70, 1, -70),
		Position = UDim2.new(0, 10, 0, 60),
		BackgroundTransparency = 1,
		Parent = main
	}, {
		Instance.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 14),
			HorizontalAlignment = Enum.HorizontalAlignment.Center
		})
	})

	-- Área Conteúdo Central (ScrollingFrames)
	local contentArea = self:CreateComponent("Frame", {
		Size = UDim2.new(1, -95, 1, -75),
		Position = UDim2.new(0, 85, 0, 65),
		BackgroundTransparency = 1,
		Parent = main
	})

	-- DEFINIÇÃO DAS ABAS
	local tabs = {
		{Id = "AIM", Icon = "🎯", Title = "⚡ AIM / FUNÇÕES"},
		{Id = "ESP", Icon = "👁", Title = "👁 VISUAL / ESP"},
		{Id = "WEAPON", Icon = "⚙", Title = "🔫 ARMAS"},
		{Id = "MOVE", Icon = "🏃", Title = "🏃 MOVIMENTO"},
		{Id = "SETTINGS", Icon = "🔧", Title = "🔧 CONFIGURAÇÕES"}
	}

	for idx, tabData in ipairs(tabs) do
		-- Botão Aba
		local tabBtn = self:CreateComponent("TextButton", {
			Size = UDim2.new(0, 48, 0, 48),
			BackgroundColor3 = (idx == 1) and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(18, 30, 22),
			Text = tabData.Icon,
			TextColor3 = (idx == 1) and Color3.fromRGB(10, 20, 10) or Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBold,
			TextSize = 20,
			Parent = sidebar
		}, {
			Instance.new("UICorner", {CornerRadius = UDim.new(1, 0)})
		})

		-- Frame do Conteúdo da Aba
		local pageScroll = self:CreateComponent("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Color3.fromRGB(0, 255, 120),
			Visible = (idx == 1),
			Parent = contentArea
		}, {
			Instance.new("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 10),
				HorizontalAlignment = Enum.HorizontalAlignment.Center
			}),
			Instance.new("UIPadding", {PaddingRight = UDim.new(0, 8)})
		})

		pageScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			pageScroll.CanvasSize = UDim2.new(0, 0, 0, pageScroll.UIListLayout.AbsoluteContentSize.Y + 20)
		end)

		self.Pages[tabData.Id] = pageScroll

		tabBtn.MouseButton1Click:Connect(function()
			for _, child in ipairs(sidebar:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = Color3.fromRGB(18, 30, 22)
					child.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end
			tabBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
			tabBtn.TextColor3 = Color3.fromRGB(10, 20, 10)

			for _, page in pairs(self.Pages) do
				page.Visible = false
			end
			pageScroll.Visible = true
			titleLabel.Text = tabData.Title
		end)
	end

	self:PopulatePages()
end

function UI:PopulatePages()
	-- 1. AIM PAGE
	local aimPage = self.Pages["AIM"]
	self:MakeToggle(aimPage, "Aimbot", "Mira automaticamente no alvo mais próximo", State.Aimbot, function(v) State.Aimbot = v end)
	self:MakeToggle(aimPage, "Silent Aim", "Redireciona disparos sem mover a câmera", State.SilentAim, function(v) State.SilentAim = v end)
	self:MakeToggle(aimPage, "AimKill", "Elimina alvos de forma automática", State.AimKill, function(v) State.AimKill = v end, function()
		-- Verificação de compatibilidade para AimKill client-side
		return false
	end)
	self:MakeToggle(aimPage, "Ignorar Bot", "Não mira em NPCs ou Bots", State.IgnoreBots, function(v) State.IgnoreBots = v end)
	self:MakeToggle(aimPage, "Ignorar Time", "Não mira em colegas de equipe", State.IgnoreTeam, function(v) State.IgnoreTeam = v end)
	self:MakeToggle(aimPage, "Verificar Visibilidade", "Ignora alvos atrás de paredes", State.CheckVisibility, function(v) State.CheckVisibility = v end)
	self:MakeToggle(aimPage, "Exibir Círculo FOV", "Mostra o raio de alcance da mira", State.ShowFOV, function(v) State.ShowFOV = v end)

	self:MakeSelector(aimPage, "Parte do Alvo", {"Head", "HumanoidRootPart"}, 1, function(opt)
		State.TargetPart = opt
	end)

	self:MakeSelector(aimPage, "Tamanho FOV", {60, 90, 120, 180, 250}, 3, function(opt)
		State.FOV = tonumber(opt)
	end)

	-- 2. VISUAL / ESP PAGE
	local espPage = self.Pages["ESP"]
	self:MakeToggle(espPage, "ESP Master", "Ativar/Desativar todos os visuais", State.ESPMaster, function(v) State.ESPMaster = v end)
	self:MakeToggle(espPage, "ESP Highlight", "Realça os jogadores através das paredes", State.ESPHighlight, function(v) State.ESPHighlight = v end)
	self:MakeToggle(espPage, "ESP Nome", "Exibe o nome do jogador", State.ESPName, function(v) State.ESPName = v end)
	self:MakeToggle(espPage, "ESP Distância", "Exibe a distância em metros", State.ESPDistance, function(v) State.ESPDistance = v end)
	self:MakeToggle(espPage, "ESP Vida", "Exibe a vida atual do jogador", State.ESPHealth, function(v) State.ESPHealth = v end)

	-- 3. ARMAS PAGE
	local wpnPage = self.Pages["WEAPON"]
	self:MakeToggle(wpnPage, "Auto Reload", "Recarrega a munição automaticamente", State.AutoReload, function(v)
		State.AutoReload = v
		WeaponScanner:ApplyModifiers()
	end, function()
		return WeaponScanner.CachedProperties["Ammo"] ~= nil
	end)

	self:MakeToggle(wpnPage, "Sem Recuo (No Recoil)", "Remove o movimento de recuo da arma", State.NoRecoil, function(v)
		State.NoRecoil = v
		WeaponScanner:ApplyModifiers()
	end, function()
		return WeaponScanner.CachedProperties["Recoil"] ~= nil
	end)

	self:MakeToggle(wpnPage, "Sem Spread (No Spread)", "Mantém os tiros no centro exato", State.NoSpread, function(v)
		State.NoSpread = v
		WeaponScanner:ApplyModifiers()
	end, function()
		return WeaponScanner.CachedProperties["Spread"] ~= nil
	end)

	self:MakeSelector(wpnPage, "Velocidade de Disparo (Fire Speed)", {"NORMAL", "1.5X", "2X", "3X", "5X"}, 1, function(opt, idx)
		local mults = {1, 1.5, 2, 3, 5}
		State.FireSpeedMultiplier = mults[idx] or 1
		WeaponScanner:ApplyModifiers()
	end)

	-- 4. MOVIMENTO PAGE
	local movePage = self.Pages["MOVE"]
	self:MakeSelector(movePage, "Velocidade (WalkSpeed)", {16, 24, 32, 48, 64}, 1, function(opt)
		State.WalkSpeed = tonumber(opt)
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			LocalPlayer.Character.Humanoid.WalkSpeed = State.WalkSpeed
		end
	end)

	self:MakeSelector(movePage, "Força do Pulo (JumpPower)", {50, 75, 100, 150}, 1, function(opt)
		State.JumpPower = tonumber(opt)
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			LocalPlayer.Character.Humanoid.JumpPower = State.JumpPower
		end
	end)

	self:MakeToggle(movePage, "FlyKill", "Voa e elimina alvos automaticamente", State.FlyKill, function(v) State.FlyKill = v end, function()
		-- Incompatível se depender puramente do servidor
		return false
	end)

	-- 5. CONFIGURAÇÕES PAGE
	local setPage = self.Pages["SETTINGS"]
	self:MakeToggle(setPage, "Exibir Logo no Topo", "Mostrar/Ocultar a marca da interface", State.ShowLogo, function(v)
		State.ShowLogo = v
	end)

	local destroyBtn = self:CreateComponent("TextButton", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = Color3.fromRGB(120, 20, 20),
		Text = "DESTRUIR INTERFACE E DESCONECTAR",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Parent = setPage
	}, {
		Instance.new("UICorner", {CornerRadius = UDim.new(0, 12)})
	})

	destroyBtn.MouseButton1Click:Connect(function()
		WeaponScanner:RestoreOriginals()
		ConnectionManager:ClearAll()
		if Targeting.FOVCircle then Targeting.FOVCircle:Remove() end
		if self.ScreenGui then self.ScreenGui:Destroy() end
	end)
end

-- ================================================================
-- INICIALIZAÇÃO E LOOP PRINCIPAL
-- ================================================================
local function Init()
	Targeting:InitFOV()
	ESPManager:Init()
	UI:Build()

	-- Detecção contínua de Personagem e Ferramentas Equipadas
	ConnectionManager:Add(RunService.RenderStepped:Connect(function()
		-- Atualizar Mira e ESP
		Targeting:Update()
		ESPManager:Update()

		-- Auto-Detecção de Arma Equipada
		local tool = WeaponScanner:GetActiveTool()
		if tool then
			if tool ~= WeaponScanner.CurrentTool then
				WeaponScanner:Scan(tool)
				WeaponScanner:ApplyModifiers()
			end
		else
			if WeaponScanner.CurrentTool then
				WeaponScanner:RestoreOriginals()
				WeaponScanner.CurrentTool = nil
			end
		end

		-- Manter Modificadores de Movimento
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			local hum = LocalPlayer.Character.Humanoid
			if hum.WalkSpeed ~= State.WalkSpeed and State.WalkSpeed ~= 16 then
				hum.WalkSpeed = State.WalkSpeed
			end
		end
	end), "Render")

	-- Reconectar eventos ao respawnar
	ConnectionManager:Add(LocalPlayer.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid")
		task.wait(0.5)
		if State.WalkSpeed ~= 16 then
			char.Humanoid.WalkSpeed = State.WalkSpeed
		end
	end), "Character")
end

Init()
