--广告匹配

local cjson = require("cjson")
local comm = require("libs.common")
local redis = require("libs.redis")

local _M = {}

local function match_check(data, ad_orig_stage, dict_key, outerkey, innerkey)
    if ad_orig_stage[dict_key] ~= "" then
        if data[outerkey][innerkey] then
            if not string.find(ad_orig_stage[dict_key], data[outerkey][innerkey]) then
                return false
            end
        else
            return false
        end
    end

    return true
end


local function get_citycode(data)
    local city_code = redis.get_from_redis('ip:' .. data['device']['ip'])
    return city_code
end

local function match_city(city_code, match_label_list)
    local match_city_list = {}
    for _, ad_orig_stage in ipairs(match_label_list) do
        if ad_orig_stage['stage']['cityCode'] == '' then
            table.insert(match_city_list, ad_orig_stage)
        else
            if string.find(ad_orig_stage['stage']['cityCode'], city_code) then
                table.insert(match_city_list, ad_orig_stage)
            end
        end
    end

    return match_city_list
end

local function match_imei(data)
    if data['device']['didsha1'] and data['device']['didsha1'] ~= '' then
        local labels = redis.get_from_redis('imei:' .. data['device']['didsha1'])
        if not labels then
            return false
        else
            return labels
        end
    elseif data['device']['dpidsha1'] and data['device']['dpidsha1'] ~= '' then
        local labels = redis.get_from_redis('imei:' .. data['device']['dpidsha1'])
        if not labels then
            return false
        else
            return labels
        end
    else
        return false
    end
end

local function match_label(labels, match_imp_list)
    local match_label_list = {}
    for _, ad_orig_stage in ipairs(match_imp_list) do
        if ad_orig_stage['stage']['labelCode'] == '' then
            table.insert(match_label_list, ad_orig_stage)
        else
            if string.find(ad_orig_stage['stage']['labelCode'], labels) then
                table.insert(match_label_list, ad_orig_stage)
            end
        end
    end
    return match_label_list
end

local function match_app(data, orig_ad_stage_json)
    local match_app_list = {}
    for _, ad_orig_stage in ipairs(orig_ad_stage_json) do
        while true do
            if ad_orig_stage['stage']['appId'] ~= "" then
                if not string.find(ad_orig_stage['stage']['appId'], data['app']['id']) then
                    break
                end
            else
                if ad_orig_stage['stage']['cat'] ~= "" then
                    if data['app']['cat'] then
                        local apptype_flag = false
                        for _, apptype in ipairs(data['app']['cat']) do
                            if string.find(ad_orig_stage['stage']['cat'], tostring(apptype)) then
                                apptype_flag = true
                                break
                            end
                        end
                        if not apptype_flag then
                            break
                        end
                    else
                        break
                    end
                end
            end

            if not match_check(data, ad_orig_stage['stage'], 'paid', 'app', 'paid') then
                break
            end

            table.insert(match_app_list, ad_orig_stage)
            break
        end
    end
    return match_app_list
end


local function match_imp(data, match_device_list)
    local match_imp_list = {}

    for _, ad_orig_stage in ipairs(match_device_list) do
        local orig_obj = ad_orig_stage['orig']
        local data_imp = data['imp'][1]
        while true do
            if tonumber(orig_obj.pic_adType) == data_imp['instl'] then
                --图片广告
                if data_imp['instl'] == 0 or data_imp['instl'] == 1 or data_imp['instl'] == 4 then
                    if data_imp['banner']['h'] == tonumber(orig_obj.pic_h) and data_imp['banner']['w'] == tonumber(orig_obj.pic_w) then
                        if not match_check(data_imp, ad_orig_stage['stage'], 'pos', 'banner', 'pos') then
                            break
                        end
                        table.insert(match_imp_list, ad_orig_stage)
                    end
                end
            end

            break
        end
    end

    return match_imp_list
end


