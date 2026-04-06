-- ShieldFree Premium v2.0
-- LocalScript > StarterPlayerScripts

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

for _, v in pairs(CoreGui:GetChildren()) do
    if v.Name == "SHIELD_PREMIUM" or v.Name == "SHIELD_WATERMARK" then v:Destroy() end
end

-- Settings
local SAC = {
    Combat = {
        Aimbot     = false,
        FOV        = 150,
        Smoothing  = 0.05,
        FOVVisible = true,
        WallCheck  = true,
        AutoShoot  = false,
        ShootDelay = 0.2,
        BoneMode   = "Head",   -- Head / Body / Torso / Random
        FOVColor   = Color3.new(1,1,1),
    },
    Visuals = {
        Box        = false,
        Name       = false,
        Health     = false,
        Line       = false,
        BoxColor   = Color3.new(1,1,1),
        LineColor  = Color3.new(1,1,1),
        NameColor  = Color3.new(1,1,1),
    },
    Movement = {
        InfJump    = false,
        Speed      = false,
        WalkSpeed  = 16,
        Fly        = false,
        FlySpeed   = 50,
        Noclip     = false,
    },
}

-- Bone listesi (random için)
local BONES_ALL = {"Head","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg"}

local function getBoneTarget(char)
    local mode = SAC.Combat.BoneMode
    if mode == "Random" then
        -- Görünür kemiklerden rastgele seç
        local visible = {}
        local myChar = LocalPlayer.Character
        local ray = RaycastParams.new()
        ray.FilterType = Enum.RaycastFilterType.Exclude
        ray.FilterDescendantsInstances = {myChar, Camera}
        for _, boneName in ipairs(BONES_ALL) do
            local part = char:FindFirstChild(boneName)
            if part then
                local result = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, ray)
                if result == nil or result.Instance:IsDescendantOf(char) then
                    table.insert(visible, part)
                end
            end
        end
        if #visible > 0 then
            return visible[math.random(1, #visible)]
        end
        return char:FindFirstChild("HumanoidRootPart")
    elseif mode == "Head" then
        return char:FindFirstChild("Head")
    elseif mode == "Body" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    elseif mode == "Torso" then
        return char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso")
    end
    return char:FindFirstChild("Head")
end

-- Drawing cache
local Cache = {}

local FOV_Circle = Drawing.new("Circle")
FOV_Circle.Thickness = 1; FOV_Circle.NumSides = 100
FOV_Circle.Color = SAC.Combat.FOVColor; FOV_Circle.Visible = false

local function GetESP(p)
    if Cache[p] then return Cache[p] end
    local d = {
        Box      = Drawing.new("Square"),
        Name     = Drawing.new("Text"),
        HealthBG = Drawing.new("Square"),
        Health   = Drawing.new("Square"),
        Line     = Drawing.new("Line"),
    }
    for _, v in pairs(d) do v.Thickness = 1; v.Color = Color3.new(1,1,1); v.Visible = false end
    d.Name.Center = true; d.Name.Outline = true; d.Name.Size = 13
    Cache[p] = d; return d
end

local function IsVisible(part, char)
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, ray)
    return result == nil or result.Instance:IsDescendantOf(char)
end

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
    if not SAC.Movement.InfJump then return end
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- Render loop
local lastShot = 0
RunService.RenderStepped:Connect(function()
    -- FOV circle
    FOV_Circle.Visible  = SAC.Combat.Aimbot and SAC.Combat.FOVVisible
    FOV_Circle.Radius   = SAC.Combat.FOV
    FOV_Circle.Position = UserInputService:GetMouseLocation()
    FOV_Circle.Color    = SAC.Combat.FOVColor

    local mouseLoc = UserInputService:GetMouseLocation()
    local target2D = nil
    local minDist  = SAC.Combat.FOV

    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not root or not head then
            if Cache[p] then for _, v in pairs(Cache[p]) do v.Visible = false end end
            continue
        end

        local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
        local esp = GetESP(p)

        if onScreen then
            local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
            local legPos  = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
            local h = math.abs(headPos.Y - legPos.Y)
            local w = h * 0.6

            esp.Box.Visible  = SAC.Visuals.Box
            esp.Box.Color    = SAC.Visuals.BoxColor
            esp.Box.Size     = Vector2.new(w, h)
            esp.Box.Position = Vector2.new(pos.X - w/2, headPos.Y)

            esp.Name.Visible   = SAC.Visuals.Name
            esp.Name.Color     = SAC.Visuals.NameColor
            esp.Name.Text      = p.Name
            esp.Name.Position  = Vector2.new(pos.X, headPos.Y - 15)

            esp.Line.Visible = SAC.Visuals.Line
            esp.Line.Color   = SAC.Visuals.LineColor
            esp.Line.From    = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            esp.Line.To      = Vector2.new(pos.X, pos.Y + h/2)

            local hum = char:FindFirstChildOfClass("Humanoid")
            if SAC.Visuals.Health and hum then
                local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                esp.HealthBG.Visible  = true
                esp.HealthBG.Size     = Vector2.new(2, h)
                esp.HealthBG.Position = Vector2.new(pos.X - w/2 - 5, headPos.Y)
                esp.Health.Visible    = true
                esp.Health.Size       = Vector2.new(2, hp * h)
                esp.Health.Position   = Vector2.new(pos.X - w/2 - 5, headPos.Y + (h - hp*h))
                esp.Health.Color      = Color3.new(1,0,0):Lerp(Color3.new(0,1,0), hp)
            else
                esp.HealthBG.Visible = false; esp.Health.Visible = false
            end

            if SAC.Combat.Aimbot then
                local bone = getBoneTarget(char)
                if bone then
                    local sPos, sVis = Camera:WorldToViewportPoint(bone.Position)
                    if sVis then
                        local mag = (Vector2.new(sPos.X, sPos.Y) - mouseLoc).Magnitude
                        if mag < minDist then
                            local ok = not SAC.Combat.WallCheck or IsVisible(bone, char)
                            if ok then target2D = Vector2.new(sPos.X, sPos.Y); minDist = mag end
                        end
                    end
                end
            end
        else
            for _, v in pairs(esp) do v.Visible = false end
        end
    end

    if target2D and SAC.Combat.Aimbot then
        local mx = (target2D.X - mouseLoc.X) * SAC.Combat.Smoothing
        local my = (target2D.Y - mouseLoc.Y) * SAC.Combat.Smoothing
        if mousemoverel then mousemoverel(mx, my) end
        if SAC.Combat.AutoShoot then
            local d = (target2D - mouseLoc).Magnitude
            if d < 15 and (tick() - lastShot) > SAC.Combat.ShootDelay then
                if mouse1click then mouse1click() end
                lastShot = tick()
            end
        end
    end
end)

-- Heartbeat: movement
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    hum.WalkSpeed = SAC.Movement.Speed and SAC.Movement.WalkSpeed or 16

    if SAC.Movement.Fly then
        hum.PlatformStand = true
        local dir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end
        root.Velocity = dir.Magnitude > 0 and dir.Unit * SAC.Movement.FlySpeed or Vector3.new(0,0,0)
    else
        hum.PlatformStand = false
    end

    if SAC.Movement.Noclip then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

-- ══════════════════════════════
--  GUI
-- ══════════════════════════════
local C = {
    bg      = Color3.fromRGB(0,  0,  0),
    sidebar = Color3.fromRGB(8,  8,  8),
    panel   = Color3.fromRGB(13, 13, 13),
    card    = Color3.fromRGB(20, 20, 20),
    accent  = Color3.fromRGB(55, 130, 255),
    textHi  = Color3.fromRGB(235, 238, 255),
    textMid = Color3.fromRGB(120, 128, 155),
    textLow = Color3.fromRGB(45,  48,  65),
    divider = Color3.fromRGB(22,  22,  22),
    red     = Color3.fromRGB(190, 40,  55),
    white   = Color3.fromRGB(255, 255, 255),
}

local easeOut = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local easeIn  = TweenInfo.new(0.2,  Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local fast    = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)

local function mkCorner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = p
end
local function mkLabel(parent, props)
    local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.BorderSizePixel = 0
    for k, v in pairs(props) do l[k] = v end; l.Parent = parent; return l
end
local function mkDivider(parent, y)
    local d = Instance.new("Frame"); d.Size = UDim2.new(1,-24,0,1); d.Position = UDim2.new(0,12,0,y)
    d.BackgroundColor3 = C.divider; d.BorderSizePixel = 0; d.Parent = parent
end

local gui = Instance.new("ScreenGui")
gui.Name = "SHIELD_PREMIUM"; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true; gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0,800,0,450); main.Position = UDim2.new(0.5,-400,0.5,-225)
main.BackgroundColor3 = C.bg; main.BorderSizePixel = 0
main.ClipsDescendants = true; main.Visible = false; main.Parent = gui
mkCorner(main, 12)

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0,195,1,0); sidebar.BackgroundColor3 = C.sidebar
sidebar.BorderSizePixel = 0; sidebar.Parent = main; mkCorner(sidebar, 12)

