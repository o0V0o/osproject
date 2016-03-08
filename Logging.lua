--load all required modules before we use them
local Event = require("Event")
local class = require("object")
local specs = require('specifications')

-- class LogEvent(Event) performs some callback function periodically
local LogEvent = class(Event)

-- constructor LogEvent(Number start, Function logfunc, Number period) 
-- *start* = VTU of the event
-- *logfunc* = callback function of the event
-- *period* = period in VTU of the event
function LogEvent:__init(start, logfunc, period, stop)
	start = start or 0 --if start time is not defined, default to 0
	local function cb(...) --setup a repeating callback.
		local events = logfunc(...) or {}
		table.insert(events, LogEvent(start+period, logfunc, period, stop))
		return events
	end
	if not stop or start<stop then
		self:super(start, cb)
	else
		self:super(start, function() end) --do nothing.
	end
end

--function average(Table items, Function field) return Number the average of all the elements in *items* returned by the *field* function
-- *items* = table of objects that will be averaged
-- *field* = function(Object) return Value the value to be averaged.
local function average(items, field)
	local total=0 --the total sum so far
	local n=0	-- the number of elements summed so far
	for _,item in pairs(items) do
		local v = field(item)
		if v then 
			total = total + v --add to sum...
			n=n+1			  --increment number of elements.
		end
	end
	return total/n --calculate average.
end

--function jobstats(_,Number cVTU, Simulation sim) return {Event}
--logs all of the job statistics relevant to the assignment.
local function jobstats(_,cVTU, sim)
	--calculate all the job stats using the average function.
	local turnaround = average(sim.processedJobs, function(j) return j.finishTime and j.finishTime-j.scheduleTime end) 
	local runtime = average(sim.processedJobs, function(j) return j.finishTime and j.finishTime-j.startTime end)
	local waittime = average(sim.processedJobs, function(j) return j.startTime and j.startTime-j.scheduleTime end)
	print(cVTU, "Job stats ~\n\tTurnaroud Time:", turnaround, "\n\tRun Time:", runtime, "\n\tWait Time:", waittime)
	--store these values in a log
	sim.logs.avg_turnaround[cVTU] = turnaround
	sim.logs.avg_runtime[cVTU] = runtime
	sim.logs.avg_waittime[cVTU] = waittime
end


--function storage(_,Number,Simulation) return {Event}
--logs the current storage utilization
local function storage(_,cVTU,sim)
	print(cVTU, "Storage Utilization:", sim.memory:storageUtilization())
	sim.logs.utilization[cVTU] = sim.memory:storageUtilization()
end

--function realStorage(_,Number,Simulation) return {Event}
--records the current storage utilization in a new table.
local function realStorage(_, cVTU, sim)
	sim.logs.utilization2[cVTU] = sim.memory:storageUtilization()
end

--function avgStorage(_,Number,Simulation) return {Event}
--prints the average storage utilization, collected at short intervals
local function avgStorage(_, cVTU, sim)
	print(cVTU, "avg storage util", average(sim.logs.utilization2, function(i) return i end))
end

--function fragmentation(_,Number,Simulation) return {Event}
--logs the current memory fragmentation, in bytes
local function fragmentation(_,cVTU,sim)
	print(cVTU, "Fragmentation:", sim.memory:fragmentation(), "bytes")
	sim.logs.fragmentation[cVTU] = sim.memory:fragmentation()
end

--function holesize(_,Number,Simulation) return {Event}
--logs the current average hole size
local function holesize(_,cVTU,sim)
	--calculate avg hole size with the average function, ignoring filled holes
	local size = average(sim.memory,function(h) return not h.filled and h.size end)
	print(cVTU, "Average Hole Size:", size)
	sim.logs.holesize[cVTU] = size
end

--function partitionsize(_,Number,Simulation) return {Event}
--logs the current average hole size
local function partitionsize(_,cVTU,sim)
	--calculate avg hole size with the average function
	local size = average(sim.memory ,function(h) return h.size end)
	print(cVTU, "Average Partition Size:", size)
	sim.logs.partitionsize[cVTU] = size
end

--function holesize(_,Number,Simulation) return {Event}
--logs the current count of rejected jobs
local function rejected(_,cVTU,sim)
	print(cVTU, "Rejected jobs so far:", sim.rejectedCount)
	sim.logs.rejected[cVTU] = sim.rejectedCount
end

--function resetJobs(_, Number,Simulation) return {Event}
--resets the list of processed jobs
local function resetJobs(_,cVTU,sim)
	sim.processedJobs = {}
end
--function that returns a table of events for logging.
--note that it is a function, not a table, so that it 
--does not get cached by 'require'. that would not work.
return function()
	return {LogEvent(specs.samplePeriod.start, storage, 100, specs.samplePeriod.stop),
		LogEvent(specs.samplePeriod.start, fragmentation, 100,specs.samplePeriod.stop),
		LogEvent(specs.samplePeriod.start, holesize, 100, specs.samplePeriod.stop),
		LogEvent(specs.samplePeriod.start, partitionsize, 100, specs.samplePeriod.stop),
		LogEvent(specs.samplePeriod.start, rejected, 1000),
		LogEvent(specs.samplePeriod.start+1, function()print""end, 100, specs.samplePeriod.stop), --seperates logging entries
		LogEvent(specs.samplePeriod.start, realStorage, 10),
		Event(specs.samplePeriod.stop+500, function()print""end), --seperate last entry
		Event(specs.samplePeriod.stop, avgStorage),
		Event(specs.samplePeriod.start, resetJobs),
		Event(specs.samplePeriod.stop, jobstats)}
end
	
