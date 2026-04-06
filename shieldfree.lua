local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

-- // Setup Helpers
local function GetGui()
    if gethui then return gethui() end
    return CoreGui
end

local function RandomString(l)
    local s = ""
    for i = 1, l do s = s .. string.char(math.random(65, 90)) end
    return s
end

-- // Settings Management
local SAC = {
    Combat = {
        Aimbot = false,
        SilentAim = false,
        FOV = 150,
        Smoothing = 0.05,
        FOVVisible = true,
        WallCheck = true,
        TargetPart = "Head",
        NoRecoil = false
    },
    Visuals = {
        Box = false,
        Name = false,
        Health = false,
        Lines = false,
        HeadDot = false,
        Chams = false,
        ChamsFill = 0.5,
        ChamsOutline = 0,
        RGB_ESP = false,
        RGB_Chams = false,
        Colors = {
            Main = Color3.fromRGB(130, 100, 255),
            Enemy = Color3.fromRGB(255, 50, 50)
        }
    },
    Movement = {
        Speed = 16,
        Jump = 50,
        Fly = false,
        FlySpeed = 50,
        Noclip = false,
        InfiniteJump = false
    },
    World = {
        FullBright = false,
        NightMode = false,
        RGB_Sky = false,
        FogRemove = false
    },
    ActiveState = {
        MenuOpen = true,
        RGB = Color3.new(1, 1, 1),
        Target = nil
    }
}

-- // RGB Loop
task.spawn(function()
    while task.wait() do
        local hue = tick() % 5 / 5
        SAC.ActiveState.RGB = Color3.fromHSV(hue, 0.8, 1)
    end
end)

