local class = require("object") --we will use a quick OOP implementation I wrote a while back.
local Event = require("Event")
local LogEvents = require("Logging")
local Events = require("Events")
local EventQueue = require('EventQueue')
local PendingQueue = require('PendingQueue')
local Memory = require("Memory")
local ReadyQueue = require('ReadyQueue')

--function table.idx)Table table, Value value) return Number the index into *table* that contains the given element, *value*
function table.idx(table, value)
	for i,v in ipairs(table) do
		if v==value then return i end
	end
end

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
	 --we have a single hole at the start, at position 0, taking up the
	 --entire memory, minus the portion reserved for the OS
	self.memory = Memory(0,2000-200)
	self.memory.schedulingAlgorithm = self.schedulingAlgorithm
	self.events = EventQueue()
	--setup our job queues.
	self.pendingQueue = PendingQueue()
	self.readyQueue = ReadyQueue()
	
	--logging values
	self.rejectedCount = 0 --keep track of rejected jobs for logs
	self.processedJobs = {} --a list of EVERY job that was ever scheduled
	--add initial events
	self.events:add( JobPostEvent(0) )
	for _,event in pairs( LogEvents() ) do
		self.events:add(event)
	end
	self.events:add( Event(1000, function()self.processedJobs={}end) )
end
--functin Simulation:simulate(Number maxVTU)
--simulates up to a time of *maxVTU*
--*maxVTU* = the time, in VTUs, to end the simulation
function Simulation:simulate(maxVTU)
	self:reset()
	local simulating = true
	 --this event will stop the simulation by set the upvalue 'simulating'
	self.events:add( Event(maxVTU+1, function() simulating = false end))
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
	return self.memory
end
function Simulation:nextEvent()
	local nextEvent = self.events:pop()
	for _,event in ipairs(nextEvent(self) or {}) do self.events:add(event) end
	return nextEvent
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
