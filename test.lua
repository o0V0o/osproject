local algorithms = require('schedulingAlgorithms')
local Simulation = require("Simulation")
local Events = require('Events')
local sim = Simulation()
sim.schedulingAlgorithm = algorithms.bestFit
sim:reset()
local lastMemConfig = ''
return function()
	while true do
		mem = sim:step()
		if tostring(mem) ~= lastMemConfig then
			lastMemConfig = tostring(mem)
			break
		end
	end
	print(lastMemConfig)
end
