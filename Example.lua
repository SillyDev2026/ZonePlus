local Replicated = game:GetService('ReplicatedStorage')
local ZonePlus = require(Replicated:FindFirstChild('ZonePlus'))

local Zones = workspace:WaitForChild('ZoneFolder'):GetChildren()
local new = ZonePlus.new() -- will register as ZoneTime as default if not u can instert 1

new:On('PlayerStaying', function(player, zoneName)
	print(player.Name, 'entered', zoneName)
end)

for i, zones in pairs(Zones) do
	if zones:IsA('BasePart') then
		new:Register(zones)
	end
end