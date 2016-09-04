local stack = require 'stack'

local myStack = stack:new('stack')
for k, v in pairs(myStack) do
	print(k, tostring(v))
end

--string & number supported
local elements = {
	'first',
	2,
	true,
	4.001,
}

for _, v in ipairs(elements) do
	local len, err = myStack:push(v)
	if len then
		ngx.say('pushed value : ' .. v .. ' to stack, stack length : ' .. len )
	else 
		ngx.say('pushed to stack falied, err : ', err)
	end
end

while true do
	local val, err = myStack:pop()
	if not val then
		ngx.say('pop from stack falied, err : ', err)
		break
	end
	ngx.say('pop from stack, value : ' .. val .. ', sizeof stack : ', myStack:size())
end
