-- language: Lua, file: delta_fps_onetap.lua, executor: Delta (Roblox)
-- Aimbot + Silent Aim + ESP with Rayfield UI for FPS one-tap games.

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ============ STATE ============
local State = {
    Aimbot = {
        Enabled = false,
        Key = Enum.UserInputType.MouseButton2,
        FOV = 120,
        Smoothness = 5,
        TeamCheck = true,
        VisibleCheck = true,
        TargetPart = "Head",
    },
    SilentAim = {
        Enabled = false,
        TeamCheck = true,
        VisibleCheck = true,
        HitChance = 100,
        TargetPart = "Head",
        FOV = 200,
    },
    ESP = {
        Enabled = false,
        Box = true,
        Name = true,
        Distance = true,
        Health = true,
        Tracer = false,
        TeamCheck = true,
    },
}

local aiming = false
local Drawings = {}
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Radius = State.Aimbot.FOV
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)

-- ============ HELPERS ============
local function isTeammate(player)
    return player.Team ~= nil and player.Team == LocalPlayer.Team
end

local function getCharParts(player)
    if not player or not player.Character then return nil end
    local char = player.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if hum and root and head and hum.Health > 0 then
        return char, hum, root, head
    end
    return nil
end

local function isVisible(part)
    if not State.Aimbot.VisibleCheck then return true end
    local cam = Workspace.CurrentCamera
    if not cam then return false end
    local origin = cam.CFrame.Position
    local dir = (part.Position - origin)
    local ray = Ray.new(origin, dir)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, cam})
    return hit == part or (hit and hit:IsDescendantOf(part.Parent))
end

local function worldToScreen(pos)
    local cam = Workspace.CurrentCamera
    if not cam then return Vector2.new(0,0), false end
    local s, on = cam:WorldToViewportPoint(pos)
    return Vector2.new(s.X, s.Y), on
end

local function getTargetPart(player)
    if not player or not player.Character then return nil end
    return player.Character:FindFirstChild(State.SilentAim.TargetPart)
        or player.Character:FindFirstChild("Head")
end

-- ============ TARGET PICK ============
local function getClosest()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local center = cam.ViewportSize / 2
    local best, bestDist = nil, State.Aimbot.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if State.Aimbot.TeamCheck and isTeammate(p) then continue end
        local _, _, _, head = getCharParts(p)
        if head then
            if State.Aimbot.VisibleCheck and not isVisible(head) then continue end
            local sp, on = worldToScreen(head.Position)
            if on then
                local d = (sp - center).Magnitude
                if d < bestDist then bestDist = d; best = p end
            end
        end
    end
    return best
end

local function aimAt(player)
    if not player then return end
    local _, _, _, head = getCharParts(player)
    if not head then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local sp, on = worldToScreen(head.Position)
    if not on then return end
    local center = cam.ViewportSize / 2
    local delta = (sp - center) / State.Aimbot.Smoothness
    if mousemoverel then
        mousemoverel(delta.X, delta.Y)
    end
end

-- ============ SILENT AIM ============
-- Hooks namecall so FireServer args get redirected to enemy head.
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if State.SilentAim.Enabled and (method == "FireServer" or method == "InvokeServer") then
        local args = {...}
        local cam = Workspace.CurrentCamera
        if cam and math.random(1, 100) <= State.SilentAim.HitChance then
            local center = cam.ViewportSize / 2
            local best, bestDist = nil, State.SilentAim.FOV
            for _, p in ipairs(Players:GetPlayers()) do
                if p == LocalPlayer then continue end
                if State.SilentAim.TeamCheck and isTeammate(p) then continue end
                local targetPart = getTargetPart(p)
                if targetPart then
                    if State.SilentAim.VisibleCheck and not isVisible(targetPart) then continue end
                    local sp, on = worldToScreen(targetPart.Position)
                    if on then
                        local d = (sp - center).Magnitude
                        if d < bestDist then bestDist = d; best = targetPart end
                    end
                end
            end
            if best then
                for i, v in ipairs(args) do
                    if typeof(v) == "Vector3" then
                        args[i] = best.Position
                    elseif typeof(v) == "CFrame" then
                        args[i] = CFrame.new(best.Position)
                    elseif typeof(v) == "Instance" and v:IsA("BasePart") then
                        args[i] = best
                    end
                end
                return oldNamecall(self, table.unpack(args))
            end
        end
    end
    return oldNamecall(self, ...)
