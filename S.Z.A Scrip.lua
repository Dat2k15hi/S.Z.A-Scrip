--[[
    S.Z.A ULTIMATE HUB - by S.Z.A Scrip
    - Godmode cũ: tự động bay lên (HipHeight = 25) + hồi máu
    - Instant Kill cũ: damage 999999 qua Heartbeat
    - Đẩy zombie: không lại gần
    - Auto Farm Void Shard
    - Auto Skip Wave (1 giây)
    - Anti Lag cực mạnh
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "by S.Z.A Scrip",
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

-- ========== BIẾN ==========
local isIK = false
local isGod = false
local isPush = false
local isFarm = false
local isSkip = false
local isAntiLag = false

local ikConnection = nil
local godConnection = nil
local godLoop = nil
local pushConnection = nil
local farmConnection = nil
local skipConnection = nil
local antiLagLoop = nil

-- Helper
local function getZombieTable()
    local ok, mod = pcall(require, LP.PlayerScripts.Controllers.ZombieClient)
    if ok and mod.Zombies then return mod.Zombies end
    if getgc then
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" and rawget(v, "Zombies") then return v.Zombies end
        end
    end
    return workspace:FindFirstChild("Zombies_Local") and workspace.Zombies_Local:GetChildren() or {}
end

-- ==================== 1. INSTANT KILL (CŨ) ====================
local function startIK()
    if ikConnection then return end
    ikConnection = RunService.Heartbeat:Connect(function()
        if not isIK then return end
        local zs = getZombieTable()
        local remote = RS:FindFirstChild("ZombieRemotes") and RS.ZombieRemotes:FindFirstChild("ZombieDamage")
        if not remote then return end
        if type(zs) == "table" and not zs.IsA then
            for id, data in pairs(zs) do
                if data and not data.IsDying and data.Health > 0 then
                    remote:FireServer(id, 9e9)
                end
            end
        else
            for _, z in ipairs(zs) do
                if z:IsA("Model") then
                    local hum = z:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local id = tonumber(z.Name:match("%d+"))
                        if id then remote:FireServer(id, 9e9) end
                    end
                end
            end
        end
    end)
end

local function stopIK()
    if ikConnection then ikConnection:Disconnect(); ikConnection = nil end
end

-- ==================== 2. GODMODE CŨ ====================
local origHip = nil

local function startGod()
    if godConnection then return end
    
    local function setProps()
        local c = LP.Character
        if c then
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then
                if origHip == nil then origHip = hum.HipHeight end
                hum.HipHeight = 25
                hum.BreakJointsOnDeath = false
            end
            for _, s in ipairs(c:GetChildren()) do
                if s:IsA("Script") and (s.Name:lower():find("damage") or s.Name:lower():find("health")) then
                    pcall(function() s:Disable() end)
                end
            end
        end
    end
    
    setProps()
    
    godConnection = LP.CharacterAdded:Connect(function()
        task.wait(1)
        setProps()
    end)
    
    godLoop = task.spawn(function()
        while isGod and task.wait(0.3) do
            local c = LP.Character
            if c then
                local hum = c:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.HipHeight = 25
                    if hum.Health < hum.MaxHealth then
                        hum.Health = hum.MaxHealth
                    end
                end
            end
        end
    end)
end

local function stopGod()
    if godConnection then
        godConnection:Disconnect()
        godConnection = nil
    end
    if godLoop then
        task.cancel(godLoop)
        godLoop = nil
    end
    local c = LP.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and origHip then
            hum.HipHeight = origHip
        end
    end
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
        local zombies = workspace:FindFirstChild("Zombies_Local")
        if not zombies then return end
        for _, z in ipairs(zombies:GetChildren()) do
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

-- ==================== 4. AUTO FARM ====================
local function startFarm()
    if farmConnection then return end
    farmConnection = RunService.Heartbeat:Connect(function()
        if not isFarm then return end
        for _, obj in ipairs(workspace:GetDescendants()) do
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
        for _, crate in ipairs(workspace:GetDescendants()) do
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

-- ==================== 5. AUTO SKIP ====================
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
            local zombies = workspace:FindFirstChild("Zombies_Local")
            local hasZombie = zombies and #zombies:GetChildren() > 0
            if not hasZombie then
                pcall(function()
                    if remote:IsA("RemoteEvent") then
                        remote:FireServer()
                    else
                        remote:Fire()
                    end
                end)
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
    
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Decal") then
            v:Destroy()
        elseif v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        end
    end
    
    antiLagLoop = task.spawn(function()
        while isAntiLag and task.wait(10) do
            for _, v in ipairs(workspace:GetDescendants()) do
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
MainTab:CreateToggle({Name = "Godmode (Bay lên cao)", CurrentValue = false, Callback = function(v) isGod = v; if v then startGod() else stopGod() end end})
MainTab:CreateToggle({Name = "Đẩy Zombie (Không lại gần)", CurrentValue = false, Callback = function(v) isPush = v; if v then startPush() else stopPush() end end})

MainTab:CreateSection("Farm & Tiện Ích")
MainTab:CreateToggle({Name = "Auto Farm Void Shard", CurrentValue = false, Callback = function(v) isFarm = v; if v then startFarm() else stopFarm() end end})
MainTab:CreateToggle({Name = "Auto Skip Wave (1 giây)", CurrentValue = false, Callback = function(v) isSkip = v; if v then startSkip() else stopSkip() end end})
MainTab:CreateToggle({Name = "Anti Lag (Cực mượt)", CurrentValue = false, Callback = function(v) isAntiLag = v; if v then startAntiLag() else stopAntiLag() end end})

Rayfield:Notify({Title = "by S.Z.A Scrip", Content = "Đã tải thành công!", Duration = 3})
