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
-- สร้าง GUI: ปุ่มหลัก + เมนูควบคุม (ซ่อนตอนแรก)
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

    -- ปุ่มหลัก (ปุ่มเดียวที่เห็นตอนแรก)
    local mainButton = Instance.new("TextButton")
    mainButton.Name = "MainButton"
    mainButton.Size = UDim2.new(0, 100, 0, 40)
    mainButton.Position = UDim2.new(0, 20, 1, -70) -- ล่างซ้าย
    mainButton.Text = "Fly"
    mainButton.Font = Enum.Font.SourceSansBold
    mainButton.TextSize = 24
    mainButton.BackgroundTransparency = 0.2
    mainButton.Parent = screenGui

    -- Frame เก็บปุ่มย่อย (ซ่อนตอนเริ่ม)
    local controlFrame = Instance.new("Frame")
    controlFrame.Name = "ControlFrame"
    controlFrame.Size = UDim2.new(0, 160, 0, 130)
    controlFrame.Position = UDim2.new(0, 130, 1, -150) -- ใกล้ ๆ ปุ่มหลัก
    controlFrame.BackgroundTransparency = 0.3
    controlFrame.Visible = false
    controlFrame.Parent = screenGui

    -- ปุ่มเปิด/ปิดบิน
    local flyToggle = Instance.new("TextButton")
    flyToggle.Name = "FlyToggle"
    flyToggle.Size = UDim2.new(1, -20, 0, 40)
    flyToggle.Position = UDim2.new(0, 10, 0, 10)
    flyToggle.Text = "Fly: OFF"
    flyToggle.Font = Enum.Font.SourceSansBold
    flyToggle.TextSize = 22
    flyToggle.BackgroundTransparency = 0.2
    flyToggle.Parent = controlFrame

    -- ปุ่มขึ้น
    local upButton = Instance.new("TextButton")
    upButton.Name = "UpButton"
    upButton.Size = UDim2.new(1, -20, 0, 30)
    upButton.Position = UDim2.new(0, 10, 0, 60)
    upButton.Text = "UP"
    upButton.Font = Enum.Font.SourceSansBold
    upButton.TextSize = 20
    upButton.BackgroundTransparency = 0.2
    upButton.Parent = controlFrame

    -- ปุ่มลง
    local downButton = Instance.new("TextButton")
    downButton.Name = "DownButton"
    downButton.Size = UDim2.new(1, -20, 0, 30)
    downButton.Position = UDim2.new(0, 10, 0, 95)
    downButton.Text = "DOWN"
    downButton.Font = Enum.Font.SourceSansBold
    downButton.TextSize = 20
    downButton.BackgroundTransparency = 0.2
    downButton.Parent = controlFrame

    -----------------------------------------------------------------
    -- การทำงานของปุ่มหลัก: เปิด/ปิดเมนู
    -----------------------------------------------------------------
    mainButton.MouseButton1Click:Connect(function()
        controlFrame.Visible = not controlFrame.Visible
        -- ถ้าปิดเมนู ให้หยุดคำสั่งขึ้น/ลงด้วย
        if not controlFrame.Visible then
            moveUp = 0
        }
    end)

    -----------------------------------------------------------------
    -- ปุ่ม Fly: ON/OFF
    -----------------------------------------------------------------
    flyToggle.MouseButton1Click:Connect(function()
        flying = not flying
        if flying then
            hoverHeight = rootPart.Position.Y
        else
            moveUp = 0
        end
    end)

    -----------------------------------------------------------------
    -- ปุ่ม UP / DOWN (กดค้าง = ทำงาน, ปล่อย = หยุด)
    -----------------------------------------------------------------
    upButton.MouseButton1Down:Connect(function()
        moveUp = 1
    end)
    upButton.MouseButton1Up:Connect(function()
        moveUp = 0
    end)

    downButton.MouseButton1Down:Connect(function()
        moveUp = -1
    end)
    downButton.MouseButton1Up:Connect(function()
        moveUp = 0
    end)

    return screenGui
end

local flyGui = createFlyGui()
local controlFrame = flyGui:WaitForChild("ControlFrame")
local flyToggle = controlFrame:WaitForChild("FlyToggle")

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

    -- อัปเดตข้อความบนปุ่ม Fly: ON/OFF
    if flyToggle then
        flyToggle.Text = flying and "Fly: ON" or "Fly: OFF"
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

    -- ใช้จอยซ้าย (MoveDirection) เป็นทิศทางบิน
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

    -- หันตัวไปทิศที่บิน
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
