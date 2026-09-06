--[[
    ADVANCED MOBILE FLY V2
    Para o SEU jogo no Roblox Studio

    Coloque em:
    StarterPlayer > StarterPlayerScripts

    MOBILE:
    - Analógico normal = direção
    - Segure SUBIR / DESCER = altura
]]

--------------------------------------------------
-- SERVICES
--------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--------------------------------------------------
-- CONFIG
--------------------------------------------------

local Config = {
	Flying = false,
	NoClip = false,
	FaceCamera = true,
	Boost = false,

	Speed = 60,
	VerticalSpeed = 50,

	MinSpeed = 20,
	MaxSpeed = 200,
	SpeedStep = 10,

	BoostMultiplier = 1.8,

	-- suavidade
	Acceleration = 10,
	Deceleration = 15,

	-- velocidade quase zero vira zero de verdade
	StopThreshold = 0.3,
}

--------------------------------------------------
-- CHARACTER
--------------------------------------------------

local Character
local Humanoid
local Root

local Attachment
local Velocity
local Orientation

local CurrentVelocity = Vector3.zero

local UpHeld = false
local DownHeld = false

local CollisionBackup = {}
local HumanoidBackup = {}

--------------------------------------------------
-- CHARACTER SETUP
--------------------------------------------------

local function bindCharacter(character)

	Character = character
	Humanoid = character:WaitForChild("Humanoid")
	Root = character:WaitForChild("HumanoidRootPart")

	Attachment = nil
	Velocity = nil
	Orientation = nil

	CurrentVelocity = Vector3.zero

	CollisionBackup = {}
	HumanoidBackup = {}
end

bindCharacter(
	Player.Character
	or Player.CharacterAdded:Wait()
)

--------------------------------------------------
-- PHYSICS
--------------------------------------------------

local function createPhysics()

	if not Root then
		return
	end

	----------------------------------------------
	-- ATTACHMENT
	----------------------------------------------

	Attachment =
		Root:FindFirstChild("MobileFlyAttachment")

	if not Attachment then

		Attachment = Instance.new("Attachment")
		Attachment.Name = "MobileFlyAttachment"
		Attachment.Parent = Root

	end

	----------------------------------------------
	-- LINEAR VELOCITY
	----------------------------------------------

	Velocity =
		Root:FindFirstChild("MobileFlyVelocity")

	if not Velocity then

		Velocity = Instance.new("LinearVelocity")

		Velocity.Name = "MobileFlyVelocity"

		Velocity.Attachment0 = Attachment

		Velocity.RelativeTo =
			Enum.ActuatorRelativeTo.World

		Velocity.VelocityConstraintMode =
			Enum.VelocityConstraintMode.Vector

		Velocity.VectorVelocity =
			Vector3.zero

		Velocity.MaxForce =
			math.huge

		Velocity.Enabled =
			false

		Velocity.Parent =
			Root
	end

	----------------------------------------------
	-- ALIGN ORIENTATION
	----------------------------------------------

	Orientation =
		Root:FindFirstChild(
			"MobileFlyOrientation"
		)

	if not Orientation then

		Orientation =
			Instance.new("AlignOrientation")

		Orientation.Name =
			"MobileFlyOrientation"

		Orientation.Attachment0 =
			Attachment

		Orientation.Mode =
			Enum.OrientationAlignmentMode.OneAttachment

		Orientation.MaxTorque =
			math.huge

		Orientation.Responsiveness =
			35

		Orientation.RigidityEnabled =
			false

		Orientation.Enabled =
			false

		Orientation.Parent =
			Root
	end
end

--------------------------------------------------
-- HUMANOID STABILITY
--------------------------------------------------

