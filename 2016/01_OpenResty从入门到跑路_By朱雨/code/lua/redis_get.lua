local redis = require "resty.redis"
local red = redis:new()

red:set_timeout(1000) -- 1 sec

local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
    ngx.say("failed to connect: ", err)
    return
end

local arg = ngx.req.get_uri_args()

local value, err = red:get(arg.key)
if not value then
    ngx.say("failed to get: ", err)
    return
end

ngx.say(arg.key , ': ', value)

-- put it into the connection pool of size 100,
-- with 10 seconds max idle time

local ok, err = red:set_keepalive(10000, 100)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end

