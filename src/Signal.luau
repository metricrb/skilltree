--!strict

--- @class Signal
--- A lightweight typed signal for event handling.
local Signal = {}
Signal.__index = Signal

type Connection = {
	_signal: Signal,
	_callback: (...any) -> (),
	disconnect: (self: Connection) -> (),
}

type Signal = {
	_callbacks: { (...any) -> () },
	connect: (self: Signal, callback: (...any) -> ()) -> Connection,
	fire: (self: Signal, ...any) -> (),
	destroyAllConnections: (self: Signal) -> (),
}

--- Creates a new Signal instance.
--- @return Signal
function Signal.new(): Signal
	local self = setmetatable({}, Signal) :: any
	self._callbacks = {}
	return self
end

--- Connects a callback to this signal.
--- @param callback function -- The callback to invoke when the signal fires
--- @return Connection -- A connection that can be disconnected
function Signal:connect(callback: (...any) -> ()): Connection
	local connection: Connection = {
		_signal = self,
		_callback = callback,
		disconnect = function(conn: Connection)
			local callbacks = conn._signal._callbacks
			for i, cb in ipairs(callbacks) do
				if cb == conn._callback then
					table.remove(callbacks, i)
					break
				end
			end
		end,
	}
	table.insert(self._callbacks, callback)
	return connection
end

--- Fires the signal with the given arguments.
--- @param ... any -- Arguments to pass to all connected callbacks
function Signal:fire(...: any)
	for _, callback in ipairs(self._callbacks) do
		task.spawn(callback, ...)
	end
end

--- Disconnects all callbacks from this signal.
function Signal:destroyAllConnections()
	table.clear(self._callbacks)
end

return Signal
