local observePlayer = require(script.Parent.observePlayer)

local function observeCharacter(callback)
	return observePlayer(function(player)
		local v = nil
		local characterAddedConnection = nil

		local function OnCharacterAdded(instance)
			local v2 = nil
			task.defer(function()
				local v3 = callback(player, instance)

				if typeof(v3) == "function" then
					if characterAddedConnection.Connected and instance.Parent then
						v2 = v3
						v = v3
					else
						task.spawn(v3)
					end
				end
			end)
			local ancestryChangedConnection = nil
			ancestryChangedConnection = instance.AncestryChanged:Connect(function(_, parent)
				if parent == nil and ancestryChangedConnection.Connected then
					ancestryChangedConnection:Disconnect()

					if v2 ~= nil then
						task.spawn(v2)

						if v == v2 then
							v = nil
						end

						v2 = nil
					end
				end
			end)
		end

		characterAddedConnection = player.CharacterAdded:Connect(OnCharacterAdded)
		task.defer(function()
			if player.Character and characterAddedConnection.Connected then
				task.spawn(OnCharacterAdded, player.Character)
			end
		end)
		return function()
			characterAddedConnection:Disconnect()

			if v ~= nil then
				task.spawn(v)
				v = nil
			end
		end
	end)
end

return observeCharacter