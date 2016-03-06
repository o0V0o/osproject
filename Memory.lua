local class = require("object") --we will use a quick OOP implementation I wrote a while back.
local Hole = require("Hole")

local Memory = class()

function Memory:__init(start, size)
	self.head = Hole(start, size)
end
--function Simulation:canFit(Job job) return Boolean true iff the job can fit in *any* of the current holes, even if they are filled
--*job* = the job to try and fit in memory
function Memory:canFit(job)
	hole = self.head
	while hole do
		if hole.size-job.size>=0 then return hole end --test if large enough
		hole = hole.next
	end
end
--functin Simulation:scheduleJob(Number cVTU, Job job, ....) return Boolean/String nil if *job* will fit later, true if *job* was scheduled, "rejected" if *job* was rejected.
--schedules *job* using the current scheduling algorithm. 
--*cVTU* = the current time in VTUs
--*job* = the job to schedule
function Memory:addJob(cVTU,job)
	--first, try to find the right hole
	local hole = self.schedulingAlgorithm(self, job)
	if hole then
		hole:place(job)
	end
	return hole
end
--function Simulation:storageUtiliaztion() return Number the current storage utilization, as a percent from 0-1
function Memory:storageUtilization()
	local used = 0
	local hole = self.head
	while hole do
		if hole.filled then used=used+hole.size end
		hole = hole.next
	end
	return used/1800
end
--function Simulation:fragmentation() return Number the current memory fragmentation in bytes
function Memory:fragmentation()
	local count = 0
	local hole = self.head
	while hole do
		if hole.size < 50 then count=count+hole.size end
		hole = hole.next
	end
	return count*1024
end
function Memory:__ipairs()
	local hole = self.head
	return function(t,i)
		local last = hole
		if last then
			i=i+1
			hole = hole.next
			return i,last
		end
	end, self, 0
end
function Memory:__pairs()
	local hole = self.head
	return function(t,i)
		local last = hole
		if last then
			i=i+1
			hole = hole.next
			return i,last
		end
	end, self, 0
end

return Memory
