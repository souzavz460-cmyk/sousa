--[[
    ============================================================
                    ULTRA NOCLIP - LOCAL V1
    ============================================================

    Feito para uso no SEU próprio jogo no Roblox Studio.

    LOCAL:
    StarterPlayer
        > StarterPlayerScripts
            > LocalScript

    RECURSOS:
    - 100% LocalScript
    - GUI simples
    - PC + Mobile
    - Tecla N liga/desliga
    - RightShift esconde/mostra GUI
    - Respawn automático
    - R6 / R15 / rigs customizados
    - Detecta novas partes automaticamente
    - Detecta acessórios e Tools equipadas
    - Preserva CanCollide original de cada peça
    - Restaura corretamente quando desligado
    - PreSimulation enforcement
    - PropertyChanged enforcement
    - Safe Exit
    - Anti-stuck básico
    - GUI arrastável
    - Não mexe em CanTouch/CanQuery
    - Limpeza automática

    ============================================================
]]

------------------------------------------------------------
-- SERVICES
------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------
-- PLAYER
------------------------------------------------------------

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------

local CONFIG = {

	-- N = ativar/desativar noclip
	ToggleKey = Enum.KeyCode.N,

	-- RightShift = esconder/mostrar interface
	GuiKey = Enum.KeyCode.RightShift,

	-- Confere se você ainda está dentro de uma parede
	-- antes de restaurar colisão.
	SafeExit = true,

	-- Intervalo da verificação de saída segura.
	SafeCheckInterval = 0.10,

	-- Reduz um pouco a caixa usada para detectar se
	-- o personagem está realmente dentro de uma parede.
	SafeBoxScale = 0.78,

	-- Quantidade máxima de objetos considerados
	-- por cada verificação.
	SafeMaxParts = 100,

	-- Reaplica CanCollide=false antes da física.
	PreSimulationEnforcement = true,
}

------------------------------------------------------------
-- STATE
------------------------------------------------------------

local State = {

	-- OFF
	-- ON
	-- EXITING
	Mode = "OFF",

	Character = nil,

	GuiVisible = true,

	TrackedCount = 0,

	ExitAccumulator = 0,
}

------------------------------------------------------------
-- TABELAS
------------------------------------------------------------

-- weak tables:
-- se uma Part for destruída, ela pode ser coletada
-- automaticamente pelo garbage collector.

local OriginalState = setmetatable({}, {
	__mode = "k"
})

local PartConnections = setmetatable({}, {
	__mode = "k"
})

local CharacterConnections = {}

------------------------------------------------------------
-- FORWARD DECLARATIONS
------------------------------------------------------------

local updateUI
local enableNoclip
local disableNoclip
local toggleNoclip
local bindCharacter

------------------------------------------------------------
-- CONNECTION UTILS
------------------------------------------------------------

local function disconnect(connection)

	if connection then
		connection:Disconnect()
	end
end

local function disconnectCharacterConnections()

	for _, connection in ipairs(CharacterConnections) do

		if connection then
			connection:Disconnect()
		end
	end

	table.clear(CharacterConnections)
end

------------------------------------------------------------
-- CHARACTER VALIDATION
------------------------------------------------------------

local function isCurrentCharacterPart(part)

	if not State.Character then
		return false
	end

	if not part then
		return false
	end

	if not part:IsA("BasePart") then
		return false
	end

	return part:IsDescendantOf(State.Character)
end

------------------------------------------------------------
-- COUNT TRACKED PARTS
------------------------------------------------------------

local function recountParts()

	local count = 0

	for part in pairs(OriginalState) do

		if part and part.Parent then
			count += 1
		end
	end

	State.TrackedCount = count
end

------------------------------------------------------------
-- STORE ORIGINAL STATE
------------------------------------------------------------

local function saveOriginalState(part)

	if OriginalState[part] ~= nil then
		return
	end

	OriginalState[part] = {

		CanCollide = part.CanCollide,
	}
end

------------------------------------------------------------
-- ENFORCE ONE PART
------------------------------------------------------------

local function enforcePart(part)

	if State.Mode == "OFF" then
		return
	end

	if not isCurrentCharacterPart(part) then
		return
	end

	if part.CanCollide then
		part.CanCollide = false
	end
end

------------------------------------------------------------
-- WATCH ONE PART
------------------------------------------------------------

