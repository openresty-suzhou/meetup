local _M = {
}

function _M.new(self, name)
	self.name = name
	self.list = ngx.shared.list
	return setmetatable({},{__index = _M})
end

function _M.push(self,v)
	return self.list:lpush(self.name, v)
end

function _M.pop(self)
	return self.list:lpop(self.name)
end

function _M.size(self)
	return self.list:llen(self.name)
end

return _M
