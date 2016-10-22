#!/usr/bin/lua

--
-- Created by IntelliJ IDEA.
-- User: LatteCake
-- Date: 16/10/22
-- Time: 14:07
-- To change this template use File | Settings | File Templates.
--

ngx.req.read_body()
ngx.header.content_type = "application/json;charset=UTF-8"


local cjson = require "cjson"

local success = function(con)
    return cjson.encode({
        success = true,
        body = con
    })
end

local failure = function(err)
    return cjson.encode({
        success = false,
        errors = err
    })
end

-- 参数获取
local request_args = ngx.req.get_uri_args()
local ip_address = request_args['ip']

local checkIp = require("ip_check"):new(ip_address)

-- 验证ip
local ok, err = checkIp:checkIp()
if not ok then
    ngx.say(failure(err))
    return
end

--
local ipdetail, err = require("ip_location"):new(ip_address, "/var/www/lua-resty-17mon/file/17monipdb.dat")
if not ipdetail then
    ngx.log(ngx.ERR, err)
    ngx.say(failure(err))
    return
end

local ipLocation, err = ipdetail:location()
if not ipLocation then
    ngx.log(ngx.ERR, err)
    ngx.say(failure(err))
    return
end

ngx.say(success(ipLocation))