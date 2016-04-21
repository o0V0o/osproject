--[[
--	DiskQueue.lua
--	provides the DiskQueue class. DiskQueue keeps track of all the jobs
--	that are on the disk and ready to run, providing a queue interface.
--
--	This queue is actually maintained in the multiply-linked lists in the
--	disk partitions
--]]

-- load all required modules before we use them
local class = require('object')
local LinkedQueue = require('LinkedQueue')

--class DiskQueue()
--provides a queue that is stored within the Job objects, which in ture are
--stored in the Partition objects which are stored in memory. Arguable in a
--small header of each actual memory partition.
local DiskQueue = class(LinkedQueue)
DiskQueue.pre = 'prevDisk'
DiskQueue.post = 'nextDisk'

return DiskQueue