local sbFix = Instance.new("Frame")
sbFix.Size = UDim2.new(0,12,1,0); sbFix.Position = UDim2.new(1,-12,0,0)
sbFix.BackgroundColor3 = C.sidebar; sbFix.BorderSizePixel = 0; sbFix.Parent = sidebar

mkLabel(sidebar,{Size=UDim2.new(1,-20,0,22),Position=UDim2.new(0,16,0,22),Text="ShieldFree",TextColor3=C.textHi,TextSize=15,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left})
mkLabel(sidebar,{Size=UDim2.new(1,-20,0,14),Position=UDim2.new(0,16,0,46),Text="v2.0  premium",TextColor3=C.textLow,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left})
mkDivider(sidebar, 70)

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1,0,1,-150); tabContainer.Position = UDim2.new(0,0,0,80)
tabContainer.BackgroundTransparency = 1; tabContainer.Parent = sidebar

local tLayout = Instance.new("UIListLayout")
tLayout.Padding = UDim.new(0,2); tLayout.SortOrder = Enum.SortOrder.LayoutOrder; tLayout.Parent = tabContainer

local tPad = Instance.new("UIPadding")
tPad.PaddingLeft=UDim.new(0,10); tPad.PaddingRight=UDim.new(0,10); tPad.PaddingTop=UDim.new(0,6); tPad.Parent=tabContainer

