local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")

-- جعل السكربت مفعل تلقائياً (ON) عند التشغيل
local autoStealEnabled = true
local learnedRestockTime = 0 
local timeRemaining = 0
local lastRestockTick = tick()
local lastEggCount = 0

local targetRarities = {
    {name = "divine", value = 3},
    {name = "secret", value = 2},
    {name = "eternal", value = 1}
}

-- ==========================================
-- 1. واجهة المستخدم (Mobile UI)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui") or player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- الزر العائم لإظهار/إخفاء الواجهة
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

-- القائمة الرئيسية
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 220)
MainFrame.Position = UDim2.new(0.5, -130, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(140, 50, 255)
Title.Text = "Smart Restock Sniper"
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
TimerLabel.Size = UDim2.new(1, -10, 0, 30)
TimerLabel.Position = UDim2.new(0, 5, 0, 50)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Text = "Waiting for 1st Restock..."
TimerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
TimerLabel.TextSize = 16
TimerLabel.Font = Enum.Font.SourceSansBold
TimerLabel.TextScaled = true
TimerLabel.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 30)
StatusLabel.Position = UDim2.new(0, 10, 0, 85)
StatusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
StatusLabel.Text = "Scanning Map..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 16
StatusLabel.Font = Enum.Font.SourceSansSemibold
StatusLabel.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 50)
ToggleBtn.Position = UDim2.new(0, 10, 1, -60)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- أخضر افتراضياً
ToggleBtn.Text = "Snipe on Restock: ON"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 18
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Parent = MainFrame

-- ==========================================
-- 2. أزرار الإخفاء والتعطيل
-- ==========================================
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

ToggleBtn.MouseButton1Click:Connect(function()
    autoStealEnabled = not autoStealEnabled
    if autoStealEnabled then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ToggleBtn.Text = "Snipe on Restock: ON"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleBtn.Text = "Snipe on Restock: OFF"
    end
end)

-- ==========================================
-- 3. دالة النقل والسرقة المحسّنة
-- ==========================================
local function teleportAndSteal(targetObj)
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart or not targetObj then return end
    
    -- إيجاد جزء المجسم لنقل اللاعب إليه
    local tpPart = targetObj:IsA("BasePart") and targetObj or targetObj.PrimaryPart or targetObj:FindFirstChildWhichIsA("BasePart", true)
    
    if tpPart then
        rootPart.CFrame = tpPart.CFrame
        
        -- إيجاد جزء اللمس لضمان أخذ البيضة
        local touchTransmitter = targetObj:FindFirstChildWhichIsA("TouchTransmitter", true)
        local touchPart = touchTransmitter and touchTransmitter.Parent or tpPart
        
        if firetouchinterest then
            firetouchinterest(rootPart, touchPart, 0)
            task.wait(0.05)
            firetouchinterest(rootPart, touchPart, 1)
        end
    end
end

-- ==========================================
-- 4. الفحص والتنفيذ المباشر
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        local currentEggs = 0
        local raresFound = {}
        
        if autoStealEnabled then
            for _, obj in pairs(workspace:GetDescendants()) do
                -- التعرف على البيض سواءً كان BasePart أو Model
                if obj.Name and (obj:IsA("BasePart") or obj:IsA("Model")) then
                    local name = string.lower(obj.Name)
                    for _, rarity in ipairs(targetRarities) do
                        if string.find(name, rarity.name) then
                            table.insert(raresFound, {inst = obj, val = rarity.value})
                            break
                        end
                    end
                end
                
                if obj:IsA("BasePart") and string.find(string.lower(obj.Name), "egg") then
                    currentEggs = currentEggs + 1
                end
            end
            
            -- سرقة البيض الأغلى فوراً عند إيجاده
            if #raresFound > 0 then
                table.sort(raresFound, function(a, b) return a.val > b.val end)
                StatusLabel.Text = "Sniping Rare Egg!"
                StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
                
                for _, rare in ipairs(raresFound) do
                    teleportAndSteal(rare.inst)
                    task.wait(0.1)
                end
            else
                StatusLabel.Text = "Scanning Map..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
        
        -- حساب وقت الريستوك بدقة عند زيادة البيض
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
                TimerLabel.Text = "Map Timer: 0s (Waiting for map...)"
            end
        end
    end
end)
