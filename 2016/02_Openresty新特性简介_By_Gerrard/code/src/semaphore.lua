local semaphore = require 'ngx.semaphore'
local sema = semaphore.new()
local buffer = {}

local function produce(buffer)
	ngx.say('producer thread : producting data ...')
	ngx.sleep(0.1) --wait a little time
	buffer.message = 'This is a message from producer!' --producing data
	ngx.say('producer thread : posting to sema...')
	sema:post(1)
end

if buffer.message then
	ngx.say(buffer.message)
else
	ngx.say('main thread : no message in buffer, waiting for semaphore from producer...')
end

local co = ngx.thread.spawn(produce, buffer)
local ok, err = sema:wait(1) --wait at most 1s
if ok then
	if buffer.message then
		ngx.say('main thread : receive message : ', buffer.message)
	else
		ngx.say('main thread : unexpected error, got semaphore but no message in buffer')
	end
else
	ngx.say('main thread : failed to wait on sema: ', err)
end
ngx.say('main thread : end.')

