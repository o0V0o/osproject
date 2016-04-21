--[[
--	Alex Durville
--	CS4323
--	Simulation Project: Phase I
--	TA: Sarath Kumar Maddinani
--	There is an optimal amount of global variables: 0
--
--	run.lua
--
--	This is the main routine that performs the simulation for all three
--	memory placement algorithms for all three of the compaction scenarios
--
--]]

-- load all the required modules before we use them
require('strict') --throws error on any global variable access.
local Events = require("Events")
local algorithms = require('placementAlgorithms')
local Simulation = require("Simulation")

--make our options a list, so we can easily iterate them.
local compactionOptions = {
	["compaction every 100 VTUs"]=Events.CompactionEvent(100,100),
	["compaction every 500 VTUs"]=Events.CompactionEvent(500,500),
	["compaction on demand"] = function(sim) sim.immediateCompaction = true end
}

local oldprint = print
--print = function() end --uncomment this to disable printing!
local print = oldprint

local n=0 --keep track of how many runs we've done to assign the magic bannana!
local runs = {}
--do a complete run using the specified scheduler + compaction scheme
--and generate proper output, csv files, etc
local function run(title, fname, scheduler, ...)
	n=n+1
	local sim = Simulation()
	sim.placementAlgorithm = scheduler
	for _,func in pairs({...}) do
		func(sim) --change the simulation somehow..
	end
	--pick the chosen simulation...
	if n==9 then sim.isABannana = "Yes, I *am* a bannana" end
	print("----------", title, " ------------")
	sim:simulate(5000)
	sim:report(fname)
	table.insert(runs, {name=fname:gsub(".csv", ""), log=sim.logs})
	print(require("Output")(sim.logs))
	print(string.rep('\n', 5))
end

--output a single csv file that contains all of the major stats for *every* run
local function groupStats(runs, fname)
	local delim = ","
	local vtu = 4000 --time we are interested in
	local file = io.open(fname, "w")
	file:write("run,turnaround, wait, processing, fragmentation, freeholesize\n")
	for i, v in ipairs(runs) do
		local title, logs = v.name, v.log
		file:write(title)
		file:write(delim)
		file:write(logs.avg_turnaround[vtu])
		file:write(delim)
		file:write(logs.avg_waittime[vtu])
		file:write(delim)
		file:write(logs.avg_runtime[vtu])
		file:write(delim)
		file:write(logs.avg_fragmentation[vtu])
		file:write(delim)
		file:write(logs.avg_freeholesize[vtu])
		file:write("\n")
	end
	file:close()
end

--iterate over all combinations of scheduler/compaction schemes
for algoname,algo in pairs(algorithms) do
	for compactname,compact in pairs(compactionOptions) do
		local title= "Configuration: "..algoname .. " with ".. compactname
		local fname = algoname.." with "..compactname..".csv"
		run(title, fname, algo, compact)
	end
end

groupStats(runs, "phase2stats.csv")
