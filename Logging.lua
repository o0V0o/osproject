local Event = require("Event")
local class = require("object")

-- class LogEvent(Event) performs some callback function periodically
local LogEvent = class(Event)

--make a table whose default value, if none exists, is a new table
--this is very usefull for logging all sorts of values to without
--having to define all the fields, and then being able to
--loop over every log item to generate a report
local logs = setmetatable({}, {__index=function(t,k) t[k]={}; return t[k] end})

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


--function storage(_,Number,Simulation) return {Event}
--logs the current storage utilization
local function storage(_,cVTU,sim)
	print(cVTU, "Storage Utilization:", sim.memory:storageUtilization())
	logs.utilization[cVTU] = sim.memory:storageUtilization()
end

--function realStorage(_,Number,Simulation) return {Event}
--records the current storage utilization in a new table.
local function realStorage(_, cVTU, sim)
	logs.utilization2[cVTU] = sim.memory:storageUtilization()
end
--function avgStorage(_,Number,Simulation) return {Event}
--prints the average storage utilization, collected at short intervals
local function avgStorage(_, cVTU, sim)
	print(cVTU, "avg storage util", average(logs.utilization2, function(i) return i end))
end
--function fragmentation(_,Number,Simulation) return {Event}
--logs the current memory fragmentation, in bytes
local function fragmentation(_,cVTU,sim)
	print(cVTU, "Fragmentation:", sim.memory:fragmentation(), "bytes")
	logs.fragmentation[cVTU] = sim.memory:fragmentation()
end

--function holesize(_,Number,Simulation) return {Event}
--logs the current average hole size
local function holesize(_,cVTU,sim)
	local size = average(sim.memory ,function(h) return not h.filled and h.size end)
	print(cVTU, "Average Hole Size:", size)
	logs.holesize[cVTU] = size
end

--function partitionsize(_,Number,Simulation) return {Event}
--logs the current average hole size
local function partitionsize(_,cVTU,sim)
	local size = average(sim.memory ,function(h) return h.size end)
	print(cVTU, "Average Partition Size:", size)
	logs.partitionsize[cVTU] = size
end

--function holesize(_,Number,Simulation) return {Event}
--logs the current count of rejected jobs
local function rejected(_,cVTU,sim)
	print(cVTU, "Rejected jobs so far:", sim.rejectedCount)
	logs.rejected[cVTU] = sim.rejectedCount
end

--function resetJobs(_, Number,Simulation) return {Event}
--resets the list of processed jobs
local function resetJobs(_,cVTU,sim)
	sim.processedJobs = {}
end

local function nextValue(log, lastidx)
	for i=(lastidx or -1)+1, 5000 do
		if log[i] then return i,log[i] end
	end
end

--function makeCSV(_, Numker, Simulation) return {Event}
--records all of the logging values to respective CSV files that
--can be imported into a spreadsheet.
local delim = ','
local last={}
local function makeCSV(_,cVTU, sim)
	local fname = "report.csv"
	local file = io.open(fname, 'w')
	assert(file, "could not open file "..fname)

	for parameter, values in pairs(logs) do
		file:write("time")
		file:write(delim)
		file:write(parameter)
		file:write(delim)
	end
	file:write("\n")
	print('header written')
	local done = false
	while not done do
		done = true
		for parameter, values in pairs(logs) do
			local vtu, val = nextValue(values, last[parameter])
			if vtu then file:write(tostring(vtu)) end
				file:write(delim)
			if val then file:write(tostring(val)) end
				file:write(delim)
			if vtu or val then done = false end
			last[parameter] = vtu or last[parameter]
		end
		file:write("\n")
	end
end

--functino that returns a table of events for logging
return function()
	return {LogEvent(1000, storage, 100),
		LogEvent(1000, fragmentation, 100),
		LogEvent(1000, holesize, 100),
		LogEvent(1000, partitionsize, 100),
		LogEvent(1000, rejected, 1000),
		LogEvent(1001, function()print"\n"end, 100), --seperates logging entries
		LogEvent(1000, realStorage, 10),
		Event(4000, avgStorage),
		Event(1000, resetJobs),
		Event(4000, jobstats),
		Event(5000, makeCSV)}
end
	
