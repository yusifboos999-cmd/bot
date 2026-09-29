local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local autoStealEnabled = true
local learnedRestockTime = 0 
local timeRemaining = 0
local lastRestockTick = tick()
local lastEggCount = 0

-- قائمة أعلى 5 حيوانات من حيث الأرباح مع الصورة والدخل والدرجة
local topPets = {
    ["aetheron"] = {name = "Aetheron", income = "$6.9B/s", icon = "rbxassetid://13893339121", priority = 10},
    ["archangel"] = {name = "ArchAngel", income = "$5.0B/s", icon = "rbxassetid://13893339121", priority = 9},
    ["world burner"] = {name = "World Burner", income = "$5.0B/s", icon = "rbxassetid://13893339121", priority = 9},
    ["shattered colossus"] = {name = "Shattered Colossus", income = "$3.5B/s", icon = "rbxassetid://13893339121", priority = 8},
    ["nightflame"] = {name = "Nightflame", income = "$3.0B/s", icon = "rbxassetid://13893339121", priority = 7},
    ["kitsune"] = {name = "Kitsune", income = "$1.8B/s", icon = "rbxassetid://13893339121", priority = 6}
}

-- النادريات العامة لشامل حيوانات الماب
local generalRarities = {
    {name = "divine", priority = 5},
    {name = "eternal", priority = 4},
    {name = "secret", priority = 3},
    {name = "cosmic", priority = 2},
    {name = "mythic", priority = 1}
}

-- ==========================================
-- 1. دالة تصفية بيسات القرى والمقرات (Plots/SafeZones)
-- ==========================================
local function isEggInBase(obj)
    local current = obj
    while current and current ~= workspace do
        local name = string.lower(current.Name)
        if string.find(name, "plot") 
           or string.find(name, "base") 
           or string.find(name, "incubator") 
           or string.find(name, "safezone") 
           or string.find(name, "safe zone") 
           or string.find(name, "pen") 
           or string.find(name, "growing") 
           or string.find(name, "tycoon") 
           or string.find(name, "claim") 
           or string.find(name, "house") then
            return true
        end
        current = current.Parent
    end
    return false
end

-- ==========================================
-- 2. واجهة المستخدم (Mobile UI)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StealEggHighPerfUI"
ScreenGui.Parent = game:GetService("CoreGui") or player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 45, 0, 45)
OpenBtn.Position = UDim2.new(0, 10, 0.4, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(140, 50, 255)
OpenBtn.Text = "UI"
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.TextSize = 16
OpenBtn.Font = Enum.Font.SourceSansBold
OpenBtn.Active = true
OpenBtn.Draggable = true 
OpenBtn.Parent = ScreenGui

local UICornerOpen = Instance.new("UICorner")
UICornerOpen.CornerRadius = UDim.new(0, 10)
UICornerOpen.Parent = OpenBtn

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 270, 0, 280)
MainFrame.Position = UDim2.new(0.5, -135, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui

local UICornerFrame = Instance.new("UICorner")
UICornerFrame.CornerRadius = UDim.new(0, 12)
UICornerFrame.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(140, 50, 255)
Title.Text = "High Performance Sniper"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.Parent = MainFrame

local TimerLabel = Instance.new("TextLabel")
TimerLabel.Size = UDim2.new(1, -10, 0, 25)
TimerLabel.Position = UDim2.new(0, 5, 0, 45)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Text = "Waiting for 1st Restock..."
TimerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
TimerLabel.TextSize = 15
TimerLabel.Font = Enum.Font.SourceSansBold
TimerLabel.Parent = MainFrame

-- صورة الحيوان النادر عند الاكتشاف
local PetImage = Instance.new("ImageLabel")
PetImage.Size = UDim2.new(0, 55, 0, 55)
PetImage.Position = UDim2.new(0.5, -27, 0, 75)
PetImage.BackgroundTransparency = 1
PetImage.Visible = false
PetImage.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 45)
StatusLabel.Position = UDim2.new(0, 10, 0, 135)
StatusLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
StatusLabel.Text = "Scanning Map (Max Speed)..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.SourceSansSemibold
StatusLabel.TextWrapped = true
StatusLabel.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 45)
ToggleBtn.Position = UDim2.new(0, 10, 1, -55)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
ToggleBtn.Text = "Snipe All Pets: ON"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 18
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Parent = MainFrame

-- ==========================================
-- 3. أزرار التحكم
-- ==========================================
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
OpenBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

ToggleBtn.MouseButton1Click:Connect(function()
    autoStealEnabled = not autoStealEnabled
    if autoStealEnabled then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ToggleBtn.Text = "Snipe All Pets: ON"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleBtn.Text = "Snipe All Pets: OFF"
    end
end)

