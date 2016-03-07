--[[
--		Memory.lua
--		provides the Memory class. Memory keeps track of all available hole and
--		provides methods to access memory, search memory, and place jobs into
--		memory using a provided scheduling algorithm. 
--
--		This module provides the *memory manager* in the form of the
--		*scheduleJob* function. 
----]]


--load all required modules before we use them.
local class = require("object") 
local Partition = require("Partition")

local Memory = class()

--constructor Memory(Number start, Number size) 
--creates a new Memory segment, with a starting address, *start*, and a total
--size *size*.
--*start* = the starting address of this memory
--*size* = total size of this memory
function Memory:__init(start, size)
	self.head = Partition(start, size)
end

--function Memory:canFit(Job job) return Boolean true iff the job can fit in *any* of the current partitions, even if they are filled
--*job* = the job to try and fit in memory
function Memory:canFit(job)
	for _,partition in ipairs(self) do --iterate over all partitions...
		if partition.size-job.size>=0 then return partition end --test if large enough
	end
end

--functin Memory:scheduleJob(Number cVTU, Job job, ....) return Boolean/String nil if *job* will fit later, true if *job* was scheduled, "rejected" if *job* was rejected.
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

--function Memory:storageUtiliaztion() return Number the current storage utilization, as a percent from 0-1
function Memory:storageUtilization()
	local used = 0 --total memory used
	--iterate over all partitions and add their in-use memory
	for _,partition in ipairs(self) do
		if partition.filled then used=used+partition.size end
	end
	return used/1800 --normalize to 0-1
end

--function Memory:fragmentation() return Number the current memory fragmentation in bytes
function Memory:fragmentation()
	local count = 0
	for _,partition in ipairs(self) do
		if partition.size < 50 then count=count+partition.size end
	end
	return count*1024
end

--function Memory:__ipairs() return Function
--provides the implementation of ipairs for this object, making it 
--iterable using the built in ipairs function.
function Memory:__ipairs()
	local partition = self.head --start at the head.
	return function(t,i)
		local last = partition --save a ref. to the last iteration's partition
		if last then --if there *was* a previous iteration, then continue.
			i=i+1
			partition = partition.next
			return i,last
		end
	end, self, 0
end
--function Memory:__pairs() return Function
--provides the implementation of pairs for this object, making it 
--iterable using the built in pairs function.
Memory.__pairs = Memory.__ipairs

--function Memory:__tostring() return String a string representation of this
--object. (equivalent to java toString)
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
