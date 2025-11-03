-- LocalScript ใน StarterPlayer > StarterPlayerScripts
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local flying = false
local flightSpeed = 60
local hoverHeight = rootPart.Position.Y

local moveUp = 0

local bodyVel
local bodyGyro

---------------------------------------------------------------------
-- สร้าง GUI สำหรับมือถือ
---------------------------------------------------------------------
local function createFlyGui()
    local playerGui = player:WaitForChild("PlayerGui")

    if playerGui:FindFirstChild("FlyGui") then
        return playerGui.FlyGui
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlyGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    -- ปุ่มเปิด/ปิดบิน
    local flyButton = Instance.new("TextButton")
    flyButton.Name = "FlyButton"
    flyButton.Size = UDim2.new(0, 140, 0, 50)
    flyButton.Position = UDim2.new(0, 20, 1, -70) -- ล่างซ้าย
    flyButton.Text = "Fly: OFF"
    flyButton.Font = Enum.Font.SourceSansBold
    flyButton.TextSize = 24
    flyButton.BackgroundTransparency = 0.2
    flyButton.Parent = screenGui

    -- ปุ่มบินขึ้น
    local upButton = Instance.new("TextButton")
    upButton.Name = "UpButton"
    upButton.Size = UDim2.new(0, 80, 0, 40)
    upButton.Position = UDim2.new(1, -110, 1, -130) -- ล่างขวา (ปุ่มบน)
    upButton.Text = "UP"
    upButton.Font = Enum.Font.SourceSansBold
    upButton.TextSize = 22
    upButton.BackgroundTransparency = 0.2
    upButton.Parent = screenGui

    -- ปุ่มบินลง
    local downButton = Instance.new("TextButton")
    downButton.Name = "DownButton"
    downButton.Size = UDim2.new(0, 80, 0, 40)
    downButton.Position = UDim2.new(1, -110, 1, -80) -- ล่างขวา (ปุ่มล่าง)
    downButton.Text = "DOWN"
    downButton.Font = Enum.Font.SourceSansBold
    downButton.TextSize = 22
    downButton.BackgroundTransparency = 0.2
    downButton.Parent = screenGui

    -- กดปุ่ม Fly เพื่อเปิด/ปิดบิน
    flyButton.MouseButton1Click:Connect(function()
        flying = not flying
        if flying then
            hoverHeight = rootPart.Position.Y
        else
            moveUp = 0
        end
    end)

    -- กดปุ่ม UP ค้าง = บินขึ้น
    upButton.MouseButton1Down:Connect(function()
        moveUp = 1
    end)
    upButton.MouseButton1Up:Connect(function()
        moveUp = 0
    end)

    -- กดปุ่ม DOWN ค้าง = บินลง
    downButton.MouseButton1Down:Connect(function()
        moveUp = -1
    end)
    downButton.MouseButton1Up:Connect(function()
        moveUp = 0
    end)

    return screenGui
end

local flyGui = createFlyGui()
local flyButton = flyGui:WaitForChild("FlyButton")

---------------------------------------------------------------------
-- ฟังก์ชันเริ่ม/หยุดบิน
---------------------------------------------------------------------
local function startFlying()
    if bodyVel or bodyGyro then return end

    humanoid.PlatformStand = true

    bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(1e7, 1e7, 1e7)
    bodyVel.Velocity = Vector3.new(0, 0, 0)
    bodyVel.Parent = rootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.P = 1e5
    bodyGyro.Parent = rootPart
end

local function stopFlying()
    humanoid.PlatformStand = false

    if bodyVel then
        bodyVel:Destroy()
        bodyVel = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
end

---------------------------------------------------------------------
-- อัปเดตทุกเฟรม
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    if not character or not humanoid or not rootPart then return end

    -- อัปเดตข้อความบนปุ่ม
    if flyButton then
        flyButton.Text = flying and "Fly: ON" or "Fly: OFF"
    end

    if not flying then
        if bodyVel or bodyGyro then
            stopFlying()
        end
        return
    end

    if not bodyVel or not bodyGyro then
        startFlying()
    end

    if not bodyVel or not bodyGyro then return end

    -- ใช้จอยซ้ายของ Roblox เป็นทิศทางบิน
    local moveDir = humanoid.MoveDirection
    local horizontal = Vector3.new(moveDir.X, 0, moveDir.Z)
    if horizontal.Magnitude > 1 then
        horizontal = horizontal.Unit
    end

    local horizontalVelocity = horizontal * flightSpeed

    -- ขึ้น/ลง
    local yVel
    if moveUp ~= 0 then
        yVel = moveUp * flightSpeed
        hoverHeight = rootPart.Position.Y
    else
        local diff = hoverHeight - rootPart.Position.Y
        yVel = diff * 5
    end

    bodyVel.Velocity = Vector3.new(horizontalVelocity.X, yVel, horizontalVelocity.Z)

    -- หันตัวไปตามทิศที่บิน
    local forward = horizontal.Magnitude > 0 and horizontal.Unit or rootPart.CFrame.LookVector
    local lookAt = Vector3.new(forward.X, 0, forward.Z)
    if lookAt.Magnitude > 0 then
        bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + lookAt)
    end
end)

---------------------------------------------------------------------
-- รีเซ็ตตอนตัวละครตาย/รีสปอว์น
---------------------------------------------------------------------
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    flying = false
    moveUp = 0
    stopFlying()
end)
