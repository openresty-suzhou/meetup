--pack response message
local uuid = require("resty.jit-uuid")

local _M = {}

function _M.pack(data, bid_price, stageid, result, paymode)
    local bid_price = bid_price
    local id_imp_stage = stageid
    local bid_imp_orig = result
    local paymode = paymode

    local http_server = "http://dsp.example.com/"
    local http_server_win = "http://dsp.example.com/"

    local device_id = ''
    if data['device']['didsha1'] and data['device']['didsha1'] ~= '' then
        device_id = data['device']['didsha1']
    else
        device_id = data['device']['dpidsha1']
    end

    local bid_dict = {}
    bid_dict['adid'] = bid_imp_orig.adId
    bid_dict['wurl'] = http_server_win .. "win/" .. data['id'] .. '/' ..
                       device_id .. '/' .. tostring(bid_imp_orig.adId) .. '/' ..
                       tostring(id_imp_stage) .. '/' .. tostring(paymode) .. "?price=%%WIN_PRICE%%"
    
    local nurl = {}
    local nurl_dict = {}
    table.insert(nurl_dict, http_server .. "display/" .. data['id'] .. "/" ..
                     device_id .. "/" .. tostring(bid_imp_orig.adId) .. "/" .. tostring(id_imp_stage))
    nurl['0'] = nurl_dict
    bid_dict['nurl'] = nurl

    --{"600x600": "http://click.bangzhumai.com/static/picture/ymjy-cp-600-600.jpg"}
    local m, err = ngx.re.match(bid_imp_orig.pic_images, '.*"(.*)".*:.*"(.*)"')
    local img_url = m[2]
    if bid_imp_orig.orig_type == 1 then
        bid_dict['adi'] = img_url
        bid_dict['adh'] = tonumber(bid_imp_orig.pic_h)
        bid_dict['adw'] = tonumber(bid_imp_orig.pic_w)
    end

    curl = {}
    table.insert(curl, http_server .. "adclick/" .. data['id'] .. "/" .. device_id .. "/" .. tostring(bid_imp_orig.adId) .. "/" .. tostring(id_imp_stage))
    bid_dict['curl'] = curl

    bid_dict['adurl'] = bid_imp_orig.clickURL

    bid_dict['admt'] = bid_imp_orig.ad_type
    bid_dict['price'] = bid_price
    bid_dict['paymode'] = paymode

    if bid_imp_orig.ad_type == '4' or bid_imp_orig.ad_type == '8' then
        return nil
    end

    bid_dict['impid'] = data['imp'][1]['id']
    bid_dict['cid'] = bid_imp_orig.originalityId
    bid_dict['adct'] = bid_imp_orig.ad_ct

    bid = {}
    table.insert(bid, bid_dict)

    seatbid_list = {}
    seatbid_list['seat'] = uuid()
    seatbid_list['bid'] = bid

    seatbid = {}
    table.insert(seatbid, seatbid_list)

    result_imp = {}
    result_imp['seatbid'] = seatbid
    result_imp['id'] = data['id']

    return result_imp
end

return _M
