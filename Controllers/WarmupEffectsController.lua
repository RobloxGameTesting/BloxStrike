local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local Router = require(ReplicatedStorage.Database.Security.Router)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local LocalPlayer = Players.LocalPlayer
local v = { WarmupColorCorrection = true, FlashbangColorCorrection = true }
local v2 = { "Brightness", "Contrast", "Saturation", "TintColor" }
local v3 = nil

local function getBestMapColorCorrection()
	local v4 = v3

	if v4 and v4.Enabled and v4:IsDescendantOf(Lighting) and not v[v4.Name] then
		return v4
	end

	local v5 = nil
	local v6 = nil

	for _, colorCorrectionEffect in ipairs(Lighting:GetDescendants()) do
		if not colorCorrectionEffect:IsA("ColorCorrectionEffect") or v[colorCorrectionEffect.Name] then
			continue
		end

		if colorCorrectionEffect.Enabled then
			v5 = v5 or colorCorrectionEffect
		end

		if not v6 then
			v6 = colorCorrectionEffect
		end
	end

	v3 = v5 or v6
	return v3
end

local function copyColorCorrection(p, p2) -- 3 equivalent calls inferred from this helper
	for _, v4 in v2 do
		p[v4] = p2[v4]
	end
end

local function findActiveViewmodelModel()
	local currentCamera = Workspace.CurrentCamera

	if not currentCamera then
		return nil
	end

	for _, model in ipairs(currentCamera:GetChildren()) do
		if model:IsA("Model") and model:FindFirstChild("Stats") then
			return model
		end
	end

	for _, model in ipairs(currentCamera:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChild("Stats") then
			return model
		end
	end

	return nil
end

local function getViewmodelModelFromInstance(parent, instance)
	while parent and parent ~= instance do
		if parent:IsA("Model") and parent:FindFirstChild("Stats") then
			return parent
		else
			parent = parent.Parent
		end
	end

	return nil
end

return {
	Start = function()
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local warmup = assets and assets:FindFirstChild("Warmup")

		if not (warmup and warmup:IsA("Folder")) then
			warn("[WarmupEffectsController] Missing ReplicatedStorage.Assets.Warmup")
			return
		end

		local colorCorrection = warmup:FindFirstChild("ColorCorrection")
		local viewmodelHighlight = warmup:FindFirstChild("ViewmodelHighlight")

		if not (colorCorrection and colorCorrection:IsA("ColorCorrectionEffect")) then
			warn("[WarmupEffectsController] Missing Assets.Warmup.ColorCorrection (ColorCorrectionEffect)")
			return
		end

		if not (viewmodelHighlight and viewmodelHighlight:IsA("Highlight")) then
			warn("[WarmupEffectsController] Missing Assets.Warmup.ViewmodelHighlight (Highlight)")
			return
		end

		local count = 0
		local fn = nil
		local flag = false

		local function isEligibleToShow() -- 2 equivalent calls inferred from this helper
			if MenuState.IsInspectActive() or MenuState.IsCaseSceneActive() then
				return false
			end

			local menuFrame = MenuState.GetMenuFrame()

			if menuFrame and menuFrame.Visible then
				return false
			end

			local isSpectating = LocalPlayer:GetAttribute("IsSpectating") == true
			return LocalPlayer.Character ~= nil or isSpectating
		end

		local function stop() -- 4 equivalent calls inferred from this helper
			count += 1

			if fn then
				fn()
				fn = nil
			end
		end

		local function startBuyPeriodEffects()
			stop() -- inferred equivalent call
			count += 1
			local v4 = count
			local v5 = false
			local v6 = false
			local lastTime = nil
			local v7 = nil
			local bestMapColorCorrection = getBestMapColorCorrection()
			local v8 = nil
			local enabled

			if bestMapColorCorrection then
				enabled = bestMapColorCorrection.Enabled or false
			else
				enabled = false
			end

			local v9 = nil

			if bestMapColorCorrection then
				v9 = {}
				copyColorCorrection(v9, bestMapColorCorrection) -- inferred equivalent call
				bestMapColorCorrection.Enabled = true
				copyColorCorrection(bestMapColorCorrection, colorCorrection) -- inferred equivalent call
			else
				warn("[WarmupEffectsController] No map ColorCorrectionEffect found under Lighting; warmup CC tween skipped")
			end

			local function getCountdownRemaining() -- 2 equivalent calls inferred from this helper
				if v5 and lastTime and v7 then
					return (math.max(0, v7 - (os.clock() - lastTime)))
				end

				return 0
			end

			local function startFinalCountdownTweens(duration: number)
				if v5 or duration <= 0 then
					return
				end

				v5 = true
				lastTime = os.clock()
				v7 = duration

				if bestMapColorCorrection and v9 then
					if v8 then
						v8:Cancel()
						v8 = nil
					end

					local tween = TweenService:Create(
						bestMapColorCorrection,
						TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						v9
					)
					v8 = tween
					tween:Play()
				end
			end

			local function maybePlayGameticSound(timer: number) -- 2 equivalent calls inferred from this helper
				if not v6 and timer <= 2 then
					v6 = true
					Router.broadcastRouter("RunRoundSound", "Round Start Countdown")
				end
			end

			local v10 = nil
			local v11 = nil
			local connections = {}
			local v12 = nil
			local flag2 = false
			local v13 = false

			local function releaseHighlight(instance) -- 2 equivalent calls inferred from this helper
				if instance.Parent then
					instance:Destroy()
				end

				if v11 == instance then
					v11 = nil
				end
			end

			local function endHighlightPhase() -- 2 equivalent calls inferred from this helper
				flag2 = true

				if v10 then
					v10:Cancel()
					v10 = nil
				end

				if v11 then
					v11:Destroy()
					v11 = nil
				end
			end

			local function startHighlightTweenIfPossible(instance)
				if flag2 then
					releaseHighlight(instance) -- inferred equivalent call
				else
					if v10 or not v5 then
						return
					end

					local countdownRemaining = getCountdownRemaining() -- inferred equivalent call

					if countdownRemaining <= 0 then
						flag2 = true
						instance.FillTransparency = 1
						instance.OutlineTransparency = 1
						instance:Destroy()

						if v11 == instance then
							v11 = nil
						end
					else
						local tween = TweenService:Create(
							instance,
							TweenInfo.new(countdownRemaining, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ FillTransparency = 1, OutlineTransparency = 1 }
						)
						v10 = tween
						tween.Completed:Connect(function(p)
							if v10 == tween then
								v10 = nil
							end

							if p == Enum.PlaybackState.Completed then
								flag2 = true
							end

							releaseHighlight(instance) -- inferred equivalent call
						end)
						tween:Play()
					end
				end
			end

			local function ensureHighlightAttached()
				if count ~= v4 or flag2 then
					return
				end

				if v5 and getCountdownRemaining() <= 0 then -- inferred equivalent call
					endHighlightPhase() -- inferred equivalent call
				else
					local currentCamera = Workspace.CurrentCamera

					if not currentCamera then
						return
					end

					local v14 = v12

					if not (v14 and v14:IsDescendantOf(currentCamera)) then
						v14 = findActiveViewmodelModel()
						v12 = v14
					end

					if not v14 then
						return
					end

					local clone = v11

					if not clone or clone.Parent == nil then
						clone = viewmodelHighlight:Clone()
						v11 = clone
						v10 = nil
					end

					if clone.Parent ~= v14 then
						clone.Parent = v14
					end

					if clone.Adornee ~= v14 then
						clone.Adornee = v14
					end

					startHighlightTweenIfPossible(clone)
				end
			end

			local function queueEnsureHighlightAttached()
				if v13 or count ~= v4 or flag2 then
					return
				end

				v13 = true
				task.defer(function()
					v13 = false
					ensureHighlightAttached()
				end)
			end

			local function startCountdown(timer: number) -- 1 equivalent call inferred from this helper
				startFinalCountdownTweens(math.min(3, timer))
				local v14 = v11

				if v14 then
					startHighlightTweenIfPossible(v14)
				elseif not v13 and count == v4 then
					if flag2 then
						return
					end

					v13 = true
					task.defer(function()
						v13 = false
						ensureHighlightAttached()
					end)
				end
			end

			ensureHighlightAttached()

			local function disconnectCamera() -- 2 equivalent calls inferred from this helper
				for _, connection in connections do
					connection:Disconnect()
				end

				table.clear(connections)
			end

			local function bindToCamera(currentCamera)
				disconnectCamera() -- inferred equivalent call

				if not currentCamera then
					return
				end

				table.insert(connections, currentCamera.ChildAdded:Connect(function(child)
					if flag2 then
						return
					end

					local viewmodelModelFromInstance = getViewmodelModelFromInstance(child, currentCamera)

					if viewmodelModelFromInstance then
						v12 = viewmodelModelFromInstance
					end

					if not v13 and count == v4 then
						if flag2 then
							return
						end

						v13 = true
						task.defer(function()
							v13 = false
							ensureHighlightAttached()
						end)
					end
				end))
				table.insert(connections, currentCamera.ChildRemoved:Connect(function(child)
					if flag2 then
						return
					end

					if v12 == child or v12 and v12:IsDescendantOf(child) then
						v12 = nil
					end

					if not v13 and count == v4 then
						if flag2 then
							return
						end

						v13 = true
						task.defer(function()
							v13 = false
							ensureHighlightAttached()
						end)
					end
				end))
				table.insert(connections, currentCamera.DescendantAdded:Connect(function(highlight)
					if
						flag2
						or highlight == v11
						or highlight:IsA("Highlight") and highlight.Name == viewmodelHighlight.Name
					then
						return
					end

					local viewmodelModelFromInstance = getViewmodelModelFromInstance(highlight, currentCamera)

					if viewmodelModelFromInstance then
						v12 = viewmodelModelFromInstance

						if not v13 and count == v4 then
							if flag2 then
								return
							end

							v13 = true
							task.defer(function()
								v13 = false
								ensureHighlightAttached()
							end)
						end
					end
				end))
			end

			bindToCamera(Workspace.CurrentCamera)
			local currentCameraChangedConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
				v12 = nil
				bindToCamera(Workspace.CurrentCamera)

				if not v13 and count == v4 then
					if flag2 then
						return
					end

					v13 = true
					task.defer(function()
						v13 = false
						ensureHighlightAttached()
					end)
				end
			end)
			local timerChangedConnection = Workspace:GetAttributeChangedSignal("Timer"):Connect(function()
				if count ~= v4 then
					return
				end

				local timer = Workspace:GetAttribute("Timer")

				if typeof(timer) ~= "number" then
					return
				end

				if timer <= 0 then
					endHighlightPhase() -- inferred equivalent call
				else
					maybePlayGameticSound(timer) -- inferred equivalent call

					if not v5 and timer <= 3 then
						startCountdown(timer) -- inferred equivalent call
					end
				end
			end)
			local timer = Workspace:GetAttribute("Timer")

			if typeof(timer) == "number" and timer > 0 then
				maybePlayGameticSound(timer) -- inferred equivalent call

				if timer <= 3 then
					startFinalCountdownTweens(math.min(3, timer))
					local v14 = v11

					if v14 then
						startHighlightTweenIfPossible(v14)
					elseif not v13 and count == v4 and not flag2 then
						v13 = true
						task.defer(function()
							v13 = false
							ensureHighlightAttached()
						end)
					end
				end
			end

			fn = function()
				v13 = false

				if v8 then
					v8:Cancel()
					v8 = nil
				end

				if v10 then
					v10:Cancel()
					v10 = nil
				end

				disconnectCamera() -- inferred equivalent call
				currentCameraChangedConnection:Disconnect()
				timerChangedConnection:Disconnect()

				if v11 then
					v11:Destroy()
					v11 = nil
				end

				if bestMapColorCorrection and v9 then
					copyColorCorrection(bestMapColorCorrection, v9) -- inferred equivalent call
					bestMapColorCorrection.Enabled = enabled
				end
			end
		end

		local function updateState()
			if GameState.GetState() == "Buy Period" and isEligibleToShow() then -- inferred equivalent call
				if flag then
					return
				end

				flag = true
				startBuyPeriodEffects()
			elseif flag then
				flag = false
				stop() -- inferred equivalent call
			end
		end

		GameState.ListenToState(updateState)
		MenuState.OnScreenChanged:Connect(updateState)
		MenuState.OnInspectStateChanged:Connect(updateState)
		MenuState.OnCaseSceneStateChanged:Connect(updateState)
		LocalPlayer.CharacterAdded:Connect(updateState)
		LocalPlayer.CharacterRemoving:Connect(updateState)
		LocalPlayer:GetAttributeChangedSignal("IsSpectating"):Connect(updateState)

		if GameState.GetState() == "Buy Period" then
			if isEligibleToShow() then -- inferred equivalent call
				if not flag then
					flag = true
					startBuyPeriodEffects()
				end
			elseif flag then
				flag = false
				stop() -- inferred equivalent call
			end
		elseif flag then
			flag = false
			stop() -- inferred equivalent call
		end
	end
}