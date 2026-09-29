-- language: Lua, file: delta_aimbot_esp.lua, executor: Delta (Roblox)
-- Aimbot + ESP for Roblox Delta executor.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Settings = {
    Aimbot = {
        Enabled = true,
        Key = Enum.UserInputType.MouseButton2, -- right mouse
        FOV = 120,
        Smoothness = 5,
        TeamCheck = true,
    },
    ESP = {
        Enabled = true,
        Box = true,
        Name = true,
        Distance = true,
        Health = true,
        Tracer = true,
        TeamCheck = true,
    },
    Colors = {
        Enemy = Color3.fromRGB(255, 60, 60),
        Team = Color3.fromRGB(60, 255, 60),
        Box = Color3.fromRGB(255, 255, 255),
        Name = Color3.fromRGB(255, 255, 255),
        Distance = Color3.fromRGB(200, 200, 200),
        Health = Color3.fromRGB(0, 255, 0),
        Tracer = Color3.fromRGB(255, 255, 255),
        FOV = Color3.fromRGB(255, 255, 255),
    }
}

local Drawings = {}
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Radius = Settings.Aimbot.FOV
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Color = Settings.Colors.FOV

local aiming = false

local function isTeamMate(player)
    if not Settings.Aimbot.TeamCheck and not Settings.ESP.TeamCheck then return false end
    return player.Team == LocalPlayer.Team and player.Team ~= nil
end

local function getCharacter(player)
    if not player or not player.Character then return nil end
    local char = player.Character
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if humanoid and root and head and humanoid.Health > 0 then
        return char, humanoid, root, head
    end
    return nil
end

local function worldToScreen(pos)
    local camera = Workspace.CurrentCamera
    if not camera then return Vector2.new(0, 0), false end
    local screen, onScreen = camera:WorldToViewportPoint(pos)
    return Vector2.new(screen.X, screen.Y), onScreen
end

local function getClosestPlayer()
    local closest = nil
    local shortest = Settings.Aimbot.FOV
    local camera = Workspace.CurrentCamera
    if not camera then return nil end
    local center = camera.ViewportSize / 2
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Settings.Aimbot.TeamCheck and isTeamMate(player) then continue end
        local char, humanoid, root, head = getCharacter(player)
        if char then
            local screenPos, onScreen = worldToScreen(head.Position)
            if onScreen then
                local dist = (screenPos - center).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

local function aimAt(target)
    if not target then return end
    local char, humanoid, root, head = getCharacter(target)
    if not char then return end
    local screenPos, onScreen = worldToScreen(head.Position)
    if not onScreen then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local center = camera.ViewportSize / 2
    local delta = screenPos - center
    local smooth = Settings.Aimbot.Smoothness
    if mousemoverel then
        mousemoverel(delta.X / smooth, delta.Y / smooth)
    end
end

local function createESP(player)
    if Drawings[player] then return end
    local d = {}
    d.Box = Drawing.new("Square")
    d.Box.Thickness = 1
    d.Box.Filled = false
    d.Box.Visible = false
    d.Box.Color = Settings.Colors.Box

    d.Name = Drawing.new("Text")
    d.Name.Size = 14
    d.Name.Center = true
    d.Name.Outline = true
    d.Name.Visible = false
    d.Name.Color = Settings.Colors.Name

    d.Distance = Drawing.new("Text")
    d.Distance.Size = 12
    d.Distance.Center = true
    d.Distance.Outline = true
    d.Distance.Visible = false
    d.Distance.Color = Settings.Colors.Distance

    d.Health = Drawing.new("Line")
    d.Health.Thickness = 2
    d.Health.Visible = false
    d.Health.Color = Settings.Colors.Health

    d.Tracer = Drawing.new("Line")
    d.Tracer.Thickness = 1
    d.Tracer.Visible = false
    d.Tracer.Color = Settings.Colors.Tracer

    Drawings[player] = d
end

local function removeESP(player)
    local d = Drawings[player]
    if not d then return end
    for _, obj in pairs(d) do
        obj:Remove()
    end
    Drawings[player] = nil
