-- S4zx ClientPanel v1.1 | Atualizado com Modos de Aimbot e Correção de Câmera/Corpo
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local GUI_NAME = "S4zxClientPanelV1"
local previous = PlayerGui:FindFirstChild(GUI_NAME)
if previous then
    local shutdown = previous:FindFirstChild("Shutdown")
    if shutdown and shutdown:IsA("BindableEvent") then shutdown:Fire() else previous:Destroy() end
end

local UI, Connections, ESPManager, Targeting = {}, {}, {}, {}
local WeaponScanner, WeaponModifier, CharacterManager = {}, {}, {}
local alive = true
local defaults = {
    Aimbot=false, AimMode="Sempre", Silent=false, AimKill=false, IgnoreBots=true, IgnoreTeam=true,
    Visibility=true, ShowFOV=false, FOV=140, Smooth=12, AimPart="Head",
    ESP=false, Highlight=true, Box=false, Name=true, Distance=true, Health=true,
    Tracer=false, Skeleton=false, AutoReload=false, FireSpeed=false, FireLevel=2,
    ProjectileSpeed=false, ProjectileLevel=2, NoRecoil=false, NoSpread=false,
    Speed=false, WalkSpeed=24, Jump=false, JumpPower=65, JumpHeight=10,
    Fly=false, FlySpeed=35, FlyKill=false, Dark=true, Logo=true, Size=1,
}
local State = table.clone(defaults)
local groups, tweens = {}, setmetatable({}, {__mode="k"})
function Connections.add(group, signal, callback)
    local connection = signal:Connect(callback)
    groups[group] = groups[group] or {}
    table.insert(groups[group], connection)
    return connection
end
function Connections.clear(group)
    for _, connection in ipairs(groups[group] or {}) do connection:Disconnect() end
    groups[group] = nil
end
function Connections.destroy()
    for group in pairs(groups) do Connections.clear(group) end
end
local function create(class, properties, parent)
    local object = Instance.new(class)
    for key,value in pairs(properties or {}) do object[key] = value end
    object.Parent = parent
    return object
end
local function corner(object, radius) create("UICorner", {CornerRadius=UDim.new(0,radius)}, object) end
local function tween(object, properties, duration)
    if tweens[object] then tweens[object]:Cancel() end
    local t = TweenService:Create(object, TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad), properties)
    tweens[object] = t
    t:Play()
    return t
end
local neon = Color3.fromRGB(113,255,65)
local muted = Color3.fromRGB(157,177,159)
local white = Color3.fromRGB(243,250,243)
local function text(parent, value, size, position, dimensions)
    return create("TextLabel", {Text=value, Font=Enum.Font.GothamMedium, TextSize=size,
        TextColor3=white, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
        TextWrapped=true, Position=position, Size=dimensions}, parent)
