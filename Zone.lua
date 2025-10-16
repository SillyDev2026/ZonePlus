local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

local Zone = {}
Zone.__index = Zone

export type Zone = typeof(setmetatable({}, Zone)) & {
	Part: BasePart,
	Name: string,
	Bus: any,
	Inside: {[Player]: boolean},
	Connection: {RBXScriptConnection},
	Active: boolean,
}

function Zone.new(part: BasePart, interval: number, bus)
	assert(part and part:IsA('BasePart'), 'Zone must be created with a part')
	local self = setmetatable({}, Zone)
	self.Part = part
	self.Bus = bus
	self._connections = {}
	self._playersInZone = {}
	self._running = false
	self._interval = interval
	return self
end

function Zone:IsPlayerInside(player)
	local character = player.Character
	if not character then return false end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	local size = self.Part.Size / 2
	local pos = self.Part.Position
	local offset = hrp.Position - pos
	return math.abs(offset.X) <= size.X and math.abs(offset.Y) <= size.Y and math.abs(offset.Z) <= size.Z
end

function Zone:Start()
	if self._running then return end
	self._running = true
	local elapsed = 0
	table.insert(self._connections, RunService.Heartbeat:Connect(function(deltaTime)
		if not self._running then return end
		elapsed = elapsed + deltaTime
		if elapsed < self._interval then return end
		elapsed = 0
		for _, player in ipairs(Players:GetPlayers()) do
			local inside = self:IsPlayerInside(player)
			local wasInside = self._playersInZone[player.UserId]
			if inside and not wasInside then
				self._playersInZone[player.UserId] = true
				self.Bus:Emit('PlayerEntered', player, self.Part.Name)
			elseif not inside and wasInside then
				self._playersInZone[player.UserId] = nil
				self.Bus:Emit('PlayerLeft', player, self.Part.Name)
			elseif inside and wasInside then
				self.Bus:Emit('PlayerStaying', player, self.Part.Name)
			end
		end
	end))
end

function Zone:Stop ()
	if not self.Active then return end
	self.Active = false
	for _, con in ipairs(self.Connections) do
		con:Disconnect()
	end
	table.clear(self.Connections)
	table.clear(self.Inside)
end

function Zone:Destroy()
	self:Stop()
	self.Bus:Emit('ZoneDestroyed', self.Name)
end

return Zone