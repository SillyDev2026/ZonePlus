local Replicated = game:GetService('ReplicatedStorage')
local Modules = Replicated:WaitForChild('Modules')
local Class = require(Modules.ClassSystem)
local EventBus = require(Modules.EventBus)
local Signal = require(Modules.Signal)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

export type Zone = {
	Part: BasePart,
	Bus: EventBus.EventBus,
	_interval: number,
	_running: boolean,
	_connections: { RBXScriptConnection },
	_playersInZone: { [number]: { elapsed: number } },
	Start: (self: Zone) -> (),
	Stop: (self: Zone) -> (),
	Destroy: (self: Zone) -> (),
	IsPlayerInside: (self: Zone, player: Player) -> boolean,
}

local Zone = Class.define({
	name = "Zone",
	properties = {
		Part = { default = nil },
		Bus = { default = nil },
	},
	constructor = function(self: Zone, part: BasePart, interval: number?, bus: EventBus.EventBus)
		assert(part and part:IsA("BasePart"), "Zone must be created with a BasePart")
		self.Part = part
		self.Bus = bus
		self._interval = interval or 1
		self._running = false
		self._connections = {}
		self._playersInZone = {}
	end,
	methods = {
		IsPlayerInside = function(self: Zone, player: Player)
			local character = player.Character
			if not character then return false end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if not hrp then return false end
			local size = self.Part.Size / 2
			local pos = self.Part.Position
			local offset = hrp.Position - pos
			return math.abs(offset.X) <= size.X
				and math.abs(offset.Y) <= size.Y
				and math.abs(offset.Z) <= size.Z
		end,

		Start = function(self: Zone)
			if self._running then return end
			self._running = true
			table.insert(self._connections, RunService.Heartbeat:Connect(function(deltaTime)
				if not self._running then return end
				for _, player in ipairs(Players:GetPlayers()) do
					local inside = self:IsPlayerInside(player)
					local timer = self._playersInZone[player.UserId]
					if inside and not timer then
						self._playersInZone[player.UserId] = { elapsed = 0 }
						self.Bus:_Fire("PlayerEntered", player, self.Part.Name)
						self.Bus:_Fire("PlayerStaying", player, self.Part.Name)
					elseif not inside and timer then
						self._playersInZone[player.UserId] = nil
						self.Bus:_Fire("PlayerLeft", player, self.Part.Name)
					elseif inside and timer then
						timer.elapsed = timer.elapsed + deltaTime
						if timer.elapsed >= self._interval then
							timer.elapsed = 0
							self.Bus:_Fire("PlayerStaying", player, self.Part.Name)
						end
					end
				end
			end))
		end,

		Stop = function(self: Zone)
			if not self._running then return end
			self._running = false
			for _, con in ipairs(self._connections) do
				con:Disconnect()
			end
			table.clear(self._connections)
			table.clear(self._playersInZone)
		end,

		Destroy = function(self: Zone)
			self:Stop()
			self.Bus:_Fire("ZoneDestroyed", self.Part.Name)
		end,
	},
}):: Class.Class<Zone>

return Zone