local function match_device(data, match_app_list)
    local match_device_list = {}
    for _, ad_orig_stage in ipairs(match_app_list) do
        while true do
            if not match_check(data, ad_orig_stage['stage'], 'carrier', 'device', 'carrier') then
                break
            end

            if not match_check(data, ad_orig_stage['stage'], 'make', 'device', 'make') then
                break
            end

            if not match_check(data, ad_orig_stage['stage'], 'model', 'device', 'model') then
                break
            end

            if not match_check(data, ad_orig_stage['stage'], 'os', 'device', 'os') then
                break
            end

            if not match_check(data, ad_orig_stage['stage'], 'connectionType', 'device', 'connectiontype') then
                break
            end

            if not match_check(data, ad_orig_stage['stage'], 'deviceType', 'device', 'devicetype') then
                break
            end

            table.insert(match_device_list, ad_orig_stage)

            break
        end
    end
    return match_device_list
end


function _M.match(data)
    if data.at ~= 1 or data['imp'][1]['bidfloorcur'] ~= 'RMB' then
        ngx.log(ngx.INFO, "不是以次高价成交或不是RMB")
        return nil
    end

    --获取所有候选的广告 创意
    local cache_ad = ngx.shared.cache_ad
    local orig_ad_stage = cache_ad:get("ad")
    --ngx.say(orig_ad_stage)
    
    if not orig_ad_stage then
        ngx.log(ngx.INFO, '没有候选广告可选择')
        return nil
    end

    local orig_ad_stage_json = cjson.decode(orig_ad_stage)

    if comm.table_is_empty(orig_ad_stage_json) then
        ngx.log(ngx.INFO, '没有候选广告可选择')
        return nil
    end

    -- app匹配
    local match_app_list = match_app(data, orig_ad_stage_json)
    if comm.table_is_empty(match_app_list) then
        ngx.log(ngx.INFO, 'app未匹配')
        return nil
    end
    --ngx.say(cjson.encode(match_app_list))

    --device匹配
    local match_device_list = match_device(data, match_app_list)
    if comm.table_is_empty(match_device_list) then
        ngx.log(ngx.INFO, 'device未匹配')
        return nil
    end
    --ngx.say(cjson.encode(match_device_list))

    --imp匹配
    local match_imp_list = match_imp(data, match_device_list)
    if comm.table_is_empty(match_imp_list) then
        ngx.log(ngx.INFO, "imp未匹配")
        return nil
    end
    --ngx.say(cjson.encode(match_imp_list))

    local match_label_list = nil
    --imei号、IDFA、androidID匹配 人群标签匹配
    local device_id = nil
    if data['device']['didsha1'] and data['device']['didsha1'] ~= '' then
        device_id = data['device']['didsha1']
    else
        device_id = data['device']['dpidsha1']
    end

    local res = redis.mget_from_redis({"imei:" .. device_id, 'ip:' .. data['device']['ip']})
    --ngx.log(ngx.INFO, cjson.encode(res))

    local labels = nil
    local city_code = nil

    if res then
        city_code = res[2]
        labels = res[1]
    end

    --local labels = match_imei(data)
    if not labels or labels == ngx.null then
        ngx.log(ngx.INFO, 'imei号未匹配')
        return nil
    else
        --ngx.say(labels)
        match_label_list = match_label(labels, match_imp_list)
        if not match_label_list then
            ngx.log(ngx.INFO, '人群标签不匹配')
            return nil
        end
    end
    --ngx.say(cjson.encode(match_label_list))

    --获取设备IP，定位所在城市
    --local city_code = get_citycode(data)

    --根据city_code筛选广告
    local match_city_list = match_city(city_code, match_label_list)
    if not match_city_list then
        ngx.log(ngx.INFO, '投放城市未匹配')
        return nil
    end
    --ngx.say(cjson.encode(match_city_list))
    return match_city_list
end

return _M
