local class = require("object") --we will use a quick OOP implementation I wrote a while back.
local Event = require("Event")
local logEvents = require("Logging")

local print = function() end
--functin table.idx(Table table, Value value) return Number the index into *table* that contains the given element, *value*
function table.idx(table, value)
	for i,v in ipairs(table) do
		if v==value then return i end
	end
end

--function RNG(Number min, Number max, Number step) return Number between *min* and *max*, by multiples of *step*
--note that according to the lang. reference, math.random is uniformly distributed.
function RNG(min, max, step)
	return steps*math.random(0,(max-min)/steps)+min
end


--class Hole()
-- the *Hole* class is the essence of our "memory" representation.
-- since we are only simulating the *effects* of job scheduling, we don't
-- actually need to simulate a 200K byte array. that would be dumb...
-- instead, we will keep track of all the subdivisions of memory, their bounds
-- and if they are filled or not.
Hole = class()
function Hole:__init(start, size, job)
	self.start = start
	self.size = size
	--place the job in the hole, if it isn't false/nil
	return job and self:place(job) 
end
--function Hole:place(Job job) 
--places *job* into this hole.
--*job* = the job to be put in this hole
function Hole:place(job)
	-- fill the hole, and stash a reference of the hole in the job.
	self.filled = job 
	job.hole = self
end
---
function Hole:__tostring()
	local s = {}
	table.insert(s, "Hole:")
	table.insert(s, " from ")
	table.insert(s, self.start)
	table.insert(s, " to ")
	table.insert(s, self.start+self.size)
	table.insert(s, " (size ")
	table.insert(s, self.size)
	table.insert(s, ")\n-->")
	table.insert(s, tostring(self.filled))
	return table.concat(s)
end
-- function Hole:subdivide(Job job) return {Hole} a list of holes, representing the result of putting the given job into this hole , and fragmenting memory as a result
-- note that the holes are returned in *reverse order* of their logical memory layout.
--*job* = the job to be put in this hole
function Hole:subdivide(job)
	local t = {}
	--if the hole size==job size we only need one hole.
	if self.size~=job.size then
		table.insert( t, Hole(self.start+job.size, self.size-job.size)) --add in the remaining free segment
	end
	table.insert( t, Hole(self.start, job.size, job)) --add in the new hole that contains the job
	return t
end

-- class Job()
-- represents a Job. jobs don't really do anything by themselves...
Job = class()
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


--class EventQueue()
--an ordered event queue.
EventQueue = class()
--function EventQueue:add(Event event)
--adds *event* to the queue
function EventQueue:add(event)
	table.insert(self, event)
	table.sort(self, function(a,b) return a.vtu < b.vtu end)
end
--function EventQueue:pop() return Event the next event to trigger
function EventQueue:pop()
	return table.remove(self, 1)
end
---
function EventQueue:__tostring()
	return "EventQueue: #events="..#self
end

-- class BlockedQueue()
-- a quick class to *represent*  **NOT** simulate or model, the jobs that are backed up *somewhere*, like a longterm scheduler.
-- note: this is **NOT** implementing a "disk" or any sort of long-term storage: just look at the code. 
-- this class is equivalent to the "catching up" approach discussed in class, where, instead of explicitly checking if the next job is in the future, we just keep track of how many jobs were in the past. 
BlockedQueue = class()
BlockedQueue.n=0 --inherited value for the number of jobs waiting
--function BlockedQueue:pop() return Job the next job waiting to be scheduled
function BlockedQueue:pop()
	--return the job stashed here, or make a new one.
	local next = self.head or (not self:empty() and Job())
	self.head = nil
	return next
end
--function BlockedQueue:push(Job job)
--save a job for later (only *one*)
--*job* = the job to store
function BlockedQueue:push(job)
	assert( not (job and self.head), "can not stash a job in a non-empty BlockedQueue")
	self.head = self.head or job --stash the first job
	self.n=self.n+1 --and increment our total count
end
--functin BlockedQueue:empty() return Boolean true iff the queue is empty
function BlockedQueue:empty()
	return self.n==0
end

--class Simulation()
--this is the main class that represents the state of the simulation.
Simulation = class()
--constructor Simulation() 
function Simulation:__init()
	self:reset()