local function enableHumanoidStability()

	if not Humanoid then
		return
	end

	HumanoidBackup = {
		AutoRotate =
			Humanoid.AutoRotate,

		FallingDown =
			Humanoid:GetStateEnabled(
				Enum.HumanoidStateType.FallingDown
			),

		Ragdoll =
			Humanoid:GetStateEnabled(
				Enum.HumanoidStateType.Ragdoll
			),
	}

	Humanoid.Sit = false
	Humanoid.PlatformStand = false

	Humanoid.AutoRotate = false

	Humanoid:SetStateEnabled(
		Enum.HumanoidStateType.FallingDown,
		false
	)

	Humanoid:SetStateEnabled(
		Enum.HumanoidStateType.Ragdoll,
		false
	)

	-- NÃO usamos Physics.
	-- Freefall mantém o Humanoid funcionando normalmente.
	Humanoid:ChangeState(
		Enum.HumanoidStateType.Freefall
	)
end

local function restoreHumanoid()

	if not Humanoid then
		return
	end

	Humanoid.PlatformStand = false

	if HumanoidBackup.AutoRotate ~= nil then
		Humanoid.AutoRotate =
			HumanoidBackup.AutoRotate
	else
		Humanoid.AutoRotate = true
	end

	if HumanoidBackup.FallingDown ~= nil then

		Humanoid:SetStateEnabled(
			Enum.HumanoidStateType.FallingDown,
			HumanoidBackup.FallingDown
		)

	end

	if HumanoidBackup.Ragdoll ~= nil then

		Humanoid:SetStateEnabled(
			Enum.HumanoidStateType.Ragdoll,
			HumanoidBackup.Ragdoll
		)

	end

	HumanoidBackup = {}
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

	for part, original in pairs(
		CollisionBackup
	) do

		if part and part.Parent then
			part.CanCollide = original
		end
	end

	CollisionBackup = {}
end

--------------------------------------------------
-- ENABLE FLY
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

	Config.Flying = true

	createPhysics()

	CurrentVelocity =
		Vector3.zero

	Root.AssemblyLinearVelocity =
		Vector3.zero

	Root.AssemblyAngularVelocity =
		Vector3.zero

	enableHumanoidStability()

	Velocity.VectorVelocity =
		Vector3.zero

	Velocity.Enabled =
		true

	Orientation.Enabled =
		true
end

--------------------------------------------------
-- DISABLE FLY
--------------------------------------------------

local function disableFly()

	Config.Flying = false

	UpHeld = false
	DownHeld = false

	CurrentVelocity =
		Vector3.zero

	if Velocity then

		Velocity.VectorVelocity =
			Vector3.zero

		Velocity.Enabled =
			false
	end

	if Orientation then
		Orientation.Enabled =
			false
	end

	if Root then

		Root.AssemblyLinearVelocity =
			Vector3.zero

		Root.AssemblyAngularVelocity =
			Vector3.zero
	end

	restoreHumanoid()
	restoreCollision()

	if Humanoid
		and Humanoid.Health > 0
	then

		Humanoid:ChangeState(
			Enum.HumanoidStateType.GettingUp
		)
	end
end

--------------------------------------------------
-- SMOOTHING
--------------------------------------------------

local function smoothAlpha(rate, dt)

	return 1 - math.exp(
		-rate * dt
	)

end

--------------------------------------------------
-- MAIN FLY LOOP
--------------------------------------------------

