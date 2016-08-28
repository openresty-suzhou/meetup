--广告竞价请求处理

local cjson = require("cjson")
local ad_cache = require("libs.cache")
local match = require("libs.match")
local bider = require("libs.bid")
local pack = require("libs.pack")

local function bid()
    --取报文
    ngx.req.read_body()
    local req_body = ngx.req.get_body_data()

    local status, req_body_json = pcall(cjson.decode, req_body)

    --json解析失败
    if not status then
        ngx.log(ngx.ERR, req_body_json)
        ngx.say('{"id":"", "nbr":2}')
        return
    end

    --ngx.log(ngx.INFO, req_body)
    --ngx.ctx.req_body = req_body

    ad_cache.cache()

    --local cache_ad = ngx.shared.cache_ad
    --local orig_ad_stage = cache_ad:get("ad")
    --ngx.say(orig_ad_stage)
    --local orig_ad_stage_json = cjson.decode(orig_ad_stage)

    local match_list = match.match(req_body_json)
    if not match_list then
        ngx.log(ngx.INFO, "未匹配到合适的广告")
        local result = {}
        result['id'] = req_body_json.id
        result['nbr'] = 8
        ngx.say(cjson.encode(result))
        return
    end
    --ngx.say(cjson.encode(match_list))

    local bid_price, stageid, result, paymode = bider.bid(req_body_json['imp'][1]['bidfloor'], match_list)
    if not result then
        local result = {}
        result['id'] = req_body_json.id
        result['nbr'] = 8
        ngx.say(cjson.encode(result))
        return
    end

    local result = pack.pack(req_body_json, bid_price, stageid, result, paymode)
    if not result then
        local result = {}
        result['id'] = req_body_json.id
        result['nbr'] = 8
        ngx.say(cjson.encode(result))
        return
    end

    local resp = cjson.encode(result)
    --ngx.log(ngx.INFO, resp)
    --ngx.ctx.resp = resp

    ngx.print(resp)
end

bid()