local tabNames = {"Combat","Visuals","Movement","Settings"}

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1,-207,1,-20); contentArea.Position = UDim2.new(0,205,0,10)
contentArea.BackgroundColor3 = C.panel; contentArea.BorderSizePixel = 0; contentArea.Parent = main
mkCorner(contentArea, 9)

local headerBar = Instance.new("Frame")
headerBar.Size = UDim2.new(1,0,0,50); headerBar.BackgroundTransparency = 1; headerBar.Parent = contentArea

local contentTitle = mkLabel(headerBar,{Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,16,0,0),Text="Combat",TextColor3=C.textHi,TextSize=15,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left})
mkDivider(contentArea, 50)

local tabPanels = {}
for _, name in ipairs(tabNames) do
    local panel = Instance.new("ScrollingFrame")
    panel.Name="Panel_"..name; panel.Size=UDim2.new(1,-8,1,-60); panel.Position=UDim2.new(0,4,0,55)
    panel.BackgroundTransparency=1; panel.BorderSizePixel=0; panel.ScrollBarThickness=2
    panel.ScrollBarImageColor3=C.accent; panel.CanvasSize=UDim2.new(0,0,0,0)
    panel.AutomaticCanvasSize=Enum.AutomaticSize.Y; panel.Visible=false; panel.Parent=contentArea
    local ll=Instance.new("UIListLayout"); ll.Padding=UDim.new(0,5); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Parent=panel
    local pp=Instance.new("UIPadding"); pp.PaddingLeft=UDim.new(0,8); pp.PaddingRight=UDim.new(0,8); pp.PaddingTop=UDim.new(0,6); pp.PaddingBottom=UDim.new(0,8); pp.Parent=panel
    tabPanels[name] = panel
end
tabPanels["Combat"].Visible = true

-- UI components
local function mkSection(parent, text)
    mkLabel(parent,{Size=UDim2.new(1,0,0,22),Text=text,TextColor3=C.accent,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left})
end

