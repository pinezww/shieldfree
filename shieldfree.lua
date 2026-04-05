local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

for _, v in pairs(CoreGui:GetChildren()) do
    if v.Name == "SHIELD_PREMIUM" or v.Name == "SHIELD_WATERMARK" then v:Destroy() end
end

local SAC = {
    Combat = {
        Aimbot = false, 
        FOV = 150, 
        Smoothing = 0.05, 
        FOVVisible = true, 
        WallCheck = true,
        AutoShoot = false, 
        ShootDelay = 0.2   
    },
    Visuals = {Box = false, Name = false, Health = false, Line = false},
    Movement = {Spin = false, SpinSpeed = 100, Fly = false, FlySpeed = 50, Noclip = false},
    Settings = {ResetTimer = 30}
}

local Cache = {}
local FOV_Circle = Drawing.new("Circle")
FOV_Circle.Thickness = 1; FOV_Circle.NumSides = 100; FOV_Circle.Color = Color3.new(1,1,1); FOV_Circle.Visible = false

local Watermark = Instance.new("ScreenGui", CoreGui); Watermark.Name = "SHIELD_WATERMARK"
local WLbl = Instance.new("TextLabel", Watermark)
WLbl.Size = UDim2.new(0, 200, 0, 30); WLbl.Position = UDim2.new(0, 10, 0, 10)
WLbl.BackgroundTransparency = 1; WLbl.Text = "shield.wtf"; WLbl.Font = "GothamBold"
WLbl.TextSize = 20; WLbl.TextXAlignment = "Left"

task.spawn(function()
    while task.wait() do
        local hue = tick() % 5 / 5
        WLbl.TextColor3 = Color3.fromHSV(hue, 1, 1)
    end
end)

task.spawn(function()
    while task.wait(SAC.Settings.ResetTimer) do
        for p, drawings in pairs(Cache) do
            for _, obj in pairs(drawings) do obj:Destroy() end
        end
        Cache = {}
    end
end)

local Screen = Instance.new("ScreenGui", CoreGui); Screen.Name = "SHIELD_PREMIUM"
local Main = Instance.new("Frame", Screen); Main.Size = UDim2.new(0, 550, 0, 400); Main.Position = UDim2.new(0.5, -275, 0.5, -200); Main.BackgroundColor3 = Color3.fromRGB(10, 10, 10); Main.BorderSizePixel = 0
Instance.new("UIStroke", Main).Color = Color3.new(1,1,1); Instance.new("UICorner", Main)

local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 150, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 18); Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar)
local TabButtons = Instance.new("Frame", Sidebar); TabButtons.Size = UDim2.new(1, 0, 1, -60); TabButtons.Position = UDim2.new(0, 0, 0, 60); TabButtons.BackgroundTransparency = 1
Instance.new("UIListLayout", TabButtons).Padding = UDim.new(0, 5); Instance.new("UIListLayout", TabButtons).HorizontalAlignment = "Center"

local PageContainer = Instance.new("Frame", Main); PageContainer.Size = UDim2.new(1, -160, 1, -10); PageContainer.Position = UDim2.new(0, 160, 0, 10); PageContainer.BackgroundTransparency = 1

local Pages = {}
local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame", PageContainer); Page.Size = UDim2.new(1, 0, 1, 0); Page.BackgroundTransparency = 1; Page.Visible = false; Page.ScrollBarThickness = 0; Page.CanvasSize = UDim2.new(0,0,1.5,0)
    Instance.new("UIListLayout", Page).Padding = UDim.new(0, 8)
    local TabBtn = Instance.new("TextButton", TabButtons); TabBtn.Size = UDim2.new(0.9, 0, 0, 35); TabBtn.Text = name; TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TabBtn.TextColor3 = Color3.new(1,1,1); TabBtn.Font = "GothamBold"; TabBtn.TextSize = 13; Instance.new("UICorner", TabBtn)
    TabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        for _, b in pairs(TabButtons:GetChildren()) do if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end end
        Page.Visible = true; TabBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end)
    Pages[name] = Page; return Page
end

local P_Combat = CreatePage("COMBAT"); local P_Visuals = CreatePage("VISUALS"); local P_Move = CreatePage("MOVEMENT")
P_Combat.Visible = true