local function trackPart(part)

	if not part:IsA("BasePart") then
		return
	end

	if not isCurrentCharacterPart(part) then
		return
	end

	saveOriginalState(part)

	--------------------------------------------------------
	-- PROPERTY WATCHER
	--------------------------------------------------------

	if not PartConnections[part] then

		PartConnections[part] =
			part:GetPropertyChangedSignal("CanCollide"):Connect(function()

				if State.Mode == "OFF" then
					return
				end

				if not isCurrentCharacterPart(part) then
					return
				end

				-- Se outro sistema reativar colisão
				-- enquanto noclip está ligado,
				-- desativa novamente.

				if part.CanCollide then
					part.CanCollide = false
				end
			end)
	end

	enforcePart(part)

	recountParts()

	if updateUI then
		updateUI()
	end
end

------------------------------------------------------------
-- RESTORE ONE PART
------------------------------------------------------------

local function restorePart(part)

	local original = OriginalState[part]

	if original then

		if part and part.Parent then

			pcall(function()

				part.CanCollide = original.CanCollide
			end)
		end

		OriginalState[part] = nil
	end

	if PartConnections[part] then

		PartConnections[part]:Disconnect()
		PartConnections[part] = nil
	end
end

------------------------------------------------------------
-- RESTORE EVERYTHING
------------------------------------------------------------

local function restoreAllParts()

	-- Primeiro deixa o modo OFF para impedir que
	-- PropertyChanged coloque false novamente.

	State.Mode = "OFF"

	local parts = {}

	for part in pairs(OriginalState) do
		table.insert(parts, part)
	end

	for _, part in ipairs(parts) do
		restorePart(part)
	end

	State.TrackedCount = 0
end

------------------------------------------------------------
-- TRACK WHOLE CHARACTER
------------------------------------------------------------

local function trackCharacter()

	local character = State.Character

	if not character then
		return
	end

	for _, object in ipairs(character:GetDescendants()) do

		if object:IsA("BasePart") then
			trackPart(object)
		end
	end
end

------------------------------------------------------------
-- RE-ENFORCE CHARACTER
------------------------------------------------------------

local function enforceCharacter()

	if State.Mode == "OFF" then
		return
	end

	local character = State.Character

	if not character then
		return
	end

	for _, object in ipairs(character:GetDescendants()) do

		if object:IsA("BasePart") then

			-- Caso ainda não esteja registrado,
			-- registra agora.

			if not OriginalState[object] then
				trackPart(object)
			else
				enforcePart(object)
			end
		end
	end
end

------------------------------------------------------------
-- SAFE EXIT PARAMETERS
------------------------------------------------------------

local Overlap = OverlapParams.new()

Overlap.FilterType = Enum.RaycastFilterType.Exclude
Overlap.MaxParts = CONFIG.SafeMaxParts
Overlap.RespectCanCollide = true

------------------------------------------------------------
-- CHECK IF CHARACTER IS INSIDE SOLID PART
------------------------------------------------------------

local function characterInsideSolid()

	local character = State.Character

	if not character then
		return false
	end

	Overlap.FilterDescendantsInstances = {
		character
	}

	for _, object in ipairs(character:GetDescendants()) do

		if object:IsA("BasePart") then

			------------------------------------------------
			-- Ignora peças absurdamente pequenas
			------------------------------------------------

			if object.Size.Magnitude > 0.15 then

				local scale = CONFIG.SafeBoxScale

				local size = Vector3.new(

					math.max(
						object.Size.X * scale,
						0.05
					),

					math.max(
						object.Size.Y * scale,
						0.05
					),

					math.max(
						object.Size.Z * scale,
						0.05
					)
				)

				local success, hits = pcall(function()

					return Workspace:GetPartBoundsInBox(
						object.CFrame,
						size,
						Overlap
					)
				end)

				if success then

					for _, hit in ipairs(hits) do

						if hit
							and hit:IsA("BasePart")
							and hit.CanCollide
							and not hit:IsDescendantOf(character)
						then

							return true
						end
					end
				end
			end
		end
	end

	return false
end

------------------------------------------------------------
-- CHARACTER DESCENDANT ADDED
------------------------------------------------------------

local function onDescendantAdded(object)

	if not object:IsA("BasePart") then
		return
	end

	if State.Mode ~= "OFF" then

		-- defer ajuda especialmente com acessórios
		-- sendo montados no character.

		task.defer(function()

			if object.Parent
				and State.Character
				and object:IsDescendantOf(State.Character)
			then

				trackPart(object)
			end
		end)
	end
end

------------------------------------------------------------
-- CHARACTER DESCENDANT REMOVING
------------------------------------------------------------