local function mkToggle(parent, labelText, onChange)
    local state = false
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,42); row.BackgroundColor3=C.card; row.BorderSizePixel=0; row.Parent=parent; mkCorner(row,8)
    mkLabel(row,{Size=UDim2.new(1,-70,1,0),Position=UDim2.new(0,12,0,0),Text=labelText,TextColor3=C.textMid,TextSize=13,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left})
    local track=Instance.new("Frame"); track.Size=UDim2.new(0,40,0,22); track.Position=UDim2.new(1,-52,0.5,-11); track.BackgroundColor3=Color3.fromRGB(35,35,35); track.BorderSizePixel=0; track.Parent=row; mkCorner(track,11)
    local knob=Instance.new("Frame"); knob.Size=UDim2.new(0,16,0,16); knob.Position=UDim2.new(0,3,0.5,-8); knob.BackgroundColor3=C.textMid; knob.BorderSizePixel=0; knob.Parent=track; mkCorner(knob,8)
    local function refresh()
        if state then TweenService:Create(track,fast,{BackgroundColor3=C.accent}):Play(); TweenService:Create(knob,fast,{Position=UDim2.new(0,21,0.5,-8),BackgroundColor3=C.white}):Play()
        else TweenService:Create(track,fast,{BackgroundColor3=Color3.fromRGB(35,35,35)}):Play(); TweenService:Create(knob,fast,{Position=UDim2.new(0,3,0.5,-8),BackgroundColor3=C.textMid}):Play() end
    end
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=row
    btn.MouseButton1Click:Connect(function() state=not state; refresh(); if onChange then onChange(state) end end)
end

