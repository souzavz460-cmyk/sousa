--[[
    ADVANCED MOBILE FLY V4
    Roblox Studio - LocalScript

    Coloque em:
    StarterPlayer > StarterPlayerScripts

    IMPORTANTE:
    Apague/desative qualquer Fly antigo antes de testar.

    MOBILE:
    • Analógico = movimentação
    • SUBIR / DESCER = segurar
    • CAMERA 3D = voa na direção que a câmera olha
    • HOVER = parada extremamente estável
]]

--------------------------------------------------
-- SERVICES
--------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

--------------------------------------------------
-- CONFIG
--------------------------------------------------

local Config = {

	Flying = false,

	NoClip = false,
	Camera3D = false,
	FaceDirection = true,

	Boost = false,
	Hover = false,

	Speed = 65,
	VerticalSpeed = 50,

	MinSpeed = 10,
	MaxSpeed = 300,

	MinVertical = 10,
	MaxVertical = 200,

	SpeedStep = 10,
	VerticalStep = 10,

	BoostMultiplier = 2,

	Acceleration = 8,
	Braking = 12,
	VerticalAcceleration = 10,

	RotationResponsiveness = 25,

	Deadzone = 0.025,
}

--------------------------------------------------
-- VARIABLES
--------------------------------------------------

local Character
local Humanoid
local Root

local FlyAttachment
local LinearVelocity
local AlignOrientation

local CurrentVelocity = Vector3.zero

local UpHeld = false
local DownHeld = false

local Original = {}

local CollisionBackup = {}

local RenderConnection
local PhysicsConnection
local NoClipConnection

--------------------------------------------------
-- MATH
--------------------------------------------------

local function expAlpha(rate, dt)
	return 1 - math.exp(-rate * dt)
end

local function flatVector(v)

	local result = Vector3.new(
		v.X,
		0,
		v.Z
	)

	if result.Magnitude > 0.001 then
		return result.Unit
	end

	return Vector3.zero
end

--------------------------------------------------
-- CHARACTER
--------------------------------------------------

local function setCharacter(character)

	Character = character

	Humanoid =
		character:WaitForChild("Humanoid")

	Root =
		character:WaitForChild("HumanoidRootPart")

	CurrentVelocity = Vector3.zero

	FlyAttachment = nil
	LinearVelocity = nil
	AlignOrientation = nil

	CollisionBackup = {}

	-- Nunca permitimos que o Fly deixe isso ligado.
	Humanoid.PlatformStand = false
end

setCharacter(
	Player.Character
	or Player.CharacterAdded:Wait()
)

--------------------------------------------------
-- BACKUP HUMANOID
--------------------------------------------------

local function backupHumanoid()

	if not Humanoid then
		return
	end

	Original = {

		WalkSpeed =
			Humanoid.WalkSpeed,

		AutoRotate =
			Humanoid.AutoRotate,

		UseJumpPower =
			Humanoid.UseJumpPower,

		JumpPower =
			Humanoid.JumpPower,

		JumpHeight =
			Humanoid.JumpHeight,
	}
end

--------------------------------------------------
-- PREPARE HUMANOID
--------------------------------------------------

local function prepareHumanoid()

	if not Humanoid then
		return
	end

	backupHumanoid()

	------------------------------------------------
	-- IMPORTANTE
	--
	-- Não usamos:
	--
	-- PlatformStand
	-- Physics
	-- Freefall forçado
	-- SetStateEnabled
	-- Ragdoll modification
	--
	------------------------------------------------

	Humanoid.PlatformStand = false

	-- Impede a caminhada padrão de competir
	-- contra o Fly.
	Humanoid.WalkSpeed = 0

	-- A rotação será controlada por AlignOrientation.
	Humanoid.AutoRotate = false

	-- Evita o botão Jump dando impulsos durante Fly.
	if Humanoid.UseJumpPower then
		Humanoid.JumpPower = 0
	else
		Humanoid.JumpHeight = 0
	end

	Humanoid.Jump = false