local function onDescendantRemoving(object)

	if not object:IsA("BasePart") then
		return
	end

	if not OriginalState[object] then
		return
	end

	-- O evento ocorre durante a mudança de parent.
	-- Esperamos um ciclo para descobrir se realmente
	-- saiu do personagem.

	task.defer(function()

		if not object.Parent then

			restorePart(object)

		elseif not State.Character
			or not object:IsDescendantOf(State.Character)
		then

			restorePart(object)
		end

		recountParts()

		if updateUI then
			updateUI()
		end
	end)
end

------------------------------------------------------------
-- BIND CHARACTER
------------------------------------------------------------

bindCharacter = function(character)

	disconnectCharacterConnections()

	--------------------------------------------------------
	-- Limpa referências anteriores
	--------------------------------------------------------

	for part, connection in pairs(PartConnections) do

		if connection then
			connection:Disconnect()
		end

		PartConnections[part] = nil
	end

	table.clear(OriginalState)

	State.Character = character
	State.TrackedCount = 0

	--------------------------------------------------------
	-- Descendants dinâmicos
	--------------------------------------------------------

	table.insert(
		CharacterConnections,

		character.DescendantAdded:Connect(
			onDescendantAdded
		)
	)

	table.insert(
		CharacterConnections,

		character.DescendantRemoving:Connect(
			onDescendantRemoving
		)
	)

	--------------------------------------------------------
	-- Mantém noclip depois de morrer/respawn
	--------------------------------------------------------

	if State.Mode ~= "OFF" then

		task.defer(function()

			if State.Character == character then
				trackCharacter()
			end
		end)
	end

	if updateUI then
		updateUI()
	end
end

------------------------------------------------------------
-- ENABLE
------------------------------------------------------------

enableNoclip = function()

	if State.Mode == "ON" then
		return
	end

	State.Mode = "ON"
	State.ExitAccumulator = 0

	trackCharacter()

	if updateUI then
		updateUI()
	end
end

------------------------------------------------------------
-- FINISH DISABLE
------------------------------------------------------------

local function finishDisable()

	restoreAllParts()

	State.Mode = "OFF"
	State.ExitAccumulator = 0

	if updateUI then
		updateUI()
	end
end

------------------------------------------------------------
-- DISABLE
------------------------------------------------------------

disableNoclip = function()

	if State.Mode == "OFF" then
		return
	end

	if not CONFIG.SafeExit then

		finishDisable()
		return
	end

	--------------------------------------------------------
	-- Se ainda estiver dentro de parede:
	-- continua sem colisão até sair.
	--------------------------------------------------------

	if characterInsideSolid() then

		State.Mode = "EXITING"
		State.ExitAccumulator = 0

	else

		finishDisable()
	end

	if updateUI then
		updateUI()
	end
end

------------------------------------------------------------
-- TOGGLE
------------------------------------------------------------

toggleNoclip = function()

	if State.Mode == "OFF" then

		enableNoclip()

	else

		disableNoclip()
	end
end

------------------------------------------------------------
-- PRE-SIMULATION ENGINE
------------------------------------------------------------

RunService.PreSimulation:Connect(function(deltaTime)

	if State.Mode == "OFF" then
		return
	end

	--------------------------------------------------------
	-- FALLBACK ENFORCEMENT
	--------------------------------------------------------

	if CONFIG.PreSimulationEnforcement then
		enforceCharacter()
	end

	--------------------------------------------------------
	-- SAFE EXIT
	--------------------------------------------------------

	if State.Mode == "EXITING" then

		State.ExitAccumulator += deltaTime

		if State.ExitAccumulator
			>= CONFIG.SafeCheckInterval
		then

			State.ExitAccumulator = 0

			if not characterInsideSolid() then

				finishDisable()
			end
		end
	end
end)

------------------------------------------------------------
-- CHARACTER RESPAWN
------------------------------------------------------------

Player.CharacterAdded:Connect(function(character)

	bindCharacter(character)
end)

Player.CharacterRemoving:Connect(function(character)

	if State.Character == character then

		disconnectCharacterConnections()

		State.Character = nil

		----------------------------------------------------
		-- As antigas partes serão destruídas.
		-- Limpamos os watchers sem desligar o modo geral,
		-- permitindo noclip persistir no próximo respawn.
		----------------------------------------------------

		for part, connection in pairs(PartConnections) do

			if connection then
				connection:Disconnect()
			end

			PartConnections[part] = nil
		end

		table.clear(OriginalState)

		State.TrackedCount = 0

		if updateUI then
			updateUI()
		end
	end
end)

