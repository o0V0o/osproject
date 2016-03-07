local class = require("object")
--class Event() represents our events (they will act like functions 'cause
--metatables are KeWLz! read the lang reference if you want! its really short!)
local Event = class()

--constructor Event(Number vtu, Function callback) 
--*vtu* = the VTU that the event is triggered
--*callback* = function(Number cVTU, ...) the function to be called when the event is triggered
function Event:__init(vtu, callback)
	assert(type(vtu)=='number', "Event: must specify VTU of event")
	self.vtu = vtu 			--save the VTU this event happens
	self.callback = callback--save the callback for this event
end
--function Event:__call() return {Event} 
--when this table is called as a function, it executes the event
--callback, and returns a list of new events to be posted.
function Event:__call(...)
	return self:callback(self.vtu, ...) --call the callback with the current VTU time, and any parameters that were passed in
end
--function Event:__tostring() return String a string representation of this
--object. (equivalent to java toString)
function Event:__tostring()
	return "Event: ("..tostring(self.vtu)..") "..tostring(self.callback)
end

return Event
