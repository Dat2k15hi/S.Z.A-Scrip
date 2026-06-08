--[[
    S.Z.A ULTIMATE HUB - by S.Z.A Scrip
    Tính năng: Instant Kill, Godmode (chống rớt + hồi máu, vẫn di chuyển), Đẩy Zombie, Auto Farm Void Shard, Auto Skip 1s, Anti Lag cực mạnh
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "S.Z.A Scrip",
    LoadingTitle = "by S.Z.A Scrip",
    LoadingSubtitle = "Đang tải...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SZA_Scrip",
        FileName = "Config"
    },
    KeySystem = false
})

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- ========== BIẾN TOÀN CỤC ==========
local isIK = false
local isGod = false
local isPush = false
local isFarm = false
local isSkip = false
local isAntiLag = false

local ikConnection = nil
local godConnection = nil
local pushConnection = nil
local farmConnection = nil
local skipConnection = nil
local antiLagLoop = nil

-- Cache remote damage
local DamageRemote = nil
local function getDamageRemote()
    if DamageRemote then return DamageRemote end
    DamageRemote = RS:FindFirstChild("ZombieRemotes") and RS.ZombieRemotes:FindFirstChild("ZombieDamage")
    if not DamageRemote then
        for _, v in ipairs(RS:GetDescendants()) do
            if v:IsA("RemoteEvent") and (v.Name:lower():find("damage") or v.Name:lower():find("hit")) then
                DamageRemote = v
                break
            end
        end
    end
    return DamageRemote
end

-- Lấy danh sách zombie
local function getZombies()
    local zombies = Workspace:FindFirstChild("Zombies_Local")
    if zombies then return zombies:GetChildren() end
    return {}
end

-- ==================== 1. INSTANT KILL ====================
local function startIK()
    if ikConnection then return end
    ikConnection = RunService.Heartbeat:Connect(function()
        if not isIK then return end
        local remote = getDamageRemote()
        if not remote then return end
        local zombies = getZombies()
        for _, z in ipairs(zombies) do
            if z:IsA("Model") then
                local hum = z:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local id = tonumber(z.Name:match("%d+"))
                    if id then
                        remote:FireServer(id, 999999999)
                    end
                end
            end
        end
    end)
end

local function stopIK()
    if ikConnection then ikConnection:Disconnect(); ikConnection = nil end
end

-- ==================== 2. GODMODE (CHỐNG RỚT + HỒI MÁU, VẪN DI CHUYỂN) ====================
local function startGod()
    if godConnection then return end
    local originalY = nil
    godConnection = RunService.Heartbeat:Connect(function()
        if not isGod then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if originalY == nil then
            originalY = hrp.Position.Y
        end
        if hrp.Position.Y < originalY - 0.5 then
            hrp.CFrame = CFrame.new(hrp.Position.X, originalY, hrp.Position.Z)
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
            hum.BreakJointsOnDeath = false
        end
    end)
end

local function stopGod()
    if godConnection then godConnection:Disconnect(); godConnection = nil end
end

-- ==================== 3. ĐẨY ZOMBIE ====================
local function startPush()
    if pushConnection then return end
    pushConnection = RunService.Heartbeat:Connect(function()
        if not isPush then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local playerPos = hrp.Position
        local zombies = getZombies()
        for _, z in ipairs(zombies) do
            if z:IsA("Model") then
                local zRoot = z:FindFirstChild("HumanoidRootPart") or z.PrimaryPart
                if zRoot then
                    local dist = (zRoot.Position - playerPos).Magnitude
                    if dist < 15 then
                        local dir = (zRoot.Position - playerPos).Unit
                        zRoot.CFrame = CFrame.new(playerPos + dir * 20)
                    end
                end
            end
        end
    end)
end

local function stopPush()
    if pushConnection then pushConnection:Disconnect(); pushConnection = nil end
end

-- ==================== 4. AUTO FARM VOID SHARD ====================
local function startFarm()
    if farmConnection then return end
    farmConnection = RunService.Heartbeat:Connect(function()
        if not isFarm then return end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name == "VoidShard" or (obj.Name and obj.Name:find("Shard"))) then
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - obj.Position).Magnitude < 40 then
                    local old = hrp.CFrame
                    hrp.CFrame = obj.CFrame
                    task.wait(0.05)
                    hrp.CFrame = old
                end
            end
        end
        for _, crate in ipairs(Workspace:GetDescendants()) do
            if crate:IsA("Model") and crate.Name == "GalacticCrate" then
                local cd = crate:FindFirstChildOfClass("ClickDetector")
                if cd then fireclickdetector(cd) end
            end
        end
        task.wait(0.15)
    end)