end

--------------------------------------------------
-- RESTORE HUMANOID
--------------------------------------------------

local function restoreHumanoid()

	if not Humanoid then
		return
	end

	Humanoid.PlatformStand = false

	if Original.WalkSpeed ~= nil then
		Humanoid.WalkSpeed =
			Original.WalkSpeed
	end

	if Original.AutoRotate ~= nil then
		Humanoid.AutoRotate =
			Original.AutoRotate
	end

	if Original.UseJumpPower ~= nil then
		Humanoid.UseJumpPower =
			Original.UseJumpPower
	end

	if Original.JumpPower ~= nil then
		Humanoid.JumpPower =
			Original.JumpPower
	end

	if Original.JumpHeight ~= nil then
		Humanoid.JumpHeight =
			Original.JumpHeight
	end

	Original = {}
end

--------------------------------------------------
-- CREATE FLY PHYSICS
--------------------------------------------------

local function createFlyPhysics()

	if not Root then
		return
	end

	------------------------------------------------
	-- ATTACHMENT
	------------------------------------------------

	FlyAttachment =
		Root:FindFirstChild(
			"AdvancedFlyAttachmentV4"
		)

	if not FlyAttachment then

		FlyAttachment =
			Instance.new("Attachment")

		FlyAttachment.Name =
			"AdvancedFlyAttachmentV4"

		FlyAttachment.Parent =
			Root
	end

	------------------------------------------------
	-- LINEAR VELOCITY
	------------------------------------------------

	LinearVelocity =
		Root:FindFirstChild(
			"AdvancedFlyVelocityV4"
		)

	if not LinearVelocity then

		LinearVelocity =
			Instance.new("LinearVelocity")

		LinearVelocity.Name =
			"AdvancedFlyVelocityV4"

		LinearVelocity.Attachment0 =
			FlyAttachment

		LinearVelocity.RelativeTo =
			Enum.ActuatorRelativeTo.World

		LinearVelocity.VelocityConstraintMode =
			Enum.VelocityConstraintMode.Vector

		LinearVelocity.VectorVelocity =
			Vector3.zero

		LinearVelocity.MaxForce =
			math.huge

		LinearVelocity.Enabled =
			false

		LinearVelocity.Parent =
			Root
	end

	------------------------------------------------
	-- ORIENTATION
	------------------------------------------------

	AlignOrientation =
		Root:FindFirstChild(
			"AdvancedFlyOrientationV4"
		)

	if not AlignOrientation then

		AlignOrientation =
			Instance.new("AlignOrientation")

		AlignOrientation.Name =
			"AdvancedFlyOrientationV4"

		AlignOrientation.Attachment0 =
			FlyAttachment

		AlignOrientation.Mode =
			Enum.OrientationAlignmentMode.OneAttachment

		AlignOrientation.MaxTorque =
			math.huge

		AlignOrientation.Responsiveness =
			Config.RotationResponsiveness

		AlignOrientation.RigidityEnabled =
			false

		AlignOrientation.Enabled =
			false

		AlignOrientation.Parent =
			Root
	end
end

--------------------------------------------------
-- NOCLIP
--------------------------------------------------

local function applyNoClip()

	if not Character then
		return
	end

	for _, object in ipairs(
		Character:GetDescendants()
	) do

		if object:IsA("BasePart") then

			if CollisionBackup[object] == nil then
				CollisionBackup[object] =
					object.CanCollide
			end

			object.CanCollide = false
		end
	end
end

local function restoreCollision()

	for part, oldValue in pairs(
		CollisionBackup
	) do

		if part
			and part.Parent
		then

			part.CanCollide =
				oldValue
		end
	end

	CollisionBackup = {}
end

--------------------------------------------------
-- GET MOBILE MOVEMENT
--------------------------------------------------

