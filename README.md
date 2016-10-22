# openResty IP数据库脚本

ipip.net IP数据库之openresty版

## 使用方式

本脚本

### nginx 配制

```nginx
lua_package_path "/usr/local/openresty/lualib/?.lua;/var/www/lua-resty-17mon/lualib/?.lua;;";
lua_package_cpath "/usr/local/openresty/lualib/?.so;;";

error_log /var/www/lua-resty-17mon/logs/lua-resty-17mon.debug.log debug;

server {
    listen 8080;
    server_name localhost;
    charset utf-8;
    location /ipLocation {
        resolver 8.8.8.8; # 如果要使用api的话 需要dns 这可以改成中国的会快一些
        default_type "text/plain";
        content_by_lua_file "/var/www/lua-resty-17mon/script/ip_location.lua";
    }
}

```

### lua 脚本使用


```lua
-- /var/www/lua-resty-17mon/script/ip_location.lua

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

-- 如果不需要验证可以不用此拓展
local checkIp = require("ip_check"):new(ip_address)

-- 验证ip
local ok, err = checkIp:checkIp()
if not ok then
    ngx.say(failure(err))
    return
end

-- 使用本地数据库
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

```

#### 通过免费api获取ip信息

> 如果通过api获取数据需要使用http服务，这里需要使用[lua-resty-http](https://github.com/pintsized/lua-resty-http)
> 这里我已经把它直接放到`lualib/resty`目录了，可以直接使用 感谢**pintsized**提供的脚本

```lua
-- /var/www/lua-resty-17mon/script/ip_location.lua

local ipdetail, err = require("ip_location"):new(ip_address)
if not ipdetail then
    ngx.log(ngx.ERR, err)
    ngx.say(failure(err))
    return
end

local ipLocation, err = ipdetail:locationApiFree()
if not ipLocation then
    ngx.log(ngx.ERR, err)
    ngx.say(failure(err))
    return
end

ngx.say(success(ipLocation))

```

#### 通过付费api获取ip信息

```lua
-- /var/www/lua-resty-17mon/script/ip_location.lua

local ipdetail, err = require("ip_location"):new(ip_address, "", "your token")
if not ipdetail then
    ngx.log(ngx.ERR, err)
    ngx.say(failure(err))
    return
end

local ipLocation, err = ipdetail:locationApiFree()
if not ipLocation then
    ngx.log(ngx.ERR, err)
    ngx.say(failure(err))
    return
end

ngx.say(success(ipLocation))

```

#### 获取aip使用状态

```lua
-- /var/www/lua-resty-17mon/script/ip_location.lua

local ipdetail, err = require("ip_location"):new(ip_address, "your token")
if not ipdetail then
    ngx.log(ngx.ERR, err)
    ngx.say(failure(err))
    return
end

local ipLocation, err = ipdetail:apiStatus()
if not ipLocation then
    ngx.log(ngx.ERR, err)
    ngx.say(failure(err))
    return
end

ngx.say(success(ipLocation))

```

### 返回数据结构

**Response**

返回类型: JSON

| 参数 | 类型 | 备注 |
| --- | --- | --- |
| `success` | bool | `true` or `false` |
| `errors` or `body` | string | 当success为false时errors有值否则返回body |

**body返回参数详情**

| 参数 | 类型 | 备注 |
| --- | --- | --- |
| country | string | 国家 |
| city  | string | 省会或直辖市（国内） |
| region  | string | 地区或城市 （国内） |
| place  | string | 学校或单位 （国内） |
| operator  | string | 运营商字段 |
| latitude  | string | 纬度 |
| longitude  | string | 经度 |
| timeZone  | string | 时区一, 可能不存在 |
| timeZoneCode  | string | 时区码 |
| administrativeAreaCode  | string | 中国行政区划代码 |
| internationalPhoneCode  | string | 国际电话代码 |
| countryTwoDigitCode  | string | 国家二位代码 |
| worldContinentCode  | string | 世界大洲代码 |

*返回结果参考:*

```json
{
	"success": true,
	"body": {
		"country": "",  // 国家
	    "city": "",  // 省会或直辖市（国内）
	    "region": "",  // 地区或城市 （国内）
	    "place": "",  // 学校或单位 （国内）
	    "operator": "",  // 运营商字段（只有购买了带有运营商版本的数据库才会有）
	    "latitude": "",  // 纬度     （每日版本提供）
	    "longitude": "",  // 经度     （每日版本提供）
	    "timeZone": "",  // 时区一, 可能不存在  （每日版本提供）
	    "timeZoneCode": "",  // 时区码, 可能不存在  （每日版本提供）
	    "administrativeAreaCode": "",  // 中国行政区划代码    （每日版本提供）
	    "internationalPhoneCode": "",  // 国际电话代码        （每日版本提供）
	    "countryTwoDigitCode": "",  // 国家二位代码        （每日版本提供）
	    "worldContinentCode": ""  // 世界大洲代码        （每日版本提供）
	}
}
```

*ERROR结果参考*

```json
{
	"success": false,
	"erros": "retun messages..."
}
```

*查询状态结果参考*

```json
{
	"success": true,
	"body": {
		"limit": false, // 是否已受访问限制
       "hour": 99680,  // 一个小时内剩余次数
       "day": 999680,  // 24小时内剩余次数
	}
}
```


如有任何疑问欢迎联系我: solacowa@gmail.com

或访问我 网站: [LatteCake](https://lattecake.com)

