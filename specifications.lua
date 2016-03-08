--[[ 
--		specifications.lua
--		provides a table with all the specifications explained in the handout,
--		including the random job sizes/durations etc, memory size, etc. etc.
--
--		changing these values will change them globally
--		]]
return {
	jobIAT = {1,10,1},
	jobSize = {50,300,10},
	jobDuration = {5,60,5},
	memorySize = 2000,
	osSize = 200,
	samplePeriod = {start=1000,stop=4000}
}
