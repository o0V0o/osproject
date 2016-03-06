local algos = {}

--function bestFit(Memory mem, Job job) return [Hole] the 'best fit' hole for this job, or nil if hole is empty/does not exist
--*mem* = the memory object that contains all the partitions
--*job* = the job to try to fit into memory
function algos.bestFit(mem, job)
	local bestErr, bestHole
	for _,hole in pairs(mem) do --iterate over all holes
		local err = hole.size - job.size --calculate size difference
		 --test against current best, and keep it if its better
		if (not bestErr or bestErr > err) and err>=0 and not hole.filled then
			bestErr = err 
			bestHole = hole
		end
	end
	 --only return the hole if it is not filled, and it exists
	return bestErr and not bestHole.filled and bestHole
end

--function firstFit(Memory mem, Job job) return the 'first fit' hole for this job, or nil if no empty hole can fit *job*
--*mem* = the memory object that contains all the partitions
--*job* = the job to try to fit into memory
function algos.firstFit(mem, job)
	for _,hole in ipairs(mem) do --iterate over all holes
		 --check if large enough and empty
		if hole.size-job.size>=0 and not hole.filled then
			return hole 
		end
	end
end

--function worstFit(Memory mem, Job job) return the 'worst fit' hole for this job, of nil if it is filled/does not fit anywhere
--*holes* = the memory object that contains all the partitions
--*job* = the job to try to fit into memory
function algos.worstFit(mem, job)
	local bestErr, bestHole
	for _,hole in pairs(mem) do --iterate over all holes
		local err = hole.size - job.size --calculate size difference
		 --test against current best and keep it if its 'worse'
		if (not bestErr or bestErr < err) and err>=0 and not hole.filled then
			bestErr = err 
			bestHole = hole
		end
	end
	 --only return the hole if it is not filled and it exists
	return bestErr and not bestHole.filled and bestHole
end

return algos
