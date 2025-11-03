-- LocalScript (StarterPlayer > StarterPlayerScripts)
-- ฟังก์ชัน: เมนู + บิน + หายตัว (เพื่อนเห็นว่าหายด้วย)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

------------------------------------------------------------
-- 🔧 สร้าง RemoteEvent + Server Script อัตโนมัติ
------------------------------------------------------------
local event = ReplicatedStorage:FindFirstChild("InvisibilityEvent")
if not event then
	event = Instance.new("RemoteEvent")
	event.Name = "InvisibilityEvent"
	event.Parent = ReplicatedStorage
end

-- ตรวจว่ามี Script ฝั่ง Server ไหม ถ้าไม่มีก็สร้าง
if game:GetService("RunService"):IsStudio() and not ServerScriptService:FindFirstChild("InvisServer") then
	local serverScript = Instance.new("Script")
	serverScript.Name = "InvisServer"
	serverScript.Source = [[
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local invisEvent = ReplicatedStorage:WaitForChild("InvisibilityEvent")

		invisEvent.OnServerEvent:Connect(function(player, toggle)
			local char = player.Character
			if not char then return end
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("Decal") then
					part.Transparency = toggle and 1 or 0
				end
				if part:IsA("BillboardGui") then
					part.Enabled = not toggle
				end
			end
			-- ปิด collisions ด้วย (กันชน)
			for _, part in ipairs(char:GetChildren()) do
				if part:IsA("BasePart") then
					part.CanCollide = not toggle
				end
			end
		end)
	]]
	serverScript.Parent = ServerScriptService
end

------------------------------------------------------------
-- ⚙️ ตัวแปรหลัก
------------------------------------------------------------
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local flying = false
local invisible = false
local flightSpeed = 60
local hoverHeight = rootPart.Position.Y
local moveUp = 0

local bodyVel
local bodyGyro

------------------------------------------------------------
-- 🖥️ GUI: ปุ่มเมนู + แผงควบคุม
------------------------------------------------------------
local function createGui()
	local pg = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "MainGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = pg

	-- ปุ่มเมนูหลัก
	local menuBtn = Instance.new("TextButton")
	menuBtn.Name = "MenuButton"
	menuBtn.Size = UDim2.new(0, 140, 0, 50)
	menuBtn.Position = UDim2.new(0, 20, 1, -70)
	menuBtn.Text = "Menu"
	menuBtn.Font = Enum.Font.SourceSansBold
	menuBtn.TextSize = 22
	menuBtn.BackgroundTransparency = 0.2
	menuBtn.Parent = gui

	-- แผงควบคุม
	local panel = Instance.new("Frame")
	panel.Name = "ControlPanel"
	panel.Size = UDim2.new(0, 220, 0, 210)
	panel.Position = UDim2.new(1, -240, 1, -230)
	panel.BackgroundTransparency = 0.2
	panel.Visible = false
	panel.Parent = gui

	-- ปุ่ม Fly
	local flyBtn = Instance.new("TextButton")
	flyBtn.Name = "FlyButton"
	flyBtn.Size = UDim2.new(1, -20, 0, 50)
	flyBtn.Position = UDim2.new(0, 10, 0, 10)
	flyBtn.Text = "Fly: OFF"
	flyBtn.Font = Enum.Font.SourceSansBold
	flyBtn.TextSize = 22
	flyBtn.BackgroundTransparency = 0.2
	flyBtn.Parent = panel

	-- ปุ่ม Invisible
	local invisBtn = Instance.new("TextButton")
	invisBtn.Name = "InvisButton"
	invisBtn.Size = UDim2.new(1, -20, 0, 50)
	invisBtn.Position = UDim2.new(0, 10, 0, 70)
	invisBtn.Text = "Invisible: OFF"
	invisBtn.Font = Enum.Font.SourceSansBold
	invisBtn.TextSize = 22
	invisBtn.BackgroundTransparency = 0.2
	invisBtn.Parent = panel

	-- ปุ่ม UP
	local upBtn = Instance.new("TextButton")
	upBtn.Name = "UpButton"
	upBtn.Size = UDim2.new(1, -20, 0, 40)
	upBtn.Position = UDim2.new(0, 10, 0, 130)
	upBtn.Text = "UP (Hold)"
	upBtn.Font = Enum.Font.SourceSansBold
	upBtn.TextSize = 20
	upBtn.BackgroundTransparency = 0.2
	upBtn.Parent = panel

	-- ปุ่ม DOWN
	local downBtn = Instance.new("TextButton")
	downBtn.Name = "DownButton"
	downBtn.Size = UDim2.new(1, -20, 0, 40)
	downBtn.Position = UDim2.new(0, 10, 0, 180)
	downBtn.Text = "DOWN (Hold)"
	downBtn.Font = Enum.Font.SourceSansBold
	downBtn.TextSize = 20
	downBtn.BackgroundTransparency = 0.2
	downBtn.Parent = panel

	-- toggle แผง
	local open = false
	menuBtn.MouseButton1Click:Connect(function()
		open = not open
		panel.Visible = open
		menuBtn.Text = open and "Close" or "Menu"
		if not open then moveUp = 0 end
	end)

	-- toggle บิน
	flyBtn.MouseButton1Click:Connect(function()
		flying = not flying
		if flying then hoverHeight = rootPart.Position.Y end
	end)

	-- toggle หายตัว
	invisBtn.MouseButton1Click:Connect(function()
		invisible = not invisible
		ReplicatedStorage.InvisibilityEvent:FireServer(invisible)
		invisBtn.Text = invisible and "Invisible: ON" or "Invisible: OFF"
	end)

	-- ปุ่มขึ้นลง
	upBtn.MouseButton1Down:Connect(function() moveUp = 1 end)
	upBtn.MouseButton1Up:Connect(function() moveUp = 0 end)
	upBtn.MouseLeave:Connect(function() moveUp = 0 end)
	downBtn.MouseButton1Down:Connect(function() moveUp = -1 end)
	downBtn.MouseButton1Up:Connect(function() moveUp = 0 end)
	downBtn.MouseLeave:Connect(function() moveUp = 0 end)

	return flyBtn, invisBtn
end

local flyBtn, invisBtn = createGui()

------------------------------------------------------------
-- ✈️ ระบบบิน
------------------------------------------------------------
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
	if bodyVel then bodyVel:Destroy() bodyVel = nil end
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
end

------------------------------------------------------------
-- 🔁 Loop
------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if flyBtn then flyBtn.Text = flying and "Fly: ON" or "Fly: OFF" end

	if not flying then
		if bodyVel or bodyGyro then stopFlying() end
		return
	end

	if not bodyVel or not bodyGyro then startFlying() end
	if not bodyVel or not bodyGyro then return end

	local moveDir = humanoid.MoveDirection
	local horizontal = Vector3.new(moveDir.X, 0, moveDir.Z)
	if horizontal.Magnitude > 1 then horizontal = horizontal.Unit end
	local horizontalVelocity = horizontal * flightSpeed

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

------------------------------------------------------------
-- ♻️ รีเซ็ตเมื่อรีสปอว์น
------------------------------------------------------------
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
	flying = false
	invisible = false
	moveUp = 0
	stopFlying()
end)