local function getMovement()

	if not Humanoid then
		return Vector3.zero
	end

	local move =
		Humanoid.MoveDirection

	if move.Magnitude <
		Config.Deadzone
	then

		return Vector3.zero
	end

	------------------------------------------------
	-- NORMAL MODE
	------------------------------------------------

	if not Config.Camera3D then

		return move

	end

	------------------------------------------------
	-- CAMERA 3D
	--
	-- Descobre quanto do joystick representa
	-- frente/trás e esquerda/direita.
	--
	------------------------------------------------

	Camera =
		workspace.CurrentCamera

	if not Camera then
		return move
	end

	local cameraForwardFlat =
		flatVector(
			Camera.CFrame.LookVector
		)

	local cameraRightFlat =
		flatVector(
			Camera.CFrame.RightVector
		)

	if cameraForwardFlat.Magnitude == 0 then
		return move
	end

	local forwardAmount =
		move:Dot(
			cameraForwardFlat
		)

	local rightAmount =
		move:Dot(
			cameraRightFlat
		)

	------------------------------------------------
	-- Frente segue inclusive o pitch da câmera.
	------------------------------------------------

	local cameraForward =
		Camera.CFrame.LookVector

	local cameraRight =
		Camera.CFrame.RightVector

	local direction =
		cameraForward * forwardAmount
		+
		cameraRight * rightAmount

	if direction.Magnitude > 1 then
		direction =
			direction.Unit
	end

	return direction
end

--------------------------------------------------
-- GET DESIRED VELOCITY
--------------------------------------------------

local function calculateTargetVelocity()

	if Config.Hover then
		return Vector3.zero
	end

	local movement =
		getMovement()

	local speed =
		Config.Speed

	if Config.Boost then

		speed *=
			Config.BoostMultiplier
	end

	local horizontal =
		movement * speed

	------------------------------------------------
	-- VERTICAL BUTTONS
	------------------------------------------------

	local verticalInput = 0

	if UpHeld then
		verticalInput += 1
	end

	if DownHeld then
		verticalInput -= 1
	end

	local vertical =
		Vector3.new(
			0,
			verticalInput
				* Config.VerticalSpeed,
			0
		)

	return horizontal + vertical
end

--------------------------------------------------
-- FACE DIRECTION
--------------------------------------------------

local LastLookDirection =
	Vector3.new(0, 0, -1)

local function updateOrientation()

	if not AlignOrientation
		or not Root
	then
		return
	end

	if not Config.FaceDirection then

		AlignOrientation.Enabled =
			false

		return
	end

	AlignOrientation.Enabled =
		true

	local desiredDirection

	------------------------------------------------
	-- CAMERA
	------------------------------------------------

	if Camera then

		local look =
			Camera.CFrame.LookVector

		desiredDirection =
			flatVector(look)

	end

	------------------------------------------------
	-- FALLBACK
	------------------------------------------------

	if not desiredDirection
		or desiredDirection.Magnitude
		< 0.1
	then

		desiredDirection =
			LastLookDirection
	end

	if desiredDirection.Magnitude > 0.1 then

		LastLookDirection =
			desiredDirection
	end

	------------------------------------------------
	-- SEMPRE UPRIGHT
	------------------------------------------------

	AlignOrientation.CFrame =
		CFrame.lookAt(
			Vector3.zero,
			LastLookDirection,
			Vector3.yAxis
		)
end

--------------------------------------------------
-- PHYSICS LOOP
--------------------------------------------------

