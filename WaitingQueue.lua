--[[
--	WaitingQueue.lua
--	provides the WaitingQueue class. WaitingQueue keeps track of the
--	jobs that are pending, without actually knowing about the jobs.
--	In essence, it acts similar to a counter, keeping track of the
--	number of pending jobs so that we know how many jobs we can
--	generate before we are looking at jobs from the future.
--
--	this class is equivalent to the "catching up" approach discussed
--	in class, where, instead of explicitly checking if the next job is
--	in the future, we just keep track of how many jobs were in the past. 
--
--	]]

--load all required modules before they are used.
local class = require("object")
local Job = require('Job')

-- class WaitingQueue()
-- a quick class to *represent*  **NOT** simulate or model, the jobs that are backed up *somewhere*, like a longterm scheduler.
-- note: this is **NOT** implementing a "disk" or any sort of long-term storage: just look at the code. 
-- this class is equivalent to the "catching up" approach discussed in class, where, instead of explicitly checking if the next job is in the future, we just keep track of how many jobs were in the past. 
local WaitingQueue = class()
WaitingQueue.n=0 --inherited value for the number of jobs waiting

--function WaitingQueue:pop() return Job the next job waiting to be scheduled
function WaitingQueue:pop()
	--return the job stashed here, or make a new one.
	local next = self.head or (not self:empty() and Job())
	self.n = self.n-1
	self.head = nil
	return next
end

--function WaitingQueue:push([Job job])
--save a job for later (only *one*)
--*job* = the job to store
function WaitingQueue:push(job)
	assert( not (job and self.head), "can not stash a job in a non-empty BlockedQueue")
	self.head = self.head or job --stash the first job
	self.n=self.n+1 --and increment our total count
end

--functin WaitingQueue:empty() return Boolean true iff the queue is empty
function WaitingQueue:empty()
	return self.n==0 --do we have any jobs??
end

function WaitingQueue:schedule(cVTU, sim)
	while not self:empty() do
		local job = self:pop()
		local success = sim:scheduleJob(cVTU, job)
		--jobs that are rejected go to disk, if space is free
		--[[
		if success == 'rejected' then
			print("adding to disk", job)
			success = (sim.disk:add(job) and success) or 'blocked'
		end
		--]]
		
		--we are blocked if we can't fit this job *anywhere* right now.
		if success == 'blocked' then
			success = sim.disk:add(job) 
			--if the disk is full, we have to wait again.
			if not success then
				self:push(job)
				break --can't continue to the next job. *they don't really exist*
			end
		end
	end
end

return WaitingQueue