-- ==========================================
-- 4. دالة السرقة والنقل الفوري السريع
-- ==========================================
local function teleportAndSteal(targetObj)
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart or not targetObj then return end
    
    local tpPart = targetObj:IsA("BasePart") and targetObj or targetObj.PrimaryPart or targetObj:FindFirstChildWhichIsA("BasePart", true)
    
    if tpPart then
        rootPart.CFrame = tpPart.CFrame
        
        local touchTransmitter = targetObj:FindFirstChildWhichIsA("TouchTransmitter", true)
        local touchPart = touchTransmitter and touchTransmitter.Parent or tpPart
        
        if firetouchinterest then
            firetouchinterest(rootPart, touchPart, 0)
            task.wait(0.02)
            firetouchinterest(rootPart, touchPart, 1)
        end
    end
end

-- ==========================================
-- 5. فحص وسرقة الهدف
-- ==========================================
local function checkAndStealObject(obj)
    if not autoStealEnabled or isEggInBase(obj) then return end
    
    if obj.Name and (obj:IsA("BasePart") or obj:IsA("Model")) then
        local objName = string.lower(obj.Name)
        
        -- الفحص أولاً في قائمة Top 5
        for key, info in pairs(topPets) do
            if string.find(objName, key) then
                PetImage.Image = info.icon
                PetImage.Visible = true
                StatusLabel.Text = "SNIPING TOP PET!\n" .. info.name .. " (" .. info.income .. ")"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                teleportAndSteal(obj)
                return
            end
        end
        
        -- الفحص في بقية النادريات
        for _, rarity in ipairs(generalRarities) do
            if string.find(objName, rarity.name) then
                PetImage.Visible = false
                StatusLabel.Text = "Sniping Rare Egg/Pet..."
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
                teleportAndSteal(obj)
                return
            end
        end
    end
end

-- الاستجابة الفورية عند رسبنة بيضة جديدة في الماب مباشرة
workspace.DescendantAdded:Connect(function(descendant)
    task.spawn(function()
        checkAndStealObject(descendant)
    end)
end)

-- ==========================================
-- 6. الحلقة الرئيسية الدورية (للمسح الشامل وحاسبة الوقت)
-- ==========================================
task.spawn(function()
    while task.wait(0.25) do
        local currentEggs = 0
        local targetsFound = {}
        
        if autoStealEnabled then
            for _, obj in pairs(workspace:GetDescendants()) do
                if not isEggInBase(obj) then
                    if obj.Name and (obj:IsA("BasePart") or obj:IsA("Model")) then
                        local objName = string.lower(obj.Name)
                        
                        local isTop = false
                        for key, info in pairs(topPets) do
                            if string.find(objName, key) then
                                table.insert(targetsFound, {inst = obj, val = info.priority, info = info})
                                isTop = true
                                break
                            end
                        end
                        
                        if not isTop then
                            for _, rarity in ipairs(generalRarities) do
                                if string.find(objName, rarity.name) then
                                    table.insert(targetsFound, {inst = obj, val = rarity.priority, info = nil})
                                    break
                                end
                            end
                        end
                    end
                    
                    if obj:IsA("BasePart") and string.find(string.lower(obj.Name), "egg") then
                        currentEggs = currentEggs + 1
                    end
                end
            end
            
            if #targetsFound > 0 then
                table.sort(targetsFound, function(a, b) return a.val > b.val end)
                local bestTarget = targetsFound[1]
                
                if bestTarget.info then
                    PetImage.Image = bestTarget.info.icon
                    PetImage.Visible = true
                    StatusLabel.Text = "SNIPING TOP PET!\n" .. bestTarget.info.name .. " (" .. bestTarget.info.income .. ")"
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                else
                    PetImage.Visible = false
                    StatusLabel.Text = "Sniping Rare Egg/Pet..."
                    StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
                end
                
                for _, target in ipairs(targetsFound) do
                    teleportAndSteal(target.inst)
                    task.wait(0.05)
                end
            else
                PetImage.Visible = false
                StatusLabel.Text = "Scanning Map (Max Speed)..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
        
        -- حساب وقت الريستوك والتوقيت
        if currentEggs >= lastEggCount + 5 then
            local interval = math.floor(tick() - lastRestockTick)
            if interval > 15 then
                learnedRestockTime = interval
            end
            lastRestockTick = tick()
            timeRemaining = learnedRestockTime
        end
        
        lastEggCount = currentEggs
        
        if learnedRestockTime > 0 then
            if timeRemaining > 0 then
                timeRemaining = timeRemaining - 1
                TimerLabel.Text = "Map Timer: " .. timeRemaining .. "s"
            else
                TimerLabel.Text = "Map Timer: 0s (Waiting...)"
            end
        end
    end
end)
