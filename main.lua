local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")

-- إعدادات السكربت
local autoStealEnabled = false
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "Snipe on Restock: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 18
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Parent = MainFrame

-- ==========================================
-- 2. نظام الفحص والسرقة الذكي
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

-- حلقة تعمل كل ثانية لفحص الماب بالكامل
task.spawn(function()
    while task.wait(1) do
        local currentEggs = 0
        local raresFound = {}
        
        -- فحص جميع المجسمات مرة واحدة فقط لتجنب اللاق
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj:FindFirstChild("TouchInterest") then
                currentEggs = currentEggs + 1
                
                if autoStealEnabled then
                    local name = string.lower(obj.Name)
                    for _, rarity in ipairs(targetRarities) do
                        if string.find(name, rarity.name) then
                            table.insert(raresFound, {inst = obj, val = rarity.value})
                            break
                        end
                    end
                end
            end
        end
        
        -- إذا وجد بيض نادر، يسرقه فوراً (يرتب من الأغلى للأرخص)
        if #raresFound > 0 and autoStealEnabled then
            table.sort(raresFound, function(a, b) return a.val > b.val end)
            StatusLabel.Text = "Sniping Rare Egg!"
            StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
            for _, rare in ipairs(raresFound) do
                teleportAndSteal(rare.inst)
            end
        else
            StatusLabel.Text = "Scanning Map..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        
        -- اكتشاف الريستوك الحقيقي (إذا زاد عدد البيض فجأة بأكثر من 10 بيضات)
        if currentEggs >= lastEggCount + 10 then
            local interval = math.floor(tick() - lastRestockTick)
            
            -- حفظ الوقت الدقيق للماب (نتجاهل الأوقات القصيرة جداً لمنع الأخطاء)
            if interval > 20 then
                learnedRestockTime = interval
            end
            
            lastRestockTick = tick()
            timeRemaining = learnedRestockTime
        end
        
        lastEggCount = currentEggs
        
        -- عرض المؤقت
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
