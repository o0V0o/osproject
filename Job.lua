local class = require("object") --we will use a quick OOP implementation I wrote a while back.
local RNG = require("rng")

-- class Job()
-- represents a Job. jobs don't really do anything by themselves...
local Job = class()
local id = 1 --keep track of job order for debug/logging purposes
--constructor Job([Number size], [Number duration])
--creates a Job of the given size and duration, or a ramdom job if not given.
function Job:__init(size, duration)
	-- call the RNG to get 'random' job stats if not passed as arguments
	self.size = size or RNG(50,300,10)
	self.duration = duration or RNG(5,60,5)
	self.id = id
	id=id+1
end
---
function Job:__tostring()
	local s = {}
	table.insert(s, "Job: ")
	table.insert(s, self.id)
	table.insert(s, " Duration=")
	table.insert(s, self.duration)
	table.insert(s, " Size=")
	table.insert(s, self.size)
	return table.concat(s)
end

return Job
