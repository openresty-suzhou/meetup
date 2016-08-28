local _M = {}

function _M.table_is_empty(t)
    if t == nil or next(t) == nil then
        return true
    else
        return false
    end
end

return _M