local function startPhysicsLoop()

	if PhysicsConnection then
		PhysicsConnection:Disconnect()
	end

	PhysicsConnection =
		RunService.PreSimulation:Connect(
			function(dt)

				if not Config.Flying then
					return
				end

				if not Character
					or not Character.Parent
					or not Humanoid
					or not Root
					or not LinearVelocity
				then
					return
				end

				if Humanoid.Health <= 0 then
					return
				end

				------------------------------------------------
				-- NÃO DEIXA PLATFORMSTAND APARECER
				------------------------------------------------

				if Humanoid.PlatformStand then
					Humanoid.PlatformStand = false
				end

				Humanoid.Jump = false

				------------------------------------------------
				-- ANTI SPIN
				------------------------------------------------

				Root.AssemblyAngularVelocity =
					Vector3.zero

				------------------------------------------------
				-- TARGET
				------------------------------------------------

				local target =
					calculateTargetVelocity()

				local moving =
					target.Magnitude
					> Config.Deadzone

				local rate

				if moving then
					rate =
						Config.Acceleration
				else
					rate =
						Config.Braking
				end

				local alpha =
					expAlpha(
						rate,
						dt
					)

				CurrentVelocity =
					CurrentVelocity:Lerp(
						target,
						alpha
					)

				------------------------------------------------
				-- PERFECT HOVER
				------------------------------------------------

				if not moving
					and CurrentVelocity.Magnitude
					< 0.15
				then

					CurrentVelocity =
						Vector3.zero
				end

				if Config.Hover then

					CurrentVelocity =
						Vector3.zero
				end

				------------------------------------------------
				-- VELOCITY
				------------------------------------------------

				LinearVelocity.VectorVelocity =
					CurrentVelocity

				updateOrientation()
			end
		)
end

--------------------------------------------------
-- NOCLIP LOOP
--------------------------------------------------

local function startNoClipLoop()

	if NoClipConnection then
		NoClipConnection:Disconnect()
	end

	NoClipConnection =
		RunService.PreSimulation:Connect(
			function()

				if Config.Flying
					and Config.NoClip
				then

					applyNoClip()
				end
			end
		)
end

--------------------------------------------------
-- ENABLE
--------------------------------------------------

local function enableFly()

	if not Character
		or not Humanoid
		or not Root
	then
		return
	end

	if Humanoid.Health <= 0 then
		return
	end

	createFlyPhysics()
	prepareHumanoid()

	Config.Flying =
		true

	Config.Hover =
		false

	UpHeld = false
	DownHeld = false

	CurrentVelocity =
		Vector3.zero

	Root.AssemblyLinearVelocity =
		Vector3.zero

	Root.AssemblyAngularVelocity =
		Vector3.zero

	LinearVelocity.VectorVelocity =
		Vector3.zero

	LinearVelocity.Enabled =
		true

	AlignOrientation.Enabled =
		Config.FaceDirection

	startPhysicsLoop()
	startNoClipLoop()
end

--------------------------------------------------
-- DISABLE
--------------------------------------------------

local function disableFly()

	Config.Flying =
		false

	Config.Hover =
		false

	UpHeld = false
	DownHeld = false

	CurrentVelocity =
		Vector3.zero

	if PhysicsConnection then

		PhysicsConnection:Disconnect()
		PhysicsConnection = nil
	end

	if NoClipConnection then

		NoClipConnection:Disconnect()
		NoClipConnection = nil
	end

	if LinearVelocity then

		LinearVelocity.VectorVelocity =
			Vector3.zero

		LinearVelocity.Enabled =
			false
	end

	if AlignOrientation then

		AlignOrientation.Enabled =
			false
	end

	if Root then

		Root.AssemblyLinearVelocity =
			Vector3.zero

		Root.AssemblyAngularVelocity =
			Vector3.zero
	end

	restoreCollision()
	restoreHumanoid()
end

--------------------------------------------------
-- HARD BRAKE
--------------------------------------------------

local function hardBrake()

	CurrentVelocity =
		Vector3.zero

	if LinearVelocity then

		LinearVelocity.VectorVelocity =
			Vector3.zero
	end

	if Root then

		Root.AssemblyLinearVelocity =
			Vector3.zero

		Root.AssemblyAngularVelocity =
			Vector3.zero
	end
end

--------------------------------------------------
-- RESPAWN
--------------------------------------------------

