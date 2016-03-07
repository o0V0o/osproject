local class = require("object") --we will use a quick OOP implementation I wrote a while back.
local Event = require("Event")
local Job = require("Job")
local RNG = require('rng')
local specs = require('specifications')


local print = function() end --disable debug print statements

--class RunJobEvent()
--the event that occurs when a Job is *terminated*. By creating a RunJobEvent, the simulation 'runs the job', and this event will trigger when the job is done processing.
RunJobEvent = class(Event)
--constructor RunJobEvent(Number startTime, Job job)
--initialize the event, and 'run' *job*. 
--**this event is the dispatcher and the termination**
--*startTime* = the time, in VTUs to start the job.
--*job* = the job to run
function RunJobEvent:__init(startTime,job)
	print(startTime, "Job running...", job)
	CPU = job --see? I have a CPU.
	self.hole = job.hole
	self.job = job
	self.job.startTime = startTime
	self.super(self, startTime+self.job.duration)
end
--function RunJobEvent:callback(Number cVTU, Simulation sim) return {Event}
--event callback function to *terminate* the job
function RunJobEvent:callback(cVTU, sim)
	print(cVTU,"Job funished!", self.job)
	CPU = nil --now nothing is 'on the cpu'
	self.hole.filled = nil --free this hole! now more jobs can fit in this hole!
	self.job.hole = nil --the job is done, but there is still a reference in the global job list for logging purposes. This frees the Hole object so it can be GC'd
	self.job.finishTime = cVTU --keep track of finish time.
	--remove us from the readyQueue
	-- (note that we keep the running job in the 'ready queue'
	-- ' while it runs *JUST* so that other subsystems (aka the scheduler)
	--  can have access to information about the current running job
	--  without making more unecessary fields. 
	--  you can think of the first element of the readyQueue as the "cpu"
	sim.readyQueue:pop() --removes this job from the 'cpu'
	--attempt to schedule any jobs that are currently blocked. now that
	--our hole is free, they may fit!
	while not sim.pendingQueue:empty() do 
		local job = sim.pendingQueue:pop() --get the next job
		local success = sim:scheduleJob(cVTU, job)
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

local lasttime = 0 --keeps track of when jobs arrived, to find the 'next' job
-- class JobPostEvent()
-- posts a job, runs the scheduler, and creates a new event for the *next* job to be posted
JobPostEvent = class(Event)
--constructor JobPostEvent([Number vtu])
--*vtu* the time in VTUs the job was posted. if no time is specified, the time will be determined from a random offset to the *last* job posted.
function JobPostEvent:__init(vtu)
	 --if no time specified, create the *next* job
	vtu = vtu or (lasttime + RNG(table.unpack(specs.jobIAT)))
	lasttime = vtu
	self.super(self, vtu, jobPosted) --call parent constructor
end
--function JobPostEvent:callback(Number cVTU, Simulation sim, ...) return {Event}
--event callback function called when the event is triggered
--**this event runs the scheduler**
--*cVTU* = the time, in VTUs that the event will be triggered
--*sim* = the current simulation state
function JobPostEvent:callback(cVTU, sim)
	if sim.pendingQueue:empty() then
		local job = Job() --make a new job!
		local success = sim:scheduleJob(cVTU, job)
		print(cVTU, "Job posted", success, job)
		if success == 'scheduled' then
			-- if this job is at the head of the line, run it now.
			if sim.readyQueue:peek() == job then
				--return 2 events,
				--	* the next job posting
				--	* the job termination event
				return {JobPostEvent(),
					RunJobEvent(cVTU, job)}
			end
		elseif success == 'blocked' then
			sim.pendingQueue:push(job) --store this job for later
		end
	else
		print(cVTU, "Job posted", "blocked")
		sim.pendingQueue:push() --store this job for later
	end
	--return 1 event:
	--	* the next job posting
	return {JobPostEvent()}
end

return {RunJobEvent=RunJobEvent,
	JobPostEvent=JobPostEvent}
