local TweenService = game:GetService('TweenService')
local Signal = {}
Signal.__index = Signal

export type Connection = {
	Connect: boolean,
	Disconnect: (self: Connection) -> ()
}

export type Signal<T...> = typeof(setmetatable({}, Signal)) & {
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Wait: (self:Signal<T...>) -> T...,
	Fire: (self:Signal<T...>, T...) -> (),
	FireAsync: (self:Signal<T...>, T...) -> (),
	Destroy: (self: Signal<T...>) -> ()
}

function Signal.new<T...>(): Signal<T...>
	local self = setmetatable({}, Signal)
	self._connections = {}
	self._waitingThreads = {}
	self._destroyed = false
	return self
end

function Signal:Connect<T...>(callBack: (T...) -> ()): Connection
	assert(typeof(callBack) == "function", "Signal:Connect expects a function")
	assert(not self._destroyed, "Cannot connect to destroyed Signal")
	local connection = {
		Connected = true,
		Callback = callBack,
		Signal = self,
	}
	function connection:Disconnect()
		if not self.Connected then return end
		self.Connected = false
		for i, conn in ipairs(self.Signal._connections) do
			if conn == self then
				table.remove(self.Signal._connections, i)
				break
			end
		end
	end
	table.insert(self._connections, connection)
	return connection
end

function Signal:Once<T...>(callBack: (T...) ->()): Connection
	local connection: Connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		callBack(...)
	end)
	return connection
end

function Signal:Wait<T...>(): T...
	assert(not self._destroyed, 'Cannot wait on destroyed Signal')
	local thread = coroutine.running()
	table.insert(self._waitingThreads, thread)
	return coroutine.yield()
end

function Signal:Fire<T...>(...: T...)
	if self._destroyed then return end
	local connections = table.clone(self._connections)
	for _, conn in ipairs(connections) do
		if conn.Connected then
			task.spawn(conn.Callback, ...)
		end
	end
	for _, thread in ipairs(self._waitingThreads) do
		task.spawn(coroutine.resume, thread, ...)
	end
	table.clear(self._waitingThreads)
end

function Signal:FireAsync<T...>(...: T...)
	if self._destroyed then return end
	local args = table.pack(...)
	task.defer(function()
		self:Fire(table.unpack(args, 1, args.n))
	end)
end

function Signal:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for _, conn in ipairs(self._connections) do
		conn.Connected = false
	end
	table.clear(self._connections)
	table.clear(self._waitingThreads)
end

local EventBus = {}
EventBus.__index = EventBus

export type Event = typeof(setmetatable({}, EventBus)) & {
	Register: (self: Event, eventName: string) -> Signal<...any>,
	GetSignal: (self: Event, eventName: string) -> Signal<...any>?,
	On: (self: Event, eventName: string, fn: (...any) -> ()) -> Connection,
	Once: (self: Event, eventName: string, fn: (...any) -> ()) -> Connection,
	Emit: (self: Event, eventName: string, ...any) -> (),
	EmitAsync: (self: Event, eventName: string, ...any) -> (),
	Remove: (self: Event, eventName: string) -> (),
	Clear: (self: Event) -> (),
	Destroy: (self: Event) -> (),
}

function EventBus.new(): Event
	local self = setmetatable({}, EventBus)
	self._events = {}
	self._destroyed = false
	return self
end

function EventBus:Register(eventName: string): Signal<...any>
	assert(not self._destroyed, "EventBus destroyed")
	assert(type(eventName) == "string", "Event name must be a string")
	if not self._events[eventName] then
		self._events[eventName] = Signal.new()
	end
	return self._events[eventName]
end

function EventBus:GetSignal(eventName: string): Signal<...any>?
	return self._events[eventName]
end

function EventBus:On(eventName: string, fn: (...any) -> ()): Connection
	local signal = self._events[eventName] or self:Register(eventName)
	return signal:Connect(fn)
end

function EventBus:Once(eventName: string, fn: (...any) -> ()): Connection
	local signal = self._events[eventName] or self:Register(eventName)
	return signal:Once(fn)
end

function EventBus:Emit(eventName: string, ...: any)
	local signal = self._events[eventName]
	if signal then
		signal:Fire(...)
	end
end

function EventBus:EmitAsync(eventName: string, ...: any)
	local signal = self._events[eventName]
	if signal then
		signal:FireAsync(...)
	end
end

function EventBus:Remove(eventName: string)
	local signal = self._events[eventName]
	if signal then
		signal:Destroy()
		self._events[eventName] = nil
	end
end

function EventBus:Clear()
	for name, signal in pairs(self._events) do
		signal:Destroy()
		self._events[name] = nil
	end
end

function EventBus:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	self:Clear()
end

local TextAnimate = {}
TextAnimate.__index = TextAnimate

export type Animation = {
	Speed: number?,
	Delay: number?,
	Loop: boolean?,
	Effect: 'Typewriter' | 'Fade' | 'Pulse'?
}

function TextAnimate.new(eventBus: Event?): any
	local self = setmetatable({}, TextAnimate)
	self._bus = eventBus or EventBus.new()
	self._active = false
	return self
end

function TextAnimate:_emit(eventName: string, ...)
	if self._bus then
		self._bus:Emit(eventName, ...)
	end
end

function TextAnimate:Typewriter(object: TextLabel | TextButton, text: string, opts: Animation?)
	opts = opts or {}
	local speed = opts.Speed or 0.05
	local delay = opts.Delay or 0
	local loop = opts.Loop or false

	self:_emit("AnimationStarted", object, "Typewriter")
	self._active = true

	repeat
		object.Text = ""
		for i = 1, #text do
			object.Text = string.sub(text, 1, i)
			task.wait(speed)
			if not self._active then return end
		end
		task.wait(delay)
	until not loop

	self._active = false
	self:_emit("AnimationEnded", object, "Typewriter")
end

function TextAnimate:Pulse(object: TextLabel | TextButton, opts: Animation?)
	opts = opts or {}
	local duration = opts.Speed or 0.5
	local loop = opts.Loop or true

	self:_emit("AnimationStarted", object, "Pulse")
	self._active = true

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1
	uiScale.Parent = object

	local function tweenScale(from: number, to: number)
		local tween = TweenService:Create(uiScale, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Scale = to })
		tween:Play()
		tween.Completed:Wait()
	end

	repeat
		tweenScale(1, 1.15)
		tweenScale(1.15, 1)
	until not loop or not self._active

	uiScale:Destroy()
	self._active = false
	self:_emit("AnimationEnded", object, "Pulse")
end

function TextAnimate:Stop()
	self._active = false
	self:_emit("AnimationStopped")
end

function TextAnimate:Destroy()
	self._active = false
	self:_emit("AnimationDestroyed")
end

return {
	EventBus = EventBus,
	Signal = Signal,
	TextAnimate = TextAnimate,
}