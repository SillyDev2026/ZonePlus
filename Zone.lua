local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

local Zone = {}
Zone.__index = Zone

function Zone.new(part: BasePart, interval: number, bus)
	assert(part and part:IsA('BasePart'), 'Zone must be created with a part')
	local self = setmetatable({}, Zone)
	self.Part = part
	self.Bus = bus
	self._connections = {}
	self._playersInZone = {}
	self._running = false
	self._interval = interval or 1
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
	return math.abs(offset.X) <= size.X
		and math.abs(offset.Y) <= size.Y
		and math.abs(offset.Z) <= size.Z
end

function Zone:Start()
	if self._running then return end
	self._running = true
	table.insert(self._connections, RunService.Heartbeat:Connect(function(deltaTime)
		if not self._running then return end
		for _, player in ipairs(Players:GetPlayers()) do
			local inside = self:IsPlayerInside(player)
			local timer = self._playersInZone[player.UserId]
			if inside and not timer then
				self._playersInZone[player.UserId] = {elapsed = 0}
				self.Bus:Emit('PlayerEntered', player, self.Part.Name)
				self.Bus:Emit('PlayerStaying', player, self.Part.Name)
			elseif not inside and timer then
				self._playersInZone[player.UserId] = nil
				self.Bus:Emit('PlayerLeft', player, self.Part.Name)
			elseif inside and timer then
				timer.elapsed = timer.elapsed + deltaTime
				if timer.elapsed >= self._interval then
					timer.elapsed = 0
					self.Bus:Emit('PlayerStaying', player, self.Part.Name)
				end
			end
		end
	end))
end

function Zone:Stop()
	if not self._running then return end
	self._running = false
	for _, con in ipairs(self._connections) do
		con:Disconnect()
	end
	table.clear(self._connections)
	for userId, _ in pairs(self._playersInZone) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
		end
	end
	table.clear(self._playersInZone)
end

function Zone:Destroy()
	self:Stop()
	self.Bus:Emit('ZoneDestroyed', self.Part.Name)
end

return Zone