RunService.Heartbeat:Connect(function(dt)

	if not Config.Flying then
		return
	end

	if not Character
		or not Character.Parent
		or not Humanoid
		or not Root
		or not Velocity
	then
		return
	end

	if Humanoid.Health <= 0 then
		return
	end

	------------------------------------------------
	-- REMOVE SPIN
	------------------------------------------------

	Root.AssemblyAngularVelocity =
		Vector3.zero

	------------------------------------------------
	-- MOBILE JOYSTICK
	------------------------------------------------

	local MoveDirection =
		Humanoid.MoveDirection

	------------------------------------------------
	-- SPEED
	------------------------------------------------

	local CurrentSpeed =
		Config.Speed

	if Config.Boost then

		CurrentSpeed =
			CurrentSpeed
			* Config.BoostMultiplier

	end

	------------------------------------------------
	-- HORIZONTAL
	------------------------------------------------

	local HorizontalVelocity =
		MoveDirection
		* CurrentSpeed

	------------------------------------------------
	-- VERTICAL
	------------------------------------------------

	local VerticalInput = 0

	if UpHeld then
		VerticalInput += 1
	end

	if DownHeld then
		VerticalInput -= 1
	end

	local VerticalVelocity =
		Vector3.new(
			0,
			VerticalInput
				* Config.VerticalSpeed,
			0
		)

	------------------------------------------------
	-- TARGET
	------------------------------------------------

	local TargetVelocity =
		HorizontalVelocity
		+ VerticalVelocity

	------------------------------------------------
	-- ACCELERATION / BRAKING
	------------------------------------------------

	local Rate

	if TargetVelocity.Magnitude
		> CurrentVelocity.Magnitude
	then

		Rate =
			Config.Acceleration

	else

		Rate =
			Config.Deceleration

	end

	local Alpha =
		smoothAlpha(
			Rate,
			dt
		)

	CurrentVelocity =
		CurrentVelocity:Lerp(
			TargetVelocity,
			Alpha
		)

	------------------------------------------------
	-- TRUE STOP / HOVER
	------------------------------------------------

	if TargetVelocity.Magnitude == 0
		and CurrentVelocity.Magnitude
		< Config.StopThreshold
	then

		CurrentVelocity =
			Vector3.zero

	end

	Velocity.VectorVelocity =
		CurrentVelocity

	------------------------------------------------
	-- KEEP UPRIGHT
	------------------------------------------------

	local DesiredDirection

	if Config.FaceCamera then

		local Camera =
			workspace.CurrentCamera

		if Camera then

			local CameraLook =
				Camera.CFrame.LookVector

			local FlatLook =
				Vector3.new(
					CameraLook.X,
					0,
					CameraLook.Z
				)

			if FlatLook.Magnitude > 0.01 then

				DesiredDirection =
					FlatLook.Unit

			end
		end

	elseif MoveDirection.Magnitude > 0.05 then

		local FlatMove =
			Vector3.new(
				MoveDirection.X,
				0,
				MoveDirection.Z
			)

		if FlatMove.Magnitude > 0.01 then
			DesiredDirection =
				FlatMove.Unit
		end
	end

	if not DesiredDirection then

		local Look =
			Root.CFrame.LookVector

		local Flat =
			Vector3.new(
				Look.X,
				0,
				Look.Z
			)

		if Flat.Magnitude > 0.01 then
			DesiredDirection = Flat.Unit
		else
			DesiredDirection =
				Vector3.new(0, 0, -1)
		end
	end

	Orientation.CFrame =
		CFrame.lookAt(
			Vector3.zero,
			DesiredDirection,
			Vector3.yAxis
		)
end)

--------------------------------------------------
-- NOCLIP LOOP
--------------------------------------------------

RunService.Stepped:Connect(function()

	if Config.Flying
		and Config.NoClip
	then

		applyNoClip()

	end
end)

--------------------------------------------------
-- RESPAWN
--------------------------------------------------

Player.CharacterAdded:Connect(
	function(character)

		local ShouldFly =
			Config.Flying

		bindCharacter(character)

		task.wait(0.5)

		if ShouldFly then
			enableFly()
		end
	end
)

--------------------------------------------------
-- GUI
--------------------------------------------------

local OldGUI =
	PlayerGui:FindFirstChild(
		"AdvancedMobileFlyV2"
	)

if OldGUI then
	OldGUI:Destroy()
end

local GUI =
	Instance.new("ScreenGui")

GUI.Name =
	"AdvancedMobileFlyV2"

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
		310,
		350
	)

Main.Position =
	UDim2.new(
		1,
		-325,
		0.5,
		-175
	)

Main.BackgroundColor3 =
	Color3.fromRGB(
		16,
		17,
		23
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
		65,
		68,
		85
	)

Stroke.Thickness = 1

Stroke.Parent =
	Main

--------------------------------------------------
-- TITLE
--------------------------------------------------

local Top =
	Instance.new("Frame")

Top.Size =
	UDim2.new(
		1,
		0,
		0,
		48
	)

Top.BackgroundTransparency =
	1

Top.Active =
	true

Top.Parent =
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
	"ADVANCED MOBILE FLY"

