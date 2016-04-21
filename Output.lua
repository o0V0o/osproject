--[[
--	Output.lua
--
--	This module provides functionality to print out the logs that are required
--	with better formatted output.
--
--	I HATE YOU WHOEVER YOU ARE! (ok, not really.. but this project has been
--	nothing but a headache.... and you have to grade 30 of these???? I'm
--	sorry...)
--]]
--



--load modules..
local class = require('object')
local Event = require("Event")
local specs = require('specifications')

local fields = {
	{time=4000, name="avg_turnaround", header="Average Turnaround Time (VTU)"},
	{time=4000, name="avg_waittime", header="Average Wait time (VTU)"},
	{time=4000, name="avg_runtime", header="Average Processing Time (VTU)"},
	{time=4000, name="avg_fragmentation", header="Average Fragmentation (bytes)"},
	{time=4000, name="avg_freeholesize", header="Average Free Hole Size (bytes)"},
	{interval=1000, stop=5000, name="disk", header="Pending List [(pid, size, time remaining)]"}
}

--quick function to format numbers to a set amount of sigfigs.
local format = function(val)
	if type(val)=="number" then
		return string.format("%.6f", val)
	end
	return val
end
--function fieldHasOutput(Field, Number) return Boolean iff this field should
--be output as this time.
local function fieldHasOutput(logs,field, i)
	--print(field.start, field.stop, field.interval, field.time, i)
	if ((field.interval
		and i%field.interval==0
		and i>=(field.start or field.interval or field.time)
		and i>=(field.start or specs.samplePeriod.start)
		and i<=(field.stop or specs.samplePeriod.stop))
		or i==field.time) then
		return logs[field.name][i]
	end
end
--function asTable(Logs) outputs all of the logging info that is described by the *fields* table. as a table of sorts.
local function asTable(logs)
	local str = {}
	table.insert(str, "VTU\n")
	for i,field in ipairs(fields) do
		table.insert(str, string.rep("|\t", i) )
		table.insert(str, field.header)
		table.insert(str, "\n")
	end

	table.insert(str, "\n")
	--now, for each VTU, check print out any relevant info
	for i=1,5000 do
		--do we need to output something?
		local output = false
		for _,field in ipairs(fields) do
			output = output or fieldHasOutput(logs,field, i)
		end
		--if so, output everything!
		if output then
			table.insert(str, "|")
			table.insert(str, i)
			table.insert(str, "|")
			for _,field in ipairs(fields) do
				if fieldHasOutput(logs,field, i) then
					table.insert(str, format(logs[field.name][i]) or "(not collected)")
				else
					table.insert(str, string.rep(" ", 5))
				end
				table.insert(str," | \t")
			end
			table.insert(str, "\n")
		end
	end

	str = table.concat(str)
	return str
end

local function asList(logs)
	local str = {}
	for i=1,5000 do
		local output = false
		for _,field in ipairs(fields) do
			output = output or fieldHasOutput(logs,field, i)
		end
		if output then
			table.insert(str, "\n------VTU ")
			table.insert(str, i)
			table.insert(str, "-----\n")
			for _,field in ipairs(fields) do
				if fieldHasOutput(logs,field, i) then
					table.insert(str, field.header)
					table.insert(str, ": ")

					table.insert(str, format(logs[field.name][i]) or "(not collected)")
					table.insert(str, "\n")
				end
			end
		end
	end
	return table.concat(str)
end

return asList
