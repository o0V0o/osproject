local class = require("object")
--class Event() represents our events (they will act like functions 'cause
--metatables are KeWLz! read the lang reference if you want! its really short!)
Event = class()

--constructor Event(Number vtu, Function callback) 
--*vtu* = the VTU that the event is triggered
--*callback* = function(Number cVTU, ...) the function to be called when the event is triggered
function Event:__init(vtu, callback)
	assert(vtu, "Event: must specify VTU of event")
	self.vtu = vtu
	self.callback = callback
end
function Event:__call(...)
	return self:callback(self.vtu, ...) --call the callback with the current VTU time, and any parameters that were passed in
end
function Event:__tostring()
	return "Event: ("..self.vtu..") "..tostring(self.callback)
end

return Event
