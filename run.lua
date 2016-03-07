--[[
--			Alex Durville
--			CS4323
--			Simulation Project: Phase I
--			TA: Sarath Kumar Maddinani
--			There is an optimal amount of global variables: 0
--
--			run.lua
--			This is the main routine that performs the simulation for all three
--			memory placement algorithms. 
--
--]]

-- load all the required modules before we use them
require('strict') --throws error on any global variable access.
local algorithms = require('schedulingAlgorithms')
local Simulation = require("Simulation")
local sim = Simulation()

-- do a simulation with first fit algorithm
print("--------------- First Fit -------------------")
print("vtu", "event")
sim.schedulingAlgorithm = algorithms.firstFit
sim:simulate(5000)
sim:report('firstfit.csv')

-- do a simulation with best fit algorithm
print(string.rep('\n', 5))
print("--------------- Best Fit -------------------")
print("vtu", "event")
sim.schedulingAlgorithm = algorithms.bestFit
sim:simulate(5000)
sim:report('bestfit.csv')

-- do a simulation with worst fit algorithm
print(string.rep('\n', 5))
print("--------------- Worst Fit -------------------")
print("vtu", "event")
sim.schedulingAlgorithm = algorithms.worstFit
sim:simulate(5000)
sim:report('worstfit.csv')
