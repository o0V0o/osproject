--[[
--		Partition.lua
--		provides the Partition class. Partition represents a memory partition,
--		and provides methods to place jobs into a partition, and subdivide a
--		partition, 
--]]



--load all required modules before we use them
local class = require("object")

--class Partition()
-- the *Partition* class is the essence of our "memory" representation.
-- since we are only simulating the *effects* of job scheduling, we don't
-- actually need to simulate a 200K byte array. that would be dumb...
-- instead, we will keep track of all the subdivisions of memory, their bounds
-- and if they are filled or not. in a real system, this would be implemented
-- as a small header in partition that would include the PCB, and a multiply
-- linked list for all of the job queues, such as the ready queue, blocked
-- queue, or any other queues we need. 
local Partition = class()
function Partition:__init(start, size, prev, next)
	self.start = start
	self.size = size
	--these pointers will allow us to traverse "memory" more efficiently.
	--since these structs will be in memory anyways, we can use this
	--structure for the readyqueue, blockedqueue, etc as a single
	--multiply linked list to save on memory, rather than using many
	--arrays to store all these lists. 
	--also, since the number of holes can grow and shrink, we will not
	--have to reallocate more *contiguous* space for an array.
	self.prev = prev 
	self.next = next
	self.job = nil --information about the job in this hole. (starts empty)

end

--function Partition:place(Job job) 
--places *job* into this hole.
--*job* = the job to be put in this hole
function Partition:place(job)
	-- fill the hole, and stash a reference of the hole in the job (not needed)
	self.filled = job 
	job.hole = self
	self:subdivide(job.size)
end

-- function Partition:__tostring() return String a strign representation of
-- this object. (equivalent to java toString)
function Partition:__tostring()
	local s = {} --store substrings in a table, then concatenate them all at once!
	table.insert(s, "Partition:")
	table.insert(s, " from ")
	table.insert(s, self.start)
	table.insert(s, " to ")
	table.insert(s, self.start+self.size)
	table.insert(s, " (size ")
	table.insert(s, self.size)
	table.insert(s, ")\n-->")
	table.insert(s, tostring(self.filled))
	return table.concat(s) --return the whole concatenated string
end

-- function Partition:subdivide(Job job) return {Partition} a list of holes, representing the result of putting the given job into this hole , and fragmenting memory as a result
-- note that the holes are returned in *reverse order* of their logical memory layout.
--*job* = the job to be put in this hole
function Partition:subdivide(size)
	--check if we even have to subdivide.
	if self.size~=size then
		self.next = Partition(self.start+size, self.size-size, self, self.next)
	end
	self.size=size
end

return Partition