end

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Settings.ESP.TeamCheck and isTeamMate(player) then
            if Drawings[player] then
                for _, obj in pairs(Drawings[player]) do obj.Visible = false end
            end
            continue
        end
        local char, humanoid, root, head = getCharacter(player)
        if not char then
            if Drawings[player] then
                for _, obj in pairs(Drawings[player]) do obj.Visible = false end
            end
            continue
        end
        createESP(player)
        local d = Drawings[player]
        local headScreen, headOn = worldToScreen(head.Position)
        local rootScreen, rootOn = worldToScreen(root.Position)
        local feetScreen, feetOn = worldToScreen(root.Position - Vector3.new(0, 3, 0))
        if not (headOn and rootOn and feetOn) then
            for _, obj in pairs(d) do obj.Visible = false end
            continue
        end
        -- Box
        if Settings.ESP.Box then
            local top = headScreen.Y
            local bottom = feetScreen.Y
            local height = bottom - top
            local width = height * 0.6
            local left = headScreen.X - width / 2
            d.Box.Position = Vector2.new(left, top)
            d.Box.Size = Vector2.new(width, height)
            d.Box.Visible = true
            d.Box.Color = isTeamMate(player) and Settings.Colors.Team or Settings.Colors.Enemy
        else
            d.Box.Visible = false
        end
        -- Name
        if Settings.ESP.Name then
            d.Name.Text = player.Name
            d.Name.Position = Vector2.new(headScreen.X, top - 16)
            d.Name.Visible = true
        else
            d.Name.Visible = false
        end
        -- Distance
        if Settings.ESP.Distance then
            local camera = Workspace.CurrentCamera
            local dist = camera and (camera.CFrame.Position - head.Position).Magnitude or 0
            d.Distance.Text = string.format("%d studs", math.floor(dist))
            d.Distance.Position = Vector2.new(headScreen.X, top - 30)
            d.Distance.Visible = true
        else
            d.Distance.Visible = false
        end
        -- Health
        if Settings.ESP.Health then
            local health = humanoid.Health / humanoid.MaxHealth
            local barHeight = (bottom - top) * health
            d.Health.From = Vector2.new(left - 4, bottom)
            d.Health.To = Vector2.new(left - 4, bottom - barHeight)
            d.Health.Visible = true
            d.Health.Color = Settings.Colors.Health
        else
            d.Health.Visible = false
        end
        -- Tracer
        if Settings.ESP.Tracer then
            local camera = Workspace.CurrentCamera
            local screenBottom = camera and Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y) or Vector2.new(0, 0)
            d.Tracer.From = screenBottom
            d.Tracer.To = headScreen
            d.Tracer.Visible = true
            d.Tracer.Color = isTeamMate(player) and Settings.Colors.Team or Settings.Colors.Enemy
        else
            d.Tracer.Visible = false
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Settings.Aimbot.Key then
        aiming = true
    end
    if input.KeyCode == Enum.KeyCode.F1 then
        Settings.Aimbot.Enabled = not Settings.Aimbot.Enabled
    end
    if input.KeyCode == Enum.KeyCode.F2 then
        Settings.ESP.Enabled = not Settings.ESP.Enabled
        if not Settings.ESP.Enabled then
            for _, d in pairs(Drawings) do
                for _, obj in pairs(d) do obj.Visible = false end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Settings.Aimbot.Key then
        aiming = false
    end
end)

RunService.RenderStepped:Connect(function()
    local camera = Workspace.CurrentCamera
    if not camera then return end

    if Settings.Aimbot.Enabled and aiming then
        FOVCircle.Visible = true
        FOVCircle.Position = camera.ViewportSize / 2
        FOVCircle.Radius = Settings.Aimbot.FOV
        local target = getClosestPlayer()
        if target then
            aimAt(target)
        end
    else
        FOVCircle.Visible = false
    end

    if Settings.ESP.Enabled then
        updateESP()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end

print("[Lokeii] Delta aimbot + ESP loaded. F1 toggle aimbot, F2 toggle ESP, hold right mouse to aim.")
