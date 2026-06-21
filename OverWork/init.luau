--[[
@TheAlmightyForehead
June 20th, 2026
This handles setting up everything needed for OverWork; should be initialized from both the server and client
]]

-- SERVICES --
const RunService = game:GetService("RunService")

-- MAIN -- 
const OverWork = {
	Server = RunService:IsServer() and require(script.Server),
	Client = RunService:IsClient() and require(script.Client)
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