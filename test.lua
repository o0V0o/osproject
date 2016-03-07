-- steps through the simulation, pausing every time the memory map changes.
local algorithms = require('placementAlgorithms')
local Simulation = require("Simulation")
local Events = require('Events')
local RNG = require('rng')

local sim = Simulation()
sim.placementAlgorithm = algorithms.bestFit
sim:reset()
for i=1,10000 do
	sim.logs.rngtest[i] = RNG(0,100,10)
end
sim:report('rngtest.csv')

local lastMemConfig = ''
return function()
	while true do
		sim:step()
		mem = sim.memory
		if tostring(mem) ~= lastMemConfig then
			lastMemConfig = tostring(mem)
			break
		end
	end
	print(lastMemConfig)
end
