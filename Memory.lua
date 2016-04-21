--[[
--	Memory.lua
--
--	provides the Memory class. Memory keeps track of all available hole and
--	provides methods to access memory, search memory, and place jobs into
--	memory using a provided placement algorithm. 
--
----]]


--load all required modules before we use them.
local class = require("object") 
local Partition = require("Partition")
local specs = require('specifications')

local Memory = class()

--constructor Memory(Number start, Number size) 
--creates a new Memory segment, with a starting address, *start*, and a total
--size *size*.
--*start* = the starting address of this memory
--*size* = total size of this memory
function Memory:__init(start, size)
	self.head = Partition(start, size)
	self.size = size
end

--function Memory:canFit(Job job) return Boolean true iff the job can fit in *any* of the current partitions, even if they are filled
--*job* = the job to try and fit in memory
function Memory:canFit(job)
	for _,partition in ipairs(self) do
		if job.size <= partition.size then
			return true
		end
	end
	return false
end

--functin Memory:scheduleJob(Number cVTU, Job job, ....) return Boolean/String nil if *job* will fit later, true if *job* was scheduled, "rejected" if *job* was rejected.
--schedules *job* using the current scheduling algorithm. 
--*cVTU* = the current time in VTUs
--*job* = the job to schedule
function Memory:addJob(cVTU,job)
	--first, try to find the right hole
	local hole = self.placementAlgorithm(self, job)
	-- if we found one, then place the job there.
	if hole then
		hole:place(job)
		self.compacted = nil --memory may not be fully compact any more
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
	return used/self.size --normalize to 0-1
end

--function Memory:fragmentation() return Number the current memory fragmentation in bytes
function Memory:fragmentation()
	local count = 0 --amount of fragmentation
	--iterate over all partitions and add partitions that are too small to fit
	--any jobs in the future.
	for _,partition in ipairs(self) do
		if partition.size < 50 then count=count+partition.size end
	end
	return count*1024 --(convert from KiB to bytes)
end

--function Memory:fragmentation() return Number the current memory fragmentation in bytes
function Memory:fragmentation()
	local count = 0
	for _, partition in ipairs(self) do
		if not partition.filled then --if its not filled, its being wasted. Its external fragmentation.
			count = count + partition.size
		end
	end
	return count*1024
end
--function Memory:evictJob(Job, Number)
--evicts the given job from its hole, and terminates it.
function Memory:evictJob(job, cVTU, sim)
	assert(job.hole, "evicting job from nil hole")
	--make sure this job is actually in memory first
	if job.hole then
		--now update everything so the job is *not* in memory
		local hole = job.hole
		job.running = nil
		hole.filled = nil
		job.hole = nil
		job.finishTime = cVTU --indicate the jobs finish time
		sim.readyQueue:remove(job) --remove from ready queue
		Memory:coalesce(hole) --we have immediate coalescense
		sim:onFreeMemory(cVTU) --and we have new free memory now.
								--we'l see if we can fit a job in.
		self.compacted = nil --memory may **not** be fully compact any more.
	end
end

--function Memory:compact()
--perform a compaction operation
function Memory:compact()
	if self.compacted then return end --don't re-run if memory is already compact
	--print(self)

	local head = self.head
	local size = head.size
	--iterate through all the partitions, and relocate them.
	for _,partition in ipairs(self) do
		--only care about *filled* holes
		if partition.filled and head~=partition then
			head:compact(partition)
			head = partition
			size = size + partition.size
		end
	end
	--make a new empty hole for the rest of the memory
	local free = Partition(size, self.size-size, head)
	head.next = free
	self.compacted = true --memory is now completely compacted.
	--print("\n.......\n")
	--print(self)
	--io.read("*l")
end

--function Memory:coalesce(Hole)
--merges free holes adjascent to this hole.
function Memory:coalesce(partition)
	--check to the left.
	if partition.prev and not partition.prev.filled then
		partition = partition:merge(partition.prev)
	end
	--check to the right.
	if partition.next and not partition.next.filled then
		partition = partition:merge(partition.next)
	end
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
	local str = {}
	for i,partition in ipairs(self) do
		local fill = '_'
		local id = 'X'
		if partition.filled then
			fill = '+'
			id = tostring(partition.filled.id)
		end
		if partition.filled and partition.filled.running then
			fill = '*'
		end
		local block = string.rep(fill, math.floor(partition.size/10))
		if #block>0 then block='['..id..string.sub(block, 2)
		else block='|'	end

		table.insert(str, block)
	end
	return table.concat(str)
end

return Memory
