local Replicated = game:GetService('ReplicatedStorage')
local Modules = Replicated:WaitForChild('Modules')
local Class = require(Modules.ClassSystem)
local EventBus = require(Modules.EventBus)
local Signal = require(Modules.Signal)
local Zone = require(script.Zone)

export type ZoneEvents = "PlayerEntered" | "PlayerStaying" | "PlayerLeft" | "ZoneRegistered" | "ZoneRemoved" | "ZonesStarted" | "ZonesStopped"

export type ZonePlusInstance<PlayerType, ZoneNameType> = {
	Zones: { [string]: Zone.Zone },
	Bus: EventBus.EventBus,
	_interval: number,
	Register: (self: ZonePlusInstance<PlayerType, ZoneNameType>, part: BasePart) -> Zone.Zone,
	StartAll: (self: ZonePlusInstance<PlayerType, ZoneNameType>) -> (),
	StopAll: (self: ZonePlusInstance<PlayerType, ZoneNameType>) -> (),
	Remove: (self: ZonePlusInstance<PlayerType, ZoneNameType>, name: string) -> (),
	On: (self: ZonePlusInstance<PlayerType, ZoneNameType>, event: ZoneEvents, callback: (PlayerType, ZoneNameType?, ...any) -> ()) -> any,
}

local ZonePlus = Class.define({
	name = "ZonePlus",
	properties = {
		Zones = { default = {} },
		Bus = { default = nil },
		_interval = { default = 1 },
	},
	constructor = function<PlayerType, ZoneNameType>(self: ZonePlusInstance<PlayerType, ZoneNameType>, interval: number?)
		self._interval = interval or 1
		self.Zones = {}
		self.Bus = EventBus.new()
	end,
	methods = {
		Register = function<PlayerType, ZoneNameType>(self: ZonePlusInstance<PlayerType, ZoneNameType>, part: BasePart)
			assert(part and part:IsA("BasePart"), "Expected a BasePart")
			if self.Zones[part.Name] then
				return self.Zones[part.Name]
			end

			local interval = part:GetAttribute("ZoneTime") or self._interval
			local zone = Zone.new(part, interval, self.Bus)
			self.Zones[part.Name] = zone
			zone:Start()
			self.Bus:_Fire("ZoneRegistered", zone)

			part.Destroying:Connect(function()
				if self.Zones[part.Name] then
					self:Remove(part.Name)
				end
			end)

			return zone
		end,

		StartAll = function<PlayerType, ZoneNameType>(self: ZonePlusInstance<PlayerType, ZoneNameType>)
			for _, zone in pairs(self.Zones) do
				zone:Start()
			end
			self.Bus:_Fire("ZonesStarted")
		end,

		StopAll = function<PlayerType, ZoneNameType>(self: ZonePlusInstance<PlayerType, ZoneNameType>)
			for _, zone in pairs(self.Zones) do
				zone:Stop()
			end
			self.Bus:_Fire("ZonesStopped")
		end,

		Remove = function<PlayerType, ZoneNameType>(self: ZonePlusInstance<PlayerType, ZoneNameType>, name: string)
			local zone = self.Zones[name]
			if not zone then return end
			zone:Destroy()
			self.Zones[name] = nil
			self.Bus:_Fire("ZoneRemoved", name)
		end,

		On = function<PlayerType, ZoneNameType>(self: ZonePlusInstance<PlayerType, ZoneNameType>, event: ZoneEvents, callback: (PlayerType, ZoneNameType?, ...any) -> ())
			return self.Bus:_On(event, callback)
		end,
	},
}) :: Class.Class<ZonePlusInstance<Player, string>>

return ZonePlus
