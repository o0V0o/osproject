local class = require("object") --we will use a quick OOP implementation I wrote a while back.
local Partition = require("Partition")

local Memory = class()

function Memory:__init(start, size)
	self.head = Partition(start, size)
end
--function Simulation:canFit(Job job) return Boolean true iff the job can fit in *any* of the current partitions, even if they are filled
--*job* = the job to try and fit in memory
function Memory:canFit(job)
	partition = self.head
	while partition do
		if partition.size-job.size>=0 then return partition end --test if large enough
		partition = partition.next
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
	for _,partition in ipairs(self) do
		if partition.filled then used=used+partition.size end
	end
	return used/1800
end
--function Simulation:fragmentation() return Number the current memory fragmentation in bytes
function Memory:fragmentation()
	local count = 0
	for _,partition in ipairs(self) do
		if partition.size < 50 then count=count+partition.size end
	end
	return count*1024
end
function Memory:__ipairs()
	local partition = self.head
	return function(t,i)
		local last = partition
		if last then
			i=i+1
			partition = partition.next
			return i,last
		end
	end, self, 0
end
function Memory:__pairs()
	local partition = self.head
	return function(t,i)
		local last = partition
		if last then
			i=i+1
			partition = partition.next
			return i,last
		end
	end, self, 0
end
function Memory:__tostring()
	str = {}
	for i,partition in ipairs(self) do
		local fill = '_'
		if partition.filled then
			fill = '+'
		end
		if partition.filled == CPU then
			fill = '*'
		end
		local block = string.rep(fill, math.floor(partition.size/10))
		if #block>0 then block='['..string.sub(block, 2)
		else block='|'	end
		table.insert(str, block)
	end
	return table.concat(str)
end

return Memory
