--[[
--	Disk.lua
--
--	This module provides the Disk class that simulates a disk
--	It provides an interface to add jobs to the disk, and to 
--	attempt to schedule jobs from the disk into memory
--]]

-- load all required modules before we use them
local class = require('object')
local DiskQueue = require('DiskQueue')

--class Disk()
--Provides an interface to a virtual disk
local Disk = class()
function Disk:__init(size)
	self.maxSize = size
	self.queue = DiskQueue()
end

--function DiskQueue:add(Job job) return Boolean true iff the job fit on disk.
--Add a job to the disk
--*job* = the job to add te the end of the queue
function Disk:add(job)
	if self:full() then
		return false
	else
		self.queue:add(job)
		return true
	end
end

--functino Disk:full() return Boolean true iff the disk is full
function Disk:full()
	return self.queue.size >= self.maxSize
end

--function Disk:scedule(Number cVTU, Simulation sim)
--attempt to schedule any jobs on the disk that can fit
--into main memory.
function Disk:schedule(cVTU, sim)
	for _,job in ipairs(self.queue) do
		--attempt to schedule *all* the jobs.
		-- this is an **expensive** search.
		-- must look at every hole, for every job.
		local success = sim:scheduleJob(cVTU, job)
		if success == 'scheduled' then
			self:remove(job)
		end
	end
end

--function Disk:uglyprint() return String an ugly representation of this Disk's
--queue
function Disk:uglyprint()
	local str = {}
	table.insert(str, "[")
	for _,job in ipairs(self.queue) do
		table.insert(str, job:uglyprint())
		table.insert(str, "|")
	end
	str[#str]="]"
	return table.concat(str)
end

--function Disk:remove(Job)
--remove this job from the disk
function Disk:remove(job)
	self.queue:remove(job)
end
return Disk
