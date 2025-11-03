-- LocalScript ใน StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local invisEvent = ReplicatedStorage:WaitForChild("ToggleInvisibility")

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ====== ตั้งค่าการบิน ======
local flying = false
local flightSpeed = 65
local hoverHeight = rootPart.Position.Y
local moveUp = 0

local bodyVel
local bodyGyro

-- ====== สถานะหายตัว ======
local invisible = false

-- ====== GUI: ปุ่มเดียว + แผงควบคุม ======
local gui, menuBtn, panel, flyBtn, invisBtn

local function createGui()
    local pg = player:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlyGui"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = pg

    -- ปุ่มเมนู (เห็นปุ่มเดียวตอนแรก)
    local menuButton = Instance.new("TextButton")
    menuButton.Name = "MenuButton"
    menuButton.Size = UDim2.new(0, 140, 0, 50)
    menuButton.Position = UDim2.new(0, 20, 1, -70) -- ล่างซ้าย
    menuButton.Text = "Fly Menu"
    menuButton.Font = Enum.Font.SourceSansBold
    menuButton.TextSize = 22
    menuButton.BackgroundTransparency = 0.2
    menuButton.Parent = screenGui

    -- แผงควบคุม
    local panelFrame = Instance.new("Frame")
    panelFrame.Name = "FlyPanel"
    panelFrame.Size = UDim2.new(0, 220, 0, 220)
    panelFrame.Position = UDim2.new(1, -240, 1, -240) -- ล่างขวา
    panelFrame.BackgroundTransparency = 0.2
    panelFrame.Visible = false
    panelFrame.Parent = screenGui

    -- ปุ่ม Toggle บิน
    local flyToggle = Instance.new("TextButton")
    flyToggle.Name = "FlyToggle"
    flyToggle.Size = UDim2.new(1, -20, 0, 50)
    flyToggle.Position = UDim2.new(0, 10, 0, 10)
    flyToggle.Text = "Fly: OFF"
    flyToggle.Font = Enum.Font.SourceSansBold
    flyToggle.TextSize = 24
    flyToggle.BackgroundTransparency = 0.2
    flyToggle.Parent = panelFrame

    -- ปุ่ม UP
    local upBtn = Instance.new("TextButton")
    upBtn.Name = "UpButton"
    upBtn.Size = UDim2.new(1, -20, 0, 40)
    upBtn.Position = UDim2.new(0, 10, 0, 70)
    upBtn.Text = "UP (hold)"
    upBtn.Font = Enum.Font.SourceSansBold
    upBtn.TextSize = 22
    upBtn.BackgroundTransparency = 0.2
    upBtn.Parent = panelFrame

    -- ปุ่ม DOWN
    local downBtn = Instance.new("TextButton")
    downBtn.Name = "DownButton"
    downBtn.Size = UDim2.new(1, -20, 0, 40)
    downBtn.Position = UDim2.new(0, 10, 0, 120)
    downBtn.Text = "DOWN (hold)"
    downBtn.Font = Enum.Font.SourceSansBold
    downBtn.TextSize = 22
    downBtn.BackgroundTransparency = 0.2
    downBtn.Parent = panelFrame

    -- ปุ่ม Invisible
    local invisToggle = Instance.new("TextButton")
    invisToggle.Name = "InvisibleToggle"
    invisToggle.Size = UDim2.new(1, -20, 0, 40)
    invisToggle.Position = UDim2.new(0, 10, 0, 170)
    invisToggle.Text = "Invisible: OFF"
    invisToggle.Font = Enum.Font.SourceSansBold
    invisToggle.TextSize = 22
    invisToggle.BackgroundTransparency = 0.2
    invisToggle.Parent = panelFrame

    -- เปิด/ปิด panel
    local panelOpen = false
    local function setPanelVisible(state)
        panelOpen = state
        panelFrame.Visible = state
        if not state then
            moveUp = 0
        end
        menuButton.Text = state and "Close Menu" or "Fly Menu"
    end

    menuButton.MouseButton1Click:Connect(function()
        setPanelVisible(not panelOpen)
    end)

    -- กดสลับบิน
    flyToggle.MouseButton1Click:Connect(function()
        flying = not flying
        if flying then
            hoverHeight = rootPart.Position.Y
        else
            moveUp = 0
        end
    end)

    -- ปุ่ม UP/DOWN กดค้าง
    upBtn.MouseButton1Down:Connect(function() moveUp = 1 end)
    upBtn.MouseButton1Up:Connect(function() moveUp = 0 end)
    upBtn.MouseLeave:Connect(function() moveUp = 0 end)

    downBtn.MouseButton1Down:Connect(function() moveUp = -1 end)
    downBtn.MouseButton1Up:Connect(function() moveUp = 0 end)
    downBtn.MouseLeave:Connect(function() moveUp = 0 end)

    -- ปุ่ม Invisible
    invisToggle.MouseButton1Click:Connect(function()
        invisible = not invisible
        invisEvent:FireServer(invisible)
    end)

    gui, menuBtn, panel, flyBtn, invisBtn =
        screenGui, menuButton, panelFrame, flyToggle, invisToggle
end

createGui()

-- ====== ฟังก์ชันบิน ======
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
    if bodyVel then bodyVel:Destroy(); bodyVel = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
end

-- ====== อัปเดตทุกเฟรม ======
RunService.RenderStepped:Connect(function()
    if flyBtn then
        flyBtn.Text = flying and "Fly: ON" or "Fly: OFF"
    end
    if invisBtn then
        invisBtn.Text = invisible and "Invisible: ON" or "Invisible: OFF"
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

    -- ใช้จอยซ้ายเป็นทิศทางบิน
    local moveDir = humanoid.MoveDirection
    local horizontal = Vector3.new(moveDir.X, 0, moveDir.Z)
    if horizontal.Magnitude > 1 then
        horizontal = horizontal.Unit
    end

    local horizontalVelocity = horizontal * flightSpeed

    -- ขึ้น/ลง + รักษาระดับ
    local yVel
    if moveUp ~= 0 then
        yVel = moveUp * flightSpeed
        hoverHeight = rootPart.Position.Y
    else
        local diff = hoverHeight - rootPart.Position.Y
        yVel = diff * 5
    end

    bodyVel.Velocity = Vector3.new(horizontalVelocity.X, yVel, horizontalVelocity.Z)

    local forward = horizontal.Magnitude > 0 and horizontal.Unit or rootPart.CFrame.LookVector
    local lookAt = Vector3.new(forward.X, 0, forward.Z)
    if lookAt.Magnitude > 0 then
        bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + lookAt)
    end
end)

-- ====== รีเซ็ตตอนรีสปอว์น ======
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    flying = false
    moveUp = 0
    invisible = false
    stopFlying()
    invisEvent:FireServer(false) -- เผื่อเคยหายตัวอยู่ให้กลับมาปกติ
end)
