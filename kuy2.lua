-- LocalScript (StarterPlayer > StarterPlayerScripts)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ====== ตั้งค่าการบิน ======
local flying = false
local flightSpeed = 40
local hoverHeight = rootPart.Position.Y
local moveUp = 0

local bodyVel
local bodyGyro

-- ====== GUI: เมนูปุ่มเดียว + แผงควบคุม ======
local function createGui()
	local pg = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "FlyGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = pg

	-- ปุ่มเปิด/ปิดแผงควบคุม (ปุ่มเดียวที่เห็นตอนแรก)
	local menuBtn = Instance.new("TextButton")
	menuBtn.Name = "MenuButton"
	menuBtn.Size = UDim2.new(0, 140, 0, 50)
	menuBtn.Position = UDim2.new(0, 20, 1, -70) -- ล่างซ้าย
	menuBtn.Text = "Fly Menu"
	menuBtn.Font = Enum.Font.SourceSansBold
	menuBtn.TextSize = 22
	menuBtn.BackgroundTransparency = 0.2
	menuBtn.Parent = gui

	-- แผงควบคุม (ซ่อนไว้ก่อน)
	local panel = Instance.new("Frame")
	panel.Name = "FlyPanel"
	panel.Size = UDim2.new(0, 200, 0, 160)
	panel.Position = UDim2.new(1, -220, 1, -180) -- ล่างขวา
	panel.BackgroundTransparency = 0.2
	panel.Visible = false
	panel.Parent = gui

	-- ปุ่ม Toggle บิน
	local flyBtn = Instance.new("TextButton")
	flyBtn.Name = "FlyToggle"
	flyBtn.Size = UDim2.new(1, -20, 0, 50)
	flyBtn.Position = UDim2.new(0, 10, 0, 10)
	flyBtn.Text = "Fly: OFF"
	flyBtn.Font = Enum.Font.SourceSansBold
	flyBtn.TextSize = 24
	flyBtn.BackgroundTransparency = 0.2
	flyBtn.Parent = panel

	-- ปุ่ม UP
	local upBtn = Instance.new("TextButton")
	upBtn.Name = "UpButton"
	upBtn.Size = UDim2.new(1, -20, 0, 40)
	upBtn.Position = UDim2.new(0, 10, 0, 70)
	upBtn.Text = "UP (hold)"
	upBtn.Font = Enum.Font.SourceSansBold
	upBtn.TextSize = 22
	upBtn.BackgroundTransparency = 0.2
	upBtn.Parent = panel

	-- ปุ่ม DOWN
	local downBtn = Instance.new("TextButton")
	downBtn.Name = "DownButton"
	downBtn.Size = UDim2.new(1, -20, 0, 40)
	downBtn.Position = UDim2.new(0, 10, 0, 120)
	downBtn.Text = "DOWN (hold)"
	downBtn.Font = Enum.Font.SourceSansBold
	downBtn.TextSize = 22
	downBtn.BackgroundTransparency = 0.2
	downBtn.Parent = panel

	-- เปิด/ปิดแผงควบคุม
	local panelOpen = false
	local function setPanelVisible(state)
		panelOpen = state
		panel.Visible = state
		if not state then
			moveUp = 0 -- กันค้างตอนปิดแผง
		end
		menuBtn.Text = state and "Close Menu" or "Fly Menu"
	end
	menuBtn.MouseButton1Click:Connect(function()
		setPanelVisible(not panelOpen)
	end)

	-- กดสลับบิน
	flyBtn.MouseButton1Click:Connect(function()
		flying = not flying
		if flying then
			hoverHeight = rootPart.Position.Y
		else
			moveUp = 0
		end
	end)

	-- กดค้างเพื่อขึ้น/ลง (มือถือใช้ได้)
	upBtn.MouseButton1Down:Connect(function() moveUp = 1 end)
	upBtn.MouseButton1Up:Connect(function() moveUp = 0 end)
	upBtn.MouseLeave:Connect(function() moveUp = 0 end)

	downBtn.MouseButton1Down:Connect(function() moveUp = -1 end)
	downBtn.MouseButton1Up:Connect(function() moveUp = 0 end)
	downBtn.MouseLeave:Connect(function() moveUp = 0 end)

	return gui, menuBtn, panel, flyBtn
end

local gui, menuBtn, panel, flyBtn = createGui()

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
	if flyBtn then flyBtn.Text = flying and "Fly: ON" or "Fly: OFF" end

	if not flying then
		if bodyVel or bodyGyro then stopFlying() end
		return
	end

	if not bodyVel or not bodyGyro then startFlying() end
	if not bodyVel or not bodyGyro then return end

	-- ใช้จอยซ้ายของ Roblox เป็นทิศทางแนวนอน
	local moveDir = humanoid.MoveDirection
	local horizontal = Vector3.new(moveDir.X, 0, moveDir.Z)
	if horizontal.Magnitude > 1 then horizontal = horizontal.Unit end
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

	-- หันตัวตามทิศที่กำลังเคลื่อน
	local forward = horizontal.Magnitude > 0 and horizontal.Unit or rootPart.CFrame.LookVector
	local lookAt = Vector3.new(forward.X, 0, forward.Z)
	if lookAt.Magnitude > 0 then
		bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + lookAt)
	end
end)

-- ====== รีเซ็ตเมื่อรีสปอว์น ======
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	flying = false
	moveUp = 0
	stopFlying()
end)
