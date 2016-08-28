--mysql缓存到lua_shared_dict

local mysql = require("resty.mysql")
local cjson = require("cjson")
local comm = require("libs.common")

local _M = {}


local function cache_mysql(cache_ad)
    ngx.log(ngx.INFO, "缓存mysql数据到共享内存")

    --当前时间
    local now = ngx.localtime()
    local m, err = ngx.re.match(now, "([0-9-]+) ([0-9:]+)")

    local now_date = nil
    local now_time = nil
    if m then
        now_date = m[1]
        now_time = m[2]
    else
        if err then
            ngx.log(ngx.ERR, err)
            return
        end
        ngx.log(ngx.ERR, "match not found")
        return
    end

    --根据当前日期时间和是否投放过滤广告计划表
    local db, err = mysql:new()
    if not db then
        ngx.log(ngx.ERR, "failed to instantiate mysql: " .. err)
        return
    end

    db:set_timeout(1000) -- 1 sec

    local ok, err, errno, sqlstate = db:connect{
        host = "127.0.0.1",
        port = 3306,
        database = "adview",
        user = "root",
        password = "111111",
        max_packet_size = 1024 * 1024 
    }

    if not ok then
        ngx.log(ngx.ERR, "failed to connect: " .. err .. ": " .. errno .. " " .. sqlstate)
        return
    end

    db:query("SET NAMES utf8")

    local res_stage, err, errno, sqlstate =
        db:query("select * from advertisement_stage where startdate <= '" .. now_date ..
                 "' and enddate >= '" .. now_date .. "' and starttime <= '" .. now_time ..
                 "' and endtime >= '" .. now_time .. "' and isbid = 1")
    if not res_stage then
        ngx.log(ngx.ERR, "bad result: " .. err .. ": " .. errno .. ": " .. sqlstate)
        return
    end

    if comm.table_is_empty(res_stage) then
        ngx.log(ngx.INFO, "暂无广告投放计划, 请确定")

        local ok, err = db:set_keepalive(60000, 100)
        if not ok then
            ngx.log(ngx.ERR, "failed to set keepalive: " .. err)
            return
        end

        return
    end

    local orig_ad_stage = {}

    for _, v in ipairs(res_stage) do
        ngx.say(v.originalityId)
        local res_orig, err, errno, sqlstate =
            db:query("select * from orig where originalityId = '" .. v.originalityId .. "'")

        if not res_orig then
            ngx.log(ngx.ERR, "bad result: " .. err .. ": " .. errno .. ": " .. sqlstate)
            return
        end

        res_orig = res_orig[1]

        if not comm.table_is_empty(res_orig) then
            local res_ad, err, errno, sqlstate =
                db:query("select * from advertisement where adid = '" .. res_orig.adId ..
                         "' and startdate <= '" .. now_date .. "' and enddate >= '" .. now_date ..
                         "' and isbid = 1")

            if not res_ad then
                ngx.log(ngx.ERR, "bad result: " .. err .. ": " .. errno .. ": " .. sqlstate)
                return
            end

            res_ad = res_ad[1]


            if not comm.table_is_empty(res_ad) then
                table.insert(orig_ad_stage, {["orig"] = res_orig, ["ad"] = res_ad, ["stage"] = v})
            end

        end
    end

    if not comm.table_is_empty(orig_ad_stage) then
        cache_ad:set("ad", cjson.encode(orig_ad_stage), 1800)
    end

    local ok, err = db:set_keepalive(60000, 100)
    if not ok then
        ngx.log(ngx.ERR, "failed to set keepalive: " .. err)
        return
    end

end


function _M.cache()
    local cache_ad = ngx.shared.cache_ad
    local ad = cache_ad:get("ad")

    --未过期
    if ad then
        return
    end
   
    --缓存加锁
    local lock = require "resty.lock"
    local lock = lock:new("locks_ad")
    lock:lock("lock_ad")
    cache_mysql(cache_ad)
    lock:unlock()
end


return _M
