-- LocalScript ใน StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local flying = false
local flightSpeed = 60              -- ความเร็วบิน
local hoverHeight = rootPart.Position.Y  -- ความสูงที่ลอย

local moveForward = 0
local moveRight = 0
local moveUp = 0

local bodyVel
local bodyGyro

-- ฟังก์ชันเริ่มบิน
local function startFlying()
	if flying then return end
	flying = true

	hoverHeight = rootPart.Position.Y

	humanoid.PlatformStand = true  -- ปิดแอนิเมชันเดิน/ล้ม

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

-- ฟังก์ชันหยุดบิน
local function stopFlying()
	if not flying then return end
	flying = false

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

-- Toggle เปิด/ปิดบิน
local function toggleFlying()
	if flying then
		stopFlying()
	else
		startFlying()
	end
end

-- รับปุ่มกด
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

-- อัปเดตการบินทุกเฟรม
RunService.RenderStepped:Connect(function(dt)
	if not flying or not bodyVel or not bodyGyro then return end

	local camera = workspace.CurrentCamera
	if not camera then return end

	local forward = camera.CFrame.LookVector
	local right = camera.CFrame.RightVector

	-- ทิศทางแนวนอน (x,z)
	local moveDir = (forward * moveForward) + (right * moveRight)
	if moveDir.Magnitude > 0 then
		moveDir = moveDir.Unit
	end
	local horizontalVelocity = moveDir * flightSpeed

	-- แนวตั้ง: ขึ้น/ลง หรือพยายามรักษาระดับ hover
	local yVel
	if moveUp ~= 0 then
		yVel = moveUp * flightSpeed
	else
		-- ดึงตัวกลับไปความสูง hover แบบนิ่ม ๆ
		local diff = hoverHeight - rootPart.Position.Y
		yVel = diff * 5
	end

	bodyVel.Velocity = Vector3.new(horizontalVelocity.X, yVel, horizontalVelocity.Z)

	-- หมุนตัวตามมุมกล้อง (หันไปทางที่กล้องมอง)
	local lookAt = Vector3.new(forward.X, 0, forward.Z)
	if lookAt.Magnitude > 0 then
		bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + lookAt)
	end
end)

-- เผื่อเกิดตาย/รีสปอว์น
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	stopFlying()
end)
