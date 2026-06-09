--[[
    by S.Z.A
    - Instant Kill + Kill Aura (bắn cực nhanh)
    - Godmode (bay lên cao)
    - Đẩy zombie
    - Auto Farm + Auto Skip + Anti Lag
--]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "by S.Z.A",
    LoadingTitle = "by S.Z.A",
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
local UserInputService = game:GetService("UserInputService")

-- ========== BIẾN ==========
local isIK = false
local isKA = false
local isGod = false
local isPush = false
local isFarm = false
local isSkip = false
local isAntiLag = false

local ikConnection = nil
local kaConnection = nil
local godConnection = nil
local godLoop = nil
local pushConnection = nil
local farmConnection = nil
local skipConnection = nil
local antiLagConnection = nil

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

local function getDamageRemote()
    local remote = RS:FindFirstChild("ZombieRemotes") and RS.ZombieRemotes:FindFirstChild("ZombieDamage")
    if not remote then
        for _, v in ipairs(RS:GetDescendants()) do
            if v:IsA("RemoteEvent") and (v.Name:lower():find("damage") or v.Name:lower():find("hit")) then
                remote = v
                break
            end
        end
    end
    return remote
end

-- ==================== 1. INSTANT KILL ====================
local function startIK()
    if ikConnection then return end
    ikConnection = RunService.Heartbeat:Connect(function()
        if not isIK then return end
        local zs = getZombieTable()
        local remote = getDamageRemote()
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

-- ==================== 2. KILL AURA (BẮN CỰC NHANH) ====================
local function startKA()
    if kaConnection then return end
    
    -- Tìm remote bắn (gun damage)
    local shootRemote = nil
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") and (v.Name:lower():find("shoot") or v.Name:lower():find("fire") or v.Name:lower():find("attack")) then
            shootRemote = v
            break
        end
    end
    
    kaConnection = RunService.Heartbeat:Connect(function()
        if not isKA then return end
        
        -- Bắn liên tục vào zombie
        local zs = getZombieTable()
        if type(zs) == "table" and not zs.IsA then
            for id, data in pairs(zs) do
                if data and not data.IsDying and data.Health > 0 then
                    -- Gửi damage trực tiếp
                    local remote = getDamageRemote()
                    if remote then remote:FireServer(id, 9e9) end
                    -- Bắn nếu có remote bắn
                    if shootRemote then pcall(function() shootRemote:FireServer(id) end) end
                end
            end
        else
            for _, z in ipairs(zs) do
                if z:IsA("Model") then
                    local hum = z:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local id = tonumber(z.Name:match("%d+"))
                        if id then
                            local remote = getDamageRemote()
                            if remote then remote:FireServer(id, 9e9) end
                            if shootRemote then pcall(function() shootRemote:FireServer(id) end) end
                        end
                    end
                end
            end
        end
    end)
end

local function stopKA()
    if kaConnection then kaConnection:Disconnect(); kaConnection = nil end
end

-- ==================== 3. GODMODE ====================
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
        if isGod then setProps() end
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
    if godConnection then godConnection:Disconnect(); godConnection = nil end
    if godLoop then task.cancel(godLoop); godLoop = nil end
    local c = LP.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and origHip then hum.HipHeight = origHip end
    end
end

-- ==================== 4. ĐẨY ZOMBIE ====================
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

-- ==================== 5. AUTO FARM ====================
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

-- ==================== 6. AUTO SKIP ====================
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
                    if remote:IsA("RemoteEvent") then remote:FireServer() else remote:Fire() end
                end)
            end
        end
        task.wait(1)
    end)
end

local function stopSkip()
    if skipConnection then skipConnection:Disconnect(); skipConnection = nil end
end

-- ==================== 7. ANTI LAG ====================
local function startAntiLag()
    if antiLagConnection then return end
    settings().Rendering.QualityLevel = 1
    Lighting.Brightness = 0
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 0
    antiLagConnection = RunService.Heartbeat:Connect(function()
        if not isAntiLag then return end
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Decal") then
                v:Destroy()
            elseif v:IsA("BasePart") then
                v.Material = Enum.Material.Plastic
                v.Reflectance = 0
            end
        end
    end)
    Rayfield:Notify({Title = "Anti Lag", Content = "Đã bật! Game cực mượt.", Duration = 2})
end

local function stopAntiLag()
    if antiLagConnection then antiLagConnection:Disconnect(); antiLagConnection = nil end
    settings().Rendering.QualityLevel = 10
    Lighting.Brightness = 1
    Lighting.GlobalShadows = true
    Lighting.FogEnd = 1000
    Rayfield:Notify({Title = "Anti Lag", Content = "Đã tắt! Khôi phục đồ họa.", Duration = 2})
end

-- ==================== TẠO GIAO DIỆN ====================
local MainTab = Window:CreateTab("Trang Chủ", "home")

MainTab:CreateSection("Chiến Đấu")
MainTab:CreateToggle({Name = "Instant Kill (1 hit chết)", CurrentValue = false, Callback = function(v) isIK = v; if v then startIK() else stopIK() end end})
MainTab:CreateToggle({Name = "Kill Aura (Bắn cực nhanh)", CurrentValue = false, Callback = function(v) isKA = v; if v then startKA() else stopKA() end end})
MainTab:CreateToggle({Name = "Godmode (Bay lên cao)", CurrentValue = false, Callback = function(v) isGod = v; if v then startGod() else stopGod() end end})
MainTab:CreateToggle({Name = "Đẩy Zombie (Không lại gần)", CurrentValue = false, Callback = function(v) isPush = v; if v then startPush() else stopPush() end end})

MainTab:CreateSection("Farm & Tiện Ích")
MainTab:CreateToggle({Name = "Auto Farm Void Shard", CurrentValue = false, Callback = function(v) isFarm = v; if v then startFarm() else stopFarm() end end})
MainTab:CreateToggle({Name = "Auto Skip Wave (1 giây)", CurrentValue = false, Callback = function(v) isSkip = v; if v then startSkip() else stopSkip() end end})
MainTab:CreateToggle({Name = "Anti Lag (Cực mượt)", CurrentValue = false, Callback = function(v) isAntiLag = v; if v then startAntiLag() else stopAntiLag() end end})

Rayfield:Notify({Title = "by S.Z.A", Content = "Đã thêm Kill Aura bắn cực nhanh!", Duration = 3})
