--[[
--	Events.lua
--
--	This module provides the standard events that the simulation needs
--	to post/processes/run jobs through our discrete event system.
--]]


--load required modules...
local class = require("object")
local Event = require("Event")
local Job = require("Job")
local RNG = require('rng')
local specs = require('specifications')

--local print = function() end --disable debug print statements

--class RunJobEvent()
--the event that occurs when a Job is *terminated*. By creating a RunJobEvent, the simulation 'runs the job', and this event will trigger when the job is done processing.
local RunJobEvent = class(Event)

--constructor RunJobEvent(Number startTime, Job job)
--initialize the event, and 'run' *job*. 
--**this event is the dispatcher and the termination**
--*startTime* = the time, in VTUs to start the job.
--*job* = the job to run
function RunJobEvent:__init(startTime,job)
	print(startTime, "Job running...", job)
	self.hole = job.hole			--save a ref. to the hole
	self.job = job					--save a ref. to the job
	self.job.startTime = startTime	--save for later logging
	self.job.running = true 		--indicate that this job is now running on CPU
	--calculate start time based on when the job expires
	self.super(self, startTime+self.job.duration) 
end
--[[
--function RunJobEvent:callback(Number cVTU, Simulation sim) return {Event}
--event callback function to *terminate* the job
function RunJobEvent:callback(cVTU, sim)
	print(cVTU,"Job funished!", self.job)
	self.job.running = nil --no longer running...
	self.hole.filled = nil --free this hole! now more jobs can fit in this hole!
	self.job.hole = nil --the job is done, but there is still a reference in the global job list for logging purposes. This frees the Hole object so it can be GC'd
	self.job.finishTime = cVTU --keep track of finish time.
	--remove us from the readyQueue
	-- (note that we keep the running job in the 'ready queue'
	-- while it runs *JUST* so that other subsystems (aka the scheduler)
	--  can have access to information about the current running job
	--  without making more unecessary fields. 
	--  you can think of the first element of the readyQueue as the "cpu"
	sim.readyQueue:pop() --removes this job from the 'cpu'
	--attempt to schedule any jobs that are currently blocked. now that
	--our hole is free, they may fit!
	while not sim.pendingQueue:empty() do 
		local job = sim.pendingQueue:pop() --get the next job
		local success = sim:scheduleJob(cVTU, job) --can we fit it?
		print(cVTU, "job rescheduled", success, job)
		if success == 'blocked' then
			sim.pendingQueue:push(job) --push back onto the queue
			break --still blocked: can't schedule any more jobs
		end
	end

	-- if there are jobs left in the ready queue then "run" the first one.
	if sim.readyQueue:peek() then
		return {RunJobEvent(cVTU,sim.readyQueue:peek())}
	end
end
--]]

--class RoundRobinEvent()
--run a job for a specified period of time, then run the *next* job
local RoundRobinEvent = class(Event)
function RoundRobinEvent:__init(vtu, quantum)
	assert(quantum, "must supply time quantum")
	self.quantum = quantum
	self.super(self, vtu) --call parent constructor
end
--execute one phase of round robin scheduling
function RoundRobinEvent:callback(cVTU, sim)
	local job = sim.readyQueue:peek()
	local used
	if job then
		if job.remaining <= 0 then --job is done, remove from queue
			sim.memory:evictJob(job, cVTU, sim)
		else
			sim.readyQueue:next() --job is not done, but still rotate queue
		end
		local nextJob = sim.readyQueue:peek()
		job.running = false
		nextJob.running = true
		used = nextJob:run(cVTU, self.quantum)
	else
		used = self.quantum --no job, just idle for a bit,
	end
	return {RoundRobinEvent( cVTU+used , self.quantum)}
end



--class CompactionEvent(Event)
--execute a memory compaction in a specified interval
local CompactionEvent = class(Event)
function CompactionEvent:__init(vtu, interval)
	self.interval = interval
	self.super(self,vtu)
end
function CompactionEvent:callback(cVTU, sim)
	sim.memory:compact()
	sim:onFreeMemory(cVTU)
	return {CompactionEvent(cVTU + self.interval, self.interval)}
end

-- class JobPostEvent()
-- posts a job, runs the scheduler, and creates a new event for the *next* job to be posted
local JobPostEvent = class(Event)
local lasttime = 0 --keeps track of when jobs arrived, to find the 'next' job

--constructor JobPostEvent([Number vtu])
--*vtu* the time in VTUs the job was posted. if no time is specified, the time will be determined from a random offset to the *last* job posted.
function JobPostEvent:__init(vtu)
	 --if no time specified, create the *next* job
	vtu = vtu or (lasttime + RNG(table.unpack(specs.jobIAT)))
	lasttime = vtu --update the last job arrival time
	self.super(self, vtu) --call parent constructor
end

--function JobPostEvent:callback(Number cVTU, Simulation sim, ...) return {Event}
--event callback function called when the event is triggered
--**this event runs the scheduler**
--*cVTU* = the time, in VTUs that the event will be triggered
--*sim* = the current simulation state
function JobPostEvent:callback(cVTU, sim)
	--we know that no jobs on the disk can fit right now,
	--otherwise they would have already been scheduled.
	--print("job posted")
	--so, check if this job is still pending.
	if sim.waitingQueue:empty() then --only post if there is no line
		local job = Job()
		sim.waitingQueue:push(job)
	else
		sim.waitingQueue:push() --add it to the pending queue...
	end
	--memory config has not changed, so no need to check disk
	sim.waitingQueue:schedule(cVTU, sim)
	return {JobPostEvent()}
end

return {RunJobEvent=RunJobEvent,
	RoundRobinEvent=RoundRobinEvent,
	CompactionEvent=CompactionEvent,
	JobPostEvent=JobPostEvent} --return the events declared in this module