local function AddToggle(parent, text, callback)
    local b = Instance.new("TextButton", parent); b.Size = UDim2.new(0.98, 0, 0, 35); b.Text = "  " .. text; b.BackgroundColor3 = Color3.fromRGB(25, 25, 25); b.TextColor3 = Color3.new(1,1,1); b.Font = "Gotham"; b.TextSize = 12; b.TextXAlignment = "Left"; Instance.new("UICorner", b); Instance.new("UIStroke", b).Color = Color3.fromRGB(40,40,40)
    local s = false; b.MouseButton1Click:Connect(function() s = not s; b.BackgroundColor3 = s and Color3.new(1,1,1) or Color3.fromRGB(25, 25, 25); b.TextColor3 = s and Color3.new(0,0,0) or Color3.new(1,1,1); callback(s) end)
end

local function AddSlider(parent, text, min, max, default, callback)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.98, 0, 0, 50); f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1, 0, 0, 20); l.Text = text .. ": " .. default; l.TextColor3 = Color3.new(1,1,1); l.BackgroundTransparency = 1; l.TextXAlignment = "Left"; l.Font = "Gotham"
    local s_bg = Instance.new("Frame", f); s_bg.Size = UDim2.new(1, 0, 0, 4); s_bg.Position = UDim2.new(0, 0, 0.7, 0); s_bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    local bar = Instance.new("Frame", s_bg); bar.Size = UDim2.new((default-min)/(max-min), 0, 1, 0); bar.BackgroundColor3 = Color3.new(1,1,1)
    s_bg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then local move; move = RunService.RenderStepped:Connect(function() local rel = math.clamp((UserInputService:GetMouseLocation().X - s_bg.AbsolutePosition.X) / s_bg.AbsoluteSize.X, 0, 1); bar.Size = UDim2.new(rel, 0, 1, 0); local val = math.floor(min + (max-min)*rel); l.Text = text .. ": " .. val; callback(val) end) UserInputService.InputEnded:Connect(function(i2) if i2.UserInputType == Enum.UserInputType.MouseButton1 then move:Disconnect() end end) end end)
end

AddToggle(P_Combat, "Aimbot Master", function(v) SAC.Combat.Aimbot = v end)
AddToggle(P_Combat, "Wall Check (Legit)", function(v) SAC.Combat.WallCheck = v end)
AddToggle(P_Combat, "Auto Shoot", function(v) SAC.Combat.AutoShoot = v end)
AddSlider(P_Combat, "Aimbot FOV", 30, 800, 150, function(v) SAC.Combat.FOV = v end)
AddSlider(P_Combat, "Smoothness", 1, 100, 5, function(v) SAC.Combat.Smoothing = v/100 end)

AddToggle(P_Visuals, "Box ESP (Pure White)", function(v) SAC.Visuals.Box = v end)
AddToggle(P_Visuals, "Player Names", function(v) SAC.Visuals.Name = v end)
AddToggle(P_Visuals, "Health Bar", function(v) SAC.Visuals.Health = v end)
AddToggle(P_Visuals, "Snaplines (Line)", function(v) SAC.Visuals.Line = v end)

AddToggle(P_Move, "Spinbot (Mevlana)", function(v) SAC.Movement.Spin = v end)
AddSlider(P_Move, "Spin Speed", 10, 500, 100, function(v) SAC.Movement.SpinSpeed = v end)
AddToggle(P_Move, "Fly Mode", function(v) SAC.Movement.Fly = v end)
AddSlider(P_Move, "Fly Speed", 10, 300, 50, function(v) SAC.Movement.FlySpeed = v end)
AddToggle(P_Move, "Noclip", function(v) SAC.Movement.Noclip = v end)

local function GetESP(p)
    if Cache[p] then return Cache[p] end
    local d = {Box = Drawing.new("Square"), Name = Drawing.new("Text"), HealthBG = Drawing.new("Square"), Health = Drawing.new("Square"), Line = Drawing.new("Line")}
    for _, v in pairs(d) do v.Thickness = 1; v.Color = Color3.new(1,1,1); v.Visible = false end
    d.Name.Center = true; d.Name.Outline = true; d.Name.Size = 13
    Cache[p] = d; return d
end

