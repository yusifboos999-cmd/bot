local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")

-- إعدادات السكربت
local autoStealEnabled = false
local mapRestockTime = 60 -- الوقت الافتراضي للرسباون
local timeRemaining = 60  -- سيبدأ العد فوراً من 60
local lastRestockTick = tick()

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

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 220)
MainFrame.Position = UDim2.new(0.5, -130, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(140, 50, 255)
Title.Text = "Smart Restock Sniper"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

local TimerLabel = Instance.new("TextLabel")
TimerLabel.Size = UDim2.new(1, -20, 0, 30)
TimerLabel.Position = UDim2.new(0, 10, 0, 50)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Text = "Map Timer: 60s"
TimerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
TimerLabel.TextSize = 16
TimerLabel.Font = Enum.Font.SourceSansBold
TimerLabel.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 30)
StatusLabel.Position = UDim2.new(0, 10, 0, 85)
StatusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
StatusLabel.Text = "Active..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 16
StatusLabel.Font = Enum.Font.SourceSansSemibold
StatusLabel.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 50)
ToggleBtn.Position = UDim2.new(0, 10, 1, -60)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "Snipe on Restock: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 18
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Parent = MainFrame

-- ==========================================
-- 2. دوال الفحص والسرقة
-- ==========================================
local function teleportAndSteal(targetEgg)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if targetEgg and rootPart then
        rootPart.CFrame = targetEgg.CFrame
        if firetouchinterest then
            firetouchinterest(rootPart, targetEgg, 0)
            task.wait(0.05)
            firetouchinterest(rootPart, targetEgg, 1)
        end
    end
end

local function checkAndSnipe(obj)
    if not autoStealEnabled then return end
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then return end
    
    local eggName = string.lower(obj.Name)
    local isRare = false
    
    for _, rarity in ipairs(targetRarities) do
        if string.find(eggName, rarity.name) then
            isRare = true
            break
        end
    end
    
    if isRare then
        StatusLabel.Text = "Sniping: " .. obj.Name
        StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
        teleportAndSteal(obj:IsA("Model") and obj.PrimaryPart or obj)
    end
end

-- ==========================================
-- 3. نظام التوقيت المتزامن (Auto-Sync)
-- ==========================================
ToggleBtn.MouseButton1Click:Connect(function()
    autoStealEnabled = not autoStealEnabled
    if autoStealEnabled then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ToggleBtn.Text = "Snipe on Restock: ON"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleBtn.Text = "Snipe on Restock: OFF"
        StatusLabel.Text = "Active..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

-- مراقبة الماب فوراً بدون لوب ثقيل
workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.1) -- انتظار تحميل المجسم
    local objName = string.lower(obj.Name)
    
    -- إذا ظهرت بيضة جديدة، نقوم بتحديث المؤقت
    if string.find(objName, "egg") or obj:FindFirstChild("TouchInterest") then
        local newInterval = math.floor(tick() - lastRestockTick)
        if newInterval > 10 then 
            mapRestockTime = newInterval
        end
        
        lastRestockTick = tick()
        timeRemaining = mapRestockTime
        StatusLabel.Text = "Restock Detected!"
        
        checkAndSnipe(obj)
    end
end)

-- تشغيل المؤقت الظاهر على الشاشة
task.spawn(function()
    while task.wait(1) do
        if timeRemaining > 0 then
            timeRemaining = timeRemaining - 1
            TimerLabel.Text = "Map Timer: " .. timeRemaining .. "s"
        else
            TimerLabel.Text = "Map Timer: 0s (Waiting...)"
        end
    end
end)