Player.CharacterAdded:Connect(
	function(character)

		local resume =
			Config.Flying

		if PhysicsConnection then
			PhysicsConnection:Disconnect()
			PhysicsConnection = nil
		end

		if NoClipConnection then
			NoClipConnection:Disconnect()
			NoClipConnection = nil
		end

		setCharacter(character)

		task.wait(0.5)

		if resume then
			enableFly()
		end
	end
)

--------------------------------------------------
-- GUI CLEANUP
--------------------------------------------------

local old =
	PlayerGui:FindFirstChild(
		"UltraMobileFly"
	)

if old then
	old:Destroy()
end

--------------------------------------------------
-- GUI
--------------------------------------------------

local GUI =
	Instance.new("ScreenGui")

GUI.Name =
	"UltraMobileFly"

GUI.ResetOnSpawn =
	false

GUI.IgnoreGuiInset =
	false

GUI.Parent =
	PlayerGui

--------------------------------------------------
-- MAIN
--------------------------------------------------

local Main =
	Instance.new("Frame")

Main.Size =
	UDim2.fromOffset(
		320,
		430
	)

Main.Position =
	UDim2.new(
		1,
		-335,
		0.5,
		-215
	)

Main.BackgroundColor3 =
	Color3.fromRGB(
		15,
		16,
		22
	)

Main.BorderSizePixel =
	0

Main.Parent =
	GUI

local Corner =
	Instance.new("UICorner")

Corner.CornerRadius =
	UDim.new(0, 16)

Corner.Parent =
	Main

local Stroke =
	Instance.new("UIStroke")

Stroke.Color =
	Color3.fromRGB(
		61,
		64,
		82
	)

Stroke.Thickness =
	1

Stroke.Parent =
	Main

--------------------------------------------------
-- HEADER
--------------------------------------------------

local Header =
	Instance.new("Frame")

Header.Size =
	UDim2.new(
		1,
		0,
		0,
		48
	)

Header.BackgroundTransparency =
	1

Header.Active =
	true

Header.Parent =
	Main

local Title =
	Instance.new("TextLabel")

Title.Size =
	UDim2.new(
		1,
		-60,
		1,
		0
	)

Title.Position =
	UDim2.fromOffset(
		15,
		0
	)

Title.BackgroundTransparency =
	1

Title.Text =
	"MOBILE FLY V4"

Title.Font =
	Enum.Font.GothamBold

Title.TextSize =
	17

Title.TextColor3 =
	Color3.fromRGB(
		245,
		245,
		250
	)

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.Parent =
	Header

--------------------------------------------------
-- BUTTON FUNCTION
--------------------------------------------------

local function createButton(
	text,
	x,
	y,
	w,
	h
)

	local button =
		Instance.new("TextButton")

	button.Position =
		UDim2.new(
			0,
			x,
			0,
			y
		)

	button.Size =
		UDim2.new(
			0,
			w,
			0,
			h
		)

	button.BackgroundColor3 =
		Color3.fromRGB(
			35,
			37,
			49
		)

	button.BorderSizePixel =
		0

	button.Text =
		text

	button.TextColor3 =
		Color3.fromRGB(
			245,
			245,
			250
		)

	button.TextSize =
		14

	button.Font =
		Enum.Font.GothamMedium

	button.AutoButtonColor =
		true

	button.Parent =
		Main

	local corner =
		Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(0, 10)

	corner.Parent =
		button

	return button
end

--------------------------------------------------
-- MINIMIZE
--------------------------------------------------

local Minimize =
	createButton(
		"—",
		274,
		8,
		36,
		32
	)

--------------------------------------------------
-- FLY
--------------------------------------------------

local FlyButton =
	createButton(
		"FLY: OFF",
		12,
		53,
		296,
		44
	)

local function updateFlyButton()

	if Config.Flying then

		FlyButton.Text =
			"FLY: ON"

		FlyButton.BackgroundColor3 =
			Color3.fromRGB(
				35,
				150,
				85
			)

	else

		FlyButton.Text =
			"FLY: OFF"

		FlyButton.BackgroundColor3 =
			Color3.fromRGB(
				35,
				37,
				49
			)
	end