end)

-- ============ ESP ============
local function createESP(player)
    if Drawings[player] then return end
    local d = {}
    d.Box = Drawing.new("Square")
    d.Box.Thickness = 1; d.Box.Filled = false; d.Box.Visible = false
    d.Box.Color = Color3.fromRGB(255,255,255)

    d.Name = Drawing.new("Text")
    d.Name.Size = 14; d.Name.Center = true; d.Name.Outline = true; d.Name.Visible = false

    d.Distance = Drawing.new("Text")
    d.Distance.Size = 12; d.Distance.Center = true; d.Distance.Outline = true; d.Distance.Visible = false

    d.Health = Drawing.new("Line")
    d.Health.Thickness = 2; d.Health.Visible = false
    d.Health.Color = Color3.fromRGB(0,255,0)

    d.Tracer = Drawing.new("Line")
    d.Tracer.Thickness = 1; d.Tracer.Visible = false
    d.Tracer.Color = Color3.fromRGB(255,60,60)

    Drawings[player] = d
end

local function hideESP(player)
    local d = Drawings[player]
    if not d then return end
    for _, o in pairs(d) do o.Visible = false end
end

local function updateESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if State.ESP.TeamCheck and isTeammate(p) then hideESP(p); continue end
        local _, hum, root, head = getCharParts(p)
        if not hum then hideESP(p); continue end
        createESP(p)
        local d = Drawings[p]
        local headS, headOn = worldToScreen(head.Position)
        local feetS, feetOn = worldToScreen(root.Position - Vector3.new(0,3,0))
        if not (headOn and feetOn) then hideESP(p); continue end

        if State.ESP.Box then
            local top, bottom = headS.Y, feetS.Y
            local h = bottom - top
            local w = h * 0.6
            d.Box.Position = Vector2.new(headS.X - w/2, top)
            d.Box.Size = Vector2.new(w, h)
            d.Box.Visible = true
            d.Box.Color = isTeammate(p) and Color3.fromRGB(60,255,60) or Color3.fromRGB(255,60,60)
        else d.Box.Visible = false end

        if State.ESP.Name then
            d.Name.Text = p.Name
            d.Name.Position = Vector2.new(headS.X, headS.Y - 16)
            d.Name.Visible = true
        else d.Name.Visible = false end

        if State.ESP.Distance then
            local cam = Workspace.CurrentCamera
            local dist = cam and (cam.CFrame.Position - head.Position).Magnitude or 0
            d.Distance.Text = string.format("%d studs", math.floor(dist))
            d.Distance.Position = Vector2.new(headS.X, headS.Y - 30)
            d.Distance.Visible = true
        else d.Distance.Visible = false end

        if State.ESP.Health then
            local pct = hum.Health / math.max(hum.MaxHealth, 1)
            local left = headS.X - (feetS.Y - headS.Y) * 0.3 - 4
            d.Health.From = Vector2.new(left, feetS.Y)
            d.Health.To = Vector2.new(left, feetS.Y - (feetS.Y - headS.Y) * pct)
            d.Health.Visible = true
        else d.Health.Visible = false end

        if State.ESP.Tracer then
            local cam = Workspace.CurrentCamera
            local origin = cam and Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y) or Vector2.new(0,0)
            d.Tracer.From = origin
            d.Tracer.To = headS
            d.Tracer.Visible = true
        else d.Tracer.Visible = false end
    end
end

-- ============ INPUT ============
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == State.Aimbot.Key then aiming = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == State.Aimbot.Key then aiming = false end
end)

