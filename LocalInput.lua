-- // SERVICES
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

-- // VARIABLES
local Character = script.Parent.Parent

local Remote = script.Parent.Parent.Actions.Action

local HoldingValues = {["E"] = false; ["Space"] = false; ["LeftControl"] = false}
local HoldingTime = {["E"] = tick()}

local WASD = {["W"] = false, ["S"] = false, ["D"] = false, ["A"] = false}

local LastM1 = 0 -- to keep track fi we reset count

UIS.InputBegan:Connect(function(input, gpe)
	-- Handles holding values, for now only Ki Blasts and space for aerial --
	
	if gpe then return end
	
	if HoldingValues[input.KeyCode.Name] ~= nil then
		HoldingValues[input.KeyCode.Name] = true
	end

	if WASD[input.KeyCode.Name] ~= nil then
		WASD[input.KeyCode.Name] = true

	end
	
	-- Update holdingtime to see how long youve been holding --
	if HoldingTime[input.KeyCode.Name] then
		HoldingTime[input.KeyCode.Name] = tick()
	end
	
	if input.KeyCode == Enum.KeyCode.Q then
		Remote:FireServer("Dash", {}) -- the {} is empty because we dont need any additional info
	end

	-- Scouter
	if input.KeyCode == Enum.KeyCode.Z then
		Remote:FireServer("Scouter", {})
	end

	-- Transformation
	if input.KeyCode == Enum.KeyCode.G then
		Remote:FireServer("Transformation", {})
	end

	-- PARRY, BLOCK --
	if input.KeyCode == Enum.KeyCode.F then
		Remote:FireServer("Parry", {State = true})
	end

	-- FLIGHT --
	
	if input.KeyCode == Enum.KeyCode.Space then
		if HoldingValues.LeftControl == true then -- Start flying
			Remote:FireServer("Flight", {Task = "Initialized"})
		end
	end

	-- M1 --
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		--print("M1")
		if LastM1 == 0 then
			LastM1 = tick()
		end

		Remote:FireServer("Combat", {Type = "M1"; LastM1 = LastM1; Aerial = HoldingValues.Space})
		LastM1 = tick()
	end

	-- CRITICAL --
	if input.KeyCode == Enum.KeyCode.R then
		Remote:FireServer("Combat", {Type = "Critical"})
	end
end)

UIS.InputEnded:Connect(function(input, gpe)
	if gpe then return end

	-- Handles holding values, for now only Ki Blasts and space for aerial --
	if HoldingValues[input.KeyCode.Name] ~= nil then
		HoldingValues[input.KeyCode.Name] = false
	end
	
	if WASD[input.KeyCode.Name] ~= nil then
		WASD[input.KeyCode.Name] = false
	end

	-- KI BLASTS --
	if input.KeyCode == Enum.KeyCode.E then
		Remote:FireServer("EnergyBlast", {TimeHeld = HoldingTime.E})
	end

	-- PARRY, BLOCK --
	if input.KeyCode == Enum.KeyCode.F then
		Remote:FireServer("Parry", {State = false})
	end

	-- Update holdtime after all the checks to make sure nothing messe sup --
	if HoldingTime[input.KeyCode.Name] then
		HoldingTime[input.KeyCode.Name] = tick()
	end
end)

local function ScouterShit(tab)
	if tab["Off"] then
		print("Turning off")
		for i, v in pairs(game.Workspace.LivingThings:GetDescendants()) do
			if v:IsA("BillboardGui") and v.Name == "ScouterDisplay" then
				print("Destroying billboard")
				v:Destroy()
			end
		end

		-- remove lighting
		if game.Lighting:FindFirstChild(tab.Scouter) then
			game.Lighting[tab.Scouter]:Destroy()
		end
		return
	end

	-- detetc if u turn on
	if tab["On"] then
		-- Tint lighting depending on scouter(color)
		if not game.Lighting:FindFirstChild(tab.Scouter) then
			local LightningEffect = RS.Lighting.Scouter:FindFirstChild(tab.Scouter)
			if LightningEffect then
				local CCclone = LightningEffect:Clone()
				CCclone.Parent = game.Lighting
			end
		end
		return
	end


	-- Add billboard guis
	if not tab.Target.HumanoidRootPart:FindFirstChild("ScouterDisplay") then
		local BillboardClone = RS.Gui.ScouterDisplay:Clone()
		BillboardClone.Parent = tab.Target.HumanoidRootPart

		BillboardClone.Frame.BPM.Text = "BPM: "..tostring(tab.Target.Humanoid.Health)

		if tab.BP then
			BillboardClone.Frame.PowerLevel.Text = "POWER LEVEL: "..tostring(tab.BP)
		end

		tab.Target.Humanoid.Health.Changed:Connect(function()
			BillboardClone.Frame.BPM.Text = "BPM: "..tostring(tab.Target.Humanoid.Health)
		end)
	else -- We remove bilbloard from target, this is for when they leave our ranger
		if tab.Target.HumanoidRootPart:FindFirstChild("ScouterDisplay") then
			tab.Target.HumanoidRootPart.ScouterDisplay:Destroy()
		end
	end
end

-- this is used fvor stuff like scouter
Remote.OnClientEvent:Connect(function(tab) -- tab is a table
	if tab["Scouter"] then
		-- Detect if we should turn it off
		ScouterShit(tab)
	end
end)


coroutine.wrap(function()
	while true do
		task.wait()
		if not Character:WaitForChild("Effects"):FindFirstChild("Flight") then continue end
		
		Remote:FireServer("Flight", {Task = "Movement"; WASD = WASD; CameraCFrame = workspace.CurrentCamera.CFrame})
	end
end)()