local function IsVisible(part, char)
    local origin = Camera.CFrame.Position
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = workspace:Raycast(origin, part.Position - origin, ray)
    return result == nil or result.Instance:IsDescendantOf(char)
end

local lastShot = 0 

RunService.RenderStepped:Connect(function(dt)
    FOV_Circle.Visible = (SAC.Combat.Aimbot and SAC.Combat.FOVVisible)
    FOV_Circle.Radius = SAC.Combat.FOV; FOV_Circle.Position = UserInputService:GetMouseLocation()
    
    local mouseLoc = UserInputService:GetMouseLocation()
    local target2D = nil; local minDist = SAC.Combat.FOV

    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
            local root = char.HumanoidRootPart; local head = char.Head
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            local esp = GetESP(p)

            if onScreen then
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                local h = math.abs(headPos.Y - legPos.Y); local w = h * 0.6

                esp.Box.Visible = SAC.Visuals.Box; esp.Box.Size = Vector2.new(w, h); esp.Box.Position = Vector2.new(pos.X - w/2, headPos.Y)
                esp.Name.Visible = SAC.Visuals.Name; esp.Name.Text = p.Name; esp.Name.Position = Vector2.new(pos.X, headPos.Y - 15)
                
                esp.Line.Visible = SAC.Visuals.Line
                esp.Line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                esp.Line.To = Vector2.new(pos.X, pos.Y + (h/2)) 

                local hum = char:FindFirstChildOfClass("Humanoid")
                if SAC.Visuals.Health and hum then
                    esp.HealthBG.Visible = true; esp.Health.Visible = true
                    esp.HealthBG.Size = Vector2.new(2, h); esp.HealthBG.Position = Vector2.new(pos.X - w/2 - 5, headPos.Y)
                    local hp = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
                    esp.Health.Size = Vector2.new(2, hp*h); esp.Health.Position = Vector2.new(pos.X - w/2 - 5, headPos.Y + (h - (hp*h))); esp.Health.Color = Color3.new(1,0,0):Lerp(Color3.new(0,1,0), hp)
                else esp.HealthBG.Visible = false; esp.Health.Visible = false end

                if SAC.Combat.Aimbot then
                    local sPos, sVis = Camera:WorldToViewportPoint(head.Position)
                    local mag = (Vector2.new(sPos.X, sPos.Y) - mouseLoc).Magnitude
                    
                    if mag < minDist then
                        if SAC.Combat.WallCheck then
                            if IsVisible(head, char) then
                                target2D = Vector2.new(sPos.X, sPos.Y); minDist = mag
                            end
                        else
                            target2D = Vector2.new(sPos.X, sPos.Y); minDist = mag
                        end
                    end
                end
            else for _, v in pairs(esp) do v.Visible = false end end
        else if Cache[p] then for _, v in pairs(Cache[p]) do v.Visible = false end end end
    end

    if target2D and SAC.Combat.Aimbot then
        local moveX = (target2D.X - mouseLoc.X) * SAC.Combat.Smoothing
        local moveY = (target2D.Y - mouseLoc.Y) * SAC.Combat.Smoothing
        if mousemoverel then mousemoverel(moveX, moveY) end
        
        if SAC.Combat.AutoShoot then
            local currentDistance = (target2D - mouseLoc).Magnitude
            if currentDistance < 15 and (tick() - lastShot) > SAC.Combat.ShootDelay then
                if mouse1click then
                    mouse1click() 
                end
                lastShot = tick()
            end
        end
    end
end)

RunService.Heartbeat:Connect(function(dt)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    if SAC.Movement.Spin then
        root.RotVelocity = Vector3.new(0, SAC.Movement.SpinSpeed, 0)
    end

    if SAC.Movement.Fly then
        hum.PlatformStand = true
        root.Velocity = Vector3.new(0,0,0)
        
        local moveDir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
        
        if moveDir.Magnitude > 0 then
            root.Velocity = moveDir.Unit * SAC.Movement.FlySpeed
        end
    else
        hum.PlatformStand = false
    end

    if SAC.Movement.Noclip then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)


local d, s, sp; Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true; s = i.Position; sp = Main.Position end end)
UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - s; Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)
UserInputService.InputBegan:Connect(function(i, g) if not g and i.KeyCode == Enum.KeyCode.Insert then Main.Visible = not Main.Visible end end)