end

FlyButton.Activated:Connect(
	function()

		if Config.Flying then
			disableFly()
		else
			enableFly()
		end

		updateFlyButton()
	end
)

--------------------------------------------------
-- NOCLIP
--------------------------------------------------

local NoClip =
	createButton(
		"NOCLIP: OFF",
		12,
		106,
		143,
		40
	)

NoClip.Activated:Connect(
	function()

		Config.NoClip =
			not Config.NoClip

		NoClip.Text =
			Config.NoClip
			and "NOCLIP: ON"
			or "NOCLIP: OFF"

		if not Config.NoClip then
			restoreCollision()
		end
	end
)

--------------------------------------------------
-- BOOST
--------------------------------------------------

local Boost =
	createButton(
		"BOOST: OFF",
		165,
		106,
		143,
		40
	)

Boost.Activated:Connect(
	function()

		Config.Boost =
			not Config.Boost

		Boost.Text =
			Config.Boost
			and "BOOST: ON"
			or "BOOST: OFF"
	end
)

--------------------------------------------------
-- CAMERA 3D
--------------------------------------------------

local Camera3D =
	createButton(
		"CAMERA 3D: OFF",
		12,
		155,
		143,
		40
	)

Camera3D.Activated:Connect(
	function()

		Config.Camera3D =
			not Config.Camera3D

		Camera3D.Text =
			Config.Camera3D
			and "CAMERA 3D: ON"
			or "CAMERA 3D: OFF"
	end
)

--------------------------------------------------
-- HOVER
--------------------------------------------------

local Hover =
	createButton(
		"HOVER: OFF",
		165,
		155,
		143,
		40
	)

Hover.Activated:Connect(
	function()

		Config.Hover =
			not Config.Hover

		if Config.Hover then
			hardBrake()
		end

		Hover.Text =
			Config.Hover
			and "HOVER: ON"
			or "HOVER: OFF"
	end
)

--------------------------------------------------
-- SPEED
--------------------------------------------------

local SpeedMinus =
	createButton(
		"−",
		12,
		204,
		48,
		40
	)

local SpeedText =
	createButton(
		"SPEED: "
			.. Config.Speed,
		68,
		204,
		184,
		40
	)

local SpeedPlus =
	createButton(
		"+",
		260,
		204,
		48,
		40
	)

local function updateSpeed()

	SpeedText.Text =
		"SPEED: "
		.. Config.Speed
end

SpeedMinus.Activated:Connect(
	function()

		Config.Speed =
			math.clamp(
				Config.Speed
					- Config.SpeedStep,
				Config.MinSpeed,
				Config.MaxSpeed
			)

		updateSpeed()
	end
)

SpeedPlus.Activated:Connect(
	function()

		Config.Speed =
			math.clamp(
				Config.Speed
					+ Config.SpeedStep,
				Config.MinSpeed,
				Config.MaxSpeed
			)

		updateSpeed()
	end
)

--------------------------------------------------
-- VERTICAL SPEED
--------------------------------------------------

local VMinus =
	createButton(
		"−",
		12,
		253,
		48,
		40
	)

local VText =
	createButton(
		"VERTICAL: "
			.. Config.VerticalSpeed,
		68,
		253,
		184,
		40
	)

local VPlus =
	createButton(
		"+",
		260,
		253,
		48,
		40
	)

local function updateVertical()

	VText.Text =
		"VERTICAL: "
		.. Config.VerticalSpeed
end

VMinus.Activated:Connect(
	function()

		Config.VerticalSpeed =
			math.clamp(
				Config.VerticalSpeed
					- Config.VerticalStep,
				Config.MinVertical,
				Config.MaxVertical
			)

		updateVertical()
	end
)

VPlus.Activated:Connect(
	function()

		Config.VerticalSpeed =
			math.clamp(
				Config.VerticalSpeed
					+ Config.VerticalStep,
				Config.MinVertical,
				Config.MaxVertical
			)

		updateVertical()
	end
)

