--[[
--	Simulation.lua
--
--	provides the Simulation class. Simulation is the highest level object
--	in our simulation. It represents the entire virtual machine, and
--	functions such as step, reset, and simulate to run the simulation.
--	]]


--load all required modules before we use them.
local class = require("object")
local Event = require("Event")
local LogEvents = require("Logging")
local Events = require("Events")
local EventQueue = require('EventQueue')
local Memory = require("Memory")
local Disk = require("Disk")
local WaitingQueue = require('WaitingQueue')
local ReadyQueue = require('ReadyQueue')
local RNG = require('rng')
local specs = require('specifications')
--unpack the Events table into the local scope.
local RunJobEvent, JobPostEvent = Events.RunJobEvent, Events.JobPostEvent
local RoundRobinEvent = Events.RoundRobinEvent
local CompactionEvent = Events.CompactionEvent
--class Simulation()
--this is the main class that represents the state of the simulation.
local Simulation = class()
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
	self.logs = setmetatable({}, { __index=function(t,k)
			t[k]=setmetatable({maxn=0}, {__newindex=function(t,k,v) rawset(t,k,v);if type(k)=='number' and t.maxn<k then rawset(t,'maxn', k) end end})
			return t[k]
	end})

	 --we have a single hole at the start, at position 0, taking up the
	 --entire memory, minus the portion reserved for the OS
	self.memory = Memory(0,specs.memorySize - specs.osSize)
	self.memory.placementAlgorithm = self.placementAlgorithm
	self.events = EventQueue()
	--setup our job queues.
	self.readyQueue = ReadyQueue()
	self.waitingQueue = WaitingQueue()
	self.disk = Disk(specs.diskSize)
	
	--add some logging values
	self.rejectedCount = 0 --keep track of rejected jobs for logs
	self.processedJobs = {} --a list of EVERY job that was ever scheduled
	--add initial events
	JobPostEvent(0) --reset the last job arrival time to 0, but don't add the event...
	self.events:add( JobPostEvent() ) --add our first job!
	self.events:add( RoundRobinEvent( 10, specs.timeQuantum ))
	self.events:add( CompactionEvent( 100, 500))
	-- add all the logging events 
	for _,event in pairs( LogEvents() ) do
		self.events:add(event)
	end
	--allow other startup events to be registered later
	--and injected into this object *cause we can!*
	for _,event in pairs(self.startupEvents or {}) do
		if type(event) == "function" then
			event(self)
		else
			self.events:add( events )
		end
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
	local last = {}--stores the last used intex for a given table
	local max = {} --stores the maximum index for a given table
	local delim = ","--the CSV format delimiter.
	local file = io.open(fname, 'w') --attempt to open the file

	assert(file, "could not open file "..fname)


	--write the header values out to the file
	for parameter, values in pairs(self.logs) do
		file:write("time")
		file:write(delim)
		file:write(parameter)
		file:write(delim)
	end
	file:write(tostring(self.logs)..tostring(self.logs.fragmentation))
	file:write("\n")
	--keep iterating until there is no more data in *any* of the
	--logs.
	local done = false --indicates whether we are done with the csv file.
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
	local simulating = true --keep track of whether we are still simulating.
	 --this event will stop the simulation by set the upvalue 'simulating'
	self.events:add( Event(maxVTU+1, function() simulating = false end))
	-- and now we keep stepping the simulation until we're done.
	while simulating do self:step(1) end
end

--functino Simulation:step(Number n)
--simulate a certain number of events
--*n* = the number of events to simulate
function Simulation:step(n)
	n=n or 1 --the number of steps. default to 1.
	while n>0 do --keep simulating until we run out of events
		--call the next event, and then put all of the returned
		--events back info the event queue.
		for _,event in ipairs(self.events:pop()(self) or {}) do self.events:add(event) end
		n=n-1
	end
end

--function Simulation:onFreeMemory(Number cVTU)
--should be run anytime new free memory is available.
function Simulation:onFreeMemory(cVTU)
	--there is some free memory, maybe we can fit some jobs?
	--give the disk jobs priority on free memory
	self.disk:schedule(cVTU, self)
	--then attempt to schedule waiting jobs
	self.waitingQueue:schedule(cVTU, self)
end

--functin Simulation:scheduleJob(Number cVTU, Job job, ....) return String 'blocked' if *job* will fit later, 'scheduled' if *job* was scheduled, "rejected" if *job* was rejected.
--schedules *job* using the current scheduling algorithm. 
--*cVTU* = the current time in VTUs
--*job* = the job to schedule
function Simulation:scheduleJob(cVTU,job)
	--first, try to find the right hole
	local hole = self.memory:addJob(cVTU, job) 
	if not hole then --if we didnt find one, maybe it can fit later?
		if self.immediateCompaction and not self.memory.compacted then
			--print("compact at ", cVTU, self.memory.compacted)
			self.memory:compact() --note that this may do nothing
								-- if compaction has already been done
								-- and the memory config has not changed.
			--and now retry to schedule.
			return self:scheduleJob(cVTU, job)
		end
		if self.memory:canFit(job) then --if it can, we will run later
			return 'blocked'
		else --else reject this job
			self.rejectedCount = self.rejectedCount + 1
			return 'rejected'
		end
	else
		 --for logging, keep track of when this job was put into
		 --the ready queue.
		 assert(cVTU, "current time needed")
		job.scheduleTime = cVTU
		table.insert(self.processedJobs, job) --add to a list for logging/debug later
		self.readyQueue:add(job)
		return 'scheduled'
	end
end

return Simulation
