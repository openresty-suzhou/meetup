local socket = require'socket'
local host = '127.0.0.1'
local port = 1234
local sock = assert(socket.connect(host, port))
sock:settimeout(0)

print('please input anything, exit to quit:')
local input, recvt, sendt, status
local connected = true

while connected do
	input = io.read()
	if #input > 0 then
		assert(sock:send(input .. '\n'))
	end
	recvt, sendt, status = socket.select({sock}, nil, 0.1)
	while #recvt > 0 do
		local response, reveive_status = sock:receive()
		if reveive_status ~= 'closed' then 
			if response then
				print(response)
				if response == 'bye' then
					sock:close()
					connected = false
				end
			end
		end
		break
	end
end
