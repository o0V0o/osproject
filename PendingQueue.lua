local class = require("object") --we will use a quick OOP implementation I wrote a while back.
local Job = require('Job')

-- class PendingQueue()
-- a quick class to *represent*  **NOT** simulate or model, the jobs that are backed up *somewhere*, like a longterm scheduler.
-- note: this is **NOT** implementing a "disk" or any sort of long-term storage: just look at the code. 
-- this class is equivalent to the "catching up" approach discussed in class, where, instead of explicitly checking if the next job is in the future, we just keep track of how many jobs were in the past. 
local PendingQueue = class()
PendingQueue.n=0 --inherited value for the number of jobs waiting
--function PendingQueue:pop() return Job the next job waiting to be scheduled
function PendingQueue:pop()
	--return the job stashed here, or make a new one.
	local next = self.head or (not self:empty() and Job())
	self.head = nil
	return next
end
--function PendingQueue:push(Job job)
--save a job for later (only *one*)
--*job* = the job to store
function PendingQueue:push(job)
	assert( not (job and self.head), "can not stash a job in a non-empty BlockedQueue")
	self.head = self.head or job --stash the first job
	self.n=self.n+1 --and increment our total count
end
--functin PendingQueue:empty() return Boolean true iff the queue is empty
function PendingQueue:empty()
	return self.n==0
end

return PendingQueue