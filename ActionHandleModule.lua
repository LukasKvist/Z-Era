-- this is responsible for things like dash, movement, other character efvents

--[[
	𝗙𝗨𝗧𝗨𝗥𝗘 𝗡𝗢𝗧𝗘𝗦:

	- Använd "HoldingValues" i local input för att hantera att flyga upp och ned.

]]

local module = {}

-- // SERVICES
local TS = game:GetService("TweenService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

-- // VARIABLES
local Remote = script.Parent.Parent:WaitForChild("Actions"):WaitForChild("Action")

local EffectModule = require(game.ServerScriptService.Scripts.Modules.CreateEffect)
local CombatModule = require(game.ServerScriptService.Scripts.Modules.Player.CombatHandler)
--local DataModule = require(game.ServerScriptService.Scripts.Modules.Data.DataModule)

-- // PLAYER VARIABLES
local Character = script.Parent.Parent
local Humanoid = Character:WaitForChild("Humanoid")
local Root:Part = Character:WaitForChild("HumanoidRootPart")

local Effects = Character.Effects

local Player = Players:GetPlayerFromCharacter(Character)

-- COMBAT STUFF --
function module.Combat(tab)
	if Effects:FindFirstChild("Stun") then return end
	if Effects:FindFirstChild("Skill") then return end
	if Character:FindFirstChildOfClass("Tool") then return end

	CombatModule.ExecuteTask({Task = tab.Type; Player = Player; Character = Character; FightingStyle = "Normal"; Last = tab.LastM1; Aerial = tab.Aerial}) -- Fighting style will use data later on
end

-- FLIGHT --
local FlightCD = 2
local FlightDB = false

local BaseFlightSpeed = 60

local IdleAnimation:AnimationTrack = Humanoid:LoadAnimation(script.FlightAnimations.IdleAnimation)
local AscendAnim:AnimationTrack = Humanoid:LoadAnimation(script.FlightAnimations.Ascend)
local DescendAnim:AnimationTrack = Humanoid:LoadAnimation(script.FlightAnimations.Descend)
local FlightAnim:AnimationTrack = Humanoid:LoadAnimation(script.FlightAnimations.Flight)

function module.Flight(tab)
	if Effects:FindFirstChild("Stun") then return end
	if Effects:FindFirstChild("Skill") then return end
	if Effects:FindFirstChild("M1") then return end -- We will add so velocity goes to Vector.new(0,0,0) here
	if Effects:FindFirstChild("Critical") then return end -- We will add so velocity goes to Vector.new(0,0,0) here

	-- Check what we should do --
	if tab.Task == "Initialized" then -- This is for starting & stopping flight
		if FlightDB == false then
			FlightDB = true

			if not Effects:FindFirstChild("Flight") and not Root:FindFirstChild("FlightVelocity") then 
				warn("Starting to fly")

				-- BEGIN FLIGHT --
				task.delay(0.5, function()
					EffectModule("Flight", Effects)
				end)

				-- Character Effects --
				--Humanoid.WalkSpeed = 0
				Humanoid.JumpPower = 0

				Character.Animate.Enabled = false

				for _, track in pairs(Humanoid:GetPlayingAnimationTracks()) do
					track:Stop()
				end

				-- Create Velocity --
				local Vel = Instance.new("BodyVelocity")
				Vel.MaxForce = Vector3.new(1,1,1) * math.huge
				Vel.Velocity = Vector3.new(0,0,0)
				Vel.Name = "FlightVelocity"

				Vel.Parent = Root
				
				-- Play animation
				Humanoid:LoadAnimation(script.FlightAnimations.Jump):Play()

				TS:Create(Root, TweenInfo.new(0.5), {CFrame = Root.CFrame + Vector3.new(0,1,0)}):Play()

			else
				warn("Stopping flight")

				if Root:FindFirstChild("FlightVelocity") then
					Root.FlightVelocity:Destroy()
				end

				Effects.Flight:Destroy()

				-- Character Effects --
				Humanoid.WalkSpeed = 16
				Humanoid.JumpPower = 50
				
				local FallAnim = Humanoid:LoadAnimation(script.FlightAnimations.Fall)
				FallAnim:Play()

				Character.Animate.Enabled = true
				
				repeat task.wait() until Humanoid:GetState() == Enum.HumanoidStateType.Landed or Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
				FallAnim:Stop()
				Humanoid:LoadAnimation(script.FlightAnimations.Land):Play()
			end

			task.wait(FlightCD)
			FlightDB = false
		end
	end

	-- THIS IS FOR FLIGHT MOVEMENT --
	if tab.Task == "Movement" then
		local CameraCFrame:CFrame = tab.CameraCFrame
		local FlightVel:BodyVelocity = Root:FindFirstChild("FlightVelocity")

		if FlightVel then

			local MoveDirection = Humanoid.MoveDirection
			local CameraVector = CameraCFrame.LookVector

			local VerticalDirection = nil -- Variable ot track descent and asencsion

			if tab.HeldKeys["Space"] == true and tab.HeldKeys["LeftControl"] == false then
				VerticalDirection = Vector3.new(0,0.5,0)
				
				if AscendAnim.IsPlaying == false then
					AscendAnim:AdjustSpeed(1)
					AscendAnim:Play()
					
					task.delay(0.35, function()
						AscendAnim:AdjustSpeed(0)
					end)
					
					if DescendAnim.IsPlaying then
						DescendAnim:Stop()
					end
				end

			elseif tab.HeldKeys["Space"] == false and tab.HeldKeys["LeftControl"] == true then
				VerticalDirection = Vector3.new(0,-0.5,0)
				
				if DescendAnim.IsPlaying == false then
					DescendAnim:AdjustSpeed(1)
					DescendAnim:Play()
					
					task.delay(0.5, function()
						DescendAnim:AdjustSpeed(0)
					end)

					if AscendAnim.IsPlaying then
						AscendAnim:Stop()
					end
				end
				
			else -- Not doing either of them
				if DescendAnim.IsPlaying then
					DescendAnim:Stop()

				end
				
				if AscendAnim.IsPlaying then
					AscendAnim:Stop()
				end
				
			end

			-- calculate how we should move depending on movedirection, Vertical and camera vector
			if MoveDirection.Magnitude > 0 then
				-- sotp idle animation
				if IdleAnimation.IsPlaying then
					IdleAnimation:Stop()
				end
				
				local Y = CameraVector.Y

				if MoveDirection:Dot(CameraVector) < 0 then
					Y = -CameraVector.Y
				end

				if VerticalDirection ~= nil then
					-- Add VerticalDirection to Y
					Y = Y + VerticalDirection.Y
				end

				FlightVel.Velocity = (MoveDirection + Vector3.new(0,Y,0)) * BaseFlightSpeed
				
				if FlightAnim.IsPlaying then return end
				
				FlightAnim:AdjustSpeed(1)
				FlightAnim:Play()
				
				task.delay(0.5, function()
					FlightAnim:AdjustSpeed(0)
				end)


			else -- theyre standing still

				-- check if they're trying to descend or ascend
				if VerticalDirection ~= nil then -- theyre tring to move
					FlightVel.Velocity = VerticalDirection * BaseFlightSpeed

				else -- They're in an "idle" state
					FlightVel.Velocity = Vector3.new(0,0,0)

					-- Return if an animation is playing
					if FlightAnim.IsPlaying then
						FlightAnim:Stop()
					end
					
					if IdleAnimation.IsPlaying then return end

					-- Start an idle if none is playing
					IdleAnimation:Play()
				end
			end

		end
	end
end

-- ENERGY BLAST ..
local BlastCD = 4.5
local BlastDB = false
function module.EnergyBlast(tab)
	if Effects:FindFirstChild("Stun") then return end
	if Effects:FindFirstChild("M1") then return end
	if Effects:FindFirstChild("Skill") then return end

	if BlastDB == false then
		BlastDB = true

		if tick() - tab.TimeHeld >= 2 then
			warn("Doing 8 blasts")

		else
			warn("Doing one blast")

		end
		task.wait(BlastCD)
		BlastDB = false
	end
end

-- PARRY AND BLOCK --
local ParryCD = 2
local ParryDur = 0.2
local ParryDB = false

local BlockDB = false
local BlockCD = 0.5

local BlockAnim = Humanoid:LoadAnimation(RS.CombatAnims.Block)

function module.Parry(tab)
	if Effects:FindFirstChild("ParryBlock") then return end
	if Effects:FindFirstChild("M1") then return end
	if Effects:FindFirstChild("Skill") then return end

	if tab.State == true then -- start blocking
		if BlockDB == false then
			BlockDB = true

			Character:SetAttribute("FKeyDown", true)
			if ParryDB == false then -- fire a parry
				ParryDB = true

				task.delay(ParryCD + ParryDur, function()
					ParryDB = false
				end)

				warn("Parry")

				local par = Instance.new("BoolValue")
				par.Name = "Parry"
				par.Parent = Effects

				task.delay(ParryDur, function()
					par:Destroy()
					print("Stopped parrying")
					if Character:GetAttribute("FKeyDown") == true then
						warn("Still holding, starting to block")
						BlockAnim:Play()

						local Block = Instance.new("BoolValue")
						Block.Name = "Block"
						Block.Parent = Effects
					end

				end)

			else -- start blocking
				warn("Block")

				BlockAnim:Play()

				local Block = Instance.new("BoolValue")
				Block.Name = "Block"
				Block.Parent = Effects
			end
		end

	else -- STOP BLOCKING		
		repeat task.wait() until not Effects:FindFirstChild("Parry")

		warn("Stopped blocking")

		Character:SetAttribute("FKeyDown", false)
		BlockAnim:Stop()

		if Effects:FindFirstChild("Block") then
			Effects.Block:Destroy()
		end

		task.wait(BlockCD)

		BlockDB = false
	end

end

-- DASH --
local DashSpeed = 50
local DashCd = 2
local DashDuration = .2
local DashDebounce = false
function module.Dash(tab) -- tab is a table containing factors, here it would be empty but for combat etc we could store dmg, stun and more
	if DashDebounce == true then return end
	-- add checks if we add effects folder, like stun etc
	DashDebounce = true -- set deboucne true so they cant spam dash

	warn("DASH!!")
	local MoveDirection = Humanoid.MoveDirection

	if MoveDirection.Magnitude > 0 then -- we dash in any direction		
		local Unit = MoveDirection.Unit

		local dashVector = Unit * DashSpeed

		local BodyVel = Instance.new("BodyVelocity")
		BodyVel.Parent = Root
		BodyVel.MaxForce = Vector3.new(math.huge,0,math.huge)
		BodyVel.Velocity = dashVector

		task.wait(DashDuration)

		game.Debris:AddItem(BodyVel, 0)
		-- destroy other stuff if we choose to add effects folder


	else -- if they dont have a magnitude, ie theyre standing still

		-- DASH BACK
	end

	task.wait(DashCd)
	DashDebounce = false
end

-- Scouter
local ScouterActive = false
local ScouterDebounce = false
local ScouterDB = 1

local PeopleNear = {}

function module.Scouter(Tab) -- {}
	if ScouterDebounce == true then return end

	if ScouterActive == false then
		warn("Start scouter")
		ScouterActive = true
		ScouterDebounce = true

		Remote:FireClient(Player, {On = true; Scouter = "Green";})

		task.delay(1, function()
			ScouterDebounce = false
		end)

		while ScouterActive == true do
			if ScouterActive == false then break end
			task.wait()
			for _, Humanoids in pairs(game.Workspace.LivingThings:GetDescendants()) do
				if Humanoids:IsA("Humanoid") then
					local otherCharacter = Humanoids.Parent
					if otherCharacter == Character then continue end

					print(otherCharacter)
					--local otherPlayer = game.Players:GetPlayerFromCharacter(otherCharacter)

					local otherRoot = otherCharacter:FindFirstChild("HumanoidRootPart")

					if not otherRoot then continue end

					local dist = (otherRoot.Position - Root.Position).Magnitude
					--print(dist)

					if dist < 50 then
						if not table.find(PeopleNear, otherCharacter) and ScouterActive == true then
							table.insert(PeopleNear, otherCharacter)
							warn("Found a humanoid near you")

							local BP = require(game.ServerScriptService.Scripts.Modules.Player.Sub.SkillPoint).ReturnBP(otherCharacter)
							Remote:FireClient(Player, {Scouter = "Green"; Target = otherCharacter; BP = BP})
						end
					else
						if table.find(PeopleNear, otherCharacter) and ScouterActive == true then
							table.remove(PeopleNear, table.find(PeopleNear, otherCharacter))
							warn("Removed, too far away")
							Remote:FireClient(Player, {Scouter = "Green"; Target = otherCharacter})
						end
					end

				end

			end
		end

	else -- if scouther is on
		ScouterActive = false
		ScouterDebounce = true

		PeopleNear = {}

		Remote:FireClient(Player, {Off = true; Scouter = "Green"})
		warn("Shut off scouter")
		task.delay(1, function()
			ScouterDebounce = false
		end)
	end
end
--[[
local TransformDB = false
local TransformCD = 5
function module.Transformation(tab)
	if TransformDB == false then
		TransformDB = true

		local TransformationModules = game.ServerScriptService.Scripts.Modules.Transformations

		local Transformations = DataModule:Get(Player, "Transformations")
		local Equipped = Transformations["Equipped"]

		if Equipped == "" then warn("You have no transformation equipped") return end

		if TransformationModules:FindFirstChild(Equipped) then

			if Character:GetAttribute("Transformed") then
				warn("Untranformiun g")
				Character:SetAttribute("Transformed", nil) -- remove transform value
				require(TransformationModules[Equipped]).UnTransform({Character = Character})


			else
				-- Set them to transformen
				warn("Transfcorming")
				Character:SetAttribute("Transformed", Equipped)
				-- intitalize their unique transformation
				require(TransformationModules[Equipped]).Transform({Character = Character})

			end

		end

		task.wait(TransformCD)
		TransformDB = false
	end

end]]

return module