Title.TextColor3 =
	Color3.fromRGB(
		245,
		245,
		250
	)

Title.Font =
	Enum.Font.GothamBold

Title.TextSize =
	16

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.Parent =
	Top

--------------------------------------------------
-- BUTTON HELPER
--------------------------------------------------

local function makeButton(
	text,
	position,
	size
)

	local Button =
		Instance.new("TextButton")

	Button.Text =
		text

	Button.Position =
		position

	Button.Size =
		size

	Button.BackgroundColor3 =
		Color3.fromRGB(
			36,
			38,
			50
		)

	Button.TextColor3 =
		Color3.fromRGB(
			245,
			245,
			250
		)

	Button.Font =
		Enum.Font.GothamMedium

	Button.TextSize =
		14

	Button.BorderSizePixel =
		0

	Button.AutoButtonColor =
		true

	Button.Parent =
		Main

	local C =
		Instance.new("UICorner")

	C.CornerRadius =
		UDim.new(0, 10)

	C.Parent =
		Button

	return Button
end

--------------------------------------------------
-- MINIMIZE
--------------------------------------------------

local Minimize =
	makeButton(
		"—",
		UDim2.new(
			1,
			-46,
			0,
			8
		),
		UDim2.fromOffset(
			36,
			32
		)
	)

--------------------------------------------------
-- FLY
--------------------------------------------------

local FlyButton =
	makeButton(
		"FLY: OFF",
		UDim2.fromOffset(
			12,
			52
		),
		UDim2.new(
			1,
			-24,
			0,
			44
		)
	)

