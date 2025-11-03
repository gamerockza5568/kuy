-- LocalScript (StarterPlayer > StarterPlayerScripts)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- RemoteEvent สำหรับหายตัว (สร้างใน Server Script ด้านล่าง)
local invisibleEvent = ReplicatedStorage:WaitForChild("ToggleInvisibility")

-- ====== ตั้งค่าการบิน ======
local flying = false
local flightSpeed = 60
local hoverHeight = rootPart.Position.Y
local moveUp = 0

local bodyVel
local bodyGyro

-- ====== GUI: ปุ่มเมนู + แผงควบคุม ======
local function createGui()
	local pg = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "FlyGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = pg

	-- ปุ่มเปิด/ปิดแผงควบคุม (ตอนแรกมีปุ่มนี้ปุ่มเดียว)
	local menuBtn = Instance.new("TextButton")
	menuBtn.Name = "MenuButton"
	menuBtn.Size = UDim2.new(0, 140, 0, 50)
	menuBtn.Position = UDim2.new(0, 20, 1, -70) -- ล่างซ้าย
	menuBtn.Text = "Menu"
	menuBtn.Font = Enum.Font.SourceSansBold
	menuBtn.TextSize = 22
	menuBtn.Background
