--[[
@TheAlmightyForehead
May 12th, 2025
This handles setting up the client-side for OverWork
]]

-- SERVICES --
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const UserInputService = game:GetService("UserInputService")

-- PLAYER --
const Player = Players.LocalPlayer
const PlayerGui = Player.PlayerGui
const Mouse = Player:GetMouse()

-- MODULES --
const Controllers = ReplicatedStorage:WaitForChild("Controllers"):GetChildren()

-- MAIN --
const Client = {
	Controllers = {},
	Remotes = ReplicatedStorage:WaitForChild("Remotes"),
	Values = ReplicatedStorage:WaitForChild("Values")
}

function Client:InvokeService(serviceName : string, funcName : string, ...)
	return self.Remotes:WaitForChild("GetFunction"):InvokeServer(serviceName, funcName, ...)
end

function Client:Init()
	if self.Initialized then warn("[OverWork]: Client already initialized") return end

	self.Initialized = true
	
	for _, module in Controllers do
		if module:IsA("ModuleScript") then
			self.Controllers[module.Name] = require(module)

			if self.Controllers[module.Name].Init then
				if type(self.Controllers[module.Name].Init) == "function" then
					self.Controllers[module.Name]:Init()
					print("[OverWork]: " .. module.Name .. " initialized")
				end
			end
			
			print("[OverWork]: " .. module.Name .. " ready")
		end
	end

	const function HandleFunctionFor(module : {[string] : any}, func : string, ...)
		if (type(module) == "table") and (type(module[func]) == "function") then
			return module[func](module, ...)
		end
	end

	const function HandleFunction(func : string, ...)
		for name, module in self.Controllers do
			task.spawn(HandleFunctionFor, module, func, ...)
		end
	end

	const function HandleRemotes(remotesFolder)
		if not remotesFolder:IsA("Folder") then return end

		for _, remote in remotesFolder:GetChildren() do
			remote.OnClientEvent:Connect(function(...)
				const serviceSplit = string.split(remotesFolder.Name, "Service")[1]			
				HandleFunction("On" .. serviceSplit .. remote.Name, ...)
			end)
		end

		remotesFolder.ChildAdded:Connect(function(remote)
			remote.OnClientEvent:Connect(function(...)
				const serviceSplit = string.split(remotesFolder.Name, "Service")[1]			
				HandleFunction("On" .. serviceSplit .. remote.Name, ...)
			end)
		end)
	end

	UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
		HandleFunction("OnInputBegan", inputObject, gameProcessedEvent)
	end)

	UserInputService.InputEnded:Connect(function(inputObject, gameProcessedEvent)
		HandleFunction("OnInputEnded", inputObject, gameProcessedEvent)
	end)

	UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
		HandleFunction("OnLastInputTypeChanged", lastInputType)
	end)

	Player.CharacterAdded:Connect(function(character)
		HandleFunction("OnLocalCharacterAdded", Player.Character)
	end)

	if Player.Character then
		HandleFunction("OnLocalCharacterAdded", Player.Character)
	end

	const ValuesChildren = self.Values:GetChildren()
	const RemotesChildren = self.Remotes:GetChildren()

	self.Remotes.ChildAdded:Connect(HandleRemotes)

	for _, remotesFolder in RemotesChildren do
		HandleRemotes(remotesFolder)
	end

	for _, value in ValuesChildren do
		value.Changed:Connect(function(newVal)
			HandleFunction("On" .. value.Name .. "ValueChanged", newVal)
		end)

		HandleFunction("On" .. value.Name .. "ValueChanged", value.Value)
	end

	const ItemsFolder = ReplicatedStorage:WaitForChild("ItemService_STORAGE")
	const AllItems = {}

	for _, typeFolder in ItemsFolder:GetChildren() do
		if typeFolder:IsA("Folder") then
			AllItems[typeFolder.Name] = {}

			const children = typeFolder:GetChildren()

			for _, itemModule in children do
				if itemModule:IsA("ModuleScript") then
					AllItems[typeFolder.Name][itemModule.Name] = require(itemModule)
				end
			end
		end
	end

	HandleFunction("OnItemsLoaded", AllItems)

	const currencyData, timestamp = self:InvokeService("CurrencyService", "GetData")

	if currencyData then
		HandleFunction("OnCurrencyDataLoaded", currencyData, timestamp)
	end

	const inventoryData, timestamp = self:InvokeService("InventoryService", "GetData")

	if inventoryData then
		HandleFunction("OnInventoryDataLoaded", inventoryData, timestamp)
	end

	const logInData = self:InvokeService("RewardsService", "GetLogInData")

	if logInData then
		HandleFunction("OnRewardsDataChanged", logInData)
	end

	const userOwnedGamePasses = self:InvokeService("ShopService", "GetUserOwnedGamePasses")

	if userOwnedGamePasses then
		HandleFunction("OnShopUpdateUserGamePasses", userOwnedGamePasses)
	end
	
	return #Controllers
end

return Client