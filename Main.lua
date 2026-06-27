-- ==========================================
-- NEBULA FARM v4.0 - МОБИЛЬНАЯ ВЕРСИЯ
-- Телепорт к коробкам + автоклик E
-- ==========================================

local player = game.Players.LocalPlayer
local char = player.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local farm = false
local boxPositions = {}
local busy = false

-- ===== НАСТРОЙКИ =====
local TELEPORT_DELAY = 0.5
local BOX_DELAY = 0.8
local CYCLE_DELAY = 1.0
local CLICK_DELAY = 0.25

-- ===== ПЕРЕМЕННЫЕ ДЛЯ ПЕРЕТАСКИВАНИЯ =====
local dragging = false
local dragStart = nil
local dragStartPos = nil

-- ===== СОЗДАНИЕ GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game:GetService("CoreGui")
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ОСНОВНАЯ РАМКА
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 280)
frame.Position = UDim2.new(0.5, -200, 0.5, -140)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
frame.BackgroundTransparency = 0
frame.ClipsDescendants = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 20)
frameCorner.Parent = frame

-- НЕОНОВАЯ ОБВОДКА
local glowStroke = Instance.new("UIStroke")
glowStroke.Color = Color3.fromRGB(100, 50, 255)
glowStroke.Thickness = 2
glowStroke.Transparency = 0.3
glowStroke.Parent = frame

-- ВНУТРЕННЯЯ ПОДЛОЖКА
local innerBg = Instance.new("Frame")
innerBg.Size = UDim2.new(0.97, 0, 0.97, 0)
innerBg.Position = UDim2.new(0.015, 0, 0.015, 0)
innerBg.BackgroundColor3 = Color3.fromRGB(15, 15, 35)
innerBg.BackgroundTransparency = 0
innerBg.Parent = frame

local innerCorner = Instance.new("UICorner")
innerCorner.CornerRadius = UDim.new(0, 16)
innerCorner.Parent = innerBg

-- ===== ЗАГОЛОВОК =====
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundTransparency = 0
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 45)
titleBar.Parent = innerBg

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- ГРАДИЕНТНЫЙ БАР
local gradientBar = Instance.new("Frame")
gradientBar.Size = UDim2.new(1, 0, 0, 3)
gradientBar.Position = UDim2.new(0, 0, 1, -3)
gradientBar.BackgroundColor3 = Color3.fromRGB(100, 50, 255)
gradientBar.Parent = titleBar

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 50, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 50, 255))
})
gradient.Parent = gradientBar

-- ЛОГО
local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(0, 35, 0, 35)
logo.Position = UDim2.new(0, 12, 0, 8)
logo.BackgroundTransparency = 1
logo.Text = "✦"
logo.TextColor3 = Color3.fromRGB(150, 100, 255)
logo.TextScaled = true
logo.Font = Enum.Font.GothamBold
logo.Parent = titleBar

-- ЗАГОЛОВОК
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 52, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "NEBULA FARM"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = titleBar

-- КНОПКИ УПРАВЛЕНИЯ
local function createTitleButton(text, color, hoverColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 35, 0, 35)
    btn.Position = UDim2.new(0, 0, 0, 8)
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = 0.2
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = titleBar
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)
    
    return btn
end

local minimizeBtn = createTitleButton("─", Color3.fromRGB(40, 40, 60), Color3.fromRGB(60, 60, 80))
minimizeBtn.Position = UDim2.new(0.85, 0, 0, 8)

local closeBtn = createTitleButton("✕", Color3.fromRGB(50, 20, 20), Color3.fromRGB(200, 50, 50))
closeBtn.Position = UDim2.new(0.92, 0, 0, 8)

-- ===== ПЕРЕТАСКИВАНИЕ ДЛЯ ТЕЛЕФОНА =====
-- Используем Touch вместо мыши
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        -- Проверяем, не нажали ли на кнопку
        local touchPos = input.Position
        local btnPos = minimizeBtn.AbsolutePosition
        local btnSize = minimizeBtn.AbsoluteSize
        local closePos = closeBtn.AbsolutePosition
        local closeSize = closeBtn.AbsoluteSize
        
        -- Если клик не по кнопкам
        if not (touchPos.X >= btnPos.X and touchPos.X <= btnPos.X + btnSize.X and 
                touchPos.Y >= btnPos.Y and touchPos.Y <= btnPos.Y + btnSize.Y) and
           not (touchPos.X >= closePos.X and touchPos.X <= closePos.X + closeSize.X and 
                touchPos.Y >= closePos.Y and touchPos.Y <= closePos.Y + closeSize.Y) then
            dragging = true
            dragStart = input.Position
            dragStartPos = frame.Position
        end
    end
end)

-- Отслеживаем движение пальца
UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position.X - dragStart.X
        local deltaY = input.Position.Y - dragStart.Y
        frame.Position = UDim2.new(
            dragStartPos.X.Scale,
            dragStartPos.X.Offset + delta,
            dragStartPos.Y.Scale,
            dragStartPos.Y.Offset + deltaY
        )
    end
