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

local res, err, errno, sqlstate =
    db:query("drop table if exists user")
if not res then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    return
end

local res, err, errno, sqlstate =
    db:query("create table user "
             .. "(id serial primary key, "
             .. "name varchar(8), " 
             .. "email varchar(32), "
             .. "password varchar(64), "
             .. "index idx_name (name))")
if not res then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    return
end

ngx.say("table user created.")

local res, err, errno, sqlstate =
    db:query("insert into user (name, email, password) "
             .. "values (\'zhuyu\', \'zhuyu1989.hi@gmail.com\', \'123456\')")
if not res then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    return
end

ngx.say(res.affected_rows, " rows inserted into table cats ",
        "(last insert id: ", res.insert_id, ")")

-- run a select query
-- the result set:
local res, err, errno, sqlstate =
    db:query("select * from user")
if not res then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    return
end

local cjson = require "cjson"
ngx.say("result: ", cjson.encode(res))

-- put it into the connection pool of size 100,
-- with 10 seconds max idle timeout
local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end
