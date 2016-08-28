--bid
local redis = require("libs.redis")
local cjson = require("cjson")

local _M = {}

function _M.bid(floor, dict_list)
    local low_price = floor

    local result = nil
    local stageid = -1
    local paymode = 1
    local bid_price = low_price
    local profit = 0

    for _, d in ipairs(dict_list) do
        while true do
            local res = redis.mget_from_redis({'ad:usedmoney:' .. d['ad'].adId, 
                                               'ad:usedmoney:' .. d['ad'].adId .. ":" .. tostring(d['stage']['stageId'])})

            --ngx.log(ngx.INFO, cjson.encode(res))
            --local total_used_money = redis.get_from_redis('ad:usedmoney:' .. d['ad'].adId)
            local total_used_money = nil
            if res then
                total_used_money = res[1]
            end
            if not total_used_money or total_used_money == ngx.null then
                total_used_money = 0
            end
            total_used_money = tonumber(total_used_money)

            --总预算不足
            if total_used_money + low_price > tonumber(d['ad'].budget) then
                ngx.log(ngx.INFO, '广告:', d['ad'].adId, '总预算不足')
                break
            end

            --local stage_used_money = redis.get_from_redis('ad:usedmoney:' .. d['ad'].adId .. ":" .. tostring(d['stage']['stageId']))
            local stage_used_money = nil
            if res then
                stage_used_money = res[2]
            end
            if not stage_used_money or stage_used_money == ngx.null then
                stage_used_money = 0
            end
            stage_used_money = tonumber(stage_used_money)

            --阶段预算不足
            if stage_used_money + low_price > tonumber(d['stage']['stageBudget']) then
                ngx.log(ngx.INFO, '广告', d['ad'].adId, '阶段', tostring(a['stage']['stageId']), '预算不足')
                break
            end

            local high_price = d['stage']['highPrice']
            if low_price >= high_price then
                break
            end

            local rand_price = math.floor(low_price * (1 + 0.02 * math.random()))

            if high_price - rand_price >= profit then
                profit = high_price - rand_price
                result = d['orig']
                stageid = d['stage']['stageId']
                bid_price = rand_price
            end

            break
        end
    end

    if not result then
        ngx.log(ngx.INFO, '预算不足或者底价太高,不竞价')
        return nil, nil, nil, nil
    end

    --ngx.log(ngx.INFO, '出价', tostring(bid_price))
    return bid_price, stageid, result, paymode
end

return _M
