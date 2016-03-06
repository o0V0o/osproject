local Event = require("Event")
local class = require("object")

-- class LogEvent(Event) performs some callback function periodically
local LogEvent = class(Event)

-- constructor LogEvent(Number start, Function logfunc, Number period) 
-- *start* = VTU of the event
-- *logfunc* = callback function of the event
-- *period* = period in VTU of the event
function LogEvent:__init(start, logfunc, period)
	start = start or 0
	local function cb(...)
		local events = logfunc(...) or {}
		table.insert(events, LogEvent(start+period, logfunc, period))
		return events
	end
	self:super(start, cb)
end

--function average(Table items, Function field) return Number the average of all the elements in *items* returned by the *field* function
-- *items* = table of objects that will be averaged
-- *field* = function(Object) return Value the value to be averaged.
local function average(items, field)
	local total, n = 0,0
	for _,item in pairs(items) do
		local v = field(item)
		if v then 
			total = total + v
			n=n+1
		end
	end
	return total/n
end

--function jobstats(_,Number cVTU, Simulation sim) return {Event}
--logs all of the job statistics relevant to the assignment.
local function jobstats(_,cVTU, sim)
	local turnaround = average(sim.processedJobs, function(j) return j.finishTime and j.finishTime-j.scheduleTime end)
	local runtime = average(sim.processedJobs, function(j) return j.finishTime and j.finishTime-j.startTime end)
	local waittime = average(sim.processedJobs, function(j) return j.startTime and j.startTime-j.scheduleTime end)
	print(cVTU, "Job stats ~\n\tTurnaroud Time:", turnaround, "\n\tRun Time:", runtime, "\n\tWait Time:", waittime)
end

local storagelog = {}
--function storage(_,Number,Simulation) return {Event}
--logs the current storage utilization
local function storage(_,cVTU,sim)
	print(cVTU, "Storage Utilization:", sim.memory:storageUtilization())
	table.insert(storagelog, sim.memory:storageUtilization())
end
local fraglog = {}
--function fragmentation(_,Number,Simulation) return {Event}
--logs the current memory fragmentation, in bytes
local function fragmentation(_,cVTU,sim)
	print(cVTU, "Fragmentation:", sim.memory:fragmentation(), "bytes")
	table.insert(fraglog, sim.memory:fragmentation())
end

local holesizelog = {}
--function holesize(_,Number,Simulation) return {Event}
--logs the current average hole size
local function holesize(_,cVTU,sim)
	local size = average(sim.memory ,function(h) return h.size end)
	print(cVTU, "Average Hole Size:", size)
	table.insert(holesizelog, size)
end

local rejectedlog = {}
--function holesize(_,Number,Simulation) return {Event}
--logs the current count of rejected jobs
local function rejected(_,cVTU,sim)
	print(cVTU, "Rejected jobs so far:", sim.rejectedCount)
	table.insert(rejectedlog, sim.rejectedCount)
end

return function()
	return {LogEvent(0, storage, 100),
		LogEvent(0, fragmentation, 100),
		LogEvent(0, holesize, 100),
		LogEvent(0, rejected, 100),
		LogEvent(1, function()print"\n"end, 100), --seperates logging entries
		Event(4000, jobstats)}
end
	
