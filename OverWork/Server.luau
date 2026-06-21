--[[
@TheAlmightyForehead
April 28th, 2025
This handles setting up the server-side for OverWork
]]

-- SERVICES --
const ServerScriptService = game:GetService("ServerScriptService")
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const PolicyService = game:GetService("PolicyService")

-- MODULES --
const Services = ServerScriptService:WaitForChild("Services"):GetChildren()
const Controllers = ReplicatedStorage:WaitForChild("Controllers"):GetChildren()
const HeartBind = require(ReplicatedStorage.Packages.HeartBind)

-- TYPES --
export type RemoteType = (
	"Event" | "Function"
)

export type ValueType = (
	"Bool" | "BrickColor" | "CFrame" | "Color3" | "Int" | "Number" | "Object" | "Ray" | "String" | "Vector3"
)

-- MAIN --
const Server = {
	Services = {},
	Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder"),
	Values = ReplicatedStorage:FindFirstChild("Values") or Instance.new("Folder")
}

do
	Server.Remotes.Name = "Remotes"
	Server.Remotes.Parent = ReplicatedStorage
	Server.Values.Name = "Values"
	Server.Values.Parent = ReplicatedStorage
end

function Server:CreateRemote(remoteType : RemoteType, remoteName : string)
	local newRemote = Instance.new(`Remote{remoteType}`)
	newRemote.Name = remoteName
	newRemote.Parent = self.Remotes
end

function Server:CreateValue(valueType : ValueType, valueName : string)
	local newRemote = Instance.new(`{valueType}Value`)
	newRemote.Name = valueName
	newRemote.Parent = self.Values
end

function Server:Init()
	if self.Initialized then warn("[OverWork]: Server already initialized") return end

	self.Initialized = true
	
	self:CreateRemote("Function", "GetFunction")
	self:CreateValue("Number", "CurrentTick")
	
	for _, module in Services do
		if module:IsA("ModuleScript") then
			self.Services[module.Name] = require(module)

			if type(self.Services[module.Name].Client) == "table" then
				local newRemotesFolder = Instance.new("Folder")

				for _, remote in self.Services[module.Name].Client do
					remote.Parent = newRemotesFolder
				end

				newRemotesFolder.Name = module.Name
				newRemotesFolder.Parent = self.Remotes
			end

			if self.Services[module.Name].Init then
				if type(self.Services[module.Name].Init) == "function" then
					self.Services[module.Name]:Init()
					print("[OverWork]: " .. module.Name .. " initialized")
				end
			end
			
			print("[OverWork]: " .. module.Name .. " ready")
		end
	end
	
	const function HandleFunctionFor(module : {[string] : any}, func : string, ...)
		if (type(module) == "table") then
			if (type(module[func]) == "function") then
				return module[func](module, ...)
			elseif (type(module.OnAny) == "function") then
				task.spawn(module.OnAny, module, func, ...)
			end
		end
	end

	const function HandleFunction(func : string, ...)
		for name, module in self.Services do
			task.spawn(HandleFunctionFor, module, func, ...)
		end
	end

	const function PlayerAdded(player : Player)
		local policyInfo = PolicyService:GetPolicyInfoForPlayerAsync(player)

		if policyInfo then
			for name, value in policyInfo do
				if type(value) == "boolean" then
					player:SetAttribute(name, value)
				end
			end
		end
	end
	
	-- !! NOTICE !!
	-- Due to the below RemoteFunction, any functions beginning with "_" can be called by the client.
	-- Do NOT start ANY functions with "_" unless you want them called by the client.
	-- Also, these types of functions will be assumed to have the first parameter as the player calling it.
	-- Example of this type of function -- "CurrencyService:_GetData(player)"

	self.Remotes.GetFunction.OnServerInvoke = function(player : Player, service : string, func : string, ...)
		if self.Services[service] then
			return HandleFunctionFor(self.Services[service], "_" .. func, player, ...)
		end
	end

	for _, controller in Controllers do
		if controller:IsA("ModuleScript") then
			for _, event in controller:GetChildren() do
				if event:IsA("RemoteEvent") then
					event.OnServerEvent:Connect(function(player, ...)
						local controllerSplit = string.split(controller.Name, "Controller")[1]
						HandleFunction("_On" .. controllerSplit .. event.Name, player, ...)
					end)
				end
			end
		end
	end

	--[[
	:OnDataLoaded
	:OnCurrencyDataLoaded
	:OnInventoryDataLoaded
	:OnPlayerAdded
	:OnPlayerRemoving
	:OnCharacterAdded
	:OnCharacterRemoving
	]]

	self.Services.CurrencyService.DataLoaded:Connect(function(player, data)
		HandleFunction("OnCurrencyDataLoaded", player, data)
	end)

	self.Services.InventoryService.DataLoaded:Connect(function(player, data)
		HandleFunction("OnInventoryDataLoaded", player, data)
	end)

	self.Services.PlayerDataService.DataLoaded:Connect(function(player, data)
		HandleFunction("OnDataLoaded", player, data)
	end)

	Players.PlayerRemoving:Connect(function(player)
		HandleFunction("OnPlayerRemoving", player)
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(function()
			if player.Character then
				task.spawn(HandleFunction, "OnCharacterAdded", player, player.Character)
			end

			player.CharacterRemoving:Connect(function(character)
				HandleFunction("OnCharacterRemoving", player, character)
			end)

			player.CharacterAppearanceLoaded:Connect(function(character)
				HandleFunction("OnCharacterAdded", player, character)
			end)

			HandleFunction("OnPlayerAdded", player)
			PlayerAdded(player)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterRemoving:Connect(function(character)
			HandleFunction("OnCharacterRemoving", player, character)
		end)

		player.CharacterAppearanceLoaded:Connect(function(character)
			HandleFunction("OnCharacterAdded", player, character)
		end)

		HandleFunction("OnPlayerAdded", player)
		PlayerAdded(player)
	end)

	HeartBind:Bind("CurrentTick", function()
		self.Values.CurrentTick.Value = DateTime.now().UnixTimestamp
	end)
	
	self.ServicesInitialized = true
	
	return #Services
end

return Server