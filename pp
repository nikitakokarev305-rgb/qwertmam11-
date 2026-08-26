local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Очистка старого интерфейса
local TargetGui = LocalPlayer:WaitForChild("PlayerGui")
if TargetGui:FindFirstChild("CutJungleFarmV3") then
    TargetGui.CutJungleFarmV3:Destroy()
end

-- Переменные состояния
local farmActive = false
local rebirthActive = false
local savedCFrame = nil
local targetWins = 10
local startWins = 0
local customSpeed = 16
local customJump = 50

-- Поиск функции Rebirth
local function triggerRebirth()
    for _, item in ipairs(ReplicatedStorage:GetDescendants()) do
        if item:IsA("RemoteEvent") or item:IsA("RemoteFunction") then
            local name = item.Name:lower()
            if name:find("rebirth") or name:find("reborn") then
                if item:IsA("RemoteEvent") then
                    item:FireServer()
                elseif item:IsA("RemoteFunction") then
                    item:InvokeServer()
                end
            end
        end
    end
end

-- Получение побед из leaderstats
local function getPlayerWins()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            local name = stat.Name:lower()
            if name:find("win") or name:find("победы") then
                return stat.Value
            end
        end
    end
    return 0
end

-- Создание GUI (компактное под телефон)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CutJungleFarmV3"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 160, 0, 275)
Frame.Position = UDim2.new(0.05, 0, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderColor3 = Color3.fromRGB(100, 100, 100)
Frame.BorderSizePixel = 1
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

-- 1. Кнопка сохранения финиша
local SetBtn = Instance.new("TextButton")
SetBtn.Size = UDim2.new(0.9, 0, 0, 26)
SetBtn.Position = UDim2.new(0.05, 0, 0.03, 0)
SetBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
SetBtn.Text = "1. Сохранить Финиш"
SetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SetBtn.Font = Enum.Font.SourceSansBold
SetBtn.TextSize = 12
SetBtn.Parent = Frame

-- 2. Ввод побед
local WinsInput = Instance.new("TextBox")
WinsInput.Size = UDim2.new(0.9, 0, 0, 24)
WinsInput.Position = UDim2.new(0.05, 0, 0.17, 0)
WinsInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
WinsInput.Text = "10"
WinsInput.PlaceholderText = "Кол-во побед"
WinsInput.TextColor3 = Color3.fromRGB(255, 255, 255)
WinsInput.Font = Enum.Font.SourceSans
WinsInput.TextSize = 12
WinsInput.Parent = Frame

-- 3. Настройка скорости (Speed)
local SpeedInput = Instance.new("TextBox")
SpeedInput.Size = UDim2.new(0.9, 0, 0, 24)
SpeedInput.Position = UDim2.new(0.05, 0, 0.31, 0)
SpeedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SpeedInput.Text = "16"
SpeedInput.PlaceholderText = "Скорость (WalkSpeed)"
SpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedInput.Font = Enum.Font.SourceSans
SpeedInput.TextSize = 12
SpeedInput.Parent = Frame

-- 4. Настройка прыжка (Jump)
local JumpInput = Instance.new("TextBox")
JumpInput.Size = UDim2.new(0.9, 0, 0, 24)
JumpInput.Position = UDim2.new(0.05, 0, 0.45, 0)
JumpInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
JumpInput.Text = "50"
JumpInput.PlaceholderText = "Прыжок (JumpPower)"
JumpInput.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpInput.Font = Enum.Font.SourceSans
JumpInput.TextSize = 12
JumpInput.Parent = Frame

-- 5. Кнопка "Авто-Реберт"
local RebirthBtn = Instance.new("TextButton")
RebirthBtn.Size = UDim2.new(0.9, 0, 0, 26)
RebirthBtn.Position = UDim2.new(0.05, 0, 0.59, 0)
RebirthBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 180)
RebirthBtn.Text = "Авто-Реберт: ВЫКЛ"
RebirthBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RebirthBtn.Font = Enum.Font.SourceSansBold
RebirthBtn.TextSize = 12
RebirthBtn.Parent = Frame

-- 6. Кнопка Старт/Стоп Фарм
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 30)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.74, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
ToggleBtn.Text = "Старт Фарм"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 13
ToggleBtn.Parent = Frame

-- 7. Статус
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
StatusLabel.Position = UDim2.new(0.05, 0, 0.88, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Собрано: 0 / 10"
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 11
StatusLabel.Parent = Frame

-- Логика кнопок и полей ввода
SetBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        savedCFrame = root.CFrame
        SetBtn.Text = "Финиш сохранен!"
        SetBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        task.wait(1.5)
        SetBtn.Text = "Обновить точку"
    end
end)

WinsInput.FocusLost:Connect(function()
    local num = tonumber(WinsInput.Text)
    if num and num > 0 then targetWins = num else WinsInput.Text = tostring(targetWins) end
end)

SpeedInput.FocusLost:Connect(function()
    local num = tonumber(SpeedInput.Text)
    if num then customSpeed = num end
end)

JumpInput.FocusLost:Connect(function()
    local num = tonumber(JumpInput.Text)
    if num then customJump = num end
end)

RebirthBtn.MouseButton1Click:Connect(function()
    rebirthActive = not rebirthActive
    if rebirthActive then
        RebirthBtn.Text = "Авто-Реберт: ВКЛ"
        RebirthBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    else
        RebirthBtn.Text = "Авто-Реберт: ВЫКЛ"
        RebirthBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 180)
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    if not savedCFrame and not farmActive then
        ToggleBtn.Text = "Сохрани финиш!"
        task.wait(1.2)
        ToggleBtn.Text = "Старт Фарм"
        return
    end

    farmActive = not farmActive
    if farmActive then
        startWins = getPlayerWins()
        ToggleBtn.Text = "СТОП"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    else
        ToggleBtn.Text = "Старт Фарм"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
end)

-- Постоянное применение скорости, прыжка и телепорта
task.spawn(function()
    while true do
        task.wait(0.3)
        
        -- Применяем скорость и прыжок (даже если фарм выключен, это удобно)
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                pcall(function()
                    humanoid.WalkSpeed = customSpeed
                    -- Поддержка разных версий прыжков в Roblox
                    if humanoid.UseJumpPower then
                        humanoid.JumpPower = customJump
                    else
                        humanoid.JumpHeight = customJump / 5
                    end
                end)
            end
        end

        -- Логика фарма
        if farmActive and savedCFrame then
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = savedCFrame
                
                local currentTotal = getPlayerWins()
                local gained = currentTotal - startWins
                if gained < 0 then gained = 0 end
                
                StatusLabel.Text = "Собрано: " .. gained .. " / " .. targetWins
                
                if gained >= targetWins then
                    farmActive = false
                    ToggleBtn.Text = "ГОТОВО!"
                    ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                    task.wait(2)
                    ToggleBtn.Text = "Старт Фарм"
                end
            end
        end
    end
end)

-- Цикл реберта
task.spawn(function()
    while true do
        task.wait(1)
        if rebirthActive then
            triggerRebirth()
        end
    end
end)