end)

-- Отпускаем палец
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ===== КОНТЕНТ =====
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 0, 210)
content.Position = UDim2.new(0, 10, 0, 55)
content.BackgroundTransparency = 1
content.Parent = innerBg

-- СТАТУС
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, 0, 0, 42)
statusFrame.Position = UDim2.new(0, 0, 0, 0)
statusFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
statusFrame.BackgroundTransparency = 0.5
statusFrame.Parent = content

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 10)
statusCorner.Parent = statusFrame

local statusIcon = Instance.new("TextLabel")
statusIcon.Size = UDim2.new(0, 30, 1, 0)
statusIcon.Position = UDim2.new(0, 8, 0, 0)
statusIcon.BackgroundTransparency = 1
statusIcon.Text = "⏸"
statusIcon.TextColor3 = Color3.fromRGB(255, 100, 100)
statusIcon.TextScaled = true
statusIcon.Font = Enum.Font.GothamBold
statusIcon.Parent = statusFrame

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -45, 1, 0)
statusText.Position = UDim2.new(0, 45, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "ОСТАНОВЛЕН"
statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
statusText.TextScaled = true
statusText.Font = Enum.Font.GothamBold
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusFrame

-- ИНФО ПАНЕЛЬ
local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(1, 0, 0, 55)
infoFrame.Position = UDim2.new(0, 0, 0, 48)
infoFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
infoFrame.BackgroundTransparency = 0.5
infoFrame.Parent = content

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 10)
infoCorner.Parent = infoFrame

-- БОКСЫ
local boxesLabel = Instance.new("TextLabel")
boxesLabel.Size = UDim2.new(0.5, 0, 0.45, 0)
boxesLabel.Position = UDim2.new(0, 10, 0, 2)
boxesLabel.BackgroundTransparency = 1
boxesLabel.Text = "📦 0"
boxesLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
boxesLabel.TextScaled = true
boxesLabel.Font = Enum.Font.GothamBold
boxesLabel.TextXAlignment = Enum.TextXAlignment.Left
boxesLabel.Parent = infoFrame

local currentLabel = Instance.new("TextLabel")
currentLabel.Size = UDim2.new(0.5, 0, 0.45, 0)
currentLabel.Position = UDim2.new(0.5, 0, 0, 2)
currentLabel.BackgroundTransparency = 1
currentLabel.Text = "📍 0/0"
currentLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
currentLabel.TextScaled = true
currentLabel.Font = Enum.Font.GothamBold
currentLabel.TextXAlignment = Enum.TextXAlignment.Right
currentLabel.Parent = infoFrame

-- СТАТУС КЛИКА
local clickStatus = Instance.new("TextLabel")
clickStatus.Size = UDim2.new(0.5, 0, 0.45, 0)
clickStatus.Position = UDim2.new(0, 10, 0.5, 2)
clickStatus.BackgroundTransparency = 1
clickStatus.Text = "🖱 Клик: ВЫКЛ"
clickStatus.TextColor3 = Color3.fromRGB(255, 150, 150)
clickStatus.TextScaled = true
clickStatus.Font = Enum.Font.Gotham
clickStatus.TextXAlignment = Enum.TextXAlignment.Left
clickStatus.Parent = infoFrame

local delayLabel = Instance.new("TextLabel")
delayLabel.Size = UDim2.new(0.5, 0, 0.45, 0)
delayLabel.Position = UDim2.new(0.5, 0, 0.5, 2)
delayLabel.BackgroundTransparency = 1
delayLabel.Text = "⏱ 250 мс"
delayLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
delayLabel.TextScaled = true
delayLabel.Font = Enum.Font.Gotham
delayLabel.TextXAlignment = Enum.TextXAlignment.Right
delayLabel.Parent = infoFrame

-- КНОПКИ
local actionsFrame = Instance.new("Frame")
actionsFrame.Size = UDim2.new(1, 0, 0, 50)
actionsFrame.Position = UDim2.new(0, 0, 1, -50)
actionsFrame.BackgroundTransparency = 1
actionsFrame.Parent = content

-- ГЛАВНАЯ КНОПКА
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.48, -5, 1, 0)
toggleBtn.Position = UDim2.new(0, 0, 0, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
toggleBtn.BackgroundTransparency = 0
toggleBtn.Text = "▶ СТАРТ"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = actionsFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 12)
toggleCorner.Parent = toggleBtn

-- КНОПКА ПОИСКА
local findBtn = Instance.new("TextButton")
findBtn.Size = UDim2.new(0.48, -5, 1, 0)
findBtn.Position = UDim2.new(0.52, 0, 0, 0)
findBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
findBtn.BackgroundTransparency = 0
findBtn.Text = "🔍 ПОИСК"
findBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
findBtn.TextScaled = true
findBtn.Font = Enum.Font.GothamBold
findBtn.Parent = actionsFrame

