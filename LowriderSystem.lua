-- Lowrider System Script (Universal)
-- By Quinton

local Players = game:GetService("Players")

-- Settings
local HOP_HEIGHT = 1.5
local HOP_TIME = 0.25
local FALL_TIME = 0.35
local HYDRAULICS_DELAY = 0.8

-- Find a bounceable chassis part
local function findChassis(car: Model): BasePart?
    if not car then return nil end
    local chassis = car:FindFirstChild("Chassis") or car:FindFirstChild("Body") or car.PrimaryPart
    if chassis and chassis:IsA("BasePart") then return chassis end
    for _, part in ipairs(car:GetDescendants()) do
        if part:IsA("BasePart") then
            local n = part.Name:lower()
            if n:find("chassis") or n:find("body") or n:find("frame") or n:find("base") or n:find("main") then
                return part
            end
        end
    end
    for _, part in ipairs(car:GetDescendants()) do
        if part:IsA("BasePart") then return part end
    end
    return nil
end

-- Bounce logic
local function startBounce(chassis: BasePart, mode: string)
    if not chassis then return end

    local bodyPos = chassis:FindFirstChild("LowriderBodyPosition")
    if not bodyPos then
        bodyPos = Instance.new("BodyPosition")
        bodyPos.Name = "LowriderBodyPosition"
        bodyPos.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        bodyPos.P = 15000
        bodyPos.D = 2000
        bodyPos.Position = chassis.Position
        bodyPos.Parent = chassis
    end

    local originalPos = chassis.Position
    local targetPos = originalPos

    if mode == "Full" then
        targetPos = originalPos + Vector3.new(0, HOP_HEIGHT, 0)
    elseif mode == "Front" then
        targetPos = originalPos + Vector3.new(0, HOP_HEIGHT, -0.5)
    elseif mode == "Back" then
        targetPos = originalPos + Vector3.new(0, HOP_HEIGHT, 0.5)
    elseif mode == "Left" then
        targetPos = originalPos + Vector3.new(-0.5, HOP_HEIGHT, 0)
    elseif mode == "Right" then
        targetPos = originalPos + Vector3.new(0.5, HOP_HEIGHT, 0)
    end

    bodyPos.Position = targetPos
    task.delay(HOP_TIME, function()
        bodyPos.Position = originalPos
        task.delay(FALL_TIME, function()
            bodyPos.Position = originalPos
        end)
    end)
end

-- GUI creation
local function giveGui(player: Player, remote: RemoteEvent)
    local playerGui = player:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("LowriderGui") then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "LowriderGui"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local function makeButton(text: string, pos: UDim2, mode: string)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 120, 0, 40)
        button.Position = pos
        button.Text = text
        button.Parent = gui

        local ref = Instance.new("ObjectValue")
        ref.Name = "RemoteRef"
        ref.Value = remote
        ref.Parent = button

        local localScript = Instance.new("LocalScript")
        localScript.Source = [[
            local button = script.Parent
            local remoteRef = button:WaitForChild("RemoteRef")
            local remote = remoteRef.Value
            local mode = button:GetAttribute("Mode")

            button.MouseButton1Click:Connect(function()
                if remote then
                    remote:FireServer(mode)
                end
            end)
        ]]
        localScript.Parent = button
        button:SetAttribute("Mode", mode)
    end

    makeButton("Full Bounce", UDim2.new(0.5, -60, 0.65, 0), "Full")
    makeButton("Front Bounce", UDim2.new(0.5, -60, 0.70, 0), "Front")
    makeButton("Back Bounce", UDim2.new(0.5, -60, 0.75, 0), "Back")
    makeButton("Left Bounce", UDim2.new(0.5, -60, 0.80, 0), "Left")
    makeButton("Right Bounce", UDim2.new(0.5, -60, 0.85, 0), "Right")
    makeButton("Hydraulics Mode", UDim2.new(0.5, -60, 0.90, 0), "HydraulicsToggle")
end

-- Seat setup
local function setupSeat(seat)
    if not (seat and (seat:IsA("VehicleSeat") or seat:IsA("Seat"))) then return end

    local hydraulicsEnabled = false
    local connection
    local car = seat:FindFirstAncestorOfClass("Model")
    if not car then return end

    seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        local humanoid = seat.Occupant
        if connection then connection:Disconnect() connection = nil end
        hydraulicsEnabled = false

        if humanoid and humanoid.Parent then
            local player = Players:GetPlayerFromCharacter(humanoid.Parent)
            if not player then return end

            local chassis = findChassis(car)
            if not (chassis and chassis:IsA("BasePart")) then return end

            local remote = car:FindFirstChild("LowriderRemote")
            if not remote then
                remote = Instance.new("RemoteEvent")
                remote.Name = "LowriderRemote"
                remote.Parent = car
            end

            connection = remote.OnServerEvent:Connect(function(plr, mode)
                if plr ~= player then return end
                if mode == "HydraulicsToggle" then
                    hydraulicsEnabled = not hydraulicsEnabled
                    if hydraulicsEnabled then
                        task.spawn(function()
                            while hydraulicsEnabled and seat.Occupant == humanoid do
                                startBounce(chassis, "Full")
                                task.wait(HYDRAULICS_DELAY)
                            end
                        end)
                    end
                else
                    startBounce(chassis, mode or "Full")
                end
            end)

            giveGui(player, remote)
        end
    end)
end

-- Hook seats
for _, desc in ipairs(workspace:GetDescendants()) do
    if desc:IsA("VehicleSeat") or desc:IsA("Seat") then
        setupSeat(desc)
    end
end

workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("VehicleSeat") or desc:IsA("Seat") then
        setupSeat(desc)
    end
end)
