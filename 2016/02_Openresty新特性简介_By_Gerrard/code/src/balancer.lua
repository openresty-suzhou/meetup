local balancer = require 'ngx.balancer'
local host = '127.0.0.1'
local port = {9000, 9001}
local val, err = ngx.shared.list:incr('count', 1, -1)
if not val then
	ngx.log(ngx.ERR, 'failed to incr key "count", err : ', err)
	ngx.exit(500)
end
local ok, err = balancer.set_current_peer(host, port[val%2+1])
if not ok then
	ngx.log(ngx.ERR, 'failed to set the current peer : ', err)
	return ngx.exit(500)
end