end
--functino Simulation:reset()
--reset the simulation to a valid initial state
function Simulation:reset()
	 --we have a single hole at the start, at position 0, taking up the
	 --entire memory, minus the portion reserved for the OS
	self.memory = {Hole(0,2000-200)}
	self.events = EventQueue()
	self.blockedQueue = BlockedQueue()
	 --use an ordered fifo queue of *scheduled* jobs waiting to run
	self.readyQueue = {}
	
	--logging values
	self.rejectedCount = 0 --keep track of rejected jobs for logs
	self.processedJobs = {} --a list of EVERY job that was ever scheduled
	--add initial events
	self.events:add( JobPostEvent(0) )
	for _,event in pairs( logEvents() ) do
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
--function Simulation:canFit(Job job) return Boolean true iff the job can fit in *any* of the current holes, even if they are filled
--*job* = the job to try and fit in memory
function Simulation:canFit(job)
	for _,hole in ipairs(self.memory) do --iterate over all holes
		if hole.size-job.size>=0 then return hole end --test if large enough
	end
end
--functin Simulation:scheduleJob(Number cVTU, Job job, ....) return Boolean/String nil if *job* will fit later, true if *job* was scheduled, "rejected" if *job* was rejected.
--schedules *job* using the current scheduling algorithm. 
--*cVTU* = the current time in VTUs
--*job* = the job to schedule
function Simulation:scheduleJob(cVTU,job, ...)
	--first, try to find the right hole
	local hole = self.schedulingAlgorithm(self.memory, job, ...)
	if not hole then --if we didnt find one, maybe it can fit later?
		if self:canFit(job) then --if it can, we will run later
			return nil
		else --else reject this job
			self.rejectedCount = self.rejectedCount + 1
			print(cVTU,"scheduling job...rejected", job)
			return "rejected"
		end
	else
		 --for logging, keep track of when this job was put into
		 --the ready queue.
		job.scheduleTime = cVTU
		self:queueJob(job, hole) --if we found a hole, queue it!
		return true
	end
end
--function Simulation:queueJob(Job job, Hole hole)
--put the job in the hole. subdivide the memory, and place the job in the ready queue, waiting to run
--*job* = the job to queue
--*hole* = the hole that the job should be placed in
function Simulation:queueJob(job, hole)

	 --locate this hole in our memory map, so we can remove it. 
	 --(note: not extremely efficient, but that is irrelevant)
	local idx = table.idx(self.memory, hole)
	table.remove( self.memory, idx) --remove the old hole from our sim
	for _,h in ipairs(hole:subdivide(job)) do --subdivide the hole
		table.insert(self.memory, idx, h) --and add the new holes
	end
	--insert the job in the ready queque to run later
	table.insert(self.readyQueue, job)
	table.insert(self.processedJobs, job)
end
--function Simulation:storageUtiliaztion() return Number the current storage utilization, as a percent from 0-1
function Simulation:storageUtilization()
	local used = 0
	for _,hole in pairs(self.memory) do
		if hole.filled then used=used+hole.size end
	end
	return used/1800
end
--function Simulation:fragmentation() return Number the current memory fragmentation in bytes
function Simulation:fragmentation()
	local count = 0
	for _,hole in pairs(self.memory) do
		if hole.size < 50 then count=count+hole.size end
	end
	return count*1024
end



--class RunJobEvent()
--the event that occurs when a Job is *terminated*. By creating a RunJobEvent, the simulation 'runs the job', and this event will trigger when the job is done processing.
RunJobEvent = class(Event)
--constructor RunJobEvent(Number startTime, Job job)
--initialize the event, and 'run' *job*. 
--*startTime* = the time, in VTUs to start the job.
--*job* = the job to run
function RunJobEvent:__init(startTime,job)
	print(startTime, "Job running...", job)
	self.hole = job.hole
	self.job = job
	self.job.startTime = startTime
	self.super(self, startTime+self.job.duration)
