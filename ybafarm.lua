-- ✅ Авто-сбор и продажа предметов с безопасной телепортацией и камерой сверху
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

------------------------------------------------------------
-- 🟦 GUI
------------------------------------------------------------
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoCollectorUI"
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 150)
frame.Position = UDim2.new(0, 25, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, -20, 0, 40)
startBtn.Position = UDim2.new(0, 10, 0, 10)
startBtn.Text = "▶ Старт"
startBtn.BackgroundColor3 = Color3.fromRGB(50, 160, 70)
startBtn.TextColor3 = Color3.new(1,1,1)
startBtn.Font = Enum.Font.SourceSansBold
startBtn.TextSize = 20
startBtn.Parent = frame

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, -20, 0, 40)
stopBtn.Position = UDim2.new(0, 10, 0, 60)
stopBtn.Text = "■ Стоп"
stopBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 60)
stopBtn.TextColor3 = Color3.new(1,1,1)
stopBtn.Font = Enum.Font.SourceSansBold
stopBtn.TextSize = 20
stopBtn.Parent = frame

local counterLabel = Instance.new("TextLabel")
counterLabel.Size = UDim2.new(1, -20, 0, 30)
counterLabel.Position = UDim2.new(0, 10, 0, 105)
counterLabel.BackgroundTransparency = 1
counterLabel.TextColor3 = Color3.new(1,1,1)
counterLabel.Font = Enum.Font.SourceSansBold
counterLabel.TextSize = 18
counterLabel.Text = "Подобрано: 0"
counterLabel.Parent = frame

------------------------------------------------------------
-- NOCLIP (всегда включён)
------------------------------------------------------------
getgenv().Players = game:GetService'Players'
getgenv().Host = Players.LocalPlayer
getgenv().RunService = game:GetService'RunService'

RunService.RenderStepped:Connect(function()
    if Host.Character then
        for _,v in pairs(Host.Character:GetDescendants()) do
            if v:IsA'BasePart' then
                v.CanCollide = false
            end
        end
    end
end)

------------------------------------------------------------
-- ⚙️ Переменные
------------------------------------------------------------
local isRunning = false
local collectedCount = 0
local itemsFolder = workspace:FindFirstChild("Item_Spawns") and workspace.Item_Spawns:FindFirstChild("Items")
local TELEPORT_STEP = 50
local TELEPORT_DELAY = 0.03

------------------------------------------------------------
-- 🎯 Цели для сбора / продажи
------------------------------------------------------------
local allowedItems = {
	["Mysterious Arrow"] = true,
	["Gold Coin"] = true,
	["Rokakaka"] = true,
	["Rib Cage of The Saint's Corpse"] = true,
	["Zeppelin's Headband"] = true,
	["Ancient Scroll"] = true,
	["Quinton's Glove"] = true,
	["Stone Mask"] = true,
	["Diamond"] = true,
	["Caesar's Headband"] = true,
	["Clackers"] = true
}
local targetNames = allowedItems

------------------------------------------------------------
-- 🚀 Телепортация с шагами и платформой
------------------------------------------------------------
local function safeTeleport(targetPos)
	if not humanoidRootPart or not character then return end

	-- Создаём временную платформу под игроком
	local platform = Instance.new("Part")
	platform.Size = Vector3.new(10,1,10)
	platform.Anchored = true
	platform.CanCollide = true
	platform.Position = humanoidRootPart.Position - Vector3.new(0, 3, 0)
	platform.Parent = workspace

	local startPos = humanoidRootPart.Position
	local vector = targetPos - startPos
	local distance = vector.Magnitude
	local steps = math.ceil(distance / TELEPORT_STEP)
	local step = vector / steps

	for i = 1, steps do
		if not isRunning then break end
		local nextPos = humanoidRootPart.Position + step
		humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
		humanoidRootPart.CFrame = CFrame.new(nextPos)
		platform.Position = humanoidRootPart.Position - Vector3.new(0,3,0)
		task.wait(TELEPORT_DELAY)
	end

	-- Удаляем платформу после телепорта
	platform:Destroy()
end

------------------------------------------------------------
-- 🧲 Сбор предметов с камерой сверху
------------------------------------------------------------
local function moveAndCollect(model, prompt)
	local basePart = model:FindFirstChildWhichIsA("BasePart")
	if not basePart or not prompt then return end

	-- Телепорт к предмету
	safeTeleport(basePart.Position)
	task.wait(0.05)

	-- Камера сверху
	local cam = workspace.CurrentCamera
	local oldType = cam.CameraType
	local oldCFrame = cam.CFrame
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.new(humanoidRootPart.Position + Vector3.new(0,30,0), basePart.Position)

	-- Подбор предмета
	if prompt.Enabled then
		prompt:InputHoldBegin()
		task.wait((prompt.HoldDuration or 0.5) + 0.05)
		prompt:InputHoldEnd()
	end

	-- Возвращаем камеру игроку
	cam.CameraType = oldType
	cam.CFrame = oldCFrame

	-- Ждём пока предмет исчезнет
	local startTime = os.clock()
	while model.Parent == itemsFolder and os.clock() - startTime < 3 do
		task.wait(0.05)
	end

	collectedCount += 1
	counterLabel.Text = "Подобрано: " .. collectedCount
end

------------------------------------------------------------
-- 💰 Продажа предметов
------------------------------------------------------------
local SELL_DELAY = 0.2

local function sellItem(item)
	local char = player.Character
	if not char or not item then return end

	local foundItem = player.Backpack:FindFirstChild(item.Name)
	if foundItem then
		foundItem.Parent = game.Workspace.Living:FindFirstChild(player.Name)
	end

	local remote = char:FindFirstChild("RemoteEvent")
	if not remote then
		warn("⚠️ RemoteEvent не найден!")
		return
	end

	local args = {
		[1] = "EndDialogue",
		[2] = {
			["NPC"] = "Merchant",
			["Option"] = "Option2",
			["Dialogue"] = "Dialogue5"
		}
	}
	remote:FireServer(unpack(args))
	print("[💰] Продан предмет:", item.Name)
end

local function sellAllowedItems()
	local backpack = player.Backpack
	for _, item in pairs(backpack:GetChildren()) do
		if allowedItems[item.Name] then
			sellItem(item)
			task.wait(SELL_DELAY)
		end
	end
end

------------------------------------------------------------
-- 🔁 Основной цикл сбора
------------------------------------------------------------
local function mainAutoCollect()
	while isRunning do
		for _, model in ipairs(itemsFolder:GetChildren()) do
			if not isRunning then break end
			local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt and targetNames[prompt.ObjectText] then
				moveAndCollect(model, prompt)
			end
		end
		sellAllowedItems()
		task.wait(0.05) -- быстрое сканирование карты
	end
end

------------------------------------------------------------
-- ▶️ Управление
------------------------------------------------------------
local function startAutoCollect()
	if isRunning or not itemsFolder then return end
	isRunning = true
	collectedCount = 0
	counterLabel.Text = "Подобрано: 0"
	task.spawn(mainAutoCollect)
end

local function stopAutoCollect()
	isRunning = false
end

startBtn.MouseButton1Click:Connect(startAutoCollect)
stopBtn.MouseButton1Click:Connect(stopAutoCollect)

print("[✅] Авто-сбор и продажа с телепортацией, платформой и камерой сверху запущен.")
