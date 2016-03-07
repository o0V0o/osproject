local class = require("object") --we will use a quick OOP implementation I wrote a while back.
local Event = require("Event")
local LogEvents = require("Logging")
local Events = require("Events")
local EventQueue = require('EventQueue')
local PendingQueue = require('PendingQueue')
local Memory = require("Memory")
local ReadyQueue = require('ReadyQueue')
local RNG = require('rng')

--[[
--function table.idx)Table table, Value value) return Number the index into *table* that contains the given element, *value*
function table.idx(table, value)
	for i,v in ipairs(table) do
		if v==value then return i end
	end
end
--]]

--class Simulation()
--this is the main class that represents the state of the simulation.
Simulation = class()
--constructor Simulation() 
function Simulation:__init()
	self:reset()
end
--function Simulation:reset()
--reset the simulation to a valid initial state
function Simulation:reset()
	--seed the randomizer with some arbitrary (changing) value.
	math.randomseed(os.clock()+os.time())


	--make a table whose default value, if none exists, is a new 
	--table this is very usefull for logging all sorts of values
	--to without having to define all the fields, and then being
	--able to loop over every log item to generate a report
	--also we keep track of the largest integer key that is set
	--so that we know how big the table is.
	self. logs = setmetatable({}, { __index=function(t,k)
			t[k]=setmetatable({maxn=0}, {__newindex=function(t,k,v) rawset(t,k,v);if type(k)=='number' and t.maxn<k then rawset(t,'maxn', k) end end})
			return t[k]
	end})

	 --we have a single hole at the start, at position 0, taking up the
	 --entire memory, minus the portion reserved for the OS
	self.memory = Memory(0,2000-200)
	self.memory.schedulingAlgorithm = self.schedulingAlgorithm
	self.events = EventQueue()
	--setup our job queues.
	self.pendingQueue = PendingQueue() --(not a real queue)
	self.readyQueue = ReadyQueue()
	
	--logging values
	self.rejectedCount = 0 --keep track of rejected jobs for logs
	self.processedJobs = {} --a list of EVERY job that was ever scheduled
	--add initial events
	JobPostEvent(0) --reset the last job arrival time to 0, but don't add the event...
	self.events:add( JobPostEvent() ) --add our first job!
	-- add all the logging events 
	for _,event in pairs( LogEvents() ) do
		self.events:add(event)
	end
end

--function nextValue({Value} log, Number lastidx) return Number
--returns the next value from a sparse list of values. For example
--in a list of values such as {1=20,50=25,100=22}, you can use
--this function to iterate over the values 20,25, and 22.
local function nextValue(log, lastidx, maxn)
	for i=(lastidx or -1)+1, maxn do
		if log[i] then return i,log[i] end
	end
end
--function Simulation:report(String filename) 
--records all of the logging values to respective CSV file that
--can be imported into a spreadsheet.
function Simulation:report(fname)
	local last,max = {}, {}
	local delim = ","
	--try to open the file
	local file = io.open(fname, 'w')
	assert(file, "could not open file "..fname)

	--write the header values out to the file
	for parameter, values in pairs(self.logs) do
		file:write("time")
		file:write(delim)
		file:write(parameter)
		file:write(delim)
	end
	file:write("\n")
	--keep iterating until there is no more data in *any* of the
	--logs.
	local done = false
	while not done do
		done = true
		--for each row, iterate over all the logs
		for parameter, values in pairs(self.logs) do
			--use the nextValue function to iterate over the
			--sparse lists in logs.
			local vtu, val = nextValue(values, last[parameter], values.maxn)
			--write out the value, if it exists, and if it does,
			--continue by setting done=false
			if vtu then file:write(tostring(vtu)) end
				file:write(delim)
			if val then file:write(tostring(val)) end
				file:write(delim)
			if vtu or val then done = false end
			--save last idx for next iteration
			last[parameter] = vtu or last[parameter] 
		end
		file:write("\n")
	end
	file:close()
end


--functin Simulation:simulate(Number maxVTU)
--simulates up to a time of *maxVTU*
--*maxVTU* = the time, in VTUs, to end the simulation
function Simulation:simulate(maxVTU)
	self:reset()
	local simulating = true
	 --this event will stop the simulation by set the upvalue 'simulating'
	self.events:add( Event(maxVTU+1, function() simulating = false end))
	-- and now we keep stepping the simulation until we're done.
	while simulating do self:step(1) end
end

--functino Simulation:step(Number n)
--simulate a certain number of events
--*n* = the number of events to simulate
function Simulation:step(n)
	n=n or 1 --min of 1 steps
	while n>0 do --keep simulating until we run out of events
		--call the next event, and then put all of the returned
		--events back info the event queue.
		for _,event in ipairs(self.events:pop()(self) or {}) do self.events:add(event) end
		n=n-1
	end
end

--functin Simulation:scheduleJob(Number cVTU, Job job, ....) return String 'blocked' if *job* will fit later, 'scheduled' if *job* was scheduled, "rejected" if *job* was rejected.
--schedules *job* using the current scheduling algorithm. 
--*cVTU* = the current time in VTUs
--*job* = the job to schedule
function Simulation:scheduleJob(cVTU,job, ...)
	--first, try to find the right hole
	local hole = self.memory:addJob(cVTU, job)
	if not hole then --if we didnt find one, maybe it can fit later?
		if self.memory:canFit(job) then --if it can, we will run later
			return 'blocked'
		else --else reject this job
			self.rejectedCount = self.rejectedCount + 1
			--print(cVTU,"scheduling job...rejected", job)
			return 'rejected'
		end
	else
		 --for logging, keep track of when this job was put into
		 --the ready queue.
		job.scheduleTime = cVTU
		table.insert(self.processedJobs, job) --add to a list for logging/debug later
		self.readyQueue:add(job)
		return 'scheduled'
	end
end

return Simulation