RunService.RenderStepped:Connect(function()
    local cam = Workspace.CurrentCamera
    if not cam then return end

    if State.Aimbot.Enabled and aiming then
        FOVCircle.Visible = true
        FOVCircle.Position = cam.ViewportSize / 2
        FOVCircle.Radius = State.Aimbot.FOV
        local t = getClosest()
        if t then aimAt(t) end
    else
        FOVCircle.Visible = false
    end

    if State.ESP.Enabled then updateESP()
    else
        for p in pairs(Drawings) do hideESP(p) end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    local d = Drawings[p]
    if d then
        for _, o in pairs(d) do o:Remove() end
        Drawings[p] = nil
    end
end)

-- ============ UI ============
local Window = Rayfield:CreateWindow({
    Name = "Lokeii | FPS One Tap",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Lokeii",
    ConfigurationSaving = { Enabled = true, FolderName = "LokeiiOnetap", FileName = "cfg" },
    Discord = { Enabled = false },
    KeySystem = false,
})

local AimTab = Window:CreateTab("Aimbot", 4483362458)
AimTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "aim_enabled",
    Callback = function(v) State.Aimbot.Enabled = v end,
})
AimTab:CreateSlider({
    Name = "FOV",
    Range = {10, 500},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 120,
    Flag = "aim_fov",
    Callback = function(v) State.Aimbot.FOV = v end,
})
AimTab:CreateSlider({
    Name = "Smoothness",
    Range = {1, 20},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 5,
    Flag = "aim_smooth",
    Callback = function(v) State.Aimbot.Smoothness = v end,
})
AimTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "aim_team",
    Callback = function(v) State.Aimbot.TeamCheck = v end,
})
AimTab:CreateToggle({
    Name = "Visible Check",
    CurrentValue = true,
    Flag = "aim_vis",
    Callback = function(v) State.Aimbot.VisibleCheck = v end,
})

local SATab = Window:CreateTab("Silent Aim", 4483362458)
SATab:CreateToggle({
    Name = "Enable Silent Aim (One Tap)",
    CurrentValue = false,
    Flag = "sa_enabled",
    Callback = function(v) State.SilentAim.Enabled = v end,
})
SATab:CreateSlider({
    Name = "Hit Chance",
    Range = {1, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "sa_hit",
    Callback = function(v) State.SilentAim.HitChance = v end,
})
SATab:CreateSlider({
    Name = "Silent FOV",
    Range = {10, 800},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 200,
    Flag = "sa_fov",
    Callback = function(v) State.SilentAim.FOV = v end,
})
SATab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "Torso"},
    CurrentOption = {"Head"},
    Flag = "sa_part",
    Callback = function(o) State.SilentAim.TargetPart = o[1] end,
})
SATab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "sa_team",
    Callback = function(v) State.SilentAim.TeamCheck = v end,
})
SATab:CreateToggle({
    Name = "Visible Check",
    CurrentValue = true,
    Flag = "sa_vis",
    Callback = function(v) State.SilentAim.VisibleCheck = v end,
})

local ESPTab = Window:CreateTab("ESP", 4483362458)
ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "esp_enabled",
    Callback = function(v) State.ESP.Enabled = v end,
})
ESPTab:CreateToggle({
    Name = "Box",
    CurrentValue = true,
    Flag = "esp_box",
    Callback = function(v) State.ESP.Box = v end,
})
ESPTab:CreateToggle({
    Name = "Name",
    CurrentValue = true,
    Flag = "esp_name",
    Callback = function(v) State.ESP.Name = v end,
})
ESPTab:CreateToggle({
    Name = "Distance",
    CurrentValue = true,
    Flag = "esp_dist",
    Callback = function(v) State.ESP.Distance = v end,
})
ESPTab:CreateToggle({
    Name = "Health Bar",
    CurrentValue = true,
    Flag = "esp_hp",
    Callback = function(v) State.ESP.Health = v end,
})
ESPTab:CreateToggle({
    Name = "Tracer",
    CurrentValue = false,
    Flag = "esp_tracer",
    Callback = function(v) State.ESP.Tracer = v end,
})
ESPTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "esp_team",
    Callback = function(v) State.ESP.TeamCheck = v end,
})

Rayfield:Notify({
    Title = "Lokeii",
    Content = "Menu loaded. Right mouse to aim, silent aim hooks FireServer.",
    Duration = 5,
})
