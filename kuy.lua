-- LocalScript ใน StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ตั้งค่าการบิน
local flying = false
local flightSpeed = 60
local hoverHeight = rootPart.Position.Y

local moveForward = 0
local moveRight = 0
local moveUp = 0

local bodyVel
local bodyGyro

-- =========================
-- สร้าง GUI ปุ่มบิน
-- =========================
local function createFlyGui()
	local playerGui = player:WaitForChild("PlayerGui")

	-- ถ้ามีอยู่แล้วไม่ต้องสร้างซ้ำ
	if playerGui:FindFirstChild("FlyGui") then
		return playerGui.FlyGui
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FlyGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local button = Instance.new("TextButton")
	button.Name = "FlyButton"
	button.Size = UDim2.new(0, 120, 0, 40)
	button.Position = UDim2.new(0, 20, 0, 100) -- มุมซ้ายบน
	button.Text = "Fly: OFF"
	button.Font = Enum.Font.SourceSansBold
	button.TextSize = 24
	button.BackgroundTransparency = 0.2
	button.Parent = screenGui

	-- เวลากดปุ่มให้ toggle บิน
	button.MouseButton1Click:Connect(function()
		if flying then
			-- ปิดบิน
			flying = false
		else
			-- เปิดบิน
			flying = true
			hoverHeight = rootPart.Position.Y
		end
	end)

	return screenGui
end

-- เรียกสร้าง GUI ตอนเริ่มเกม
local flyGui = createFlyGui()
local flyButton = flyGui:WaitForChild("FlyButton")

-- =========================
-- ฟังก์ชันเริ่ม/หยุดบินจริง ๆ
-- =========================
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

local function toggleFlying()
	flying = not flying
	if flying then
		hoverHeight = rootPart.Position.Y
	end
end

-- =========================
-- รับปุ่มคีย์บอร์ด (เสริมจาก GUI)
-- =========================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.F then
		toggleFlying()
	end

	if input.KeyCode == Enum.KeyCode.W then
		moveForward = 1
	elseif input.KeyCode == Enum.KeyCode.S then
		moveForward = -1
	elseif input.KeyCode == Enum.KeyCode.A then
		moveRight = -1
	elseif input.KeyCode == Enum.KeyCode.D then
		moveRight = 1
	elseif input.KeyCode == Enum.KeyCode.Space then
		moveUp = 1
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		moveUp = -1
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
		moveForward = 0
	elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
		moveRight = 0
	elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.LeftControl then
		moveUp = 0
	end
end)

-- =========================
-- อัปเดตทุกเฟรม
-- =========================
RunService.RenderStepped:Connect(function(dt)
	-- อัปเดตข้อความบนปุ่ม
	if flyButton then
		flyButton.Text = flying and "Fly: ON" or "Fly: OFF"
	end

	-- ถ้ายังไม่กดให้บิน ก็ปิดแรงทั้งหมด
	if not flying then
		if bodyVel or bodyGyro then
			stopFlying()
		end
		return
	end

	-- ถ้าเริ่มบินแล้วแต่ยังไม่มี body* ให้สร้าง
	if not bodyVel or not bodyGyro then
		startFlying()
	end

	if not bodyVel or not bodyGyro then return end

	local camera = workspace.CurrentCamera
	if not camera then return end

	local forward = camera.CFrame.LookVector
	local right = camera.CFrame.RightVector

	local moveDir = (forward * moveForward) + (right * moveRight)
	if moveDir.Magnitude > 0 then
		moveDir = moveDir.Unit
	end
	local horizontalVelocity = moveDir * flightSpeed

	local yVel
	if moveUp ~= 0 then
		yVel = moveUp * flightSpeed
	else
		local diff = hoverHeight - rootPart.Position.Y
		yVel = diff * 5
	end

	bodyVel.Velocity = Vector3.new(horizontalVelocity.X, yVel, horizontalVelocity.Z)

	local lookAt = Vector3.new(forward.X, 0, forward.Z)
	if lookAt.Magnitude > 0 then
		bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + lookAt)
	end
end)

-- =========================
-- รีเซ็ตเมื่อรีสปอว์น
-- =========================
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	flying = false
	stopFlying()
end)
