local class = require('object')

local ReadyQueue = class()
function ReadyQueue:__init()
end

function ReadyQueue:add(job)
	if not self.head then
		self.head = job
		self.tail = self.head
	else
		self.tail.nextReady = job
		self.tail = job
	end
end
function ReadyQueue:peek()
	return self.head and self.head
end
function ReadyQueue:pop()
	local job=self.head
	self.head = self.head.nextReady
	return job
end

return ReadyQueue
