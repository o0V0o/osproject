--[[
--		LinkedQueue.lua
--
--		provides the LinkedQueue class. LinkedQueue keeps track of all the jobs
--		that are in memory and ready to run, providing a queue interface.
--
--		This queue is actually maintained in the multiply-linked lists in the
--		partitions. 
--]]

-- load all required modules before we use them
local class = require('object')

--class LinkedQueue()
--provides a queue that is stored within the Job objects, which in ture are
--stored in the Partition objects which are stored in memory. Arguable in a
--small header of each actual memory partition.
local LinkedQueue = class()
LinkedQueue.size = 0

--function LinkedQueue:add(Job job)
--Add a job to the end of the queue
--*job* = the job to add te the end of the queue
function LinkedQueue:add(element)
	self.size = self.size+1
	if not self.head then --if this is the first job, make it the head
		self.head = element
	else --if this is not the first job, add to end
		self.head[self.pre][self.post] = element
		element[self.pre] = self.head[self.pre]
	end
	element[self.post] = self.head
	self.head[self.pre] = element
end

--functino LinkedQueue:peek() return Job the next job in the queue
--Returns, but does not remove remove the next job from the queue
function LinkedQueue:peek()
	return self.head
end

--function LinkedQueue:pop() return Job the next job in the queue
--Returns and removes the next job from the queue
function LinkedQueue:pop()
	--self.size=self.size-1
	return self:remove(self.head)
	--[[
	local element=self.head --get the job
	local tail = self.head[self.pre]
	local newHead = self.head[self.post]
	--remove references
	tail[self.post] = newHead
	newHead[self.pre] = tail
	self.head = newHead --move to next job
	return element --and return it.
	--]]
end

--function LinkedQueue:next() return Job the next job in the queue
--Increments the head and tail, then returns the job now pointed to by head
function LinkedQueue:next()
	self.head = self.head[self.post]
	return self:peek()
end

--function LinkedQueue:remove(Job) 
--remove the job from the ready queue
function LinkedQueue:remove(element)
	self.size = self.size-1
	if element[self.pre] then
		element[self.pre][self.post] = element[self.post]
	end
	if element[self.post] then
		element[self.post][self.pre] = element[self.pre]
	end
	if self.head == element then
		if self.head == element[self.post] then
			self.head = nil
		else
			self.head = element[self.post]
		end
	end
end

function LinkedQueue:__ipairs()
	local nextEl = self:peek()
	return function(table, i)
		if i<self.size and nextEl then
			local element = nextEl
			nextEl = element[self.post]
			return i+1, element
		end
	end, self, 0
end
LinkedQueue.__pairs = LinkedQueue.__ipairs

function LinkedQueue:__tostring()
	local str = {}
	table.insert(str, "[")
	for k,element in ipairs(self) do
		table.insert(str, tostring(element))
		table.insert(str, "\n")
	end
	table.insert(str, "]")
	return table.concat(str)
end

return LinkedQueue
