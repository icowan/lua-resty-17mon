--
-- Created by IntelliJ IDEA.
-- User: LatteCake
-- Date: 16/10/19
-- Time: 15:58
-- To change this template use File | Settings | File Templates.
--

local ngx = require('ngx')

local setmetatable = setmetatable
local rawget = rawget

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function(narr, nrec) return {} end
end

local _M = new_tab(0, 32)

local mt = { __index = _M }

_M._VERSION = '0.01'

-- 初始化
function _M.new(self, ipAddress)
    return setmetatable({ _ipAddress = ipAddress }, mt)
end

-- 获取所有信息
function _M.checkIp(self)
    local ipAddress = rawget(self, "_ipAddress")
    if not ipAddress then
        return nil, "not initialized"
    end

    return ngx.re.match(ipAddress, "^(((\\d{1,2})|(1\\d{2})|(2[0-4]\\d)|(25[0-5]))\\.){3}((\\d{1,2})|(1\\d{2})|(2[0-4]\\d)|(25[0-5]))$")
end

-- 把ip转成整型
function _M.ip2long(self)
    local ipAddress = rawget(self, "_ipAddress")
    if not ipAddress then
        return nil, "not initialized"
    end

    local o1, o2, o3, o4 = ipAddress:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)")
    local num = 2 ^ 24 * o1 + 2 ^ 16 * o2 + 2 ^ 8 * o3 + o4
    return num
end

return _M