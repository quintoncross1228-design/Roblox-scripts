local Players = game:GetService("Players")

-- Configuration
local HOP_HEIGHT = 1.5
local HOP_TIME = 0.25
local FALL_TIME = 0.35

-- Bounce logic with styles
local function startBounce(chassis: BasePart, mode: string)
    if not chassis then return end

    local bodyPos = chassis:FindFirstChild("LowriderBodyPosition")
    if not bodyPos then
        bodyPos = Instance.new("BodyPosition")
        bodyPos.Name = "LowriderBodyPosition"
        bodyPos.MaxForce = Vector3.new(50000, 50000, 50000)
        bodyPos.P = 15000
        bodyPos.D = 2000
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

-- Detect when a player sits in a vehicle seat
local function setupSeat(seat: VehicleSeat)
    seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        local humanoid = seat.Occupant
        if humanoid and humanoid.Parent then
            local player = Players:GetPlayerFromCharacter(humanoid.Parent)
            if not player then return end

            local car = seat:FindFirstAncestorOfClass("Model")
            if not car then return end

            local chassis = car:FindFirstChild("Chassis") or car:FindFirstChild("Body") or car.PrimaryPart
            if not (chassis and chassis:IsA("BasePart")) then return end

            -- Ensure RemoteEvent exists
            local remote = car:FindFirstChild("LowriderRemote")
            if not remote then
                remote = Instance.new("RemoteEvent")
                remote.Name = "LowriderRemote"
                remote.Parent = car
            end

            -- Hydraulics loop state
            local hydraulicsEnabled = false

            -- Connect remote to bounce function
            remote.OnServerEvent:Connect(function(plr, mode)
                if plr == player then
                    if mode == "HydraulicsToggle" then
                        hydraulicsEnabled = not hydraulicsEnabled
                        if hydraulicsEnabled then
                            task.spawn(function()
                                while hydraulicsEnabled do
                                    startBounce(chassis, "Full")
                                    task.wait(0.8) -- repeat delay
                                end
                            end)
                        end
                    else
                        startBounce(chassis, mode or "Full")
                    end
                end
            end)

            -- Give player the GUI
            local playerGui = player:WaitForChild("PlayerGui")
            if not playerGui:FindFirstChild("LowriderGui") then
                local gui = Instance.new("ScreenGui")
                gui.Name = "LowriderGui"
                gui.ResetOnSpawn = false
                gui.Parent = playerGui

                local function makeButton(text, pos, mode)
                    local button = Instance.new("TextButton")
                    button.Size = UDim2.new(0, 120, 0, 40)
                    button.Position = pos
                    button.Text = text
                    button.Parent = gui

                    local localScript = Instance.new("LocalScript")
                    localScript.Source = string.format([[
                        local button = script.Parent
                        local player = game.Players.LocalPlayer
                        button.MouseButton1Click:Connect(function()
                            local char = player.Character
                            if char then
                                local remote = char:FindFirstChild("LowriderRemote", true)
                                if remote and remote:IsA("RemoteEvent") then
                                    remote:FireServer("%s")
                                end
                            end
                        end)
                    ]], mode)
                    localScript.Parent = button
                end

                -- Buttons layout
                makeButton("Full Bounce", UDim2.new(0.5, -60, 0.65, 0), "Full")
                makeButton("Front Bounce", UDim2.new(0.5, -60, 0.7, 0), "Front")
                makeButton("Back Bounce", UDim2.new(0.5, -60, 0.75, 0), "Back")
                makeButton("Left Bounce", UDim2.new(0.5, -60, 0.8, 0), "Left")
                makeButton("Right Bounce", UDim2.new(0.5, -60, 0.85, 0), "Right")
                makeButton("Hydraulics Mode", UDim2.new(0.5, -60, 0.9, 0), "HydraulicsToggle")
            end
        end
    end)
end

-- Hook all existing and new seats
for _, seat in ipairs(workspace:GetDescendants()) do
    if seat:IsA("VehicleSeat") then
        setupSeat(seat)
    end
end

workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("VehicleSeat") then
        setupSeat(desc)
    end
end)
