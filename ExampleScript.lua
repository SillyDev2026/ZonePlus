local Replicated = game:GetService('ReplicatedStorage')
local ZonePlus = require(Replicated:WaitForChild('ZonePlus'))
local Zone = ZonePlus.new(1)

local ZoneFolder = workspace:FindFirstChild('ZoneFolder'):GetChildren()

-- player has left the zone so u would be able to register newer zones
Zone:On('PlayerLeft', function(player, zoneName)
	print(player.Name, 'left', zoneName)
end)

-- player has entered the zone and the loop will run until playerLeft so it will be able to work with Button Sims
Zone:On('PlayerStaying', function(player, zoneName)
	print(player.Name, 'Staying in', zoneName)
end)

-- player has entered the zone only for testing printing to make suer it works
Zone:On('PlayerEntered', function(player, zoneName)
	print(player.Name, 'Has Entered Zone', zoneName)
end)

-- this will regsiter all zones before running Zone:On()
for _, part in pairs(ZoneFolder) do
	if part:IsA('BasePart') then
		Zone:Register(part)
	end
end

Zone:StartAll()