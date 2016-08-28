local mysql = require "resty.mysql"
local db, err = mysql:new()
if not db then
    ngx.say("failed to instantiate mysql: ", err)
    return
end

db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = "127.0.0.1",
    port = 3306,
    database = "ngx_test",
    user = "root",
    password = "111111",
    max_packet_size = 1024 * 1024 
}

if not ok then
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
    return
end

--ngx.say("connected to mysql.")

local arg = ngx.req.get_uri_args()


local res, err, errno, sqlstate =
    db:query(string.format([[insert into user (name, email, password) 
                            values ('%s', '%s', '%s')]], arg.name, arg.email, arg.password))
if not res then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    return
end

ngx.say(res.affected_rows, " rows inserted into table cats ",
        "(last insert id: ", res.insert_id, ")")

-- put it into the connection pool of size 100,
-- with 10 seconds max idle timeout
local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end

