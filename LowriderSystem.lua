-- Lowrider Show Mode (Visual + Audio)
-- By Quinton

local Players = game:GetService("Players")

-- Settings
local SHAKE_INTENSITY = 2
local SHAKE_DURATION = 0.3
local RHYTHM_DELAY = 0.8

-- Camera shake effect
local function cameraShake(player)
    local cam = workspace.CurrentCamera
    if not cam then return end

    local originalCF = cam.CFrame
    local offset = Vector3.new(
        math.random(-SHAKE_INTENSITY, SHAKE_INTENSITY) * 0.1,
        math.random(-SHAKE_INTENSITY, SHAKE_INTENSITY) * 0.1,
        0
    )
    cam.CFrame = originalCF * CFrame.new(offset)

    task.delay(SHAKE_DURATION, function()
        cam.CFrame = originalCF
    end)
end

-- Screen pulse effect
local function screenPulse(player)
    local gui = player:WaitForChild("PlayerGui")
    local pulse = Instance.new("Frame")
    pulse.Size = UDim2.new(1,0,1,0)
    pulse.BackgroundColor3 = Color3.fromRGB(255,255,255)
    pulse.BackgroundTransparency = 0.7
    pulse.Parent = gui

    pulse:TweenSizeAndPosition(
        UDim2.new(1.2,0,1.2,0),
        UDim2.new(-0.1,0,-0.1,0),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        SHAKE_DURATION,
        true,
        function()
            pulse:Destroy()
        end
    )
end

-- Bounce show effect
local function showBounce(player, mode)
    cameraShake(player)
    screenPulse(player)

    -- Play sound
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://138248981" -- bass thump
    sound.Volume = 2
    sound.Parent = workspace
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 2)
end

-- GUI creation
local function giveGui(player, remote)
    local playerGui = player:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("LowriderGui") then return end

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

        button.MouseButton1Click:Connect(function()
            showBounce(player, mode)
        end)
    end

    makeButton("Full Bounce", UDim2.new(0.5, -60, 0.65, 0), "Full")
    makeButton("Front Bounce", UDim2.new(0.5, -60, 0.70, 0), "Front")
    makeButton("Back Bounce", UDim2.new(0.5, -60, 0.75, 0), "Back")
    makeButton("Left Bounce", UDim2.new(0.5, -60, 0.80, 0), "Left")
    makeButton("Right Bounce", UDim2.new(0.5, -60, 0.85, 0), "Right")
    makeButton("Hydraulics Mode", UDim2.new(0.5, -60, 0.90, 0), "HydraulicsToggle")
end

-- Give GUI when player joins
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        giveGui(player)
    end)
end)

-- For existing players
for _, player in ipairs(Players:GetPlayers()) do
    giveGui(player)
end
