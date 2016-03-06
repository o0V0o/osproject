local class = require("object") --we will use a quick OOP implementation I wrote a while back.
--
--class EventQueue()
--an ordered event queue.
EventQueue = class()
--function EventQueue:add(Event event)
--adds *event* to the queue
function EventQueue:add(event)
	table.insert(self, event)
	table.sort(self, function(a,b) return a.vtu < b.vtu end)
end
--function EventQueue:pop() return Event the next event to trigger
function EventQueue:pop()
	return table.remove(self, 1)
end
---
function EventQueue:__tostring()
	return "EventQueue: #events="..#self
end

return EventQueue
