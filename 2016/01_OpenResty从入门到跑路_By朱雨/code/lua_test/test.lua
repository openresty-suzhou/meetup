local cjson = require("cjson")

local function print_env()
    print("LUA_PATH", package.path)
    print("LUA_CPATH", package.cpath)
    print()
end

print_env()

local input = [[{"id": "9d66d9249cc5bd549b0e68b9fedc69a7","paid": 0,"cat": [10505],
                 "storeurl": "https://itunes.apple.com/cn/app/id902345501?l=zh&mt=8", 
                 "name": "App Name","bundle": "yourcompany.com.app","ver": "1.2"}]]

local tab = cjson.decode(input)

for k, v in pairs(tab) do
    if type(v) ~= 'table' then
        print(k .. ': ' .. v)
    else
        print(k .. ": ")
        for _, v in ipairs(v) do
            print(v)
        end
    end
    print("----------------------------------------------------------------")
end

print()

print("tab.id", tab.id)
print("tab['id']", tab['id'])
print()

local arr = {123, "abc", 456, 'def'}
print("arr length:", #arr)
print("arr length:", table.getn(arr))
print("arr[1]", arr[1])
for i, v in ipairs(arr) do
    print(i, v)
end
print()

local input2 = "{'abc': , 'def': 1}"

local status, tab2 = pcall(cjson.decode, input2)
if not status then
    print(status, tab2)
else
    print(status, tab2) 
end

print()
local ffi = require("ffi")
ffi.cdef[[
    int printf(const char *fmt, ...);
]]
ffi.C.printf("Hello %s!\n", "world")