-- // UI Library (RGB & Advanced)
local Library = {}
do
    function Library:Create(name, props, children)
        local obj = Instance.new(name)
        for i, v in pairs(props or {}) do obj[i] = v end
        for i, v in pairs(children or {}) do v.Parent = obj end
        return obj
    end

    function Library:Tween(obj, info, props)
        local t = TweenService:Create(obj, TweenInfo.new(table.unpack(info)), props)
        t:Play()
        return t
    end

    function Library.New(title)
        local Screen = Instance.new("ScreenGui", GetGui())
        Screen.Name = RandomString(12)
        Screen.ResetOnSpawn = false

        local Main = Library:Create("Frame", {
            Name = "Main",
            Parent = Screen,
            Size = UDim2.new(0, 550, 0, 380),
            Position = UDim2.new(0.5, -275, 0.5, -190),
            BackgroundColor3 = Color3.fromRGB(10, 10, 14),
            BorderSizePixel = 0,
            ClipsDescendants = true
        }, {
            Library:Create("UICorner", {CornerRadius = UDim.new(0, 12)}),
            Library:Create("UIStroke", {Name = "Glow", Color = SAC.ActiveState.RGB, Thickness = 2, ApplyStrokeMode = "Border"})
        })

        -- RGB Loop for Border
        RunService.RenderStepped:Connect(function()
            Main.Glow.Color = SAC.ActiveState.RGB
        end)

        local Sidebar = Library:Create("Frame", {
            Name = "Sidebar",
            Parent = Main,
            Size = UDim2.new(0, 150, 1, 0),
            BackgroundColor3 = Color3.fromRGB(15, 15, 20),
            BorderSizePixel = 0
        }, {
            Library:Create("UICorner", {CornerRadius = UDim.new(0, 12)})
        })

        local Title = Library:Create("TextLabel", {
            Parent = Sidebar,
            Size = UDim2.new(1, 0, 0, 60),
            Text = title,
            Font = Enum.Font.GothamBold,
            TextSize = 18,
            TextColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1
        })
        
        RunService.RenderStepped:Connect(function() Title.TextColor3 = SAC.ActiveState.RGB end)

        local TabContainer = Library:Create("ScrollingFrame", {
            Parent = Sidebar,
            Position = UDim2.new(0, 0, 0, 60),
            Size = UDim2.new(1, 0, 1, -70),
            BackgroundTransparency = 1,
            ScrollBarThickness = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0)
        }, {
            Library:Create("UIListLayout", {Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center})
        })

        local Pages = Library:Create("Frame", {
            Parent = Main,
            Position = UDim2.new(0, 160, 0, 15),
            Size = UDim2.new(1, -175, 1, -30),
            BackgroundTransparency = 1
        })

        local Tabs = {}
        local First = true

        function Tabs:CreateTab(name)
            local Page = Library:Create("ScrollingFrame", {
                Parent = Pages,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Visible = First,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Color3.fromRGB(40, 40, 50),
                CanvasSize = UDim2.new(0, 0, 0, 0)
            }, {
                Library:Create("UIListLayout", {Padding = UDim.new(0, 8)})
            })

            local Button = Library:Create("TextButton", {
                Parent = TabContainer,
                Size = UDim2.new(0.9, 0, 0, 35),
                BackgroundColor3 = First and Color3.fromRGB(25, 25, 35) or Color3.fromRGB(20, 20, 25),
                Text = name,
                TextColor3 = First and Color3.new(1, 1, 1) or Color3.fromRGB(150, 150, 160),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                AutoButtonColor = false
            }, {
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
                Library:Create("UIStroke", {Color = SAC.ActiveState.RGB, Thickness = 1.2, Enabled = First, Name = "TabGlow"})
            })

            RunService.RenderStepped:Connect(function() if Button.UIStroke.Enabled then Button.UIStroke.Color = SAC.ActiveState.RGB end end)

            Button.MouseButton1Click:Connect(function()
                for _, p in pairs(Pages:GetChildren()) do if p:IsA("ScrollingFrame") then p.Visible = false end end
                for _, b in pairs(TabContainer:GetChildren()) do 
                    if b:IsA("TextButton") then 
                        Library:Tween(b, {0.2}, {BackgroundColor3 = Color3.fromRGB(20, 20, 25), TextColor3 = Color3.fromRGB(150, 150, 160)})
                        b.TabGlow.Enabled = false
                    end 
                end
                Page.Visible = true
                Library:Tween(Button, {0.2}, {BackgroundColor3 = Color3.fromRGB(25, 25, 35), TextColor3 = Color3.new(1,1,1)})
                Button.TabGlow.Enabled = true
            end)

            First = false
            local Elements = {}

            function Elements:AddToggle(text, callback)
                local Tgl = Library:Create("Frame", {
                    Parent = Page,
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundColor3 = Color3.fromRGB(18, 18, 24),
                    BorderSizePixel = 0
                }, {
                    Library:Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
                    Library:Create("TextLabel", {
                        Size = UDim2.new(1, -60, 1, 0),
                        Position = UDim2.new(0, 15, 0, 0),
                        Text = text,
                        TextColor3 = Color3.fromRGB(220, 220, 230),
                        Font = Enum.Font.Gotham,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundTransparency = 1
                    })
                })
                local Box = Library:Create("Frame", {
                    Parent = Tgl,
                    Position = UDim2.new(1, -45, 0.5, -11),
                    Size = UDim2.new(0, 34, 0, 22),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                }, {
                    Library:Create("UICorner", {CornerRadius = UDim.new(0, 11)}),
                    Library:Create("Frame", {
                        Name = "Indicator",
                        Position = UDim2.new(0, 3, 0.5, -8),
                        Size = UDim2.new(0, 16, 0, 16),
                        BackgroundColor3 = Color3.fromRGB(140, 140, 150)
                    }, {Library:Create("UICorner", {CornerRadius = UDim.new(1, 0)})})
                })

                local s = false
                local function update()
                    Library:Tween(Box.Indicator, {0.25, Enum.EasingStyle.Quart}, {Position = s and UDim2.new(0, 15, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = s and SAC.ActiveState.RGB or Color3.fromRGB(140, 140, 150)})
                    Library:Tween(Box, {0.2}, {BackgroundColor3 = s and Color3.fromRGB(40, 40, 60) or Color3.fromRGB(30, 30, 40)})
                    callback(s)
                end
                
                RunService.RenderStepped:Connect(function() if s then Box.Indicator.BackgroundColor3 = SAC.ActiveState.RGB end end)

                Tgl.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then s = not s; update() end end)
                Page.CanvasSize = UDim2.new(0, 0, 0, Page.UIListLayout.AbsoluteContentSize.Y + 10)
            end

            function Elements:AddSlider(text, min, max, default, callback)
                local Sld = Library:Create("Frame", {
                    Parent = Page,
                    Size = UDim2.new(1, 0, 0, 55),
                    BackgroundColor3 = Color3.fromRGB(18, 18, 24),
                    BorderSizePixel = 0
                }, {
                    Library:Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
                    Library:Create("TextLabel", {
                        Name = "Title",
                        Size = UDim2.new(1, -24, 0, 30),
                        Position = UDim2.new(0, 15, 0, 4),
                        Text = text .. ": " .. default,
                        TextColor3 = Color3.fromRGB(220, 220, 230),
                        Font = Enum.Font.Gotham,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundTransparency = 1
                    })
                })
                local Bg = Library:Create("Frame", {
                    Parent = Sld,
                    Position = UDim2.new(0, 15, 0.75, -5),
                    Size = UDim2.new(1, -30, 0, 5),
                    BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                }, {
                    Library:Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
                    Library:Create("Frame", {
                        Name = "Fill",
                        Size = UDim2.new((default-min)/(max-min), 0, 1, 0),
                        BackgroundColor3 = SAC.ActiveState.RGB
                    }, {Library:Create("UICorner", {CornerRadius = UDim.new(0, 3)})})
                })
                
                RunService.RenderStepped:Connect(function() Bg.Fill.BackgroundColor3 = SAC.ActiveState.RGB end)

                local dragging = false
                local function update()
                    local pos = math.clamp((UserInputService:GetMouseLocation().X - Bg.AbsolutePosition.X) / Bg.AbsoluteSize.X, 0, 1)
                    Bg.Fill.Size = UDim2.new(pos, 0, 1, 0)
                    local val = math.floor(min + (max-min)*pos)
                    Sld.Title.Text = text .. ": " .. val
                    callback(val)
                end

                Sld.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update() end end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
                UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update() end end)
                Page.CanvasSize = UDim2.new(0, 0, 0, Page.UIListLayout.AbsoluteContentSize.Y + 10)
            end

            return Elements
        end

        -- Dragging
        local d, s, sp
        Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true; s = i.Position; sp = Main.Position end end)
        UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then 
            local delta = i.Position - s
            Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y) 
        end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)

        UserInputService.InputBegan:Connect(function(i, g)
            if not g and i.KeyCode == Enum.KeyCode.Insert then
                SAC.ActiveState.MenuOpen = not SAC.ActiveState.MenuOpen
                Main.Visible = SAC.ActiveState.MenuOpen
            end
        end)

        return Tabs
    end