------------------------------------------------------------
-- INITIAL CHARACTER
------------------------------------------------------------

if Player.Character then

	bindCharacter(Player.Character)
end

------------------------------------------------------------
-- DESTROY OLD GUI
------------------------------------------------------------

local oldGui =
	PlayerGui:FindFirstChild("UltraNoclipGUI")

if oldGui then
	oldGui:Destroy()
end

------------------------------------------------------------
-- GUI
------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")

ScreenGui.Name = "UltraNoclipGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

------------------------------------------------------------
-- MAIN FRAME
------------------------------------------------------------

local Main = Instance.new("Frame")

Main.Name = "Main"

Main.Size = UDim2.fromOffset(
	260,
	150
)

Main.Position = UDim2.new(
	0.5,
	-130,
	0.5,
	-75
)

Main.BackgroundColor3 =
	Color3.fromRGB(
		18,
		18,
		24
	)

Main.BorderSizePixel = 0
Main.Parent = ScreenGui

------------------------------------------------------------
-- MAIN CORNER
------------------------------------------------------------

local MainCorner = Instance.new("UICorner")

MainCorner.CornerRadius =
	UDim.new(
		0,
		12
	)

MainCorner.Parent = Main

------------------------------------------------------------
-- STROKE
------------------------------------------------------------

local Stroke = Instance.new("UIStroke")

Stroke.Color =
	Color3.fromRGB(
		72,
		72,
		92
	)

Stroke.Thickness = 1
Stroke.Transparency = 0.15
Stroke.Parent = Main

------------------------------------------------------------
-- TITLE
------------------------------------------------------------

local Title = Instance.new("TextLabel")

Title.Size =
	UDim2.new(
		1,
		-20,
		0,
		28
	)

Title.Position =
	UDim2.fromOffset(
		10,
		8
	)

Title.BackgroundTransparency = 1

Title.Text =
	"ULTRA NOCLIP"

Title.TextColor3 =
	Color3.fromRGB(
		245,
		245,
		250
	)

Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

------------------------------------------------------------
-- STATUS
------------------------------------------------------------

local Status = Instance.new("TextLabel")

Status.Size =
	UDim2.new(
		1,
		-20,
		0,
		20
	)

Status.Position =
	UDim2.fromOffset(
		10,
		36
	)

Status.BackgroundTransparency = 1

Status.Text =
	"STATUS: OFF"

Status.TextColor3 =
	Color3.fromRGB(
		150,
		150,
		165
	)

Status.TextSize = 12
Status.Font = Enum.Font.GothamMedium
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

------------------------------------------------------------
-- BUTTON
------------------------------------------------------------

local ToggleButton = Instance.new("TextButton")

ToggleButton.Size =
	UDim2.new(
		1,
		-20,
		0,
		42
	)

ToggleButton.Position =
	UDim2.fromOffset(
		10,
		62
	)

ToggleButton.BackgroundColor3 =
	Color3.fromRGB(
		67,
		67,
		82
	)

ToggleButton.BorderSizePixel = 0

ToggleButton.Text =
	"ENABLE"

ToggleButton.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

ToggleButton.TextSize = 14
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.AutoButtonColor = false
ToggleButton.Parent = Main

local ButtonCorner = Instance.new("UICorner")

ButtonCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

ButtonCorner.Parent = ToggleButton

------------------------------------------------------------
-- INFO
------------------------------------------------------------

local Info = Instance.new("TextLabel")

Info.Size =
	UDim2.new(
		1,
		-20,
		0,
		30
	)

Info.Position =
	UDim2.fromOffset(
		10,
		112
	)

Info.BackgroundTransparency = 1

Info.Text =
	"N • Toggle   |   RightShift • GUI"

Info.TextColor3 =
	Color3.fromRGB(
		115,
		115,
		130
	)

Info.TextSize = 10
Info.Font = Enum.Font.Gotham
Info.TextXAlignment = Enum.TextXAlignment.Center
Info.Parent = Main

------------------------------------------------------------
-- UI UPDATE
------------------------------------------------------------