local function mkSlider(parent, labelText, minVal, maxVal, defaultVal, suffix, onChange)
    local val = defaultVal or minVal
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,54); row.BackgroundColor3=C.card; row.BorderSizePixel=0; row.Parent=parent; mkCorner(row,8)
    mkLabel(row,{Size=UDim2.new(0.6,0,0,20),Position=UDim2.new(0,12,0,6),Text=labelText,TextColor3=C.textMid,TextSize=13,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left})
    local valLbl=mkLabel(row,{Size=UDim2.new(0.4,-12,0,20),Position=UDim2.new(0.6,0,0,6),Text=tostring(val)..(suffix or ""),TextColor3=C.accent,TextSize=12,Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Right})
    local track=Instance.new("Frame"); track.Size=UDim2.new(1,-24,0,4); track.Position=UDim2.new(0,12,0,36); track.BackgroundColor3=Color3.fromRGB(30,30,30); track.BorderSizePixel=0; track.Parent=row; mkCorner(track,2)
    local fill=Instance.new("Frame"); fill.Size=UDim2.new((val-minVal)/(maxVal-minVal),0,1,0); fill.BackgroundColor3=C.accent; fill.BorderSizePixel=0; fill.Parent=track; mkCorner(fill,2)
    local knob=Instance.new("Frame"); knob.Size=UDim2.new(0,12,0,12); knob.AnchorPoint=Vector2.new(0.5,0.5); knob.Position=UDim2.new((val-minVal)/(maxVal-minVal),0,0.5,0); knob.BackgroundColor3=C.white; knob.BorderSizePixel=0; knob.Parent=track; mkCorner(knob,6)
    local sliding=false
    local hitbox=Instance.new("TextButton"); hitbox.Size=UDim2.new(1,0,0,20); hitbox.Position=UDim2.new(0,0,0,28); hitbox.BackgroundTransparency=1; hitbox.Text=""; hitbox.Parent=row
    local function update(inputX)
        local pct=math.clamp((inputX-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        val=math.floor(minVal+pct*(maxVal-minVal)); fill.Size=UDim2.new(pct,0,1,0); knob.Position=UDim2.new(pct,0,0.5,0)
        valLbl.Text=tostring(val)..(suffix or ""); if onChange then onChange(val) end
    end
    hitbox.MouseButton1Down:Connect(function() sliding=true; update(UserInputService:GetMouseLocation().X) end)
    UserInputService.InputChanged:Connect(function(i) if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end end)
end

-- Color picker: 3 slider (R G B)
local function mkColorPicker(parent, labelText, defaultColor, onChange)
    local r = math.floor(defaultColor.R * 255)
    local g = math.floor(defaultColor.G * 255)
    local b = math.floor(defaultColor.B * 255)

    local wrap=Instance.new("Frame"); wrap.Size=UDim2.new(1,0,0,130); wrap.BackgroundColor3=C.card; wrap.BorderSizePixel=0; wrap.Parent=parent; mkCorner(wrap,8)
    mkLabel(wrap,{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,12,0,6),Text=labelText,TextColor3=C.textMid,TextSize=12,Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Left})

    -- Preview box
    local preview=Instance.new("Frame"); preview.Size=UDim2.new(0,18,0,18); preview.Position=UDim2.new(1,-30,0,6); preview.BackgroundColor3=defaultColor; preview.BorderSizePixel=0; preview.Parent=wrap; mkCorner(preview,4)

    local function fireChange()
        local col = Color3.fromRGB(r,g,b)
        preview.BackgroundColor3 = col
        if onChange then onChange(col) end
    end

    local channels = {{"R", Color3.fromRGB(200,50,50), r}, {"G", Color3.fromRGB(50,200,80), g}, {"B", Color3.fromRGB(50,120,255), b}}
    for idx, ch in ipairs(channels) do
        local yOff = 28 + (idx-1)*32
        mkLabel(wrap,{Size=UDim2.new(0,12,0,16),Position=UDim2.new(0,12,0,yOff+4),Text=ch[1],TextColor3=ch[2],TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left})
        local track=Instance.new("Frame"); track.Size=UDim2.new(1,-50,0,4); track.Position=UDim2.new(0,28,0,yOff+10); track.BackgroundColor3=Color3.fromRGB(30,30,30); track.BorderSizePixel=0; track.Parent=wrap; mkCorner(track,2)
        local fill=Instance.new("Frame"); fill.Size=UDim2.new(ch[3]/255,0,1,0); fill.BackgroundColor3=ch[2]; fill.BorderSizePixel=0; fill.Parent=track; mkCorner(fill,2)
        local knob=Instance.new("Frame"); knob.Size=UDim2.new(0,10,0,10); knob.AnchorPoint=Vector2.new(0.5,0.5); knob.Position=UDim2.new(ch[3]/255,0,0.5,0); knob.BackgroundColor3=C.white; knob.BorderSizePixel=0; knob.Parent=track; mkCorner(knob,5)
        local valLbl=mkLabel(wrap,{Size=UDim2.new(0,20,0,16),Position=UDim2.new(1,-22,0,yOff+4),Text=tostring(ch[3]),TextColor3=C.textLow,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Right})
        local sliding=false
        local hitbox=Instance.new("TextButton"); hitbox.Size=UDim2.new(1,0,0,16); hitbox.Position=UDim2.new(0,0,0,yOff+4); hitbox.BackgroundTransparency=1; hitbox.Text=""; hitbox.Parent=wrap
        local function update(inputX)
            local pct=math.clamp((inputX-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            local v=math.floor(pct*255)
            fill.Size=UDim2.new(pct,0,1,0); knob.Position=UDim2.new(pct,0,0.5,0)
            valLbl.Text=tostring(v)
            if idx==1 then r=v elseif idx==2 then g=v else b=v end
            fireChange()
        end
        hitbox.MouseButton1Down:Connect(function() sliding=true; update(UserInputService:GetMouseLocation().X) end)
        UserInputService.InputChanged:Connect(function(i) if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end end)
    end
end

-- Bone selector (dropdown style: 4 buton)
local function mkBoneSelector(parent)
    local wrap=Instance.new("Frame"); wrap.Size=UDim2.new(1,0,0,54); wrap.BackgroundColor3=C.card; wrap.BorderSizePixel=0; wrap.Parent=parent; mkCorner(wrap,8)
    mkLabel(wrap,{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,12,0,4),Text="Target Bone",TextColor3=C.textMid,TextSize=13,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left})
    local options={"Head","Body","Torso","Random"}
    local btnW = (1/#options)
    local btns={}
    for i, opt in ipairs(options) do
        local b=Instance.new("TextButton"); b.Size=UDim2.new(btnW,-4,0,22); b.Position=UDim2.new((i-1)*btnW,2,0,28)
        b.BackgroundColor3=Color3.fromRGB(30,30,30); b.Text=opt; b.TextColor3=C.textMid; b.TextSize=11; b.Font=Enum.Font.GothamSemibold; b.BorderSizePixel=0; b.Parent=wrap; mkCorner(b,5)
        btns[opt]=b
        b.MouseButton1Click:Connect(function()
            SAC.Combat.BoneMode=opt
            for _, bb in pairs(btns) do bb.BackgroundColor3=Color3.fromRGB(30,30,30); bb.TextColor3=C.textMid end
            b.BackgroundColor3=C.accent; b.TextColor3=C.white
        end)
    end
    -- Default aktif
    btns["Head"].BackgroundColor3=C.accent; btns["Head"].TextColor3=C.white
end

-- COMBAT TAB
local cP = tabPanels["Combat"]
mkSection(cP, "Aimbot")
mkToggle(cP, "Aimbot",       function(s) SAC.Combat.Aimbot    = s end)
mkToggle(cP, "Wall Check",   function(s) SAC.Combat.WallCheck = s end)
mkToggle(cP, "Auto Shoot",   function(s) SAC.Combat.AutoShoot = s end)
mkToggle(cP, "FOV Circle",   function(s) SAC.Combat.FOVVisible= s end)
mkBoneSelector(cP)
mkSection(cP, "Settings")
mkSlider(cP, "FOV Size",     30, 800, 150, " px",  function(v) SAC.Combat.FOV        = v end)
mkSlider(cP, "Smoothness",    1, 100,   5, "",      function(v) SAC.Combat.Smoothing  = v/100 end)
mkSlider(cP, "Shoot Delay",   1,  20,   2, " tick", function(v) SAC.Combat.ShootDelay = v/10 end)
mkSection(cP, "Colors")
mkColorPicker(cP, "FOV Color", Color3.new(1,1,1), function(col) SAC.Combat.FOVColor = col end)

-- VISUALS TAB
local vP = tabPanels["Visuals"]
mkSection(vP, "ESP")
mkToggle(vP, "Box ESP",    function(s) SAC.Visuals.Box    = s end)
mkToggle(vP, "Name ESP",   function(s) SAC.Visuals.Name   = s end)
mkToggle(vP, "Health Bar", function(s) SAC.Visuals.Health = s end)
mkToggle(vP, "Snap Line",  function(s) SAC.Visuals.Line   = s end)
mkSection(vP, "Colors")
mkColorPicker(vP, "Box Color",  Color3.new(1,1,1), function(col) SAC.Visuals.BoxColor  = col end)
mkColorPicker(vP, "Line Color", Color3.new(1,1,1), function(col) SAC.Visuals.LineColor = col end)
mkColorPicker(vP, "Name Color", Color3.new(1,1,1), function(col) SAC.Visuals.NameColor = col end)

-- MOVEMENT TAB
local mP = tabPanels["Movement"]
mkSection(mP, "Movement")
mkToggle(mP, "Infinite Jump", function(s) SAC.Movement.InfJump = s end)
mkToggle(mP, "Speed Hack",    function(s) SAC.Movement.Speed   = s end)
mkSlider(mP, "Walk Speed",  16, 300, 16, "",  function(v) SAC.Movement.WalkSpeed = v end)
mkToggle(mP, "Fly Mode",      function(s) SAC.Movement.Fly     = s end)
mkSlider(mP, "Fly Speed",   10, 300, 50, "",  function(v) SAC.Movement.FlySpeed  = v end)
mkToggle(mP, "Noclip",        function(s) SAC.Movement.Noclip  = s end)

-- SETTINGS TAB
local sP = tabPanels["Settings"]
mkSection(sP, "Info")
mkLabel(sP,{Size=UDim2.new(1,0,0,28),Text="INSERT = Toggle menu",TextColor3=C.textLow,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left})
mkLabel(sP,{Size=UDim2.new(1,0,0,28),Text="Uses Drawing API (executor required)",TextColor3=C.textLow,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left})
mkLabel(sP,{Size=UDim2.new(1,0,0,28),Text="Fly: WASD + Space/Shift",TextColor3=C.textLow,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left})

-- User card
mkDivider(sidebar, 390)
local userCard=Instance.new("Frame"); userCard.Size=UDim2.new(1,-20,0,44); userCard.Position=UDim2.new(0,10,1,-54); userCard.BackgroundColor3=C.card; userCard.BorderSizePixel=0; userCard.Parent=sidebar; mkCorner(userCard,8)
mkLabel(userCard,{Size=UDim2.new(1,-16,0,16),Position=UDim2.new(0,12,0,7),Text=LocalPlayer.DisplayName,TextColor3=C.textHi,TextSize=12,Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Left})
mkLabel(userCard,{Size=UDim2.new(1,-16,0,13),Position=UDim2.new(0,12,0,25),Text="@"..LocalPlayer.Name,TextColor3=C.textLow,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left})

-- Close button
local closeBtn=Instance.new("TextButton"); closeBtn.Size=UDim2.new(0,26,0,26); closeBtn.Position=UDim2.new(1,-36,0,12); closeBtn.BackgroundColor3=Color3.fromRGB(20,20,20); closeBtn.Text="x"; closeBtn.TextColor3=C.textLow; closeBtn.TextSize=12; closeBtn.Font=Enum.Font.GothamBold; closeBtn.BorderSizePixel=0; closeBtn.Parent=main; mkCorner(closeBtn,6)
closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn,fast,{BackgroundColor3=C.red,TextColor3=C.white}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn,fast,{BackgroundColor3=Color3.fromRGB(20,20,20),TextColor3=C.textLow}):Play() end)

-- Tab system
local activeTabBtn = nil
local function setActiveTab(btn, name)
    if activeTabBtn and activeTabBtn ~= btn then
        TweenService:Create(activeTabBtn,fast,{BackgroundTransparency=1}):Play()
        local pb=activeTabBtn:FindFirstChild("Bar"); local pl=activeTabBtn:FindFirstChild("TL")
        if pb then TweenService:Create(pb,fast,{BackgroundTransparency=1}):Play() end
        if pl then TweenService:Create(pl,fast,{TextColor3=C.textMid}):Play() end
        local on=activeTabBtn.Name:sub(5); if tabPanels[on] then tabPanels[on].Visible=false end
    end
    TweenService:Create(btn,fast,{BackgroundColor3=C.card,BackgroundTransparency=0}):Play()
    local b=btn:FindFirstChild("Bar"); local l=btn:FindFirstChild("TL")
    if b then TweenService:Create(b,fast,{BackgroundTransparency=0}):Play() end
    if l then TweenService:Create(l,fast,{TextColor3=C.textHi}):Play() end
    activeTabBtn=btn; contentTitle.Text=name
    if tabPanels[name] then tabPanels[name].Visible=true end
end

for i, name in ipairs(tabNames) do
    local btn=Instance.new("TextButton"); btn.Name="Tab_"..name; btn.Size=UDim2.new(1,0,0,40); btn.BackgroundColor3=C.card; btn.BackgroundTransparency=1; btn.Text=""; btn.BorderSizePixel=0; btn.LayoutOrder=i; btn.Parent=tabContainer; mkCorner(btn,7)
    local bar=Instance.new("Frame"); bar.Name="Bar"; bar.Size=UDim2.new(0,3,0,18); bar.Position=UDim2.new(0,0,0.5,-9); bar.BackgroundColor3=C.accent; bar.BackgroundTransparency=1; bar.BorderSizePixel=0; bar.Parent=btn; mkCorner(bar,2)
    local tl=Instance.new("TextLabel"); tl.Name="TL"; tl.Size=UDim2.new(1,-20,1,0); tl.Position=UDim2.new(0,16,0,0); tl.BackgroundTransparency=1; tl.Text=name; tl.TextColor3=C.textMid; tl.TextSize=13; tl.Font=Enum.Font.GothamSemibold; tl.TextXAlignment=Enum.TextXAlignment.Left; tl.Parent=btn
    btn.MouseButton1Click:Connect(function() setActiveTab(btn,name) end)
    btn.MouseEnter:Connect(function() if btn~=activeTabBtn then TweenService:Create(btn,fast,{BackgroundColor3=C.card,BackgroundTransparency=0.5}):Play() end end)
    btn.MouseLeave:Connect(function() if btn~=activeTabBtn then TweenService:Create(btn,fast,{BackgroundTransparency=1}):Play() end end)
    if i==1 then task.defer(function() setActiveTab(btn,name) end) end
end

-- Drag
local dragging,dragStart,startPos=false,nil,nil
sidebar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;dragStart=i.Position;startPos=main.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-dragStart; main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

-- Toggle menu
local menuOpen=false
local function toggle()
    menuOpen=not menuOpen
    if menuOpen then
        main.Visible=true; main.BackgroundTransparency=1; main.Size=UDim2.new(0,785,0,435)
        TweenService:Create(main,easeOut,{BackgroundTransparency=0,Size=UDim2.new(0,800,0,450)}):Play()
    else
        local t=TweenService:Create(main,easeIn,{BackgroundTransparency=1,Size=UDim2.new(0,785,0,435)})
        t:Play(); t.Completed:Connect(function() main.Visible=false end)
    end
end

closeBtn.MouseButton1Click:Connect(toggle)
UserInputService.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.Insert then toggle() end
end)

print("[ShieldFree] v2.0 loaded. INSERT = toggle")
