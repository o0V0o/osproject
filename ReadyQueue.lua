--[[
--	ReadyQueue.lua
--	provides the ReadyQueue class. ReadyQueue keeps track of all the jobs
--	that are in memory and ready to run, providing a queue interface.
--
--	This queue is actually maintained in the multiply-linked lists in the
--	partitions. 
--]]

-- load all required modules before we use them
local class = require('object')
local LinkedQueue = require("LinkedQueue")

--class ReadyQueue()
--provides a queue that is stored within the Job objects, which in ture are
--stored in the Partition objects which are stored in memory. Arguable in a
--small header of each actual memory partition.
local ReadyQueue = class(LinkedQueue)
ReadyQueue.post = "nextReady"
ReadyQueue.pre = "prevReady"

return ReadyQueue