end
UI.gui = create("ScreenGui", {Name=GUI_NAME, ResetOnSpawn=false, IgnoreGuiInset=false,
    DisplayOrder=50, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, PlayerGui)
UI.overlay = create("ScreenGui", {Name="Overlay", ResetOnSpawn=false, IgnoreGuiInset=true,
    DisplayOrder=49, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, PlayerGui)
UI.safe = create("Frame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1}, UI.gui)
UI.panel = create("CanvasGroup", {AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
    Size=UDim2.fromOffset(560,590), BackgroundColor3=Color3.fromRGB(4,8,5), BorderSizePixel=0}, UI.safe)
corner(UI.panel,30)
create("UIStroke", {Color=Color3.fromRGB(36,73,32), Thickness=1.5}, UI.panel)
UI.scale = create("UIScale", {Scale=1}, UI.panel)
UI.logo = create("ImageLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(20,19),
    Size=UDim2.fromOffset(48,48), Image="rbxthumb://type=Asset&id=98880379063768&w=420&h=420"}, UI.panel)
corner(UI.logo,24)
UI.drag = create("TextButton", {Text="", AutoButtonColor=false, BackgroundTransparency=1,
    Position=UDim2.fromOffset(82,12), Size=UDim2.fromOffset(337,67)}, UI.panel)
UI.heading = text(UI.drag,"✧  FUNÇÕES",23,UDim2.fromOffset(14,7),UDim2.fromOffset(270,48))
UI.heading.TextColor3=neon
local function button(parent,label,position,size)
    local b=create("TextButton", {Text=label, Font=Enum.Font.GothamBold, TextSize=20,
        TextColor3=neon, BackgroundColor3=Color3.fromRGB(13,39,15), BorderSizePixel=0,
        AutoButtonColor=false, Position=position, Size=size},parent)
    corner(b,24)
    Connections.add("UI",b.MouseEnter,function() tween(b,{BackgroundColor3=Color3.fromRGB(28,65,23)}) end)
    Connections.add("UI",b.MouseLeave,function() tween(b,{BackgroundColor3=Color3.fromRGB(13,39,15)}) end)
    Connections.add("UI",b.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch then tween(b,{BackgroundColor3=Color3.fromRGB(37,83,29)}) end
    end)
    Connections.add("UI",b.InputEnded,function(input)
        if input.UserInputType==Enum.UserInputType.Touch then tween(b,{BackgroundColor3=Color3.fromRGB(13,39,15)}) end
    end)
    return b
end
local moon=button(UI.panel,"☾",UDim2.fromOffset(429,23),UDim2.fromOffset(48,48))
local close=button(UI.panel,"×",UDim2.fromOffset(489,23),UDim2.fromOffset(48,48))
create("Frame",{BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(34,53,32),
    Position=UDim2.fromOffset(83,94),Size=UDim2.new(0,1,1,-119)},UI.panel)
UI.pages, UI.rows, UI.nav = {}, {}, {}
local pageNames={"AIM / FUNÇÕES","VISUAL / ESP","ARMAS","MOVIMENTO","CONFIGURAÇÕES"}
local icons={"⊕","◉","⚙","↑","≡"}
local pagePositions={}
for i,name in ipairs(pageNames) do
    local nav=button(UI.panel,icons[i],UDim2.fromOffset(17,101+(i-1)*76),UDim2.fromOffset(53,53))
    UI.nav[i]=nav
    local page=create("ScrollingFrame",{Position=UDim2.fromOffset(99,95),Size=UDim2.fromOffset(441,445),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=neon,
        AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,
        ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,Visible=i==1},UI.panel)
    create("UIPadding",{PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,9),PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,18)},page)
    create("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},page)
    UI.pages[i]=page
    Connections.add("UI",nav.Activated,function()
        for j,p in ipairs(UI.pages) do p.Visible=j==i end
        UI.heading.Text=name
        page.Position=UDim2.fromOffset(106,95)
        tween(page,{Position=UDim2.fromOffset(99,95)})
        for j,n in ipairs(UI.nav) do n.TextColor3=j==i and neon or muted end
    end)
    nav.TextColor3=i==1 and neon or muted
end
UI.footer=text(UI.panel,"CLIENTE • pronto",12,UDim2.fromOffset(105,550),UDim2.fromOffset(427,27))
UI.footer.TextColor3=muted
function UI.message(value) if alive then UI.footer.Text=value end end
local order=0
local onChange
local function card(page,title,description,height)
    order=order+1
    local frame=create("Frame",{Size=UDim2.new(1,0,0,height or 86),BorderSizePixel=0,
        BackgroundColor3=Color3.fromRGB(9,35,13),LayoutOrder=order},UI.pages[page])
    corner(frame,22)
    create("UIStroke",{Color=Color3.fromRGB(38,69,31),Transparency=0.25},frame)
    local label=text(frame,title,18,UDim2.fromOffset(18,12),UDim2.new(1,-105,0,27))
    local desc=text(frame,description,12,UDim2.fromOffset(18,42),UDim2.new(1,-34,0,(height or 86)-48))
    desc.TextColor3=muted
    return frame,desc,label
end
local function toggle(page,key,title,description)
    local frame,desc=card(page,title,description)
    local hit=create("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},frame)
    local track=create("Frame",{Size=UDim2.fromOffset(58,32),Position=UDim2.new(1,-77,0,12),
        BackgroundColor3=Color3.fromRGB(54,65,54),BorderSizePixel=0},frame)
    corner(track,16)
    local dot=create("Frame",{Size=UDim2.fromOffset(24,24),Position=UDim2.fromOffset(4,4),
        BackgroundColor3=Color3.fromRGB(151,159,148),BorderSizePixel=0},track)
    corner(dot,12)
    local row={desc=desc,base=description,track=track,dot=dot}
    UI.rows[key]=row
    Connections.add("UI",hit.Activated,function() onChange(key,not State[key]) end)
end
function UI.refresh()
    for key,row in pairs(UI.rows) do
        if row.track then
            tween(row.track,{BackgroundColor3=State[key] and Color3.fromRGB(40,108,25) or Color3.fromRGB(54,65,54)})
            tween(row.dot,{Position=UDim2.fromOffset(State[key] and 30 or 4,4),BackgroundColor3=State[key] and neon or muted})
        elseif row.value then row.value.Text=row.format(State[key]) end
    end
end
local function selector(page,key,title,values,format,description)
    local frame=card(page,title,description or "Toque em − / + para ajustar.",102)
    local minus=button(frame,"−",UDim2.new(1,-173,0,9),UDim2.fromOffset(44,44))
    local plus=button(frame,"+",UDim2.new(1,-58,0,9),UDim2.fromOffset(44,44))
    local value=text(frame,"",14,UDim2.new(1,-129,0,12),UDim2.fromOffset(71,38))
    value.TextXAlignment=Enum.TextXAlignment.Center
    frame:FindFirstChildOfClass("TextLabel").Size=UDim2.new(1,-195,0,32)
    UI.rows[key]={value=value,format=format or tostring}
    local function step(direction)
        local index=1
        for i,v in ipairs(values) do if v==State[key] then index=i break end end
        index=math.clamp(index+direction,1,#values)
        onChange(key,values[index])
    end
    Connections.add("UI",minus.Activated,function() step(-1) end)
    Connections.add("UI",plus.Activated,function() step(1) end)
end
local function action(page,title,description,callback)
    local frame=card(page,title,description,90)
    local hit=create("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},frame)
    Connections.add("UI",hit.Activated,callback)
end
function UI.status(key,message)
    local row=UI.rows[key]
    if row and row.desc then row.desc.Text=message or row.base end
end
UI.floating=button(UI.safe,"",UDim2.fromOffset(18,120),UDim2.fromOffset(58,58))
UI.floating.Visible=false
local floatingLogo=create("ImageLabel",{Image=UI.logo.Image,BackgroundTransparency=1,
    Size=UDim2.new(1,-8,1,-8),Position=UDim2.fromOffset(4,4)},UI.floating)
corner(floatingLogo,24)
local floatingText=text(UI.floating,"S4",18,UDim2.fromScale(0,0),UDim2.fromScale(1,1))
floatingText.TextXAlignment=Enum.TextXAlignment.Center; floatingText.Visible=false
local open=true
local function setOpen(value)
    open=value
    UI.floating.Visible=not value
    if value then
        UI.panel.Visible=true
        tween(UI.panel,{GroupTransparency=0},0.2)
    else
        local t=tween(UI.panel,{GroupTransparency=1},0.18)
        Connections.clear("CloseTween")
        Connections.add("CloseTween",t.Completed,function(state)
            if not open and state==Enum.PlaybackState.Completed then UI.panel.Visible=false end
            Connections.clear("CloseTween")
        end)
    end
end
Connections.add("UI",close.Activated,function() setOpen(false) end)
Connections.add("UI",UI.floating.Activated,function() setOpen(true) end)
local function fit(center)
    local area=UI.safe.AbsoluteSize
    if area.X<1 or area.Y<1 then return end
    UI.scale.Scale=math.min(State.Size,(area.X-20)/560,(area.Y-20)/590)
    local half=Vector2.new(280,295)*UI.scale.Scale
    local pos=center or Vector2.new(area.X*UI.panel.Position.X.Scale+UI.panel.Position.X.Offset,
        area.Y*UI.panel.Position.Y.Scale+UI.panel.Position.Y.Offset)
    UI.panel.Position=UDim2.fromOffset(math.clamp(pos.X,half.X+5,area.X-half.X-5),math.clamp(pos.Y,half.Y+5,area.Y-half.Y-5))
end
Connections.add("UI",UI.safe:GetPropertyChangedSignal("AbsoluteSize"),function() fit() end)
local dragInput,dragStart,panelStart
Connections.add("UI",UI.drag.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragInput=input; dragStart=Vector2.new(input.Position.X,input.Position.Y)
        panelStart=Vector2.new(UI.panel.Position.X.Offset,UI.panel.Position.Y.Offset)
    end
end)
Connections.add("UI",UIS.InputChanged,function(input)
    if dragInput and (input==dragInput or (dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then
        fit(panelStart+Vector2.new(input.Position.X,input.Position.Y)-dragStart)
    end
end)
Connections.add("UI",UIS.InputEnded,function(input) if input==dragInput then dragInput=nil end end)

-- CONTROLE DE INPUTS PARA AIMBOT (Mirar ou Atirar)
local isAiming = false
local isShooting = false
Connections.add("UI", UIS.InputBegan, function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = true
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        isShooting = true
    end
end)
Connections.add("UI", UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        isShooting = false
    end
end)

CharacterManager.original={}
function CharacterManager.restore()
    local h=CharacterManager.humanoid
    if h and h.Parent then
        for property,value in pairs(CharacterManager.original) do h[property]=value end
    end
    CharacterManager.original={}
end
local function setCharacterProperty(property,value,enabled)
    local h=CharacterManager.humanoid
    if not h or h.Health<=0 then return end
    if enabled then
        if CharacterManager.original[property]==nil then CharacterManager.original[property]=h[property] end
        h[property]=value
    elseif CharacterManager.original[property]~=nil then
        h[property]=CharacterManager.original[property]; CharacterManager.original[property]=nil
    end
end
function CharacterManager.apply()
    local h=CharacterManager.humanoid
    if not h then return end
    setCharacterProperty("WalkSpeed",State.WalkSpeed,State.Speed)
    setCharacterProperty("JumpPower",State.JumpPower,State.Jump and h.UseJumpPower)
    setCharacterProperty("JumpHeight",State.JumpHeight,State.Jump and not h.UseJumpPower)
end
function CharacterManager.stopFly()
    if CharacterManager.velocity then CharacterManager.velocity:Destroy(); CharacterManager.velocity=nil end
    if CharacterManager.attachment then CharacterManager.attachment:Destroy(); CharacterManager.attachment=nil end
    if CharacterManager.flyRoot and CharacterManager.flyRoot.Parent then
        CharacterManager.flyRoot.AssemblyLinearVelocity=Vector3.zero
    end
    CharacterManager.flyRoot=nil
    if UI.flight then UI.flight.Visible=false end
end
function CharacterManager.startFly()
    CharacterManager.stopFly()
    local h=CharacterManager.humanoid
    local root=CharacterManager.character and CharacterManager.character:FindFirstChild("HumanoidRootPart")
    if not h or h.Health<=0 or not root then return end
    CharacterManager.flyRoot=root
    CharacterManager.attachment=create("Attachment",{Name="S4zxFlightAttachment"},root)
    CharacterManager.velocity=create("LinearVelocity",{Attachment0=CharacterManager.attachment,
        RelativeTo=Enum.ActuatorRelativeTo.World,VelocityConstraintMode=Enum.VelocityConstraintMode.Vector,
        ForceLimitsEnabled=false,VectorVelocity=Vector3.zero},root)
    UI.flight.Visible=true
end
UI.flight=create("Frame",{Size=UDim2.fromOffset(128,62),Position=UDim2.new(1,-146,0.45,0),BackgroundTransparency=1,Visible=false},UI.safe)
local up=button(UI.flight,"↑",UDim2.fromOffset(0,0),UDim2.fromOffset(58,58))
local down=button(UI.flight,"↓",UDim2.fromOffset(68,0),UDim2.fromOffset(58,58))
local flightInputs={}
local function hold(buttonObject,direction)
    Connections.add("UI",buttonObject.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then flightInputs[input]=direction end
    end)
end
hold(up,1); hold(down,-1)
Connections.add("UI",UIS.InputBegan,function(input,processed)
    if not processed and (input.KeyCode==Enum.KeyCode.E or input.KeyCode==Enum.KeyCode.Q) then
        flightInputs[input]=input.KeyCode==Enum.KeyCode.E and 1 or -1
    end
end)
Connections.add("UI",UIS.InputEnded,function(input) flightInputs[input]=nil end)
Connections.add("UI",UIS.WindowFocusReleased,function() table.clear(flightInputs); dragInput=nil end)

Targeting.records={}
local function rebuildRig(record)
    local model=record.model
    record.head=model:FindFirstChild("Head")
    record.root=model:FindFirstChild("HumanoidRootPart")
    record.parts={}; record.joints={}
    for _,object in ipairs(model:GetDescendants()) do
        if object:IsA("BasePart") and not object:FindFirstAncestorOfClass("Tool") and not object:FindFirstAncestorOfClass("Accessory") then
            table.insert(record.parts,object)
        elseif object:IsA("Motor6D") then table.insert(record.joints,object) end
    end
    record.rigDirty=false
end
local function addHumanoid(h)
    local model=h.Parent
    if not model or not model:IsA("Model") or Targeting.records[h] then return end
    local record={model=model,humanoid=h,rigDirty=true}
    Targeting.records[h]=record
    Connections.add(record,model.DescendantAdded,function() record.rigDirty=true end)
    Connections.add(record,model.DescendantRemoving,function() record.rigDirty=true end)
end
local function removeHumanoid(h)
    local record=Targeting.records[h]
    if record then
        ESPManager.remove(record)
        Connections.clear(record)
        Targeting.records[h]=nil
    end
end
function Targeting.valid(record)
    local model,h=record.model,record.humanoid
    if h.Health<=0 or not model:IsDescendantOf(Workspace) or model==LocalPlayer.Character then return false end
    local player=Players:GetPlayerFromCharacter(model)
    if State.IgnoreBots and not player then return false end
    if State.IgnoreTeam and player and not player.Neutral and not LocalPlayer.Neutral and player.Team==LocalPlayer.Team then return false end
    if State.IgnoreTeam and not player then
        local npcTeam=model:GetAttribute("Team")
        if npcTeam and LocalPlayer.Team and npcTeam==LocalPlayer.Team.Name then return false end
    end
    if record.rigDirty then rebuildRig(record) end
    local part=State.AimPart=="Head" and record.head or record.root
    return part and part:IsA("BasePart") and part or false
end
local rayParams=RaycastParams.new()
rayParams.FilterType=Enum.RaycastFilterType.Exclude
function Targeting.pick(camera)
    local best,bestPart,bestDistance=nil,nil,State.FOV
    local center=camera.ViewportSize/2
    rayParams.FilterDescendantsInstances=LocalPlayer.Character and {LocalPlayer.Character} or {}
    for _,record in pairs(Targeting.records) do
        local part=Targeting.valid(record)
        if part then
            local projected,onScreen=camera:WorldToViewportPoint(part.Position)
            local distance=(Vector2.new(projected.X,projected.Y)-center).Magnitude
            if onScreen and projected.Z>0 and distance<bestDistance then
                local visible=true
                if State.Visibility then
                    local hit=Workspace:Raycast(camera.CFrame.Position,part.Position-camera.CFrame.Position,rayParams)
                    visible=not hit or hit.Instance:IsDescendantOf(record.model)
                end
                if visible then best=record; bestPart=part; bestDistance=distance end
            end
        end
    end
    return best,bestPart
end
UI.fov=create("Frame",{AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,
    Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(State.FOV*2,State.FOV*2),Visible=false},UI.overlay)
create("UICorner",{CornerRadius=UDim.new(1,0)},UI.fov)
create("UIStroke",{Color=neon,Thickness=1,Transparency=0.25},UI.fov)

ESPManager.items={}
ESPManager.folder=create("Folder",{Name="S4zxLocalHighlights"},Workspace)
function ESPManager.remove(record)
    local item=ESPManager.items[record]
    if item then
        item.container:Destroy(); item.highlight:Destroy()
        ESPManager.items[record]=nil
    end
end
function ESPManager.clear()
    for record in pairs(ESPManager.items) do ESPManager.remove(record) end
end
local function line(parent)
    return create("Frame",{AnchorPoint=Vector2.new(0.5,0.5),BorderSizePixel=0,BackgroundColor3=neon,Visible=false},parent)
end
local function drawLine(object,a,b)
    local delta=b-a
    object.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
    object.Size=UDim2.fromOffset(delta.Magnitude,1.5)
    object.Rotation=math.deg(math.atan2(delta.Y,delta.X)); object.Visible=true
end
function ESPManager.make(record)
    local container=create("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},UI.overlay)
    local box=create("Frame",{BackgroundTransparency=1,Visible=false},container)
    create("UIStroke",{Color=neon,Thickness=1.5},box)
    local label=text(container,"",13,UDim2.new(),UDim2.fromOffset(260,48))
    label.TextXAlignment=Enum.TextXAlignment.Center
    label.TextStrokeTransparency=0.2
    local health=create("Frame",{BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(32,32,32)},container)
    local fill=create("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.fromScale(0,1),
        Size=UDim2.fromScale(1,1),BorderSizePixel=0,BackgroundColor3=neon},health)
    local highlight=create("Highlight",{Adornee=record.model,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
        FillColor=neon,OutlineColor=neon,FillTransparency=0.78,OutlineTransparency=0.1,Enabled=false},ESPManager.folder)
    local item={container=container,box=box,label=label,health=health,fill=fill,highlight=highlight,
        tracer=line(container),bones={}}
    ESPManager.items[record]=item
    return item
end
local corners={}
for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
    table.insert(corners,Vector3.new(x,y,z))
end end end
local function bounds(record,camera)
    local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
    local count=0
    for _,part in ipairs(record.parts) do
        if part.Parent then
            for _,v in ipairs(corners) do
                local p=camera:WorldToViewportPoint(part.CFrame:PointToWorldSpace(part.Size*v*0.5))
                if p.Z<=0.1 then return nil end
                minX=math.min(minX,p.X); minY=math.min(minY,p.Y)
                maxX=math.max(maxX,p.X); maxY=math.max(maxY,p.Y); count=count+1
            end
        end
    end
    if count==0 or maxX<0 or minX>camera.ViewportSize.X or maxY<0 or minY>camera.ViewportSize.Y then return nil end
    return minX,minY,maxX,maxY
end
function ESPManager.update(camera)
    if not State.ESP then return end
    for _,record in pairs(Targeting.records) do
        local part=Targeting.valid(record)
        if not part then ESPManager.remove(record) else
            local item=ESPManager.items[record] or ESPManager.make(record)
            item.highlight.Enabled=State.Highlight
            local x,y,right,bottom=bounds(record,camera)
            item.container.Visible=x~=nil
            if x then
                local width,height=right-x,bottom-y
                item.box.Visible=State.Box; item.box.Position=UDim2.fromOffset(x,y); item.box.Size=UDim2.fromOffset(width,height)
                local labels={}
                local player=Players:GetPlayerFromCharacter(record.model)
                if State.Name then table.insert(labels,player and player.DisplayName or record.model.Name) end
                if State.Distance then
                    local origin=CharacterManager.character and CharacterManager.character:FindFirstChild("HumanoidRootPart")
                    table.insert(labels,string.format("%.0f studs",(part.Position-(origin and origin.Position or camera.CFrame.Position)).Magnitude))
                end
                if State.Health then table.insert(labels,string.format("HP %.0f",record.humanoid.Health)) end
                item.label.Text=table.concat(labels," • "); item.label.Visible=#labels>0
                item.label.Position=UDim2.fromOffset((x+right)/2-130,y-49)
                item.health.Visible=State.Health; item.health.Position=UDim2.fromOffset(x-7,y); item.health.Size=UDim2.fromOffset(4,height)
                item.fill.Size=UDim2.fromScale(1,math.clamp(record.humanoid.Health/math.max(record.humanoid.MaxHealth,1),0,1))
                item.tracer.Visible=false
                if State.Tracer then drawLine(item.tracer,Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y-4),Vector2.new((x+right)/2,bottom)) end
                for _,bone in pairs(item.bones) do bone.Visible=false end
                if State.Skeleton then
                    for i,joint in ipairs(record.joints) do
                        local a,b=joint.Part0,joint.Part1
                        if a and b and a.Parent and b.Parent then
                            local pa,va=camera:WorldToViewportPoint(a.Position)
                            local pb,vb=camera:WorldToViewportPoint(b.Position)
                            if va and vb and pa.Z>0 and pb.Z>0 then
                                item.bones[i]=item.bones[i] or line(item.container)
                                drawLine(item.bones[i],Vector2.new(pa.X,pa.Y),Vector2.new(pb.X,pb.Y))
                            end
                        end
                    end
                end
            end
        end
    end
end

local aliases={
    Ammo={"ammo","currentammo","bullets","magazine","mag","clip","ammocount"},
    MaxAmmo={"maxammo","maxbullets","magazinesize","magsize","clipsize","maxclip","capacity"},
    FireSpeed={"firedelay","shootdelay","cooldown","firerate","rpm","attackspeed","timebetweenshots"},
    Reload={"reloadtime","reloaddelay","reloadspeed","reloading","isreloading"},
    ProjectileSpeed={"bulletspeed","projectilespeed","muzzlevelocity","velocity"},
    NoRecoil={"recoil","recoilamount","recoilpower","recoilscale","recoilenabled"},
    NoSpread={"spread","bulletspread","accuracyspread","spreadangle","spreadenabled"},
}
local aliasLookup={}
local function normalize(name) return string.lower(tostring(name)):gsub("[^%w]", "") end
for category,names in pairs(aliases) do
    for rank,name in ipairs(names) do aliasLookup[name]={category=category,rank=rank} end
end
local function finite(value) return type(value)=="number" and value==value and math.abs(value)<math.huge end
WeaponScanner.tools={}
WeaponScanner.current=nil
WeaponScanner.dirty=true
WeaponScanner.serial=0
WeaponModifier.originals={}
WeaponModifier.errors={}
local weaponKeys={"AutoReload","FireSpeed","ProjectileSpeed","NoRecoil","NoSpread","Silent","AimKill","FlyKill"}
local incompatible="Não compatível com este sistema de armas"
local scannerLabel
local function candidate(record,object,key,value,kind)
    local match=aliasLookup[normalize(key)]
    if not match then return end
    table.insert(record.candidates,{object=object,key=key,value=value,kind=kind,category=match.category,rank=match.rank})
end
function WeaponScanner.scan(record)
    record.candidates={}; record.modules={}; record.remotes=0
    local objects=record.tool:GetDescendants()
    table.insert(objects,1,record.tool)
    for _,object in ipairs(objects) do
        if object:IsA("NumberValue") or object:IsA("IntValue") or object:IsA("BoolValue") or object:IsA("StringValue") then
            candidate(record,object,object.Name,object.Value,"Value")
        end
        for key,value in pairs(object:GetAttributes()) do candidate(record,object,key,value,"Attribute") end
        if object:IsA("ModuleScript") then table.insert(record.modules,object) end
        if object:IsA("RemoteEvent") or object:IsA("RemoteFunction") then record.remotes=record.remotes+1 end
    end
    table.sort(record.candidates,function(a,b)
        if a.rank~=b.rank then return a.rank<b.rank end
        return a.object:GetFullName()..a.key<b.object:GetFullName()..b.key
    end)
    record.dirty=false
end
function WeaponScanner.track(tool)
    if WeaponScanner.tools[tool] or not tool:IsA("Tool") then return end
    local record={tool=tool,dirty=true,candidates={},modules={},api=nil,attempted=false}
    WeaponScanner.tools[tool]=record
    Connections.add(record,tool.DescendantAdded,function() record.dirty=true end)
    Connections.add(record,tool.DescendantRemoving,function() record.dirty=true end)
    Connections.add(record,tool.AncestryChanged,function() WeaponScanner.dirty=true end)
    Connections.add(record,tool.AttributeChanged,function() record.dirty=true end)
    WeaponScanner.dirty=true
end
local function owned(tool)
    return tool.Parent==CharacterManager.character or (tool.Parent and tool.Parent:IsA("Backpack") and tool.Parent.Parent==LocalPlayer)
end
local function callAPI(api,method,...)
    local fn=api and api[method]
    if type(fn)~="function" then return false,"Método ausente" end
    local thread=coroutine.create(fn)
    local ok,a,b=coroutine.resume(thread,api,...)
    if coroutine.status(thread)~="dead" then
        task.cancel(thread)
        return false,"API assíncrona não compatível com este painel"
    end
    if not ok then return false,"A API da arma retornou erro" end
    return true,a,b
end
local function loadAPI(record)
    if record.attempted then return end
    record.attempted=true
    local modules={}
    for _,m in ipairs(record.modules) do
        if m:GetAttribute("S4zxClientAPI")==1 then table.insert(modules,m) end
    end
    if #modules~=1 then
        record.reason=#modules>1 and "Mais de uma API: integração ambígua" or "Nenhuma API client-side compatível identificada"
        return
    end
    local module=modules[1]
    record.loading=true; record.loadStart=os.clock(); record.apiModule=module
    local generation=WeaponScanner.serial
    local thread
    thread=task.defer(function()
        local ok,api=pcall(require,module)
        record.loading=false; record.thread=nil
        if not alive or not owned(record.tool) or generation~=WeaponScanner.serial then return end
        if ok and type(api)=="table" and api.Version==1 and api.Tool==record.tool and api.Authority=="Client" and type(api.Capabilities)=="table" then
            record.api=api; record.reason="API client-side identificada"
        else
            record.reason="API ausente, inválida ou autoridade não client-side"
        end
        record.apiDirty=true
    end)
    record.thread=thread
end
local function findConfig(api,category)
    if type(api.Config)~="table" then return nil,"Configuração consumida não exposta" end
    local matches={}
    for key,value in pairs(api.Config) do
        local match=aliasLookup[normalize(key)]
        if match and match.category==category then table.insert(matches,{key=key,value=value,rank=match.rank}) end
    end
    table.sort(matches,function(a,b) return a.rank<b.rank end)
    if #matches==0 then return nil,"Configuração compatível não encontrada" end
    local choice=matches[1]
    local name=normalize(choice.key)
    if category=="FireSpeed" then
        if name=="rpm" then choice.mode="rate"
        elseif name=="firedelay" or name=="shootdelay" or name=="cooldown" or name=="timebetweenshots" then choice.mode="delay"
        else
            local units=api.Units and api.Units[choice.key]
            if units=="seconds" then choice.mode="delay"
            elseif units=="perSecond" or units=="perMinute" then choice.mode="rate"
            else return nil,"FireRate sem unidade: compatibilidade não confirmada" end
        end
    end
    if category=="NoRecoil" or category=="NoSpread" then
        if not finite(choice.value) and type(choice.value)~="boolean" then return nil,"Tipo de configuração não compatível" end
    elseif not finite(choice.value) or choice.value<=0 then return nil,"Valor numérico inválido" end
    return choice
end
function WeaponScanner.capability(key)
    local record=WeaponScanner.current
    if not record then return false,"Equipe uma Tool para verificar" end
    local api=record.api
    if record.loading then return false,"Verificando API client-side…" end
    if not api then return false,incompatible end
    if api.Capabilities[key]~=true then return false,incompatible end
    local methods={AutoReload="Reload",Silent="SetSilentTarget",AimKill="FireAt",FlyKill="FlyKill"}
    if methods[key] then
        if type(api[methods[key]])~="function" then return false,incompatible end
        if key=="AutoReload" and type(api.GetAmmo)~="function" then return false,"Munição client-side não acessível" end
        return true
    end
    if type(api.SetConfig)~="function" then return false,incompatible end
    local field,reason=findConfig(api,key)
    return field~=nil,reason,field
end
function WeaponModifier.restoreKey(key)
    local saved=WeaponModifier.originals[key]
    if not saved then return true end
    local ok,result=callAPI(saved.api,"SetConfig",saved.key,saved.value)
    if ok and result==true then WeaponModifier.originals[key]=nil; return true end
    WeaponModifier.errors[key]="A arma recusou restaurar o valor original"
    UI.message("Falha ao restaurar "..key.."; confira a API da arma")
    return false
end
function WeaponModifier.restoreAll()
    local success=true
    for key in pairs(WeaponModifier.originals) do if not WeaponModifier.restoreKey(key) then success=false end end
    return success
end
function WeaponModifier.apply()
    for _,key in ipairs({"FireSpeed","ProjectileSpeed","NoRecoil","NoSpread"}) do
        local supported,reason,field=WeaponScanner.capability(key)
        if State[key] and supported then
            local api=WeaponScanner.current.api
            local saved=WeaponModifier.originals[key]
            if saved and saved.api~=api then
                if WeaponModifier.restoreKey(key) then saved=nil else supported=false end
            end
            if supported then
                if not saved then
                    saved={api=api,key=field.key,value=field.value}; WeaponModifier.originals[key]=saved
                end
                local value=saved.value
                if key=="FireSpeed" then value=field.mode=="delay" and saved.value/State.FireLevel or saved.value*State.FireLevel
                elseif key=="ProjectileSpeed" then value=saved.value*State.ProjectileLevel
                else value=0 end
                if (key=="NoRecoil" or key=="NoSpread") and type(saved.value)=="boolean" then value=false end
                local ok,result=callAPI(api,"SetConfig",saved.key,value)
                if not ok or result~=true then
                    State[key]=false
                    WeaponModifier.errors[key]="API recusou a alteração"
                    WeaponModifier.restoreKey(key)
                else WeaponModifier.errors[key]=nil end
            end
        else
            WeaponModifier.restoreKey(key)
            if State[key] and not supported then UI.status(key,reason) end
        end
    end
end
local function clearSilent(record)
    if record and record.api and type(record.api.SetSilentTarget)=="function" then
        local ok,result=callAPI(record.api,"SetSilentTarget",nil)
        if not ok or result~=true then UI.message("API não confirmou a limpeza do Silent") end
    end
end
function WeaponScanner.refreshUI()
    local record=WeaponScanner.current
    for _,key in ipairs(weaponKeys) do
        local supported,reason=WeaponScanner.capability(key)
        UI.status(key,WeaponModifier.errors[key] or (supported and (State[key] and "Ativo • integração client-side" or "API client-side compatível") or reason))
    end
    if scannerLabel then
        if not record then scannerLabel.Text="Nenhuma Tool equipada. Tools da mochila são indexadas automaticamente."
        else
            local counts={}
            for _,entry in ipairs(record.candidates) do counts[entry.category]=(counts[entry.category] or 0)+1 end
            local found={}
            for _,category in ipairs({"Ammo","MaxAmmo","FireSpeed","Reload","ProjectileSpeed","NoRecoil","NoSpread"}) do
                if counts[category] then table.insert(found,category..": "..counts[category]) end
            end
            scannerLabel.Text=record.tool.Name.."\n"..(#found>0 and table.concat(found," • ") or "Nenhum valor com nome reconhecido")..
                "\n"..(record.reason or "Analisando…").."\nCandidatos não confirmam autoridade. Remotes: "..record.remotes
        end
    end
    UI.refresh()
end
function WeaponScanner.update()
    local nextRecord=nil
    for tool,record in pairs(WeaponScanner.tools) do
        if not owned(tool) then
            if record==WeaponScanner.current then
                clearSilent(record); WeaponModifier.restoreAll(); WeaponScanner.current=nil
            end
            if record.thread then task.cancel(record.thread); record.thread=nil end
            Connections.clear(record); WeaponScanner.tools[tool]=nil
        else
            if record.loading and os.clock()-record.loadStart>5 then
                if record.thread then task.cancel(record.thread); record.thread=nil end
                record.loading=false; record.reason="API excedeu 5 segundos de carregamento"; record.apiDirty=true
            end
            if record.apiModule and not record.apiModule:IsDescendantOf(tool) then
                if record==WeaponScanner.current then clearSilent(record); WeaponModifier.restoreAll() end
                if record.thread then task.cancel(record.thread); record.thread=nil end
                record.api=nil; record.apiModule=nil; record.loading=false; record.attempted=false
                record.dirty=true
            end
            if record.dirty then
                WeaponScanner.scan(record); record.apiDirty=true
                if not record.api and not record.loading then record.attempted=false end
                if record==WeaponScanner.current then loadAPI(record) end
            end
            if tool.Parent==CharacterManager.character and (not nextRecord or tool.Name<nextRecord.tool.Name) then nextRecord=record end
        end
    end
    if nextRecord~=WeaponScanner.current then
        clearSilent(WeaponScanner.current)
        WeaponModifier.restoreAll()
        WeaponScanner.current=nextRecord
        WeaponModifier.errors={}
        if nextRecord then loadAPI(nextRecord) end
        WeaponModifier.apply(); WeaponScanner.refreshUI()
    end
    if nextRecord and nextRecord.apiDirty then
        nextRecord.apiDirty=false
        WeaponModifier.apply(); WeaponScanner.refreshUI()
    end
    WeaponScanner.dirty=false
end
local function trackContainer(container,group)
    Connections.clear(group)
    for _,child in ipairs(container:GetChildren()) do if child:IsA("Tool") then WeaponScanner.track(child) end end
    Connections.add(group,container.ChildAdded,function(child) if child:IsA("Tool") then WeaponScanner.track(child) end; WeaponScanner.dirty=true end)
    Connections.add(group,container.ChildRemoved,function() WeaponScanner.dirty=true end)
end
function CharacterManager.bind(character)
    Connections.clear("Character")
    CharacterManager.stopFly(); CharacterManager.restore()
    CharacterManager.character=character; CharacterManager.humanoid=nil
    WeaponScanner.dirty=true
    if not character then return end
    trackContainer(character,"CharacterTools")
    local function attach(h)
        if CharacterManager.humanoid==h then return end
        Connections.clear("Humanoid")
        CharacterManager.restore(); CharacterManager.humanoid=h
        CharacterManager.apply()
        Connections.add("Humanoid",h:GetPropertyChangedSignal("UseJumpPower"),function() CharacterManager.apply() end)
        Connections.add("Humanoid",h.Died,function() CharacterManager.stopFly(); CharacterManager.restore() end)
        if State.Fly then CharacterManager.startFly() end
    end
    local h=character:FindFirstChildOfClass("Humanoid")
    if h then attach(h) end
    Connections.add("Character",character.ChildAdded,function(child)
        if child:IsA("Humanoid") then attach(child) end
        if child.Name=="HumanoidRootPart" and State.Fly then CharacterManager.startFly() end
    end)
end
local lastReload,lastFire,lastFlyKill=0,0,0
function WeaponModifier.tick(target)
    local record=WeaponScanner.current
    if not record or not record.api then return end
    local api=record.api
    local function invoke(key,method,...)
        if not State[key] or not WeaponScanner.capability(key) then return end
        local ok,result=callAPI(api,method,...)
        if not ok then
            State[key]=false; WeaponModifier.errors[key]="Erro na integração; função desligada"
            if key=="Silent" then clearSilent(record) end
            WeaponScanner.refreshUI()
        elseif result~=true and result~=false then
            State[key]=false; WeaponModifier.errors[key]="API não confirmou a operação"
            if key=="Silent" then clearSilent(record) end
            WeaponScanner.refreshUI()
        end
    end
    if State.Silent then invoke("Silent","SetSilentTarget",target) end
    local now=os.clock()
    if target and now-lastFire>=0.1 then lastFire=now; invoke("AimKill","FireAt",target) end
    if target and now-lastFlyKill>=0.1 then lastFlyKill=now; invoke("FlyKill","FlyKill",target) end
    if State.AutoReload and WeaponScanner.capability("AutoReload") and now-lastReload>=0.75 then
        lastReload=now
        local ok,ammo,maxAmmo=callAPI(api,"GetAmmo")
        if ok and finite(ammo) and finite(maxAmmo) and maxAmmo>0 then
            if ammo<=0 then invoke("AutoReload","Reload") end
        else
            State.AutoReload=false; WeaponModifier.errors.AutoReload="Ammo/MaxAmmo inválidos na API"
            WeaponScanner.refreshUI()
        end
    end
end

local shutdown
local function stopESPs()
    for _,key in ipairs({"ESP","Highlight","Box","Name","Distance","Health","Tracer","Skeleton"}) do State[key]=false end
    ESPManager.clear(); UI.refresh()
end
local function restoreValues()
    for _,key in ipairs(weaponKeys) do State[key]=false end
    State.Speed=false; State.Jump=false; State.Fly=false
    clearSilent(WeaponScanner.current)
    local ok=WeaponModifier.restoreAll()
    CharacterManager.stopFly(); CharacterManager.restore()
    WeaponScanner.refreshUI()
    UI.message(ok and "Valores originais restaurados" or "Restauração incompleta: a API da arma recusou")
end
local function appearance()
    UI.panel.BackgroundColor3=State.Dark and Color3.fromRGB(4,8,5) or Color3.fromRGB(31,46,33)
    UI.logo.Visible=State.Logo; floatingLogo.Visible=State.Logo; floatingText.Visible=not State.Logo
    UI.fov.Visible=State.ShowFOV; UI.fov.Size=UDim2.fromOffset(State.FOV*2,State.FOV*2)
    fit()
end
onChange=function(key,value)
    if not alive then return end
    if table.find(weaponKeys,key) and value then
        local supported,reason=WeaponScanner.capability(key)
        if not supported then UI.status(key,reason); UI.message(reason); return end
    end
    State[key]=value
    if key=="ESP" and not value then ESPManager.clear() end
    if key=="Silent" and not value then clearSilent(WeaponScanner.current) end
    if key=="Fly" then if value then CharacterManager.startFly() else CharacterManager.stopFly() end end
    if key=="Speed" or key=="WalkSpeed" or key=="Jump" or key=="JumpPower" or key=="JumpHeight" then CharacterManager.apply() end
    if table.find(weaponKeys,key) or key=="FireLevel" or key=="ProjectileLevel" then
        WeaponModifier.apply(); WeaponScanner.refreshUI()
    end
    appearance(); UI.refresh()
end
Connections.add("UI",moon.Activated,function() onChange("Dark",not State.Dark) end)

-- MENU DE CONFIGURAÇÃO DO AIMBOT (Com o novo seletor de modo)
toggle(1,"Aimbot","Aimbot","Mira por câmera enquanto ligado; alvos dentro do FOV.")
selector(1,"AimMode","Modo do Aimbot",{"Sempre","Ao Mirar","Ao Atirar"},tostring,"Quando o aimbot deve puxar a mira.")

toggle(1,"Silent","Silent","Requer integração real com a direção de disparo da arma.")
toggle(1,"AimKill","AimKill","Seleciona alvos e chama disparo local compatível; sem prometer dano.")
toggle(1,"IgnoreBots","Ignorar Bots","Ligado: apenas jogadores. Desligado: inclui NPCs com Humanoid.")
toggle(1,"IgnoreTeam","Ignorar Time","Exclui aliados; NPCs podem declarar atributo Team.")
toggle(1,"Visibility","Visibilidade","Raycast entre câmera e alvo; ignora alvos obstruídos.")
toggle(1,"ShowFOV","Mostrar FOV","Círculo em pixels ao redor do centro da tela.")
selector(1,"FOV","Raio do FOV",{50,80,100,140,180,220,280,350,450},function(v) return v.." px" end)
selector(1,"Smooth","Suavização",{0,4,8,12,18,25,40},tostring,"0 = instantâneo. Valores maiores tornam a transição mais suave.")
selector(1,"AimPart","Parte alvo",{"Head","HumanoidRootPart"},function(v) return v=="Head" and "Cabeça" or "Centro" end)

toggle(2,"ESP","ESP Master","Ativa o gerenciador; desligar destrói todos os objetos ESP.")
for _,spec in ipairs({{"Highlight","ESP Highlight","AlwaysOnTop: destaque através de objetos."},
    {"Box","ESP Box","Caixa projetada a partir das partes do personagem."},
    {"Name","ESP Name","Nome de exibição do jogador ou nome do NPC."},
    {"Distance","ESP Distance","Distância em studs a partir do seu personagem."},
    {"Health","ESP Health","Barra e valor atual de vida."},
    {"Tracer","ESP Tracer","Linha da base da tela até o personagem."},
    {"Skeleton","ESP Skeleton","Linhas entre partes conectadas por Motor6D; R6/R15."}}) do toggle(2,spec[1],spec[2],spec[3]) end

local scannerCard
scannerCard,scannerLabel=card(3,"Scanner automático","Aguardando Tool…",174)
scannerLabel.Size=UDim2.new(1,-34,0,122)
scannerLabel.TextYAlignment=Enum.TextYAlignment.Top
scannerCard:FindFirstChildOfClass("TextLabel").Size=UDim2.new(1,-36,0,27)
action(3,"Reexaminar arma","Atualiza candidatos, atributos e tenta identificar uma API existente.",function()
    local record=WeaponScanner.current
    if record then
        if record.loading then UI.message("A API ainda está carregando") return end
        clearSilent(record)
        if not WeaponModifier.restoreAll() then return end
        record.api=nil; record.attempted=false; record.reason=nil
        WeaponScanner.scan(record); loadAPI(record); record.apiDirty=true
        WeaponScanner.refreshUI()
    else UI.message("Equipe uma Tool primeiro") end
end)
toggle(3,"AutoReload","Auto Reload","Verifica munição real exposta e chama recarga local compatível.")
toggle(3,"FireSpeed","Fire Speed","Altera frequência ou intervalo com unidade conhecida.")
selector(3,"FireLevel","Nível de disparo",{1,1.5,2,3,5,10},function(v) return v==1 and "NORMAL" or v.."X" end)
toggle(3,"ProjectileSpeed","Bullet / Projectile Speed","Só altera configuração efetivamente exposta pela API.")
selector(3,"ProjectileLevel","Velocidade",{1,1.5,2,3,5,10},function(v) return v.."X" end)
toggle(3,"NoRecoil","No Recoil","Reduz recoil na configuração client-side compatível.")
toggle(3,"NoSpread","No Spread","Reduz spread na configuração client-side compatível.")
toggle(4,"Speed","WalkSpeed","Modifica o Humanoid local. O servidor pode corrigir o valor.")
selector(4,"WalkSpeed","Velocidade",{8,16,24,32,48,64,80,100},tostring)
toggle(4,"Jump","Modificar salto","Respeita UseJumpPower; restaura a propriedade original.")
selector(4,"JumpPower","JumpPower",{25,50,65,80,100,125,150},tostring)
selector(4,"JumpHeight","JumpHeight",{5,7.2,10,15,20,30,40},tostring)
toggle(4,"Fly","Voo local","Joystick/WASD move. ↑/↓ ou E/Q muda altura; sem dano.")
selector(4,"FlySpeed","Velocidade de voo",{15,25,35,50,70,100},tostring)
toggle(4,"FlyKill","FlyKill","Requer lógica local explícita de voo/ataque da arma.")
action(5,"Resetar tudo","Restaura valores e volta às configurações iniciais.",function()
    restoreValues(); ESPManager.clear()
    for key,value in pairs(defaults) do State[key]=value end
    appearance(); UI.refresh(); WeaponScanner.refreshUI()
end)
action(5,"Desligar todos os ESPs","Desativa todas as camadas e destrói os objetos ESP.",stopESPs)
action(5,"Restaurar valores originais","Desliga modificadores de armas, movimento e integrações.",restoreValues)
toggle(5,"Dark","Tema escuro","Alterna entre preto e verde escuro.")
toggle(5,"Logo","Mostrar logo","Exibe a logo no cabeçalho e botão flutuante.")
selector(5,"Size","Tamanho da interface",{0.7,0.85,1,1.1,1.2},function(v) return math.floor(v*100).."%" end,"Limitado automaticamente à área disponível da tela.")
action(5,"Destruir interface","Restaura valores e limpa GUI, ESP, voo e todas as conexões.",function() shutdown() end)

local binding="S4zxPanel_"..HttpService:GenerateGUID(false)
shutdown=function()
    if not alive then return end
    clearSilent(WeaponScanner.current)
    WeaponModifier.restoreAll()
    CharacterManager.stopFly(); CharacterManager.restore()
    alive=false; WeaponScanner.serial=WeaponScanner.serial+1
    RunService:UnbindFromRenderStep(binding)
    Connections.destroy(); ESPManager.clear()
    for _,record in pairs(WeaponScanner.tools) do
        if record.thread then task.cancel(record.thread); record.thread=nil end
    end
    for _,t in pairs(tweens) do t:Cancel() end
    ESPManager.folder:Destroy(); UI.overlay:Destroy(); UI.gui:Destroy()
    table.clear(Targeting.records); table.clear(WeaponScanner.tools); table.clear(flightInputs)
end
local shutdownEvent=create("BindableEvent",{Name="Shutdown"},UI.gui)
Connections.add("Lifecycle",shutdownEvent.Event,shutdown)
Connections.add("Lifecycle",UI.gui.Destroying,shutdown)
Connections.add("Lifecycle",script.Destroying,shutdown)
Connections.add("Lifecycle",Players.PlayerRemoving,function(player)
    for h,record in pairs(Targeting.records) do if record.model==player.Character then removeHumanoid(h) end end
end)
Connections.add("Lifecycle",Workspace.DescendantAdded,function(object) if object:IsA("Humanoid") then addHumanoid(object) end end)
Connections.add("Lifecycle",Workspace.DescendantRemoving,function(object) if object:IsA("Humanoid") then removeHumanoid(object) end end)
for _,object in ipairs(Workspace:GetDescendants()) do if object:IsA("Humanoid") then addHumanoid(object) end end
Connections.add("Lifecycle",LocalPlayer.CharacterAdded,CharacterManager.bind)
Connections.add("Lifecycle",LocalPlayer.CharacterRemoving,function()
    Connections.clear("CharacterTools"); Connections.clear("Humanoid")
    CharacterManager.bind(nil)
end)
Connections.add("Lifecycle",LocalPlayer.ChildAdded,function(child)
    if child:IsA("Backpack") then trackContainer(child,"Backpack") end
end)
local backpack=LocalPlayer:FindFirstChildOfClass("Backpack")
if backpack then trackContainer(backpack,"Backpack") end
CharacterManager.bind(LocalPlayer.Character)
local targetRecord,targetPart=nil,nil
local accumulated,espElapsed,scanElapsed=0,0,0

-- RENDER STEP (Com correções de alinhamento da câmera e corpo do jogador)
RunService:BindToRenderStep(binding,Enum.RenderPriority.Camera.Value+1,function(dt)
    if not alive then return end
    local camera=Workspace.CurrentCamera
    if not camera then return end
    
    -- Verifica se deve ativar o Aimbot baseado na regra selecionada
    local shouldAim = false
    if State.Aimbot then
        if State.AimMode == "Sempre" then
            shouldAim = (targetRecord ~= nil)
        elseif State.AimMode == "Ao Mirar" then
            shouldAim = isAiming and (targetRecord ~= nil)
        elseif State.AimMode == "Ao Atirar" then
            shouldAim = isShooting and (targetRecord ~= nil)
        end
    end

    if shouldAim and targetRecord and targetPart and targetPart.Parent and Targeting.valid(targetRecord) then
        local delta=targetPart.Position-camera.CFrame.Position
        if delta.Magnitude>0.01 then
            local alpha=State.Smooth==0 and 1 or 1-math.exp(-dt*60/State.Smooth)
            
            -- Move a câmera suavemente para o alvo
            camera.CFrame=camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position,targetPart.Position),alpha)
            
            -- Gira o corpo do boneco junto para não ficar travado ou com bug visual
            local localChar = CharacterManager.character
            if localChar and localChar:FindFirstChild("HumanoidRootPart") then
                local rootPart = localChar.HumanoidRootPart
                local targetPosBody = Vector3.new(targetPart.Position.X, rootPart.Position.Y, targetPart.Position.Z)
                local targetRootCFrame = CFrame.lookAt(rootPart.Position, targetPosBody)
                rootPart.CFrame = rootPart.CFrame:Lerp(targetRootCFrame, alpha)
            end
        end
    end
    
    espElapsed=espElapsed+dt
    if State.ESP and espElapsed>=1/30 then espElapsed=0; ESPManager.update(camera) end
end)

Connections.add("Loop",RunService.Heartbeat,function(dt)
    if not alive then return end
    accumulated=accumulated+dt; scanElapsed=scanElapsed+dt
    if scanElapsed>=0.25 then scanElapsed=0; WeaponScanner.update() end
    local h=CharacterManager.humanoid
    if State.Fly and CharacterManager.velocity and h and h.Health>0 then
        local vertical=0
        for _,direction in pairs(flightInputs) do vertical=vertical+direction end
        local movement=h.MoveDirection+Vector3.new(0,math.clamp(vertical,-1,1),0)
        if movement.Magnitude>1 then movement=movement.Unit end
        CharacterManager.velocity.VectorVelocity=movement*State.FlySpeed
    end
    if accumulated>=1/30 then
        accumulated=0
        local camera=Workspace.CurrentCamera
        local active=State.Aimbot or State.Silent or State.AimKill or State.FlyKill
        if active and camera and h and h.Health>0 then targetRecord,targetPart=Targeting.pick(camera)
        else targetRecord=nil; targetPart=nil end
        if h and h.Health>0 then WeaponModifier.tick(targetPart)
        elseif State.Silent then clearSilent(WeaponScanner.current) end
    end
end)

appearance(); UI.refresh(); WeaponScanner.update(); WeaponScanner.refreshUI()
UI.message("Pronto • controles por toque e mouse")