end

-- // Feature Initialization
local Window = Library.New("SHIELD PREMIUM V3")
local Combat = Window:CreateTab("Combat")
local Visuals = Window:CreateTab("Visuals")
local Movement = Window:CreateTab("Movement")
local World = Window:CreateTab("World")

Combat:AddToggle("Master Aimbot", function(v) SAC.Combat.Aimbot = v end)
Combat:AddToggle("Silent Aim", function(v) SAC.Combat.SilentAim = v end)
Combat:AddToggle("Wall Check", function(v) SAC.Combat.WallCheck = v end)
Combat:AddToggle("No Recoil (Legit)", function(v) SAC.Combat.NoRecoil = v end)
Combat:AddSlider("FOV radius", 30, 800, 150, function(v) SAC.Combat.FOV = v end)
Combat:AddSlider("Smoothing", 1, 100, 5, function(v) SAC.Combat.Smoothing = v/100 end)

Visuals:AddToggle("Box ESP", function(v) SAC.Visuals.Box = v end)
Visuals:AddToggle("Names", function(v) SAC.Visuals.Name = v end)
Visuals:AddToggle("Health Bars", function(v) SAC.Visuals.Health = v end)
Visuals:AddToggle("Snaplines", function(v) SAC.Visuals.Lines = v end)
Visuals:AddToggle("Character Chams", function(v) SAC.Visuals.Chams = v end)
Visuals:AddToggle("RGB ESP", function(v) SAC.Visuals.RGB_ESP = v end)
Visuals:AddToggle("RGB Chams", function(v) SAC.Visuals.RGB_Chams = v end)

Movement:AddSlider("Walk Speed", 16, 300, 16, function(v) SAC.Movement.Speed = v end)
Movement:AddSlider("Jump Power", 50, 300, 50, function(v) SAC.Movement.Jump = v end)
Movement:AddToggle("Fly Mode", function(v) SAC.Movement.Fly = v end)
Movement:AddToggle("Infinite Jump", function(v) SAC.Movement.InfiniteJump = v end)
Movement:AddToggle("Noclip", function(v) SAC.Movement.Noclip = v end)

World:AddToggle("Full Bright", function(v) SAC.World.FullBright = v end)
World:AddToggle("Night Mode", function(v) SAC.World.NightMode = v end)
World:AddToggle("RGB Sky (Party)", function(v) SAC.World.RGB_Sky = v end)
World:AddToggle("Remove Fog", function(v) SAC.World.FogRemove = v end)

-- // Drawing & Visual Logic
local Cache = {}
local FOV_Circle = Drawing.new("Circle")
FOV_Circle.Thickness = 1; FOV_Circle.NumSides = 100; FOV_Circle.Color = SAC.ActiveState.RGB; FOV_Circle.Visible = false

local function GetDrawings(p)
    if Cache[p] then return Cache[p] end
    local d = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBG = Drawing.new("Square"),
        Health = Drawing.new("Square"),
        Line = Drawing.new("Line"),
        Highlight = Library:Create("Highlight", {Adornee = p.Character, FillTransparency = 0.5, OutlineTransparency = 0})
    }
    for _, v in pairs(d) do if v.Thickness then v.Thickness = 1; v.Color = Color3.new(1,1,1); v.Visible = false end end
    d.Name.Center = true; d.Name.Outline = true; d.Name.Size = 13
    Cache[p] = d; return d
end

