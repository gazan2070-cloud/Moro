-- ============================================================
-- KUKIRIN AUTO STANT | GUI + AC BYPASS
-- ============================================================

-- ======================== AC-МОДУЛЬ =========================
local function loadAnticheatBypass()
    local AC = {}
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local LocalPlayer = Players.LocalPlayer

    -- 1. safeTeleport: 4 уровня fallback
    function AC.safeTeleport(targetCFrame)
        local char = LocalPlayer.Character
        if not char then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end

        -- Уровень 1: Anchored + пошаговое движение
        local ok1 = pcall(function()
            hrp.Anchored = true
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            local start = hrp.CFrame.Position
            local target = targetCFrame.Position
            local dist = (target - start).Magnitude
            local steps = math.max(1, math.floor(dist / 7))
            for i = 1, steps do
                local alpha = i / steps
                -- Рандомизация ±15%
                local jitter = Vector3.new(
                    math.random(-15, 15) / 100,
                    math.random(-15, 15) / 100,
                    math.random(-15, 15) / 100
                )
                local pos = start:Lerp(target, alpha) + jitter
                hrp.CFrame = CFrame.new(pos)
                RunService.Heartbeat:Wait()
                task.wait(math.random(3, 8) / 100) -- 0.03–0.08 сек
            end
            hrp.Anchored = false
        end)
        if ok1 and (hrp.CFrame.Position - targetCFrame.Position).Magnitude < 5 then
            return true
        end

        -- Уровень 2: TweenService
        local ok2 = pcall(function()
            local tween = TweenService:Create(hrp, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
            tween:Play()
            tween.Completed:Wait()
        end)
        if ok2 and (hrp.CFrame.Position - targetCFrame.Position).Magnitude < 5 then
            return true
        end

        -- Уровень 3: прямой CFrame
        local ok3 = pcall(function()
            hrp.CFrame = targetCFrame
        end)
        if ok3 then return true end

        -- Уровень 4: Humanoid:MoveTo
        local ok4 = pcall(function()
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:MoveTo(targetCFrame.Position)
                humanoid.MoveToFinished:Wait()
            end
        end)
        return ok4
    end

    -- 2. Спуф позиции через __index
    pcall(function()
        local mt = getrawmetatable(game)
        local oldIndex = mt.__index
        setreadonly(mt, false)
        mt.__index = newcclosure(function(self, key)
            if not checkcaller() then
                local caller = getcallingscript and getcallingscript() or nil
                if caller and caller.Name:lower():find("anticheat") then
                    if key == "Position" or key == "CFrame" or key == "AssemblyLinearVelocity" then
                        return Vector3.zero
                    end
                end
            end
            return oldIndex(self, key)
        end)
        setreadonly(mt, true)
    end)

    -- 3. Защита от Kick через __namecall
    pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" and not checkcaller() then
                warn("[AC-BYPASS] Kick blocked")
                return
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)

    -- 4. Отключение античит-сигналов (если найдены)
    pcall(function()
        for _, obj in pairs(getnilinstances and getnilinstances() or {}) do
            if obj.Name:lower():find("anticheat") or obj.Name:lower():find("detect") then
                if getconnections then
                    for _, conn in pairs(getconnections(obj.Changed)) do
                        conn:Disconnect()
                    end
                end
            end
        end
    end)

    return AC
end

local AC = loadAnticheatBypass()
warn("[KUKIRIN] AC-модуль загружен")

-- ======================== GUI =========================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Kukirin Stant",
    LoadingTitle = "Загрузка Kukirin Stant...",
    LoadingSubtitle = "by AI",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "KukirinStant",
        FileName = "Config"
    },
    KeySystem = false,
    Icon = 4483362458 -- иконка скутера (ASSET ID)
})

local MainTab = Window:CreateTab("Main", 4483362458)
local MainSection = MainTab:CreateSection("Управление скутером")

-- ======================== ЛОГИКА =========================
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local autoStantEnabled = false
local autoGasEnabled = false
local maxSpeedEnabled = false

-- Получить текущий VehicleSeat
local function getScooter()
    local char = LocalPlayer.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local seat = humanoid.SeatPart
    if seat and seat:IsA("VehicleSeat") then
        return seat
    end
    return nil
end

-- Эмуляция нажатия клавиши (fallback: VirtualInputManager → keypress)
local function pressKey(keyCode)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    end)
end

local function releaseKey(keyCode)
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

-- Цикл Auto Stant
local function autoStantLoop()
    while autoStantEnabled do
        local scooter = getScooter()
        if scooter then
            -- Эмуляция Shift с рандомизацией интервала
            pressKey(Enum.KeyCode.LeftShift)
            task.wait(math.random(4, 7) / 100) -- 0.04–0.07 сек
            releaseKey(Enum.KeyCode.LeftShift)
        end
        task.wait(math.random(8, 12) / 100) -- 0.08–0.12 сек
    end
end

-- Цикл Auto Gas
local function autoGasLoop()
    while autoGasEnabled do
        pcall(function()
            pressKey(Enum.KeyCode.W)
        end)
        task.wait(0.1)
    end
    pcall(function()
        releaseKey(Enum.KeyCode.W)
    end)
end

-- Применить Max Speed
local function applyMaxSpeed()
    local scooter = getScooter()
    if scooter then
        pcall(function()
            scooter.MaxSpeed = 500
        end)
        pcall(function()
            local bodyVelocity = scooter:FindFirstChildOfClass("BodyVelocity")
            if bodyVelocity then
                bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bodyVelocity.Velocity = scooter.CFrame.LookVector * 500
            end
        end)
        pcall(function()
            local bodyAngular = scooter:FindFirstChildOfClass("BodyAngularVelocity")
            if bodyAngular then
                bodyAngular.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            end
        end)
    end
end

-- ======================== КНОПКИ GUI =========================
MainSection:CreateToggle({
    Name = "Auto Stant (бесконечный стант)",
    CurrentValue = false,
    Flag = "AutoStant",
    Callback = function(value)
        autoStantEnabled = value
        if value then
            task.spawn(autoStantLoop)
        end
    end
})

MainSection:CreateToggle({
    Name = "Auto Gas (удержание газа)",
    CurrentValue = false,
    Flag = "AutoGas",
    Callback = function(value)
        autoGasEnabled = value
        if value then
            task.spawn(autoGasLoop)
        end
    end
})

MainSection:CreateToggle({
    Name = "Max Speed (макс. скорость)",
    CurrentValue = false,
    Flag = "MaxSpeed",
    Callback = function(value)
        maxSpeedEnabled = value
        if value then
            task.spawn(function()
                while maxSpeedEnabled do
                    applyMaxSpeed()
                    task.wait(0.5)
                end
            end)
        end
    end
})

-- ======================== RESPAWN =========================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2) -- ожидание загрузки персонажа
    if autoStantEnabled then
        task.spawn(autoStantLoop)
    end
    if autoGasEnabled then
        task.spawn(autoGasLoop)
    end
end)

-- Загрузка сохранённой конфигурации
pcall(function()
    Rayfield:LoadConfiguration()
end)

warn("[KUKIRIN] Скрипт успешно загружен. Открой меню.")
