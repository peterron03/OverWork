--[[
@TheAlmightyForehead
June 20th, 2026
This handles setting up everything needed for OverWork; should be initialized from both the server and client
]]

-- SERVICES --
const RunService = game:GetService("RunService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- MODULES --
const Signal = require(ReplicatedStorage.Packages.Signal)

-- TYPES --
export type Signal = typeof(Signal.new())

export type RemoteType = (
	"Event" | "Function"
)

export type ValueType = (
	"Bool" | "BrickColor" | "CFrame" | "Color3" | "Int" | "Number" | "Object" | "Ray" | "String" | "Vector3"
)

export type Server = {
	CreateRemote : (self : Server, remoteType : RemoteType, remoteName : string) -> (RemoteEvent | RemoteFunction),
	CreateValue : (self : Server, valueType : ValueType, valueName : string) -> (ValueBase),
	Init : (self : Server) -> (number)
}

export type Client = {
	EventReceived : Signal,
	InvokeService : (self : Client, serviceName : string, funcName : string, ... any) -> (),
	Init : (self : Client) -> (number)
}
-- MAIN -- 
const OverWork = {
	Server = (RunService:IsServer() and require(script.Server)) :: Server,
	Client = (RunService:IsClient() and require(script.Client)) :: Client
}

function OverWork:Init()
	if self.Initialized then warn("[OverWork]: OverWork already initialized") return end

	self.Initialized = true
	
	if self.Server then
		const start = os.clock()
		const serviceCount = self.Server:Init()
		
		print("[OverWork]: Server initialized " .. serviceCount .. " services in " .. os.clock() - start .. " seconds")
	end
	
	if self.Client then
		const start = os.clock()
		const controllerCount = self.Client:Init()
		
		print("[OverWork]: Client initialized " .. controllerCount .. " controllers in " .. os.clock() - start .. " seconds")
	end
end

return OverWork