RunService.RenderStepped:Connect(function()
    FOV_Circle.Visible = (SAC.Combat.Aimbot and SAC.Combat.FOVVisible)
    FOV_Circle.Radius = SAC.Combat.FOV; FOV_Circle.Position = UserInputService:GetMouseLocation()
    FOV_Circle.Color = SAC.ActiveState.RGB
    
    local mouseLoc = UserInputService:GetMouseLocation()
    local target2D = nil; local bestTarg = nil; local minDist = SAC.Combat.FOV

    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.Health > 0 then
            local root = char.HumanoidRootPart; local head = char:FindFirstChild("Head")
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            local esp = GetDrawings(p)

            if onScreen then
                local h = math.abs(Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)).Y - Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0)).Y)
                local w = h * 0.6
                
                local col = SAC.Visuals.RGB_ESP and SAC.ActiveState.RGB or Color3.new(1,1,1)

                esp.Box.Visible = SAC.Visuals.Box; esp.Box.Size = Vector2.new(w, h); esp.Box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2); esp.Box.Color = col
                esp.Name.Visible = SAC.Visuals.Name; esp.Name.Text = p.Name; esp.Name.Position = Vector2.new(pos.X, pos.Y - h/2 - 15); esp.Name.Color = col
                esp.Line.Visible = SAC.Visuals.Lines; esp.Line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); esp.Line.To = Vector2.new(pos.X, pos.Y); esp.Line.Color = col

                if SAC.Visuals.Health then
                    esp.HealthBG.Visible = true; esp.Health.Visible = true
                    esp.HealthBG.Position = Vector2.new(pos.X - w/2 - 5, pos.Y - h/2); esp.HealthBG.Size = Vector2.new(2, h)
                    local hp = char.Humanoid.Health/char.Humanoid.MaxHealth
                    esp.Health.Position = Vector2.new(pos.X - w/2 - 5, pos.Y - h/2 + (h - (h*hp))); esp.Health.Size = Vector2.new(2, h*hp); esp.Health.Color = Color3.fromHSV(hp * 0.3, 1, 1)
                else esp.HealthBG.Visible = false; esp.Health.Visible = false end

                if SAC.Visuals.Chams then
                    esp.Highlight.Enabled = true
                    esp.Highlight.Adornee = char
                    esp.Highlight.FillColor = SAC.Visuals.RGB_Chams and SAC.ActiveState.RGB or Color3.fromRGB(130, 100, 255)
                    esp.Highlight.OutlineColor = Color3.new(1, 1, 1)
                else esp.Highlight.Enabled = false end

                if (not SAC.ActiveState.MenuOpen) and SAC.Combat.Aimbot then
                    local sPos, sVis = Camera:WorldToViewportPoint(head.Position)
                    local mag = (Vector2.new(sPos.X, sPos.Y) - mouseLoc).Magnitude
                    if mag < minDist then target2D = Vector2.new(sPos.X, sPos.Y); bestTarg = head; minDist = mag end
                end
            else for _, v in pairs(esp) do if v.Visible ~= nil then v.Visible = false end end esp.Highlight.Enabled = false end
        else if Cache[p] then for _, v in pairs(Cache[p]) do if v.Visible ~= nil then v.Visible = false end end Cache[p].Highlight.Enabled = false end end
    end

    if bestTarg and not SAC.ActiveState.MenuOpen then
        local moveX = (target2D.X - mouseLoc.X) * SAC.Combat.Smoothing
        local moveY = (target2D.Y - mouseLoc.Y) * SAC.Combat.Smoothing
        if mousemoverel then mousemoverel(moveX, moveY) end
    end
end)

-- // World & Lighting Loop
RunService.Heartbeat:Connect(function()
    if SAC.World.FullBright then Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1) end
    if SAC.World.NightMode then Lighting.ClockTime = 0 end
    if SAC.World.FogRemove then Lighting.FogEnd = 999999 end
    if SAC.World.RGB_Sky then
        Lighting.OutdoorAmbient = SAC.ActiveState.RGB
        Lighting.ColorShift_Bottom = SAC.ActiveState.RGB
        Lighting.ColorShift_Top = SAC.ActiveState.RGB
    end

    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char.Humanoid.WalkSpeed = SAC.Movement.Speed
        char.Humanoid.JumpPower = SAC.Movement.Jump
        if SAC.Movement.Noclip then for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
        if SAC.Movement.Fly then
            local root = char.HumanoidRootPart
            char.Humanoid.PlatformStand = true; root.Velocity = Vector3.new(0,0,0)
            local moveDir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
            if moveDir.Magnitude > 0 then root.Velocity = moveDir.Unit * SAC.Movement.FlySpeed end
        else char.Humanoid.PlatformStand = false end
    end
end)

UserInputService.JumpRequest:Connect(function() if SAC.Movement.InfiniteJump then LocalPlayer.Character.Humanoid:ChangeState("Jumping") end end)
