local class = require("object") --we will use a quick OOP implementation I wrote a while back.

--class Hole()
-- the *Hole* class is the essence of our "memory" representation.
-- since we are only simulating the *effects* of job scheduling, we don't
-- actually need to simulate a 200K byte array. that would be dumb...
-- instead, we will keep track of all the subdivisions of memory, their bounds
-- and if they are filled or not.
Hole = class()
function Hole:__init(start, size, prev, next)
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
--function Hole:place(Job job) 
--places *job* into this hole.
--*job* = the job to be put in this hole
function Hole:place(job)
	-- fill the hole, and stash a reference of the hole in the job.
	self.filled = job 
	job.hole = self
	self:subdivide(job.size)
end
---
function Hole:__tostring()
	local s = {}
	table.insert(s, "Hole:")
	table.insert(s, " from ")
	table.insert(s, self.start)
	table.insert(s, " to ")
	table.insert(s, self.start+self.size)
	table.insert(s, " (size ")
	table.insert(s, self.size)
	table.insert(s, ")\n-->")
	table.insert(s, tostring(self.filled))
	return table.concat(s)
end
-- function Hole:subdivide(Job job) return {Hole} a list of holes, representing the result of putting the given job into this hole , and fragmenting memory as a result
-- note that the holes are returned in *reverse order* of their logical memory layout.
--*job* = the job to be put in this hole

--[[
function Hole:subdivide(job)
	local t = {}
	--if the hole size==job size we only need one hole.
	if self.size~=job.size then
		table.insert( t, Hole(self.start+job.size, self.size-job.size)) --add in the remaining free segment
	end
	table.insert( t, Hole(self.start, job.size, job)) --add in the new hole that contains the job
	return t
end
--]]
function Hole:subdivide(size)
	if self.size~=size then
		self.next = Hole(self.start+size, self.size-size, self, self.next)
	end
end

return Hole
