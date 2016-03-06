print(package.path)
local algorithms = require('schedulingAlgorithms')
local Simulation = require("Simulation")
local sim = Simulation()
sim.schedulingAlgorithm = algorithms.firstFit

sim:simulate(5000)
