--[[
--	Job.lua
--
--	This module provides the Job class, which represents a job and its memory.
--	A job is parameterized by its size, and duration.
--	Information stored in this object would reside in a header at  the 
--	beginning of the job's memory.
--	]]

--load the required modules before we use them.
local class = require("object")
local RNG = require("rng")
local specs = require('specifications')

-- class Job()
-- represents a Job. jobs don't really do anything by themselves...
-- can think of this class as the PCB, its just a struct of information
-- related to a job.
local Job = class()
local id = 1 --keep track of job order for debug/logging purposes

--constructor Job([Number size], [Number duration])
--creates a Job of the given size and duration, or a ramdom job if not given.
function Job:__init(size, duration)
	-- call the RNG to get 'random' job stats if not passed as arguments
	self.size = size or RNG(table.unpack(specs.jobSize))
	self.duration = duration or RNG(table.unpack(specs.jobDuration))
	self.remaining = self.duration
	self.id = id --save the id for debug and logging later
	id=id+1
end
--function Job:__tostring() return String a string representation of 
--this object. (equivalent to java toString)
function Job:__tostring()
	local s = {} --make a table of substrings, then concat them all at once.
	table.insert(s, "Job: ")
	table.insert(s, self.id)
	table.insert(s, " Duration=")
	table.insert(s, self.duration)
	table.insert(s, " Size=")
	table.insert(s, self.size)
	return table.concat(s) --return the whole string!
end

--function Job:run(Number, Number) return Number the amount of time spent on this job
function Job:run(cVTU, time)
	self.startTime = self.startTime or cVTU
	time = time or self.remaining --if no time specified, run until finished
	local timeUsed =  math.min(time, self.remaining)
	if timeUsed==0 then
		print("time", timeUsed, time, self.remaining, self)
	end
	assert(timeUsed>0, "used no time?")
	self.remaining = self.remaining - timeUsed
	return timeUsed
end

--function Job:uglyprint() return String an ugly string representation of this
--job
function Job:uglyprint()
	return "("..self.id.." "..self.size.." "..self.remaining..")"
end

--function Job:turnaround() return Number this job's turnaround time, from when
--it "arrives" in **memory**, to when it completes.
function Job:turnaround()
	return self.finishTime and self.finishTime-self.scheduleTime
end
-- function Job:runtime() return Number this job's time spent running
-- (equivalent to Job.duration)
function Job:runtime()
	return self.duration
end

--function Job:waittime() return Number the amount of time this job spent
--waiting **in memory** before it completed.
function Job:waittime()
	return self.finishTime and  self:turnaround() - self:runtime()
end

return Job