end

local function stopFarm()
    if farmConnection then farmConnection:Disconnect(); farmConnection = nil end
end

-- ==================== 5. AUTO SKIP WAVE ====================
local skipRemote = nil
local function findSkipRemote()
    if skipRemote then return skipRemote end
    local names = {"SkipWave", "SkipRound", "WaveSkip", "RoundSkip", "RequestSkip"}
    for _, p in ipairs({RS, RS:FindFirstChild("Remotes"), RS:FindFirstChild("Events")}) do
        if p then
            for _, n in ipairs(names) do
                local r = p:FindFirstChild(n)
                if r and (r:IsA("RemoteEvent") or r:IsA("BindableEvent")) then
                    skipRemote = r
                    return r
                end
            end
        end
    end
    return nil
end

local function startSkip()
    if skipConnection then return end
    skipConnection = RunService.Heartbeat:Connect(function()
        if not isSkip then return end
        local remote = findSkipRemote()
        if remote then
            local zombies = Workspace:FindFirstChild("Zombies_Local")
            local hasZombie = zombies and #zombies:GetChildren() > 0
            if not hasZombie then
                if remote:IsA("RemoteEvent") then
                    remote:FireServer()
                else
                    remote:Fire()
                end
            end
        end
        task.wait(1)
    end)
end

local function stopSkip()
    if skipConnection then skipConnection:Disconnect(); skipConnection = nil end
end

-- ==================== 6. ANTI LAG ====================
local savedSettings = {}
local function startAntiLag()
    savedSettings.Quality = settings().Rendering.QualityLevel
    savedSettings.Brightness = Lighting.Brightness
    savedSettings.GlobalShadows = Lighting.GlobalShadows
    savedSettings.FogEnd = Lighting.FogEnd
    
    settings().Rendering.QualityLevel = 1
    Lighting.Brightness = 0
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 0
    
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Decal") then
            v:Destroy()
        elseif v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        end
    end
    
    antiLagLoop = task.spawn(function()
        while isAntiLag and task.wait(10) do
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") then
                    v:Destroy()
                end
            end
        end
    end)
    
    Rayfield:Notify({Title = "Anti Lag", Content = "Đã bật! Game cực mượt.", Duration = 2})
end

local function stopAntiLag()
    settings().Rendering.QualityLevel = savedSettings.Quality or 10
    Lighting.Brightness = savedSettings.Brightness or 1
    Lighting.GlobalShadows = savedSettings.GlobalShadows or true
    Lighting.FogEnd = savedSettings.FogEnd or 1000
    
    if antiLagLoop then
        task.cancel(antiLagLoop)
        antiLagLoop = nil
    end
    
    Rayfield:Notify({Title = "Anti Lag", Content = "Đã tắt! Khôi phục đồ họa.", Duration = 2})
end

-- ==================== TẠO GIAO DIỆN ====================
local MainTab = Window:CreateTab("Trang Chủ", "home")

MainTab:CreateSection("Chiến Đấu")
MainTab:CreateToggle({Name = "Instant Kill (1 hit chết)", CurrentValue = false, Callback = function(v) isIK = v; if v then startIK() else stopIK() end end})
MainTab:CreateToggle({Name = "Godmode (Chống rớt + Hồi máu)", CurrentValue = false, Callback = function(v) isGod = v; if v then startGod() else stopGod() end end})
MainTab:CreateToggle({Name = "Đẩy Zombie (Không lại gần)", CurrentValue = false, Callback = function(v) isPush = v; if v then startPush() else stopPush() end end})

MainTab:CreateSection("Farm & Tiện Ích")
MainTab:CreateToggle({Name = "Auto Farm Void Shard", CurrentValue = false, Callback = function(v) isFarm = v; if v then startFarm() else stopFarm() end end})
MainTab:CreateToggle({Name = "Auto Skip Wave (1 giây)", CurrentValue = false, Callback = function(v) isSkip = v; if v then startSkip() else stopSkip() end end})
MainTab:CreateToggle({Name = "Anti Lag (Cực mượt)", CurrentValue = false, Callback = function(v) isAntiLag = v; if v then startAntiLag() else stopAntiLag() end end})

Rayfield:Notify({Title = "S.Z.A Scrip", Content = "Đã tải thành công!", Duration = 3})# S.Z.A-Scrip
