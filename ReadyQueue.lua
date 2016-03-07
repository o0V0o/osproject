--[[
--		ReadyQueue.lua
--		provides the ReadyQueue class. ReadyQueue keeps track of all the jobs
--		that are in memory and ready to run, providing a queue interface.
--
--		This queue is actually maintained in the multiply-linked lists in the
--		partitions. 
--]]

-- load all required modules before we use them
local class = require('object')

--class ReadyQueue()
--provides a queue that is stored within the Job objects, which in ture are
--stored in the Partition objects which are stored in memory. Arguable in a
--small header of each actual memory partition.
local ReadyQueue = class()

--function ReadyQueue:add(Job job)
--Add a job to the end of the queue
--*job* = the job to add te the end of the queue
function ReadyQueue:add(job)
	if not self.head then --if this is the first job, make it the head
		self.head = job
		self.tail = self.head
	else --if this is not the first job, add to end
		self.tail.nextReady = job
		self.tail = job
	end
end

--functino ReadyQueue:peek() return Job the next job in the queue
--Returns, but does not remove remove the next job from the queue
function ReadyQueue:peek()
	return self.head
end

--function ReadyQueue:pop() return Job the next job in the queue
--Returns and removes the next job from the queue
function ReadyQueue:pop()
	local job=self.head --get the job
	self.head = self.head.nextReady --and remove it.
	return job --and return it.
end

return ReadyQueue
