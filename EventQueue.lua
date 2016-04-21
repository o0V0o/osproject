--[[
--	EventQueue.lua
--
--	provides the EventQueue class. EventQueue provides a simple, ordered
--	queue for events, and methods to add new events, and pop events off the
--	queue.
-
--]]


--load all required modules before we use them.
local class = require("object")


--class EventQueue()
--an ordered event queue.
local EventQueue = class()
--function EventQueue:add(Event event)
--adds *event* to the queue
function EventQueue:add(event)
	table.insert(self, event)      --add to the end of the list
	table.sort(self, function(a,b) --and sort
		return a.vtu < b.vtu end)
end
--function EventQueue:pop() return Event the next event to trigger
function EventQueue:pop()
	return table.remove(self, 1)
end
--function EventQueue:__tostring() return String a string representation of
--this object (equivalent to java toString)
function EventQueue:__tostring()
	return "EventQueue: #events="..#self
end

return EventQueue
