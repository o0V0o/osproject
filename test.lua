local m = require("Memory")(0,100)
local i=0
for k,v in ipairs(m) do
	print(k,v)
	i=i+1
	if i>100 then break end
end
