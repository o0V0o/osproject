local algorithms = require('schedulingAlgorithms')
local Simulation = require("Simulation")
local sim = Simulation()

print("--------------- First Fit -------------------")
sim.schedulingAlgorithm = algorithms.firstFit
sim:simulate(5000)
sim:report('firstfit.csv')

print("--------------- Best Fit -------------------")
sim.schedulingAlgorithm = algorithms.bestFit
sim:simulate(5000)
sim:report('bestfit.csv')

print("--------------- Worst Fit -------------------")
sim.schedulingAlgorithm = algorithms.worstFit
sim:simulate(5000)
sim:report('worstfit.csv')
