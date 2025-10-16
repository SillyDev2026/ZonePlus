local Zone = require(script.Zone)
local Module = require(script.EventBus)
local EventBus = Module.EventBus

local ZonePlus = {}
ZonePlus.__index = ZonePlus

export type ZonePlus = typeof(setmetatable({}, ZonePlus)) & {
	Zones: {[string]: Zone.Zone},
	Bus:any,
}

--interval is to track how long the player is in the zone
function ZonePlus.new(interval: number)
	local self = setmetatable({}, ZonePlus)
	self.Zones = {}
	self.Bus = EventBus.new()
	self._interval = interval
	return self
end

function ZonePlus:Register(part:BasePart)
	assert(part:IsA('BasePart'), 'Expected a part')
	if self.Zones[part.Name] then
		return self.Zones[part.Name]
	end
	local zone = Zone.new(part, self._interval, self.Bus)
	self.Zones[part.Name] = zone
	zone:Start()
	self.Bus:Emit('ZoneRegistered', zone)
	part.Destroying:Connect(function()
		if self.Zones[part.Name] then
			self:Remove(part.Name)
		end
	end)
	return zone
end

function ZonePlus:StartAll()
	for _, zone in pairs(self.Zones) do
		zone:Start()
	end
	self.Bus:Emit('ZonesStarted')
end

function ZonePlus:StopAll()
	for _, zone in pairs(self.Zones) do
		zone:Stop()
	end
	self.Bus:Emit('ZonesStopped')
end

function ZonePlus:Remove(name: string)
	local zone = self.Zones[name]
	if not zone then return end
	zone:Destroy()
	self.Zones[name] = nil
	self.Bus:Emit('ZoneRemoved', name)
end

function ZonePlus:On(event: string, callBack: (...any) -> ())
	return self.Bus:On(event, callBack)
end

return ZonePlus