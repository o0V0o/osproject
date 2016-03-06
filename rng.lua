--function RNG(Number min, Number max, Number step) return Number between *min* and *max*, by multiples of *step*
--note that according to the lang. reference, math.random is uniformly distributed.
function RNG(min, max, step)
	return step*math.random(0,(max-min)/step)+min
end

return RNG
