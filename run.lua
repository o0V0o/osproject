local algorithms = require('schedulingAlgorithms')
local Simulation = require("simulation")
local sim = Simulation()
sim.schedulingAlgorithm = algorithms.firstFit

sim:simulate(100)
