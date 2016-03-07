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

return Job