--------------------------------------------------
-- UP/DOWN
--------------------------------------------------

local Up =
	createButton(
		"▲ SUBIR",
		12,
		302,
		143,
		54
	)

local Down =
	createButton(
		"▼ DESCER",
		165,
		302,
		143,
		54
	)

--------------------------------------------------
-- HOLD SYSTEM
--------------------------------------------------

local function bindHold(
	button,
	callback
)

	local active = {}

	button.InputBegan:Connect(
		function(input)

			if input.UserInputType
				== Enum.UserInputType.Touch
				or
				input.UserInputType
				== Enum.UserInputType.MouseButton1
			then

				active[input] = true

				callback(true)
			end
		end
	)

	button.InputEnded:Connect(
		function(input)

			if active[input] then

				active[input] = nil

				callback(false)
			end
		end
	)
end

bindHold(
	Up,
	function(value)

		UpHeld = value

		if value then
			Config.Hover = false
			Hover.Text =
				"HOVER: OFF"
		end
	end
)

bindHold(
	Down,
	function(value)

		DownHeld = value

		if value then
			Config.Hover = false
			Hover.Text =
				"HOVER: OFF"
		end
	end
)

--------------------------------------------------
-- BRAKE
--------------------------------------------------

local Brake =
	createButton(
		"PARAR IMEDIATAMENTE",
		12,
		365,
		296,
		42
	)

Brake.Activated:Connect(
	function()

		Config.Hover = true

		Hover.Text =
			"HOVER: ON"

		hardBrake()
	end
)

--------------------------------------------------
-- MINIMIZE
--------------------------------------------------

local Minimized = false

local OriginalSize =
	Main.Size

Minimize.Activated:Connect(
	function()

		Minimized =
			not Minimized

		for _, object in ipairs(
			Main:GetChildren()
		) do

			if object:IsA("GuiObject")
				and object ~= Header
				and object ~= Minimize
			then

				object.Visible =
					not Minimized
			end
		end

		if Minimized then

			Main.Size =
				UDim2.fromOffset(
					320,
					48
				)

			Minimize.Text = "+"

		else

			Main.Size =
				OriginalSize

			Minimize.Text = "—"
		end
	end
)

--------------------------------------------------
-- DRAG MOBILE
--------------------------------------------------

local Dragging = false
local DragInput
local DragStart
local StartPosition

Header.InputBegan:Connect(
	function(input)

		if input.UserInputType
			== Enum.UserInputType.Touch
			or
			input.UserInputType
			== Enum.UserInputType.MouseButton1
		then

			Dragging = true

			DragStart =
				input.Position

			StartPosition =
				Main.Position

			input.Changed:Connect(
				function()

					if input.UserInputState
						== Enum.UserInputState.End
					then

						Dragging =
							false
					end
				end
			)
		end
	end
)

Header.InputChanged:Connect(
	function(input)

		if input.UserInputType
			== Enum.UserInputType.Touch
			or
			input.UserInputType
			== Enum.UserInputType.MouseMovement
		then

			DragInput =
				input
		end
	end
)

UIS.InputChanged:Connect(
	function(input)

		if Dragging
			and input == DragInput
		then

			local delta =
				input.Position
				- DragStart

			Main.Position =
				UDim2.new(
					StartPosition.X.Scale,
					StartPosition.X.Offset
						+ delta.X,

					StartPosition.Y.Scale,
					StartPosition.Y.Offset
						+ delta.Y
				)
		end
	end
)

--------------------------------------------------
-- SAFETY: TOUCH RELEASE
--------------------------------------------------

UIS.InputEnded:Connect(
	function(input)

		if input.UserInputType
			== Enum.UserInputType.Touch
		then

			-- Evita ficar subindo eternamente
			-- se o Roblox perder o evento do botão.

			if not UIS.TouchEnabled then
				UpHeld = false
				DownHeld = false
			end
		end
	end
)
