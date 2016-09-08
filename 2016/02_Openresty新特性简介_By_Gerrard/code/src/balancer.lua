local balancer = require 'ngx.balancer'
local host = '127.0.0.1'
local port = {9000, 9001, 9002}
local val, err = ngx.shared.list:incr('count', 1, -1)
if not val then
	ngx.log(ngx.ERR, 'failed to incr key "count", err : ', err)
	ngx.exit(500)
end

local state, status = balancer.get_last_failure()
if state then
    ngx.log(ngx.ERR,'last peer failure:', state, " ", status)
end
if not ngx.ctx.tries then
    ngx.ctx.tries = 0
end
if ngx.ctx.tries < 1 then
    local ok, err = balancer.set_more_tries(1)
    if not ok then
	return error('failed to set more tries: ', err)
    elseif err then
	ngx.log(ngx.ERR, "set more tries:", err)
    end
end
ngx.ctx.tries = ngx.ctx.tries + 1
local ok, err = balancer.set_current_peer(host, port[val%3+1])
if not ok then
	ngx.log(ngx.ERR, 'failed to set the current peer : ', err)
	return ngx.exit(500)
end