updateUI = function()

	if not Status
		or not ToggleButton
	then
		return
	end

	if State.Mode == "ON" then

		Status.Text =
			"STATUS: ON  •  PARTS: "
			.. tostring(State.TrackedCount)

		Status.TextColor3 =
			Color3.fromRGB(
				110,
				255,
				155
			)

		ToggleButton.Text =
			"DISABLE NOCLIP"

		ToggleButton.BackgroundColor3 =
			Color3.fromRGB(
				115,
				72,
				235
			)

	elseif State.Mode == "EXITING" then

		Status.Text =
			"SAIA DA PAREDE PARA DESLIGAR"

		Status.TextColor3 =
			Color3.fromRGB(
				255,
				195,
				90
			)

		ToggleButton.Text =
			"CANCEL SAFE EXIT"

		ToggleButton.BackgroundColor3 =
			Color3.fromRGB(
				200,
				125,
				50
			)

	else

		Status.Text =
			"STATUS: OFF"

		Status.TextColor3 =
			Color3.fromRGB(
				150,
				150,
				165
			)

		ToggleButton.Text =
			"ENABLE NOCLIP"

		ToggleButton.BackgroundColor3 =
			Color3.fromRGB(
				67,
				67,
				82
			)
	end
end

updateUI()

------------------------------------------------------------
-- BUTTON CLICK
------------------------------------------------------------

ToggleButton.MouseButton1Click:Connect(function()

	if State.Mode == "EXITING" then

		-- Clicar novamente cancela a tentativa
		-- de desligar e volta para ON.

		State.Mode = "ON"
		State.ExitAccumulator = 0

		updateUI()

		return
	end

	toggleNoclip()
end)

------------------------------------------------------------
-- BUTTON ANIMATION
------------------------------------------------------------

ToggleButton.MouseEnter:Connect(function()

	TweenService:Create(

		ToggleButton,

		TweenInfo.new(
			0.12
		),

		{
			BackgroundTransparency = 0.12
		}

	):Play()
end)

ToggleButton.MouseLeave:Connect(function()

	TweenService:Create(

		ToggleButton,

		TweenInfo.new(
			0.12
		),

		{
			BackgroundTransparency = 0
		}

	):Play()
end)

------------------------------------------------------------
-- KEYBINDS
------------------------------------------------------------

UserInputService.InputBegan:Connect(
	function(input, gameProcessed)

		if gameProcessed then
			return
		end

		-- Não ativa tecla enquanto o player
		-- estiver escrevendo em TextBox.

		if UserInputService:GetFocusedTextBox() then
			return
		end

		if input.KeyCode == CONFIG.ToggleKey then

			if State.Mode == "EXITING" then

				State.Mode = "ON"
				State.ExitAccumulator = 0

				updateUI()

			else

				toggleNoclip()
			end

		elseif input.KeyCode == CONFIG.GuiKey then

			State.GuiVisible =
				not State.GuiVisible

			Main.Visible =
				State.GuiVisible
		end
	end
)

------------------------------------------------------------
-- DRAGGING SYSTEM
------------------------------------------------------------

local dragging = false
local dragInput = nil
local dragStart = nil
local startPosition = nil

Main.InputBegan:Connect(function(input)

	if input.UserInputType
			== Enum.UserInputType.MouseButton1

		or input.UserInputType
			== Enum.UserInputType.Touch
	then

		dragging = true

		dragStart =
			input.Position

		startPosition =
			Main.Position

		input.Changed:Connect(function()

			if input.UserInputState
				== Enum.UserInputState.End
			then

				dragging = false
			end
		end)
	end
end)

Main.InputChanged:Connect(function(input)

	if input.UserInputType
		== Enum.UserInputType.MouseMovement

		or input.UserInputType
		== Enum.UserInputType.Touch
	then

		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)

	if input ~= dragInput then
		return
	end

	if not dragging then
		return
	end

	local delta =
		input.Position
		- dragStart

	Main.Position =
		UDim2.new(

			startPosition.X.Scale,

			startPosition.X.Offset
				+ delta.X,

			startPosition.Y.Scale,

			startPosition.Y.Offset
				+ delta.Y
		)
end)

------------------------------------------------------------
-- SCRIPT CLEANUP
------------------------------------------------------------

script.Destroying:Connect(function()

	--------------------------------------------------------
	-- Restaura tudo antes do script desaparecer
	--------------------------------------------------------

	restoreAllParts()

	disconnectCharacterConnections()

	for part, connection in pairs(PartConnections) do

		if connection then
			connection:Disconnect()
		end

		PartConnections[part] = nil
	end

	if ScreenGui then
		ScreenGui:Destroy()
	end
end)

------------------------------------------------------------
-- READY
------------------------------------------------------------

print(
	"[ULTRA NOCLIP] Loaded successfully."
)