local findCorner = Instance.new("UICorner")
findCorner.CornerRadius = UDim.new(0, 12)
findCorner.Parent = findBtn

-- ===== ХОВЕР ЭФФЕКТЫ =====
toggleBtn.MouseEnter:Connect(function()
    TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
end)
toggleBtn.MouseLeave:Connect(function()
    TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
end)

findBtn.MouseEnter:Connect(function()
    TweenService:Create(findBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
end)
findBtn.MouseLeave:Connect(function()
    TweenService:Create(findBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
end)

-- ===== СВЕРТЫВАНИЕ =====
local minimized = false
local savedSize = frame.Size

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(frame, TweenInfo.new(0.3), {Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, 55)}):Play()
        content.Visible = false
        minimizeBtn.Text = "□"
    else
        TweenService:Create(frame, TweenInfo.new(0.3), {Size = savedSize}):Play()
        content.Visible = true
        minimizeBtn.Text = "─"
    end
end)

-- ===== ПОИСК КОРОБОК =====
local function findBoxes()
    boxPositions = {}
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") then
            local partCount = 0
            local hasPrompt = false
            
            for _, child in pairs(v:GetDescendants()) do
                if child:IsA("Part") then
                    partCount = partCount + 1
                end
                if child:IsA("ProximityPrompt") then
                    hasPrompt = true
                end
            end
            
            if partCount == 15 and hasPrompt then
                local name = v.Name:lower()
                if not name:match("placement") and not name:match("sign") and not name:match("board") then
                    local center = v:GetPivot().Position
                    table.insert(boxPositions, center)
                end
            end
        end
    end
    
    boxesLabel.Text = "📦 " .. #boxPositions
    print("🔍 Найдено коробок:", #boxPositions)
end

findBoxes()
findBtn.MouseButton1Click:Connect(function()
    findBoxes()
    currentLabel.Text = "📍 0/" .. #boxPositions
end)

-- ===== ФУНКЦИЯ КЛИКА E =====
local function pressE()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

-- ===== ОСНОВНЫЕ ФУНКЦИИ =====
local function toggleFarm()
    farm = not farm
    if farm then
        if #boxPositions == 0 then findBoxes() end
        statusText.Text = "РАБОТАЕТ"
        statusText.TextColor3 = Color3.fromRGB(100, 255, 100)
        statusIcon.Text = "▶"
        statusIcon.TextColor3 = Color3.fromRGB(100, 255, 100)
        statusFrame.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        toggleBtn.Text = "⏹ СТОП"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        clickStatus.Text = "🖱 Клик: ВКЛ"
        clickStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
        busy = false
    else
        statusText.Text = "ОСТАНОВЛЕН"
        statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
        statusIcon.Text = "⏸"
        statusIcon.TextColor3 = Color3.fromRGB(255, 100, 100)
        statusFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
        toggleBtn.Text = "▶ СТАРТ"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        clickStatus.Text = "🖱 Клик: ВЫКЛ"
        clickStatus.TextColor3 = Color3.fromRGB(255, 150, 150)
        busy = false
    end
end

toggleBtn.MouseButton1Click:Connect(toggleFarm)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    farm = false
    busy = false
end)

UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.G then
        toggleFarm()
    end
end)

-- ===== ТЕЛЕПОРТ + АВТОКЛИК =====
local currentBox = 1

local function teleportToBoxes()
    if busy or not farm then return end
    busy = true
    
    task.spawn(function()
        if #boxPositions == 0 then
            findBoxes()
            busy = false
            return
        end
        
        if currentBox > #boxPositions then
            currentBox = 1
            currentLabel.Text = "📍 1/" .. #boxPositions
            statusText.Text = "НОВЫЙ КРУГ"
            task.wait(CYCLE_DELAY)
        end
        
        local pos = boxPositions[currentBox]
        currentLabel.Text = "📍 " .. currentBox .. "/" .. #boxPositions
        
        if root then
            root.CFrame = CFrame.new(pos) + Vector3.new(0, 2, 0)
            statusText.Text = "📦 " .. currentBox .. "/" .. #boxPositions
            task.wait(TELEPORT_DELAY)
            
            pressE()
            task.wait(CLICK_DELAY)
            pressE()
        end
        
        currentBox = currentBox + 1
        task.wait(BOX_DELAY)
        busy = false
    end)
end

RunService.Heartbeat:Connect(function()
    if farm then
        teleportToBoxes()
    end
end)

print("✦ NEBULA FARM v4.0 - МОБИЛЬНАЯ ВЕРСИЯ!")
print("📦 Найдено коробок:", #boxPositions)
print("🖱 Автоклик E с задержкой 250 мс")
print("👆 ТЯНИ ПАЛЬЦЕМ ЗА ЗАГОЛОВОК")
print("─ Сворачивай кнопкой в заголовке")
print("⌨ [G] - вкл/выкл")