local function updateFlyButton()

	if Config.Flying then

		FlyButton.Text =
			"FLY: ON"

		FlyButton.BackgroundColor3 =
			Color3.fromRGB(
				34,
				145,
				82
			)

	else

		FlyButton.Text =
			"FLY: OFF"

		FlyButton.BackgroundColor3 =
			Color3.fromRGB(
				36,
				38,
				50
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

local NoClipButton =
	makeButton(
		"NOCLIP: OFF",
		UDim2.fromOffset(
			12,
			105
		),
		UDim2.new(
			0.48,
			-12,
			0,
			40
		)
	)

NoClipButton.Activated:Connect(
	function()

		Config.NoClip =
			not Config.NoClip

		NoClipButton.Text =
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

local BoostButton =
	makeButton(
		"BOOST: OFF",
		UDim2.new(
			0.52,
			0,
			0,
			105
		),
		UDim2.new(
			0.48,
			-12,
			0,
			40
		)
	)

BoostButton.Activated:Connect(
	function()

		Config.Boost =
			not Config.Boost

		BoostButton.Text =
			Config.Boost
			and "BOOST: ON"
			or "BOOST: OFF"

	end
)

--------------------------------------------------
-- CAMERA
--------------------------------------------------

local CameraButton =
	makeButton(
		"OLHAR: CÂMERA",
		UDim2.fromOffset(
			12,
			153
		),
		UDim2.new(
			1,
			-24,
			0,
			38
		)
	)

CameraButton.Activated:Connect(
	function()

		Config.FaceCamera =
			not Config.FaceCamera

		CameraButton.Text =
			Config.FaceCamera
			and "OLHAR: CÂMERA"
			or "OLHAR: MOVIMENTO"

	end
)

--------------------------------------------------
-- SPEED
--------------------------------------------------

local Minus =
	makeButton(
		"−",
		UDim2.fromOffset(
			12,
			200
		),
		UDim2.fromOffset(
			50,
			40
		)
	)

local SpeedLabel =
	makeButton(
		"VELOCIDADE: "
			.. Config.Speed,

		UDim2.fromOffset(
			68,
			200
		),

		UDim2.new(
			1,
			-136,
			0,
			40
		)
	)

local Plus =
	makeButton(
		"+",
		UDim2.new(
			1,
			-62,
			0,
			200
		),
		UDim2.fromOffset(
			50,
			40
		)
	)

local function updateSpeed()

	SpeedLabel.Text =
		"VELOCIDADE: "
		.. math.floor(
			Config.Speed
		)

end

Minus.Activated:Connect(
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

Plus.Activated:Connect(
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
-- VERTICAL BUTTONS
--------------------------------------------------

local Up =
	makeButton(
		"▲ SUBIR",
		UDim2.fromOffset(
			12,
			249
		),
		UDim2.new(
			0.5,
			-18,
			0,
			50
		)
	)

local Down =
	makeButton(
		"▼ DESCER",
		UDim2.new(
			0.5,
			6,
			0,
			249
		),
		UDim2.new(
			0.5,
			-18,
			0,
			50
		)
	)

--------------------------------------------------
-- MOBILE HOLD SYSTEM
--------------------------------------------------

local function bindHold(
	button,
	setter
)

	local ActiveInput = nil

	button.InputBegan:Connect(
		function(input)

			if
				input.UserInputType
					== Enum.UserInputType.Touch
				or
				input.UserInputType
					== Enum.UserInputType.MouseButton1
			then

				ActiveInput = input

				setter(true)

				input.Changed:Connect(
					function()

						if
							input.UserInputState
							== Enum.UserInputState.End
						then

							if ActiveInput
								== input
							then

								ActiveInput =
									nil

								setter(false)
							end
						end
					end
				)
			end
		end
	)

	button.InputEnded:Connect(
		function(input)

			if input == ActiveInput then

				ActiveInput =
					nil

				setter(false)
			end
		end
	)
end

bindHold(
	Up,
	function(value)
		UpHeld = value
	end
)

bindHold(
	Down,
	function(value)
		DownHeld = value
	end
)

--------------------------------------------------
-- BRAKE
--------------------------------------------------

local Brake =
	makeButton(
		"PARAR NO AR",
		UDim2.fromOffset(
			12,
			307
		),
		UDim2.new(
			1,
			-24,
			0,
			32
		)
	)

Brake.Activated:Connect(
	function()

		CurrentVelocity =
			Vector3.zero

		if Velocity then

			Velocity.VectorVelocity =
				Vector3.zero

		end

		if Root then

			Root.AssemblyLinearVelocity =
				Vector3.zero

			Root.AssemblyAngularVelocity =
				Vector3.zero

		end
	end
)

--------------------------------------------------
-- MINIMIZE
--------------------------------------------------

local NormalSize =
	Main.Size

local Minimized =
	false

for _, item in ipairs(
	Main:GetChildren()
) do

	if item:IsA("GuiObject")
		and item ~= Top
		and item ~= Minimize
	then

		-- handled later
	end
end

Minimize.Activated:Connect(
	function()

		Minimized =
			not Minimized

		for _, item in ipairs(
			Main:GetChildren()
		) do

			if item:IsA("GuiObject")
				and item ~= Top
				and item ~= Minimize
			then

				item.Visible =
					not Minimized
			end
		end

		if Minimized then

			Main.Size =
				UDim2.fromOffset(
					310,
					48
				)

			Minimize.Text = "+"

		else

			Main.Size =
				NormalSize

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

Top.InputBegan:Connect(
	function(input)

		if
			input.UserInputType
				== Enum.UserInputType.Touch
			or
			input.UserInputType
				== Enum.UserInputType.MouseButton1
		then

			Dragging = true
			DragStart = input.Position
			StartPosition = Main.Position

			input.Changed:Connect(
				function()

					if
						input.UserInputState
						== Enum.UserInputState.End
					then

						Dragging = false
					end
				end
			)
		end
	end
)

Top.InputChanged:Connect(
	function(input)

		if
			input.UserInputType
				== Enum.UserInputType.Touch
			or
			input.UserInputType
				== Enum.UserInputType.MouseMovement
		then

			DragInput = input
		end
	end
)

UIS.InputChanged:Connect(
	function(input)

		if Dragging
			and input == DragInput
		then

			local Delta =
				input.Position
				- DragStart

			Main.Position =
				UDim2.new(
					StartPosition.X.Scale,
					StartPosition.X.Offset
						+ Delta.X,

					StartPosition.Y.Scale,
					StartPosition.Y.Offset
						+ Delta.Y
				)
		end
	end
)
