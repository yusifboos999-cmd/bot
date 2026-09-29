local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")

-- إعدادات السكربت
local autoStealEnabled = false
local mapRestockTime = 60 -- الوقت الافتراضي (سيقوم السكربت بتعديله تلقائياً ليطابق الماب)
local timeRemaining = 0
local lastEggCount = 0

-- ترتيب الندرات المستهدفة وقيمتها لسرقة الأغلى أولاً
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
MainFrame.Draggable = true -- سحب القائمة في الجوال
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(140, 50, 255)
Title.Text = "Smart Restock Sniper"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

-- مؤقت الماب
local TimerLabel = Instance.new("TextLabel")
TimerLabel.Size = UDim2.new(1, -20, 0, 30)
TimerLabel.Position = UDim2.new(0, 10, 0, 50)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Text = "Syncing with Map..."
TimerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
TimerLabel.TextSize = 16
TimerLabel.Font = Enum.Font.SourceSansBold
TimerLabel.Parent = MainFrame

-- حالة الرسباون (هل رسبن شيء أم لا؟)
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 30)
StatusLabel.Position = UDim2.new(0, 10, 0, 85)
StatusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
StatusLabel.Text = "Waiting for restock..."
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

-- دالة لمعرفة إجمالي عدد البيض حالياً في الماب
local function getTotalEggs()
    local count = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj:FindFirstChild("TouchInterest") then
            count = count + 1
        end
    end
    return count
end

-- دالة النقل الفوري والسرقة
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

-- دالة البحث عن البيض النادر عند حدوث الريسباون
local function snipeRareEggs()
    local rareEggsFound = {}
    
    -- البحث في الماب
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj:FindFirstChild("TouchInterest") then
            local eggName = string.lower(obj.Name)
            for _, rarity in ipairs(targetRarities) do
                if string.find(eggName, rarity.name) then
                    table.insert(rareEggsFound, {instance = obj, priority = rarity.value, name = obj.Name})
                    break
                end
            end
        end
    end
    
    -- إذا لم يرسبن شيء من الندرات المطلوبة
    if #rareEggsFound == 0 then
        StatusLabel.Text = "لم يرسبن أي شيء!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80) -- لون أحمر
        return
    end
    
    -- إذا وجد بيض نادر، يرتبه لسرقة الأغلى أولاً (Divine > Secret > Eternal)
    table.sort(rareEggsFound, function(a, b)
        return a.priority > b.priority
    end)
    
    StatusLabel.Text = "تم إيجاد بيض نادر! جاري السرقة..."
    StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80) -- لون أخضر
    
    -- سرقة البيض بالترتيب
    for _, eggData in ipairs(rareEggsFound) do
        if eggData.instance and eggData.instance.Parent ~= nil then
            teleportAndSteal(eggData.instance)
            task.wait(0.1) -- فاصل بسيط جداً لتجنب اللاق
        end
    end
end

-- ==========================================
-- 3. نظام التوقيت المتزامن (Auto-Sync)
-- ==========================================

-- زر التفعيل
ToggleBtn.MouseButton1Click:Connect(function()
    autoStealEnabled = not autoStealEnabled
    if autoStealEnabled then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ToggleBtn.Text = "Snipe on Restock: ON"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleBtn.Text = "Snipe on Restock: OFF"
        StatusLabel.Text = "Waiting..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

-- حلقة المراقبة (تعمل كل ثانية)
local lastRestockTick = tick()

task.spawn(function()
    lastEggCount = getTotalEggs()
    
    while task.wait(1) do
        local currentEggs = getTotalEggs()
        
        -- إذا زاد عدد البيض فجأة بأكثر من 5 بيضات، هذا يعني أن الماب عمل (Restock)
        if currentEggs > lastEggCount + 5 then
            -- حساب الوقت بين آخر ريسباون وهذا الريسباون لضبط توقيت الماب بدقة
            local newInterval = math.floor(tick() - lastRestockTick)
            if newInterval > 10 then -- لضمان عدم حدوث خطأ
                mapRestockTime = newInterval
            end
            
            lastRestockTick = tick()
            timeRemaining = mapRestockTime
            
            -- فحص وسرقة البيض النادر إذا كان الزر مفعلاً
            if autoStealEnabled then
                snipeRareEggs()
            else
                StatusLabel.Text = "Restock Detected!"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
        
        lastEggCount = currentEggs
        
        -- تحديث المؤقت الظاهر على الشاشة
        if timeRemaining > 0 then
            timeRemaining = timeRemaining - 1
            TimerLabel.Text = "Map Timer: " .. timeRemaining .. "s"
        else
            -- إذا انتهى الوقت ولم يرسبن (يحدث إذا تأخر الماب ثانية أو ثانيتين)
            TimerLabel.Text = "Map Timer: 0s (Waiting...)"
        end
    end
end)
