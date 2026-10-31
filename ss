-- LocalScript (StarterPlayerScripts 또는 StarterGui에 배치)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Linoria = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local Toggles = Linoria.Toggles

-- ★ 실행 시 딱 1초 게임 멈춤
local freezeStart = os.clock()
while os.clock() - freezeStart < 1 do end

-- UI
local Window = Linoria:CreateWindow({
    Title = "Larp Sling",
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(400, 340),
})

local Tab = Window:AddTab("Main", nil)
local slingGroup = Tab:AddLeftGroupbox("Sling")

local orbitToggle = slingGroup:AddToggle("sling_orbit", {
    Text = "sling_orbit",
    Default = false,
})

local voidToggle = slingGroup:AddToggle("sling_void", {
    Text = "sling_void",
    Default = false,
})

local hitboxToggle = slingGroup:AddToggle("hitbox", {
    Text = "hitbox",
    Default = false,
})

------------------------------------------------------------
-- sling 기능 (중복 가능)
------------------------------------------------------------
local slingStates = {
    sling_orbit = { conn = nil, basePos = nil, angle = 0 },
    sling_void  = { conn = nil, basePos = nil, angle = 0 },
}

local CONFIG = {
    sling_orbit = { distance = 10000,   speed = 1000000 },
    sling_void  = { distance = 1000000, speed = 5000000 },
}

local function stopSling(mode)
    local st = slingStates[mode]
    if not st then return end
    if st.conn then
        st.conn:Disconnect()
        st.conn = nil
    end
end

local function startSling(mode)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local cfg = CONFIG[mode]
    if not cfg then return end

    stopSling(mode)

    local st = slingStates[mode]
    st.basePos = hrp.CFrame.Position
    st.angle = 0

    local DISTANCE = cfg.distance
    local SPEED = cfg.speed

    st.conn = RunService.Heartbeat:Connect(function(dt)
        local c = player.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        if not root then return end

        st.angle = st.angle + SPEED * dt * 0.0001

        local x = math.cos(st.angle) * DISTANCE
        local y = math.sin(st.angle * 1.37) * DISTANCE * 0.5
        local z = math.sin(st.angle) * DISTANCE
        local dx = math.sin(st.angle * 0.7) * DISTANCE * 0.35
        local dz = math.cos(st.angle * 1.13) * DISTANCE * 0.35

        local newPos = st.basePos + Vector3.new(x + dx, y, z + dz)
        root.CFrame = CFrame.new(newPos)
        root.Velocity = Vector3.zero
        root.RotVelocity = Vector3.zero
    end)
end

orbitToggle:OnChanged(function(v)
    if v then startSling("sling_orbit") else stopSling("sling_orbit") end
end)

voidToggle:OnChanged(function(v)
    if v then startSling("sling_void") else stopSling("sling_void") end
end)

------------------------------------------------------------
-- hitbox: 화면 오른쪽 아래에 "8200m 아래" ESP/네임태그 표시
------------------------------------------------------------
local hitboxGui = nil
local hitboxLabel = nil
local hitboxConn = nil
local hitboxBillboard = nil

local OFFSET_RIGHT = 8200
local OFFSET_DOWN  = 8200

local function destroyHitbox()
    if hitboxConn then
        hitboxConn:Disconnect()
        hitboxConn = nil
    end
    if hitboxGui then
        hitboxGui:Destroy()
        hitboxGui = nil
    end
    if hitboxBillboard then
        hitboxBillboard:Destroy()
        hitboxBillboard = nil
    end
    hitboxLabel = nil
end

local function createHitbox()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    destroyHitbox()

    -- 1) 화면 오른쪽 아래 고정 라벨 (ESP 스타일)
    local gui = Instance.new("ScreenGui")
    gui.Name = "HitboxESP"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = player:WaitForChild("PlayerGui")

    local label = Instance.new("TextLabel")
    label.Name = "HitboxLabel"
    label.Size = UDim2.fromOffset(260, 24)
    label.AnchorPoint = Vector2.new(1, 1)          -- 오른쪽 아래 정렬
    label.Position = UDim2.new(1, -20, 1, -20)     -- 화면 오른쪽 아래
    label.BackgroundTransparency = 1
    label.Text = "target: 8200m 아래 (오른쪽 아래)"
    label.TextColor3 = Color3.fromRGB(255, 60, 60)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Right
    label.Parent = gui

    hitboxGui = gui
    hitboxLabel = label

    -- 2) 월드 빌보드 (캐릭터 머리 위에 8200m 아래 표시)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HitboxBillboard"
    billboard.Adornee = hrp
    billboard.Size = UDim2.fromOffset(200, 40)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = hrp

    local bLabel = Instance.new("TextLabel")
    bLabel.Size = UDim2.fromScale(1, 1)
    bLabel.BackgroundTransparency = 1
    bLabel.Text = "8200m 아래"
    bLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
    bLabel.TextStrokeTransparency = 0
    bLabel.Font = Enum.Font.GothamBold
    bLabel.TextSize = 14
    bLabel.Parent = billboard

    hitboxBillboard = billboard

    -- 실시간 거리 갱신 (오른쪽 아래 8200m 목표점 기준)
    hitboxConn = RunService.RenderStepped:Connect(function()
        local c = player.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        if not root or not hitboxLabel then return end

        -- 목표 지점: 내 기준 오른쪽 8200m + 아래 8200m
        local rightVec = root.CFrame.RightVector * OFFSET_RIGHT
        local downVec  = Vector3.new(0, -OFFSET_DOWN, 0)
        local targetPos = root.Position + rightVec + downVec

        local dist = (targetPos - root.Position).Magnitude
        hitboxLabel.Text = string.format("target: %.0fm 아래 (오른쪽 아래)", dist)
    end)
end

hitboxToggle:OnChanged(function(v)
    if v then createHitbox() else destroyHitbox() end
end)

------------------------------------------------------------
-- 재스폰 처리
------------------------------------------------------------
player.CharacterAdded:Connect(function()
    for mode, tgl in pairs({ sling_orbit = orbitToggle, sling_void = voidToggle }) do
        stopSling(mode)
        if tgl.Value then
            task.wait(0.5)
            startSling(mode)
        end
    end

    if hitboxToggle.Value then
        task.wait(0.2)
        createHitbox()
    end
end)