end
--function RunJobEvent:callback(Number cVTU, Simulation sim) return {Event}
--event callback function to *terminate* the job
function RunJobEvent:callback(cVTU, sim)
	print(cVTU,"Job funished!", self.job)
	self.hole.filled = nil --free this hole! now more jobs can fit in this hole!
	self.job.hole = nil --the job is done, but there is still a reference in the global job list for logging purposes. This frees the Hole object so it can be GC'd
	self.job.finishTime = cVTU --keep track of finish time.
	--remove us from the readyQueue
	-- (note that we keep the running job in the 'ready queuer'
	-- ' while it runs *JUST* so that other subsystems (aka the scheduler)
	--  can have access to information about the current running job
	--  without making more unecessary fields. 
	table.remove(sim.readyQueue, 1) 
	--attempt to schedule any jobs that are currently blocked. now that
	--our hole is free, they may fit!
	while not sim.blockedQueue:empty() do 
		local job = sim.blockedQueue:pop() --get the next job
		if not sim:scheduleJob(cVTU,job) then --try to fit it
			print(cVTU, "job rescheduled", "blocked", job)
			sim.blockedQueue:push(job) --push back onto the queue
			break --still blocked: can't schedule any more jobs
		else	--success! try again!
			print(cVTU, "job rescheduled", "scheduled")
		end
	end

	-- if there are jobs left in the ready queue then "run" the first one.
	if #sim.readyQueue~=0 then
		return {RunJobEvent(cVTU,sim.readyQueue[1])}
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
	vtu = vtu or (lasttime + RNG(1,10,1))
	lasttime = vtu
	self.super(self, vtu, jobPosted) --call parent constructor
end
--function JobPostEvent:callback(Number cVTU, Simulation sim, ...) return {Event}
--event callback function called when the event is triggered
--*cVTU* = the time, in VTUs that the event will be triggered
--*sim* = the current simulation state
function JobPostEvent:callback(cVTU, sim, ...)
	if sim.blockedQueue:empty() then
		local job = Job() --make a new job!
		if sim:scheduleJob(cVTU,job,...) then --try to schedule it!
			print(cVTU, "Job posted", "scheduled")
			-- if there were no jobs in the RQ then "run" the job.
			if #sim.readyQueue==1 then
				--return 2 events,
				--	* the next job posting
				--	* the job termination event
				return {JobPostEvent(),
					RunJobEvent(cVTU, job)}
			end
		else
			print(cVTU, "Job posted", "waiting", job)
			sim.blockedQueue:push(job) --store this job for later
		end
	else
		print(cVTU, "Job posted", "blocked")
		sim.blockedQueue:push() --store this job for later
	end
	--return 1 event:
	--	* the next job posting
	return {JobPostEvent()}
end


--function bestFit({Hole} holes, Job job) return [Hole] the 'best fit' hole for this job, or nil if hole is empty/does not exist
--*holes* = a list of holes that represent the current memory
--*job* = the job to try to fit into memory
local function bestFit(holes, job)
	local bestErr, bestHole
	for _,hole in pairs(holes) do --iterate over all holes
		local err = hole.size - job.size --calculate size difference
		 --test against current best, and keep it if its better
		if (not bestErr or bestErr > err) and err>=0 then
			bestErr = err 
			bestHole = hole
		end
	end
	 --only return the hole if it is not filled, and it exists
	return bestErr and not bestHole.filled and bestHole
end
--function firstFit({Hole} holes, Job job) return the 'first fit' hole for this job, or nil if no empty hole can fit *job*
--*holes* = a list of holes that represent the current memory
--*job* = the job to try to fit into memory
local function firstFit(holes, job)
	for _,hole in ipairs(holes) do --iterate over all holes
		 --check if large enough and empty
		if hole.size-job.size>=0 and not hole.filled then
			return hole 
		end
	end
end
--function worstFit({Hole} holes, Job job) return the 'worst fit' hole for this job, of nil if it is filled/does not fit anywhere
--*holes* = a list of holes that represent the current memory
--*job* = the job to try to fit into memory
local function worstFit(holes, job)
	local bestErr, bestHole
	for _,hole in pairs(holes) do --iterate over all holes
		local err = hole.size - job.size --calculate size difference
		 --test against current best and keep it if its 'worse'
		if (not bestErr or bestErr < err) and err>=0 then
			bestErr = err 
			bestHole = hole
		end
	end
	 --only return the hole if it is not filled and it exists
	return bestErr and not bestHole.filled and bestHole
end

--some helper functions to change the scheduling alrogithm used.
function Simulation:tryBestFit() self.schedulingAlgorithm = bestFit end
function Simulation:tryFirstFit() self.schedulingAlgorithm = firstFit end
function Simulation:tryWorstFit() self.schedulingAlgorithm = worstFit end

return Simulation
